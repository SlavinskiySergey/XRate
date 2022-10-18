import Foundation
import ComposableArchitecture
import Models

public struct CurrencyListState: Equatable {
  var baseCurrency: Currency
  let currencies: [Currency]
  var searchQuery = ""
  var searchResults: [Currency]
  
  public init(baseCurrency: Currency, currencies: [Currency]) {
    self.baseCurrency = baseCurrency
    self.currencies = currencies
    self.searchResults = currencies
  }
}

public enum CurrencyListAction: Equatable {
  case change(baseCurrency: Currency)
  case onDismiss
  case searchQueryChanged(String)
}

public let currencyListReducer = Reducer<
  CurrencyListState,
  CurrencyListAction,
  Void
> {
  state, action, _ in
  switch action {
  case let .change(baseCurrency):
    state.baseCurrency = baseCurrency
    return .none
    
  case .onDismiss:
    return .none
    
  case let .searchQueryChanged(query):
    guard !query.isEmpty else {
      state.searchResults = state.currencies
      return .none
    }
    
    state.searchResults = state.currencies.filter { $0.code.lowercased().contains(query.lowercased()) }
    return .none
  }
}
