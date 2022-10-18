import Foundation

public struct RateDetails: Equatable {
  public let date: String
  public let value: Double
  
  public init(date: String, value: Double) {
    self.date = date
    self.value = value
  }
}

extension RateDetails: Identifiable {
  public var id: String { date }
}
