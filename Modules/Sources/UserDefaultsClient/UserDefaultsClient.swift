import Foundation

public protocol UserDefaultsStorable: Codable {
  static var key: String { get }
}

public protocol UserDefaultsClient {
  func create<Model: UserDefaultsStorable>(model: Model)
  func delete<Model: UserDefaultsStorable>(modelType: Model.Type)
  func read<Model: UserDefaultsStorable>() -> Model?
}

public final class UserDefaultsClientImpl: UserDefaultsClient {
  private let userDefaults: UserDefaults
  
  init(userDefaults: UserDefaults) {
    self.userDefaults = userDefaults
  }
  
  public func create<Model: UserDefaultsStorable>(model: Model) {
    guard let modelData = try? JSONEncoder().encode(model) else {
      return
    }
    userDefaults.set(modelData, forKey: Model.key)
  }

  public func delete<Model: UserDefaultsStorable>(modelType: Model.Type) {
    userDefaults.removeObject(forKey: modelType.key)
  }

  public func read<Model: UserDefaultsStorable>() -> Model? {
    guard let modelData = userDefaults.data(forKey: Model.key) else {
      return nil
    }
    return try? JSONDecoder().decode(Model.self, from: modelData)
  }
}

public final class UserDefaultsClientMock: UserDefaultsClient {
  private var storage: [String: Codable] = [:]
  
  public static let instance = UserDefaultsClientMock()
  
  public func create<Model: UserDefaultsStorable>(model: Model) {
    storage[Model.key] = model
  }

  public func delete<Model: UserDefaultsStorable>(modelType: Model.Type) {
    storage[Model.key] = nil
  }

  public func read<Model: UserDefaultsStorable>() -> Model? {
    storage[Model.key] as? Model
  }
}

extension UserDefaultsClientImpl {
  public static var live: Self {
    Self(userDefaults: UserDefaults(suiteName: "group.xrate")!)
  }
}
