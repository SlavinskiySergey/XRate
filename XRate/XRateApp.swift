import ComposableArchitecture
import RateListFeature
import SwiftUI

@main
struct XRateApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationView {
        RateListView(store: store)
      }
    }
  }
}
