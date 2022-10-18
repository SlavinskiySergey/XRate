import ApiClient
import ComposableArchitecture
import Foundation
import Models

@Sendable public func rateDetailsList(request: ServerRoute.RateDetails) async throws -> [RateDetails] {
  try await Task.sleep(nanoseconds: NSEC_PER_SEC)
  return rateDetailsMocks()
}

func rateDetailsMocks() -> [RateDetails] {
  [
    RateDetails(
      date: "2022-05-05",
      value: 1.243
    ),
    RateDetails(
      date: "2022-05-07",
      value: 2.243
    ),
    RateDetails(
      date: "2022-05-09",
      value: 3.243
    )
  ]
}

extension ApiClient {
  static var mock: ApiClient {
    var apiClient = ApiClient.noop
    apiClient.rateDetailsList = rateDetailsList(request:)
    return apiClient
  }
}
