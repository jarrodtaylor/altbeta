import Foundation

class Watcher {
  @discardableResult init(_ url: URL) {
    let handler: FSEventStreamCallback = { (_, _, numEvents, eventPaths, _, _) in
      let bufferPathsStart = eventPaths
        .assumingMemoryBound(to: UnsafePointer<CChar>.self)
      
      let bufferPaths = UnsafeBufferPointer(
        start: bufferPathsStart,
        count: numEvents)
      
      let eventURLs = (0..<numEvents)
        .map { URL(bufferPath: bufferPaths[$0]) }
      
      guard !eventURLs.unique
        .filter({
          guard Project.sourceContainsTarget else { return true }
          return !$0.absoluteString.contains(Project.target!.absoluteString)
        }).isEmpty
      else {
        return
      }
      
      Project.build()
    }
    
    let pathsToWatch = [url.path() as NSString] as NSArray
    let sinceWhen = UInt64(kFSEventStreamEventIdSinceNow)
    let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
    
    let stream = FSEventStreamCreate(nil, handler, nil, pathsToWatch, sinceWhen, 1.0, flags)!
    
    FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
    FSEventStreamStart(stream)
    
    log("[watch] watching \(Project.source!.masked) for changes")
  }
}
