import Foundation

nonisolated(unsafe) var standardError = FileHandle.standardError

func log(_ message: String) {
  print(message, to: &standardError)
}

extension FileHandle: @retroactive TextOutputStream {
  public func write(_ message: String) {
    write(message.data(using: .utf8)!)
  }
}
