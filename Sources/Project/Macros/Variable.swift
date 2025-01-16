import Foundation

struct Variable {
  static let pattern =
    #"((<!--|/\*)\s*@[\s\S]*?(-->|\*/)|//[^\S\r\n]*@[^\n]*)"#

  var fragment: String

  var arguments: [String] {
    var match = ""
    
    if let result = try? /\/\/\s*@+(?<match>.+?)/
      .wholeMatch(in: fragment)
    {
      match = result.match.description
    }
    
    if let result = try? /(\<!--|\/\*)\s*@(?<match>(.|\n)+?)(-->|\*\/)/
      .wholeMatch(in: fragment)
    {
      match = result.match.description
    }
    
    var args = match.split(separator: "??", maxSplits: 1)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    args[0] = "@" + args[0]
    
    return args
  }

  var key: String { arguments.first! }

  var defaultValue: String? {
    guard arguments.count == 2 else {
      return nil
    }
    
    return arguments.last
  }
}
