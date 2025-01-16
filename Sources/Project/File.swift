import Foundation
import Ink

struct File {
  let source: URL
  
  var isModified: Bool {
    get throws {
      return true
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
    return text
  }
}

extension MarkdownParser {
  nonisolated(unsafe) static let shared = MarkdownParser()
}

extension String {
  func find(_ pattern: String) -> [String] {
    let range = NSRange(location: 0, length: self.utf16.count)
    
    return try! NSRegularExpression(pattern: pattern)
      .matches(in: self, range: range)
      .map { (self as NSString).substring(with: $0.range) }
  }
}

extension URL {
  var contents: String {
    get throws {
      if pathExtension == "md" {
        MarkdownParser.shared.html(from: try rawContents)
      }
      
      else if try context.isEmpty {
        try rawContents
      }
      
      else {
        try rawContents.replacingFirstOccurrence(
          of: try rawContents.find(#"---(\n|.)*?---\n"#).first!,
          with: "")
      }
    }
  }
  
  var context: [String: String] {
    get throws {
      MarkdownParser.shared.parse(try rawContents).metadata
    }
  }

  var isRenderable: Bool {
    ["css", "htm", "html", "js", "md", "rss", "svg", "txt", "xml"]
      .contains(pathExtension)
  }
  
  var rawContents: String {
    get throws {
      String(decoding: try Data(contentsOf: self), as: UTF8.self)
    }
  }
  
  func touch() throws {
    var file = self
    var resourceValues = URLResourceValues()
    resourceValues.contentModificationDate = Date()
    try file.setResourceValues(resourceValues)
  }
}
