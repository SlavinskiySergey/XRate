import AppArchitecture
import ComposableArchitecture
import UserDefaultsClient
import RateListFeature

let store = Store<RateListState, RateListAction>(
  initialState: RateListState(),
  reducer: rateListReducer,
  environment: SystemEnvironment.live(
    environment: RateListEnvironment(
      apiClient: .live,
      userDefaultsClient: .live
    )
  )
)
