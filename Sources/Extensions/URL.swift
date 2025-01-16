import Foundation
import Ink

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

  var dependencies: [File] {
    get throws {
      guard isRenderable else {
        return []
      }
      
      var deps: [File?] = []
      
      for match in try contents.find(Include.pattern) {
        deps.append(Include(fragment: match).file)
      }
      
      if let ref = try context["#layout"] {
        deps.append(Project.file(ref))
      }
      
      return try deps
        .filter { $0 != nil && $0!.source.exists == true }
        .map { $0! }
        .flatMap { try [$0] + $0.source.dependencies }
        .map { $0.source }
        .unique
        .map { File(source: $0) }
    }
  }

  var exists: Bool {
    var isDir: ObjCBool = true
    
    return FileManager.default.fileExists(
      atPath: path(percentEncoded: false),
      isDirectory: &isDir)
  }
  
  var files: [URL] {
    list.filter { !$0.isDirectory }
  }

  var folders: [URL] {
    list.filter { $0.isDirectory }
  }

  var isDirectory: Bool {
    (try? resourceValues(forKeys: [.isDirectoryKey]))?
      .isDirectory == true
  }
  
  var isRenderable: Bool {
    ["css", "htm", "html", "js", "md", "rss", "svg", "txt", "xml"]
      .contains(pathExtension)
  }
  
  var list: [URL] {
    guard exists else { return [] }
    
    return FileManager.default
      .subpaths(atPath: path())!
      .filter { !$0.contains(".DS_Store") }
      .map { appending(component: $0) }
  }

  var masked: String {
    path(percentEncoded: false)
      .replacingFirstOccurrence(
        of: FileManager.default.currentDirectoryPath,
        with: "")
      .replacingFirstOccurrence(
        of: "file:///",
        with: "")
      .asRef
  }
  
  var modificationDate: Date? {
    get throws {
      let attributes = try FileManager.default
        .attributesOfItem(atPath: path(percentEncoded: false))
      
      return attributes[FileAttributeKey.modificationDate] as? Date
    }
  }
  
  var rawContents: String {
    get throws {
      String(decoding: try Data(contentsOf: self), as: UTF8.self)
    }
  }

  init(bufferPath: UnsafePointer<Int8>) {
    self = URL(
      fileURLWithFileSystemRepresentation: bufferPath,
      isDirectory: false,
      relativeTo: nil)
  }
  
  func touch() throws {
    var file = self
    var resourceValues = URLResourceValues()
    resourceValues.contentModificationDate = Date()
    try file.setResourceValues(resourceValues)
  }
}
