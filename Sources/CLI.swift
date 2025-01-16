import ArgumentParser
import Foundation

@main
struct CLI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "alternator",
    abstract: "Alternator builds static websites.",
    discussion: "Visit https://alternator.sh to learn more.",
    version: "2.0.0")
  
  @Argument(help: "Path to your source directory.")
  var source: String = "."

  @Argument(help: "Path to your target directory.")
  var target: String = "<source>/_build"
  
  @Option(name: .shortAndLong, help: "Port for the localhost server.")
  var port: UInt16?
  
  mutating func run() throws {
    if target == "<source>/_build" {
      target = "\(source)/_build"
    }
    
    Project.source = URL(
      string: source.asRef,
      relativeTo: URL.currentDirectory())
    
    Project.target = URL(
      string: target.asRef,
      relativeTo: URL.currentDirectory())
    
    guard Project.source!.exists else {
      throw ValidationError("<source> does not exist.")
    }
    
    guard Project.source!.masked != Project.target!.masked else {
      throw ValidationError("<source> and <target> cannot be the same directory.")
    }
    
    Project.build()
    
    if let port = port {
      Watcher(Project.source!)
      Server(path: Project.target!.masked, port: port)
      
      log("^c to stop")
      RunLoop.current.run()
    }
  }
}

nonisolated(unsafe) var standardError = FileHandle.standardError

func log(_ message: String) {
  print(message, to: &standardError)
}

extension FileHandle: @retroactive TextOutputStream {
  public func write(_ message: String) {
    write(message.data(using: .utf8)!)
  }
}
