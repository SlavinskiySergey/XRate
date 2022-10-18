import ApiClient
import AppArchitecture
import CasePaths
import ComposableArchitecture
import CurrencyListFeature
import Foundation
import Models
import UserDefaultsClient
import RateDetailsFeature

public struct RateListState: Equatable {
  var route: Route?
  var baseCurrency: Currency = .eur
  var favoriteCurrencies: Set<Currency> = []
  var favoriteRates: [Rate] = []
  var liveRates: [Rate] = []
  var isLoading = true
  
  public init() {
    self.route = nil
    self.baseCurrency = .eur
    self.favoriteCurrencies = []
    self.favoriteRates = []
    self.liveRates = []
    self.isLoading = true
  }
      
  enum Route: Equatable {
    case currencyList(CurrencyListState)
    case rateDetails(RateDetailsState)
    
    enum Tag: Int {
      case currencyList
      case rateDetails
    }

    var tag: Tag {
      switch self {
      case .currencyList:
        return .currencyList
      case .rateDetails:
        return .rateDetails
      }
    }
  }
}

public enum RateListAction {
  case currencyList(CurrencyListAction)
  case onDidLoad
  case rateListResponse(TaskResult<[Rate]>)
  case rateDetails(RateDetailsAction)
  case setCurrencyList(isPresented: Bool)
  case setRateDetails(Rate?)
}

public struct RateListEnvironment {
  var apiClient: ApiClient
  var userDefaultsClient: UserDefaultsClient
  
  public init(apiClient: ApiClient, userDefaultsClient: UserDefaultsClient) {
    self.apiClient = apiClient
    self.userDefaultsClient = userDefaultsClient
  }
}

public let rateListReducer = Reducer<
  RateListState,
  RateListAction,
  SystemEnvironment<RateListEnvironment>
>.combine(
  currencyListReducer
    ._pullback(
      state: (\RateListState.route)
        .appending(path: /RateListState.Route.currencyList),
      action: /RateListAction.currencyList,
      environment: { _ in () }
    ),
  
  rateDetailsReducer
    ._pullback(
      state: (\RateListState.route)
        .appending(path: /RateListState.Route.rateDetails),
      action: /RateListAction.rateDetails,
      environment: { environment in
        environment.map {
          RateDetailsEnvironment(apiClient: $0.apiClient)
        }
      }
    ),
  
  .init { state, action, environment in
    switch action {
    case .currencyList(.change(let baseCurrency)):
      state.baseCurrency = baseCurrency
      return .fireAndForget {
        environment.userDefaultsClient.create(model: baseCurrency)
      }
                    
    case .onDidLoad:
      if let currency: Currency = environment.userDefaultsClient.read() {
        state.baseCurrency = currency
      }
      if let favoriteCurrencies: Set<Currency> = environment.userDefaultsClient.read() {
        state.favoriteCurrencies = favoriteCurrencies
      }
      return .task { [currency = state.baseCurrency] in
        await .rateListResponse(TaskResult {
          try await environment.apiClient.rateList(ServerRoute.RateList(currency: currency))
        })
      }
      
    case let .rateListResponse(.success(rates)):
      var favoriteRateList: [Rate] = []
      var liveRatesList: [Rate] = []

      for rate in rates {
        let currency = Currency(code: rate.code)
        state.favoriteCurrencies.contains(currency) ?
        favoriteRateList.append(rate) : liveRatesList.append(rate)
      }
      
      state.isLoading = false
      state.favoriteRates = favoriteRateList
      state.liveRates = liveRatesList
      return .none

    case .rateListResponse(.failure):
      state.isLoading = false
      return .none
            
    case .rateDetails(.changeFavorite):
      guard let rateDetailsState = (/RateListState.Route.rateDetails).extract(from: state.route) else {
        return .none
      }
      let currency = Currency(code: rateDetailsState.rate.code)
      
      if state.favoriteCurrencies.contains(currency) {
        state.favoriteCurrencies.remove(currency)
        
        if let index = state.favoriteRates.firstIndex(where: { $0.code == currency.code }) {
          let rate = state.favoriteRates.remove(at: index)
          state.liveRates.insert(rate, at: .zero)
        }
      } else {
        state.favoriteCurrencies.insert(currency)
        
        if let index = state.liveRates.firstIndex(where: { $0.code == currency.code }) {
          let rate = state.liveRates.remove(at: index)
          state.favoriteRates.insert(rate, at: .zero)
        }
      }
      return .fireAndForget { [favoriteCurrencies = state.favoriteCurrencies] in
        environment.userDefaultsClient.create(model: favoriteCurrencies)
      }

    case .rateDetails:
      return .none
      
    case .setCurrencyList(true):
      state.route = .currencyList(
        CurrencyListState(
          baseCurrency: state.baseCurrency,
          currencies: (state.favoriteRates + state.liveRates).map { Currency(code: $0.code) }
        )
      )
      return .none
                
    case .setCurrencyList(false),
        .currencyList(.onDismiss):
      state.route = nil
      state.isLoading = true
      
      return .task { [currency = state.baseCurrency] in
        await .rateListResponse(TaskResult {
          try await environment.apiClient.rateList(ServerRoute.RateList(currency: currency))
        })
      }

    case let .setRateDetails(.some(rate)):
      state.route = .rateDetails(
        RateDetailsState(
          baseCurrency: state.baseCurrency,
          rate: rate,
          isFavorite: state.favoriteRates.contains(rate)
        )
      )
      return .none
      
    case .setRateDetails(.none):
      state.route = nil
      return .none
      
    case .currencyList:
      return .none
    }
  }
)
