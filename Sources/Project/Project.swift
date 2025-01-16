import Foundation

struct Project {
  nonisolated(unsafe) static var source: URL?
  nonisolated(unsafe) static var target: URL?
  
  static func build() {
    log("TODO: build project")
  }
}

extension String {
  var asRef: String {
    split(separator: "/")
      .joined(separator: "/")
  }
    
  func replacingFirstOccurrence(of: String, with: String) -> String {
    guard let range = range(of: of) else {
      return self
    }
    
    return replacingCharacters(in: range, with: with)
  }
}

extension URL {
  var exists: Bool {
    var isDir: ObjCBool = true
    
    return FileManager.default.fileExists(
      atPath: path(percentEncoded: false),
      isDirectory: &isDir)
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
}
