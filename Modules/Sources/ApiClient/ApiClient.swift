import ComposableArchitecture
import Foundation
import Models
import NetworkClient

public struct ApiClient {
  public var rateDetailsList: @Sendable (ServerRoute.RateDetails) async throws -> [RateDetails]
  public var rateList: @Sendable (ServerRoute.RateList) async throws -> [Rate]
}

extension ApiClient {
  public static var live: Self {
    let networkClient = NetworkClient(baseURL: URL(string: "https://api.exchangerate.host"))
        
    return Self(
      rateDetailsList: { route in
        let startDateValue = Formatter.date.string(from: route.startDate)
        let endDateValue = Formatter.date.string(from: route.endDate)
        
        var request = Request<RateDetailsDto>(path: "/timeseries")
        request.query = [
          ("start_date", "\(startDateValue)"),
          ("end_date", "\(endDateValue)"),
          ("base", "\(route.currency.code)"),
          ("symbols", "\(route.rate.code)")
        ]
        let rateDetails = try await networkClient.send(request).value
        
        return rateDetails.rates
          .compactMap { key, value -> RateDetails? in
            guard let value = value.values.first else {
              return nil
            }
            return RateDetails(date: key, value: value)
          }
          .sorted(by: { $0.date > $1.date })
      },
      rateList: { route in
        var request = Request<RateListDto>(path: "/latest")
        request.query = [ ("base", "\(route.currency.code)")]
        let rateList = try await networkClient.send(request).value
        
        return rateList.rates
          .map(Rate.init)
          .sorted(by: { $0.code < $1.code })
      }
    )
  }
}

extension ApiClient {
  public static let noop = Self(
    rateDetailsList: { _ in try await Task.never() },
    rateList: { _ in try await Task.never() }
  )
}

private struct RateDetailsDto: Decodable {
  let rates: [String: [String: Double]]
}

private struct RateListDto: Decodable {
  let rates: [String: Double]
}

