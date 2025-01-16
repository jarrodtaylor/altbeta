import Foundation

extension String {
  var asRef: String {
    split(separator: "/")
      .joined(separator: "/")
  }
  
  func find(_ pattern: String) -> [String] {
    let range = NSRange(location: 0, length: self.utf16.count)
    
    return try! NSRegularExpression(pattern: pattern)
      .matches(in: self, range: range)
      .map { (self as NSString).substring(with: $0.range) }
  }
  
  func replacingFirstOccurrence(of: String, with: String) -> String {
    guard let range = range(of: of) else {
      return self
    }
    
    return replacingCharacters(in: range, with: with)
  }
}
