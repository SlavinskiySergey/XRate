import Foundation

final class DataLoader: NSObject, @unchecked Sendable {
  private let handlers = TaskHandlersDictionary()
  
  var userSessionDelegate: URLSessionDelegate? {
    didSet {
      userTaskDelegate = userSessionDelegate as? URLSessionTaskDelegate
      userDataDelegate = userSessionDelegate as? URLSessionDataDelegate
    }
  }
  private var userTaskDelegate: URLSessionTaskDelegate?
  private var userDataDelegate: URLSessionDataDelegate?
  
  func startDataTask(_ task: URLSessionDataTask, session: URLSession, delegate: URLSessionDataDelegate?) async throws -> Response<Data> {
    try await withTaskCancellationHandler(handler: { task.cancel() }) {
      try await withUnsafeThrowingContinuation { continuation in
        let handler = DataTaskHandler(delegate: delegate)
        handler.completion = continuation.resume(with:)
        self.handlers[task] = handler
        
        task.resume()
      }
    }
  }
}

extension DataLoader: URLSessionDelegate {
  func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
    userSessionDelegate?.urlSession?(session, didBecomeInvalidWithError: error)
  }
  
  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    if #available(macOS 11.0, *) {
      userSessionDelegate?.urlSessionDidFinishEvents?(forBackgroundURLSession: session)
    }
  }
}

extension DataLoader: URLSessionTaskDelegate {
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let handler = handlers[task] else { return assertionFailure() }
    handlers[task] = nil

    handler.delegate?.urlSession?(session, task: task, didCompleteWithError: error)
    userTaskDelegate?.urlSession?(session, task: task, didCompleteWithError: error)
    
    switch handler {
    case let handler as DataTaskHandler:
      if let response = task.response, error == nil {
        let data = handler.data ?? Data()
        let response = Response(value: data, data: data, response: response, task: task)
        handler.completion?(.success(response))
      } else {
        handler.completion?(.failure(error ?? URLError(.unknown)))
      }
    default:
      break
    }
  }
    
  func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
    handlers[task]?.delegate?.urlSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler) ??
    userTaskDelegate?.urlSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler) ??
    completionHandler(request)
  }
  
  func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
    handlers[task]?.delegate?.urlSession?(session, taskIsWaitingForConnectivity: task)
    userTaskDelegate?.urlSession?(session, taskIsWaitingForConnectivity: task)
  }
  
#if !os(macOS) && !targetEnvironment(macCatalyst) && swift(>=5.7)
  func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
      handlers[task]?.delegate?.urlSession?(session, didCreateTask: task)
      userTaskDelegate?.urlSession?(session, didCreateTask: task)
    }
  }
#endif
  
  func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    handlers[task]?.delegate?.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler) ??
    userTaskDelegate?.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler) ??
    completionHandler(.performDefaultHandling, nil)
  }
  
  func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
    handlers[task]?.delegate?.urlSession?(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler) ??
    userTaskDelegate?.urlSession?(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler) ??
    completionHandler(.continueLoading, nil)
  }
}

extension DataLoader: URLSessionDataDelegate {
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    (handlers[dataTask] as? DataTaskHandler)?.dataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler) ??
    userDataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler) ??
    completionHandler(.allow)
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    guard let handler = handlers[dataTask] as? DataTaskHandler else { return }
    handler.dataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: data)
    userDataDelegate?.urlSession?(session, dataTask: dataTask, didReceive: data)
    
    if handler.data == nil {
      handler.data = Data()
    }
    handler.data!.append(data)
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
    (handlers[dataTask] as? DataTaskHandler)?.dataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
    userDataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
    (handlers[dataTask] as? DataTaskHandler)?.dataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
    userDataDelegate?.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
    (handlers[dataTask] as? DataTaskHandler)?.dataDelegate?.urlSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler) ??
    userDataDelegate?.urlSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler) ??
    completionHandler(proposedResponse)
  }
}

private class TaskHandler {
  let delegate: URLSessionTaskDelegate?
  
  init(delegate: URLSessionTaskDelegate?) {
    self.delegate = delegate
  }
}

private final class DataTaskHandler: TaskHandler {
  typealias Completion = (Result<Response<Data>, Error>) -> Void
  
  let dataDelegate: URLSessionDataDelegate?
  var completion: Completion?
  var data: Data?
  
  override init(delegate: URLSessionTaskDelegate?) {
    self.dataDelegate = delegate as? URLSessionDataDelegate
    super.init(delegate: delegate)
  }
}

protocol OptionalDecoding {}

struct AnyEncodable: Encodable {
  let value: Encodable
  
  func encode(to encoder: Encoder) throws {
    try value.encode(to: encoder)
  }
}

extension OperationQueue {
  static func serial() -> OperationQueue {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    return queue
  }
}

extension Optional: OptionalDecoding {}

func encode(_ value: Encodable, using encoder: JSONEncoder) async throws -> Data? {
  if let data = value as? Data {
    return data
  } else if let string = value as? String {
    return string.data(using: .utf8)
  } else {
    return try await Task.detached {
      try encoder.encode(AnyEncodable(value: value))
    }.value
  }
}

func decode<T: Decodable>(_ data: Data, using decoder: JSONDecoder) async throws -> T {
  if data.isEmpty, T.self is OptionalDecoding.Type {
    return Optional<Decodable>.none as! T
  } else if T.self == Data.self {
    return data as! T
  } else if T.self == String.self {
    guard let string = String(data: data, encoding: .utf8) else {
      throw URLError(.badServerResponse)
    }
    return string as! T
  } else {
    return try await Task.detached {
      try decoder.decode(T.self, from: data)
    }.value
  }
}

/// With iOS 16, there is now a delegate method (`didCreateTask`) that gets
/// called outside of the session's delegate queue, which means that the access
/// needs to be synchronized.
private final class TaskHandlersDictionary {
  private var unfairLock = os_unfair_lock_s()
  private var handlers = [URLSessionTask: TaskHandler]()
  
  subscript(task: URLSessionTask) -> TaskHandler? {
    get {
      os_unfair_lock_lock(&unfairLock)
      defer { os_unfair_lock_unlock(&unfairLock) }
      return handlers[task]
    }
    set {
      os_unfair_lock_lock(&unfairLock)
      defer { os_unfair_lock_unlock(&unfairLock) }
      handlers[task] = newValue
    }
  }
}
