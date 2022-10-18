import Foundation

extension Double {
  public func formatted() -> String {
    rateFormatter.string(for: self) ?? ""
  }
}

private let rateFormatter: NumberFormatter = {
  let formatter = NumberFormatter()
  formatter.numberStyle = .decimal
  formatter.minimumFractionDigits = 2
  formatter.maximumFractionDigits = 2
  return formatter
}()
