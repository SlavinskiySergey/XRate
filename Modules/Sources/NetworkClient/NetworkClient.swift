import Foundation

public actor NetworkClient {
  public nonisolated let configuration: Configuration
  public nonisolated let session: URLSession
  
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder
  private let dataLoader = DataLoader()
    
  public struct Configuration: @unchecked Sendable {
    public var baseURL: URL?
    public var sessionConfiguration: URLSessionConfiguration = .default
    public var sessionDelegate: URLSessionDelegate?
    public var sessionDelegateQueue: OperationQueue?
    public var decoder: JSONDecoder
    public var encoder: JSONEncoder

    public init(
      baseURL: URL?,
      sessionConfiguration: URLSessionConfiguration = .default
    ) {
      self.baseURL = baseURL
      self.sessionConfiguration = sessionConfiguration
      self.decoder = JSONDecoder()
      self.decoder.dateDecodingStrategy = .iso8601
      self.encoder = JSONEncoder()
      self.encoder.dateEncodingStrategy = .iso8601
    }
  }
  
  public convenience init(baseURL: URL?) {
    self.init(configuration: Configuration(baseURL: baseURL))
  }
  
  public init(configuration: Configuration) {
    self.configuration = configuration
    let delegateQueue = configuration.sessionDelegateQueue ?? .serial()
    self.session = URLSession(configuration: configuration.sessionConfiguration, delegate: dataLoader, delegateQueue: delegateQueue)
    self.dataLoader.userSessionDelegate = configuration.sessionDelegate
    self.decoder = configuration.decoder
    self.encoder = configuration.encoder
  }
  
  @discardableResult public func send<T: Decodable>(
    _ request: Request<T>,
    delegate: URLSessionDataDelegate? = nil,
    configure: ((inout URLRequest) throws -> Void)? = nil
  ) async throws -> Response<T> {
    let response = try await data(for: request, delegate: delegate, configure: configure)
    let value: T = try await decode(response.data, using: decoder)
    return response.map { _ in value }
  }
  
  @discardableResult public func send(
    _ request: Request<Void>,
    delegate: URLSessionDataDelegate? = nil,
    configure: ((inout URLRequest) throws -> Void)? = nil
  ) async throws -> Response<Void> {
    try await data(for: request, delegate: delegate, configure: configure).map { _ in () }
  }
  
  public func data<T>(
    for request: Request<T>,
    delegate: URLSessionDataDelegate? = nil,
    configure: ((inout URLRequest) throws -> Void)? = nil
  ) async throws -> Response<Data> {
    let request = try await makeURLRequest(for: request, configure)
    let task = session.dataTask(with: request)
    return try await dataLoader.startDataTask(task, session: session, delegate: delegate)
  }

  public func makeURLRequest<T>(for request: Request<T>) async throws -> URLRequest {
    try await makeURLRequest(for: request, { _ in })
  }
  
  private func makeURLRequest<T>(
    for request: Request<T>,
    _ configure: ((inout URLRequest) throws -> Void)?
  ) async throws -> URLRequest {
    let url = try makeURL(for: request)
    var urlRequest = URLRequest(url: url)
    urlRequest.allHTTPHeaderFields = request.headers
    urlRequest.httpMethod = request.method.rawValue
    if let body = request.body {
      urlRequest.httpBody = try await encode(body, using: encoder)
      if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil &&
          session.configuration.httpAdditionalHeaders?["Content-Type"] == nil {
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      }
    }
    if urlRequest.value(forHTTPHeaderField: "Accept") == nil &&
        session.configuration.httpAdditionalHeaders?["Accept"] == nil {
      urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    }
    if let configure = configure {
      try configure(&urlRequest)
    }
    return urlRequest
  }
  
  private func makeURL<T>(for request: Request<T>) throws -> URL {
    func makeURL() -> URL? {
      guard let url = request.url else {
        return nil
      }
      return url.scheme == nil ? configuration.baseURL?.appendingPathComponent(url.absoluteString) : url
    }
    guard let url = makeURL(), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      throw URLError(.badURL)
    }
    if let query = request.query, !query.isEmpty {
      components.queryItems = query.map(URLQueryItem.init)
    }
    guard let url = components.url else {
      throw URLError(.badURL)
    }
    return url
  }
}
