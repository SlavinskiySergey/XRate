import Foundation
import Models

extension Currency: UserDefaultsStorable {
  public static var key: String {
    "CurrencyKey"
  }
}

extension Set: UserDefaultsStorable where Element == Currency {
  public static var key: String {
    "FavouriteCurrenciesKey"
  }
}
