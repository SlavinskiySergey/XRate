import ApiClient
import ComposableArchitecture
import Foundation
import Models

@Sendable public func rateList(request: ServerRoute.RateList) async throws -> [Rate] {
  try await Task.sleep(nanoseconds: NSEC_PER_SEC)
  return rateListMocks()
}

func rateListMocks() -> [Rate] {
  [
    Rate(
      code: "USD",
      value: 10.01
    ),
    Rate(
      code: "EUR",
      value: 200.02
    ),
    Rate(
      code: "RUR",
      value: 3000.03
    )
  ]
}

extension ApiClient {
  static var mock: ApiClient {
    var apiClient = ApiClient.noop
    apiClient.rateList = rateList(request:)
    return apiClient
  }
}
