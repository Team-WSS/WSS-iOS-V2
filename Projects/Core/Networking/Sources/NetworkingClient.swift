import Foundation

public final class NetworkingClient: NetworkingRequestable {
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func request(_ endpoint: Endpoint) async throws -> Data {
        let (data, response) = try await urlSession.data(for: endpoint.urlRequest)
        try validateResponse(data: data, response: response)
        return data
    }
}

extension NetworkingClient {
    private func validateResponse(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkingError.invalidURL
        }
        
        switch http.statusCode {
        case 200..<300:
            return
        default:
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw NetworkingError.responseFailure(code: http.statusCode, body: errorResponse)
        }
    }
}
