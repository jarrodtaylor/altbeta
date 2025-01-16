import Foundation

struct Layout {
  static let pattern =
    #"((<!--|/\*)\s*#content[\s\S]*?(-->|\*/)|//[^\S\r\n]*#content[^\n]*)"#

  let template: File
  let content: String

  var context: [String: String] {
    get throws {
      try template.source.context
    }
  }

  func render() throws -> String {
    var text = try template.source.contents
    
    for match in text.find(Layout.pattern) {
      text = text.replacingFirstOccurrence(of: match, with: content)
    }
    
    if
      let ref = try context["#layout"],
      let file = Project.file(ref)
    {
      text = try Layout(template: file, content: text).render()
    }
    
    return text
  }
}
