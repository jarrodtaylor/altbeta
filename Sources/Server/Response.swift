import Foundation
import UniformTypeIdentifiers

struct Response {
  let body: Data
  let headers: [Header: String]
  let httpVersion = "HTTP/1.1"
  let status: Status

  enum Header: String {
    case contentLength = "Content-Length"
    case contentType = "Content-Type"
  }

  enum Status: Int, CustomStringConvertible {
    case ok = 200
    case notFound = 404
    case teapot = 418
    
    var description: String {
      switch self {
        case .ok: return "OK"
        case .notFound: return "Not Found"
        case .teapot: return "I'm a teapot"
      }
    }
  }

  var data: Data {
    var headerLines = ["\(httpVersion) \(status.rawValue) \(status)"]
    
    headerLines.append(
      contentsOf: headers.map({ "\($0.key.rawValue): \($0.value)" }))
    headerLines.append("")
    headerLines.append("")

    let header = headerLines
      .joined(separator: "\r\n")
      .data(using: .utf8)!

    return header + body
  }

  init(
    _ status: Status = .ok,
    body: Data = Data(),
    contentType: UTType? = nil,
    headers: [Header: String] = [:]
  ) {
    self.body = body
    
    let (contentLength, contentType) =
      (String(body.count), contentType?.preferredMIMEType)
    
    self.headers = headers.merging(
      [.contentLength: contentLength, .contentType: contentType]
        .compactMapValues { $0 },
      uniquingKeysWith: { _, new in new })
    
    self.status = status
  }

  init(filePath: String) throws {
    let url = URL(filePath: filePath)
    
    self.init(
      body: try Data(contentsOf: url),
      contentType: try url.resourceValues(forKeys: [.contentTypeKey])
        .contentType)
  }

  init(_ text: String, contentType: UTType = .plainText) {
    self.init(
      body: text.data(using: .utf8)!,
      contentType: contentType
    )
  }
}
