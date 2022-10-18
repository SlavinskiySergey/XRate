import Foundation
import ComposableArchitecture

@dynamicMemberLookup
public struct SystemEnvironment<Environment> {
  public var environment: Environment
  
  public subscript<Dependency>(
    dynamicMember keyPath: WritableKeyPath<Environment, Dependency>
  ) -> Dependency {
    get { self.environment[keyPath: keyPath] }
    set { self.environment[keyPath: keyPath] = newValue }
  }
  
  public var date: () -> Date
  public var calendar: () -> Calendar
    
  public static func live(environment: Environment) -> Self {
    Self(
      environment: environment,
      date: Date.init,
      calendar: { Calendar(identifier: .gregorian) }
    )
  }
  
  public func map<NewEnvironment>(
    _ transform: @escaping (Environment) -> NewEnvironment
  ) -> SystemEnvironment<NewEnvironment> {
    .init(
      environment: transform(self.environment),
      date: self.date,
      calendar: self.calendar
    )
  }
}
