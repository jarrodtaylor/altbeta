import Foundation

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
    log("build file")
  }
}
