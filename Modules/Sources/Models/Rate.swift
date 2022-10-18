import Foundation

public struct Rate: Hashable {
  public let code: String
  public let value: Double
  
  public init(code: String, value: Double) {
    self.code = code
    self.value = value
  }
}
