import Foundation

public struct Currency: Hashable, Codable {
  public let code: String
  
  public init(code: String) {
    self.code = code
  }
}

extension Currency: Identifiable {
  public var id: String { code }
}

extension Currency {
  public static let eur = Currency(code: "EUR")
}
