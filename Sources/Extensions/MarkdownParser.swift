import Ink

extension MarkdownParser {
  nonisolated(unsafe) static let shared = MarkdownParser()
}
