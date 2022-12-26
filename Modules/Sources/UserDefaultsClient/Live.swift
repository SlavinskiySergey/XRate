import Foundation

extension UserDefaultsClient {
  public static var live: Self {
    Self(userDefaults: .standard)
  }
}
