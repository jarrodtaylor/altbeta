import Foundation

struct Include {
  static let pattern =
    #"((<!--|/\*)\s*#include[\s\S]*?(-->|\*/)|//[^\S\r\n]*#include[^\n]*)"#

  var fragment: String

  var arguments: String? {
    if let result = try? /\/\/\s*#include\s+(?<match>.+?)/
      .wholeMatch(in: fragment)
    {
      return result.match.description
    }
    
    if let result = try? /(\<!--|\/\*)\s*#include\s+(?<match>(.|\n)+?)(-->|\*\/)/
      .wholeMatch(in: fragment)
    {
      return result.match.description
    }
    
    return nil
  }

  var file: File? {
    guard let ref = arguments?
      .split(separator: " ").first?.description
      .trimmingCharacters(in: .whitespacesAndNewlines)
    else {
      return nil
    }
    
    return Project.file(ref)
  }

  var parameters: [String: String] {
    var params: [String: String] = [:]
    
    guard let args = arguments?
      .split(separator: " ").dropFirst().joined(separator: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    else {
      return params
    }
    
    let keys = args.find(#"(@\S+:|#\S+:)"#)
      .map { $0.dropLast().description }
    
    let vals = args.split(separator: /(@\S+:|#\S+:)/)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    for (k, v) in zip(keys, vals) {
      params[k] = v.description
    }
    
    return params
  }
}
