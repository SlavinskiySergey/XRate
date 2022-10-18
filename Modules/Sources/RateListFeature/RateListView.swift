import ComposableArchitecture
import CurrencyListFeature
import Models
import SwiftUI
import RateDetailsFeature
import UserDefaultsClient

public struct RateListView: View {
  struct ViewState: Equatable {
    let baseCurrency: Currency
    let favoriteCurrencies: Set<Currency>
    let favoriteRates: [Rate]
    let liveRates: [Rate]
    let isLoading: Bool
    let routeTag: RateListState.Route.Tag?
    
    var isCurrencyListPresented: Bool {
      routeTag == .currencyList
    }
    
    var isRateDetailsPresented: Bool {
      routeTag == .rateDetails
    }
    
    init(state: RateListState) {
      self.baseCurrency = state.baseCurrency
      self.favoriteCurrencies = state.favoriteCurrencies
      self.favoriteRates = state.favoriteRates
      self.liveRates = state.liveRates
      self.isLoading = state.isLoading
      self.routeTag = state.route?.tag
    }
  }
  
  let store: Store<RateListState, RateListAction>
  @ObservedObject var viewStore: ViewStore<ViewState, RateListAction>
  
  public init(store: Store<RateListState, RateListAction>) {
    self.store = store
    self.viewStore = ViewStore(store.scope(state: ViewState.init(state:)))
  }
  
  @State private var didLoad = false
  
  public var body: some View {
    VStack {
      if viewStore.isLoading {
        ProgressView()
      } else {
        ScrollView {
          LazyVStack {
            if !viewStore.favoriteRates.isEmpty {
              section(for: viewStore.favoriteRates, with: "Favorites")
            }
            
            section(for: viewStore.liveRates, with: "Live rates")
          }
        }
      }
    }
    .background(
      NavigationLink(
        destination: IfLetStore(
          self.store.scope(
            state: (\RateListState.route)
              .appending(path: /RateListState.Route.rateDetails)
              .extract(from:),
            action: RateListAction.rateDetails
          ),
          then: RateDetailsView.init(store:)
        ),
        isActive: viewStore.binding(
          get: \.isRateDetailsPresented,
          send: RateListAction.setRateDetails(nil)
        ),
        label: EmptyView.init
      )
    )
    .navigationBarTitle {
      Button(action: {
        viewStore.send(.setCurrencyList(isPresented: true))
      }) {
        BaseCurrencyView(currency: viewStore.baseCurrency)
      }
    }
    .onAppear {
      if didLoad == false {
        didLoad = true
        viewStore.send(.onDidLoad)
      }
    }
    .sheet(
      isPresented: viewStore.binding(
        get: \.isCurrencyListPresented,
        send: RateListAction.setCurrencyList(isPresented:)
      )
    ) {
      IfLetStore(
        self.store.scope(
          state: (\RateListState.route)
            .appending(path: /RateListState.Route.currencyList)
            .extract(from:),
          action: RateListAction.currencyList
        ),
        then: CurrencyListView.init(store:)
      )
    }
  }
  
  @ViewBuilder
  func section(for items: [Rate], with text: String) -> some View {
    HeaderView(text: text)
    ForEach(items, id: \.code) { rate in
      RateRowView(rate: rate)
        .onTapGesture {
          viewStore.send(.setRateDetails(rate))
        }
    }
  }
}


struct RateListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      RateListView(
        store: Store(
          initialState: RateListState(),
          reducer: rateListReducer,
          environment: .live(
            environment: RateListEnvironment(
              apiClient: .mock,
              userDefaultsClient: UserDefaultsClientMock.instance
            )
          )
        )
      )
    }
  }
}

extension View {
  func navigationBarTitle<Content>(
    @ViewBuilder content: () -> Content
  ) -> some View where Content : View {
    self.toolbar {
      ToolbarItem(placement: .principal, content: content)
    }
  }
}
