import Foundation

extension Array where Element: Hashable {
  var unique: [Element] {
    Array(Set(self))
  }
}
