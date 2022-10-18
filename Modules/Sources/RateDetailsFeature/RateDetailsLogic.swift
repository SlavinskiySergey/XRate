import ApiClient
import AppArchitecture
import ComposableArchitecture
import Foundation
import Models
import ApiClient

public struct RateDetailsState: Equatable {
  public let baseCurrency: Currency
  public let rate: Rate
  public var list: [RateDetails] = []
  public var isLoading = true
  public var isFavorite: Bool
  
  public init(
    baseCurrency: Currency,
    rate: Rate,
    list: [RateDetails] = [],
    isLoading: Bool = true,
    isFavorite: Bool
  ) {
    self.baseCurrency = baseCurrency
    self.rate = rate
    self.list = list
    self.isLoading = isLoading
    self.isFavorite = isFavorite
  }
}

public enum RateDetailsAction {
  case onAppear
  case rateDetailsResponse(TaskResult<[RateDetails]>)
  case changeFavorite
}

public struct RateDetailsEnvironment {
  var apiClient: ApiClient
  
  public init(apiClient: ApiClient) {
    self.apiClient = apiClient
  }
}

public let rateDetailsReducer = Reducer<
  RateDetailsState,
  RateDetailsAction,
  SystemEnvironment<RateDetailsEnvironment>
> { state, action, environment in
  switch action {
  case .onAppear:
    return .task { [state] in
      await .rateDetailsResponse(TaskResult {
        let request = ServerRoute.RateDetails(
          currency: state.baseCurrency,
          rate: state.rate,
          startDate: environment.calendar().date(byAdding: .weekOfYear, value: -52, to: environment.date())!,
          endDate: environment.date()
        )
        return try await environment.apiClient.rateDetailsList(request)
      })
    }
    
  case let .rateDetailsResponse(.success(list)):
    state.isLoading = false
    state.list = list
    return .none
    
  case .rateDetailsResponse(.failure):
    state.isLoading = false
    return .none
    
  case .changeFavorite:
    state.isFavorite = !state.isFavorite
    return .none
  }
}
