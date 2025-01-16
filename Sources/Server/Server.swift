import Foundation
import Network

final class Server: Sendable {
  let listener: NWListener
  let path: String

  @discardableResult init(path: String, port: UInt16) {
    self.path = path

    self.listener = try! NWListener(
      using: .tcp,
      on: NWEndpoint.Port(rawValue: port)!)

    listener.newConnectionHandler = handleConnection
    listener.start(queue: .main)

    log("[serve] serving \(path) on http://localhost:\(port)")
  }

  func handleConnection(_ connection: NWConnection) {
    connection.start(queue: .main)
    receive(from: connection)
  }

  func receive(from connection: NWConnection) {
    connection.receive(
      minimumIncompleteLength: 1,
      maximumLength: connection.maximumDatagramSize)
    { content, _, complete, err in
      if let err {
        self.logRequest(err: err)
      } else if let content, let req = Request(content) {
        self.respond(on: connection, req: req)
      }
      
      if !complete {
        self.receive(from: connection)
      }
    }
  }

  func respond(on connection: NWConnection, req: Request) {
    guard req.method == "GET" else {
      let res = Response(.teapot)
      self.logRequest(req: req, res: res)
      connection.send(content: res.data, completion: .idempotent)
      return
    }

    func findFile(_ filePath: String) -> String? {
      guard let foundPath = [
        filePath,
        filePath + "/index.html",
        filePath + "/index.htm"
      ].first(where: {
          var isDir: ObjCBool = false
          return FileManager.default.fileExists(
            atPath: $0,
            isDirectory: &isDir)
          ? !isDir.boolValue : false
        })
      else {
        return nil
      }
      
      return foundPath
    }

    guard
      let filePath = findFile(self.path + req.path),
      let res = try? Response(filePath: filePath)
    else {
      let res = Response(.notFound)
      logRequest(req: req, res: res)
      connection.send(content: res.data, completion: .idempotent)
      return
    }
    
    logRequest(req: req, res: res)
    connection.send(content: res.data, completion: .idempotent)
  }

  func logRequest(
    req: Request? = nil,
    res: Response? = nil,
    err: NWError? = nil)
  {
    var message: [String] = ["[serve]"]
    if let req { message.append(req.path) }
    if let res { message.append("(\(res.status.rawValue) \(res.status))") }
    if let err { message.append("Error: \(err)") }
    
    log(message.joined(separator: " "))
  }
}
