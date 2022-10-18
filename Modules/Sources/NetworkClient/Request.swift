import Foundation

public struct Request<Response>: @unchecked Sendable {
  public var method: HTTPMethod
  public var url: URL?
  public var query: [(String, String?)]?
  public var body: Encodable?
  public var headers: [String: String]?
  
  public init(
    url: URL,
    method: HTTPMethod = .get,
    query: [(String, String?)]? = nil,
    body: Encodable? = nil,
    headers: [String: String]? = nil
  ) {
    self.method = method
    self.url = url
    self.query = query
    self.headers = headers
    self.body = body
  }
  
  public init(
    path: String,
    method: HTTPMethod = .get,
    query: [(String, String?)]? = nil,
    body: Encodable? = nil,
    headers: [String: String]? = nil
  ) {
    self.method = method
    self.url = URL(string: path.isEmpty ? "/" : path)
    self.query = query
    self.headers = headers
    self.body = body
  }
  
  private init(optionalUrl: URL?, method: HTTPMethod) {
    self.url = optionalUrl
    self.method = method
  }
  
  public func withResponse<T>(_ type: T.Type) -> Request<T> {
    var copy = Request<T>(optionalUrl: url, method: method)
    copy.query = query
    copy.body = body
    copy.headers = headers
    return copy
  }
}

extension Request where Response == Void {
  public init(
    url: URL,
    method: HTTPMethod = .get,
    query: [(String, String?)]? = nil,
    body: Encodable? = nil,
    headers: [String: String]? = nil
  ) {
    self.method = method
    self.url = url
    self.query = query
    self.headers = headers
    self.body = body
  }
  
  public init(
    path: String,
    method: HTTPMethod = .get,
    query: [(String, String?)]? = nil,
    body: Encodable? = nil,
    headers: [String: String]? = nil
  ) {
    self.method = method
    self.url = URL(string: path.isEmpty ? "/" : path)
    self.query = query
    self.headers = headers
    self.body = body
  }
}

public struct HTTPMethod: RawRepresentable, Hashable, ExpressibleByStringLiteral {
  public let rawValue: String
  
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
  
  public init(stringLiteral value: String) {
    self.rawValue = value
  }
  
  public static let get: HTTPMethod = "GET"
  public static let post: HTTPMethod = "POST"
  public static let patch: HTTPMethod = "PATCH"
  public static let put: HTTPMethod = "PUT"
  public static let delete: HTTPMethod = "DELETE"
  public static let options: HTTPMethod = "OPTIONS"
  public static let head: HTTPMethod = "HEAD"
  public static let trace: HTTPMethod = "TRACE"
}
