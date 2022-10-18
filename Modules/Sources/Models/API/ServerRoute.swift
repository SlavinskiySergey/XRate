import Foundation

public enum ServerRoute {
  
  public struct RateDetails {
    public let currency: Currency
    public let rate: Rate
    public let startDate: Date
    public let endDate: Date
    
    public init(
      currency: Currency,
      rate: Rate,
      startDate: Date,
      endDate: Date
    ) {
      self.currency = currency
      self.rate = rate
      self.startDate = startDate
      self.endDate = endDate
    }
  }
  
  public struct RateList {
    public let currency: Currency
    
    public init(currency: Currency) {
      self.currency = currency
    }
  }
}
