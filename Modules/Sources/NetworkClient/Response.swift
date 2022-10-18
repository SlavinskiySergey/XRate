import Foundation

public struct Response<T> {
  public let value: T
  public let data: Data
  public let response: URLResponse
  public let task: URLSessionTask
  
  public var statusCode: Int? {
    (response as? HTTPURLResponse)?.statusCode
  }
  public var originalRequest: URLRequest? {
    task.originalRequest
  }
  public var currentRequest: URLRequest? {
    task.currentRequest
  }
  
  public init(value: T, data: Data, response: URLResponse, task: URLSessionTask) {
    self.value = value
    self.data = data
    self.response = response
    self.task = task
  }
  
  public func map<U>(_ closure: (T) throws -> U) rethrows -> Response<U> {
    Response<U>(value: try closure(value), data: data, response: response, task: task)
  }
}

extension Response: @unchecked Sendable where T: Sendable {}
