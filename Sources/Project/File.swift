import Foundation
import Ink

struct File {
  let source: URL
  
  var isModified: Bool {
    get throws {
      guard target.exists,
        let sourceModDate = try source.modificationDate,
        let targetModDate = try target.modificationDate,
        targetModDate > sourceModDate
      else { return true }
      for dependency in try source.dependencies {
        if let dependencyModDate = try dependency.source.modificationDate,
          dependencyModDate > targetModDate
        { return true } }
      return false
    }
  }

  var ref: String {
    source
      .path(percentEncoded: false)
      .replacingFirstOccurrence(
        of: Project.source!.path(),
        with: "")
      .asRef
  }
  
  var target: URL {
    var targetURL: URL = Project.target!.appending(path: ref)
    
    if targetURL.pathExtension == "md" {
      targetURL = targetURL
        .deletingPathExtension()
        .appendingPathExtension("html")
    }

    return targetURL
  }

  
  func build() throws {
    if target.exists {
      try FileManager.default.removeItem(at: target)
    }
    
    let directoryPath = target
      .deletingLastPathComponent()
      .path(percentEncoded: false)
    
    try FileManager.default.createDirectory(
      atPath: directoryPath,
      withIntermediateDirectories: true)

    if source.isRenderable {
      log("[build] rendering \(source.masked) -> \(target.masked)")
      FileManager.default.createFile(
        atPath: target.path(percentEncoded: false),
        contents: try render().data(using: .utf8))
    }
    
    else {
      log("[build] copying \(source.masked) -> \(target.masked)")
      try source.touch()
      try FileManager.default
        .copyItem(at: source, to: target)
      try target.touch()
    }
  }
  
  func render(_ context: [String: String] = [:]) throws -> String {
    var (context, text) = (context, try source.contents)

    for (key, val) in try source.context {
      guard !context.keys.contains(key) || context["#isIncluding"] != "true"
      else {
        continue
      }
      
      context[key] = val
    }
    
    if context["#forceLayout"] == "true" || context["#isIncluding"] != "true",
       let layoutRef = context["#layout"],
       let layoutFile = Project.file(layoutRef)
    {
      let macro = Layout(template: layoutFile, content: text)
      
      for (key, val) in try macro.context {
        if context[key] == nil {
          context[key] = val
        }
      }
      
      text = try macro.render()
    }
    
    for match in text.find(Include.pattern) {
      let macro = Include(fragment: match)

      if macro.file?.source.exists == true {
        var params = macro.parameters
        
        for (key, val) in params {
          if let v = context[val] {
            params[key] = v
          }
        }
        
        params["#isIncluding"] = "true"
        
        text = text.replacingFirstOccurrence(
          of: match,
          with: try macro.file!.render(params))
      }
    }
    
    for match in text.find(Variable.pattern) {
      let macro = Variable(fragment: match)
      
      let contextContainsKey = context
        .contains(where: { $0.key == macro.key })
      
      if let val = contextContainsKey
          ? context[macro.key]
          : macro.defaultValue
      {
        text = text.replacingFirstOccurrence(
          of: match,
          with: val as String)
      }
    }
    
    return text
  }
}
