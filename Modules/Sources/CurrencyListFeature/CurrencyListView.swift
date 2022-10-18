import SwiftUI
import ComposableArchitecture
import Models

public struct CurrencyListView: View {
  let store: Store<CurrencyListState, CurrencyListAction>
  
  public init(store: Store<CurrencyListState, CurrencyListAction>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
        VStack {
          HStack {
            Image(systemName: "magnifyingglass")
              .foregroundColor(.gray)
            TextField(
              "Search",
              text: viewStore.binding(
                get: \.searchQuery,
                send: CurrencyListAction.searchQueryChanged
              )
            )
          }
          .padding(16)
          
          List {
            ForEach(viewStore.searchResults) { currency in
              Button(action: {
                viewStore.send(.change(baseCurrency: currency))
              }) {
                HStack {
                  Spacer()
                    .frame(width: 16)
                  Text(currency.code)
                    .font(.title3)
                    .foregroundColor(.black)
                  Spacer()
                  if currency == viewStore.baseCurrency {
                    Image(systemName: "checkmark")
                      .resizable()
                      .frame(width: 12, height: 8)
                    Spacer()
                      .frame(width: 16)
                  }
                }
              }
              .buttonStyle(BorderlessButtonStyle())
            }
          }
          .listStyle(.inset)
        }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Dismiss") {
              viewStore.send(.onDismiss)
            }
          }
        }
      }
    }
  }
}

struct CurrencyListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      CurrencyListView(
        store: Store(
          initialState: CurrencyListState(
            baseCurrency: Currency(code: "USD"),
            currencies: [
              Currency(code: "EUR"),
              Currency(code: "USD"),
              Currency(code: "BYN")
            ]
          ),
          reducer: currencyListReducer,
          environment: ()
        )
      )
    }
  }
}
