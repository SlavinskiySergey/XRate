import ComposableArchitecture
import Models
import SwiftUI

public struct RateDetailsView: View {
  let store: Store<RateDetailsState, RateDetailsAction>
  
  public init(store: Store<RateDetailsState, RateDetailsAction>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store) { viewStore in
      Group {
        if viewStore.isLoading {
          ProgressView()
        } else {
          ScrollView {
            LazyVStack {
              HeaderView(text: "Historical rates")
              ForEach(viewStore.list) { item in
                RateDetailsRowView(rateDetails: item)
              }
            }
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          VStack {
            HStack {
              Text(viewStore.baseCurrency.code)
              Text("·")
              Text(viewStore.rate.code)
            }
            Text("\(viewStore.rate.value)")
            Spacer()
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { viewStore.send(.changeFavorite) }) {
            Image(systemName: viewStore.isFavorite ? "star.fill" : "star")
          }
        }
      }
      .onAppear {
        viewStore.send(.onAppear)
      }
    }
  }
}

struct RateDetailsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      RateDetailsView(
        store: Store(
          initialState: RateDetailsState(
            baseCurrency: Currency(code: "USD"),
            rate: Rate(code: "EUR", value: 1.01),
            isFavorite: false
          ),
          reducer: rateDetailsReducer,
          environment: .live(
            environment: RateDetailsEnvironment(
              apiClient: .mock
            )
          )
        )
      )
    }
  }
}
