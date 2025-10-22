//
//  NetworkClient.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation
import RxSwift

// MARK: - Network Client Protocol
protocol NetworkClientProtocol {
    func execute<T: NetworkRequest>(_ request: T) -> Observable<T.Response>
    func execute<T: NetworkRequest>(_ request: T) -> Observable<APIResponse<T.Response>>
    func executePaginated<T: NetworkRequest>(_ request: T) -> Observable<PaginatedResponse<T.Response>>
}

// MARK: - URLSession-based Network Client
final class URLSessionNetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder

        setupDecoder()
    }

    private func setupDecoder() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        decoder.dateDecodingStrategy = .formatted(formatter)
        // 네이버 API는 camelCase 사용하므로 snake_case 변환 제거
    }

    // MARK: - Execute Request (Direct Response)
    func execute<T: NetworkRequest>(_ request: T) -> Observable<T.Response> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NetworkError.networkError(NSError(domain: "NetworkClient", code: NetworkConstants.ErrorCode.clientDeallocated, userInfo: [NSLocalizedDescriptionKey: "Client deallocated"])))
                return Disposables.create()
            }

            guard let urlRequest = self.buildURLRequest(from: request) else {
                observer.onError(NetworkError.invalidURL)
                return Disposables.create()
            }

            let task = self.session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    let networkError = self.mapError(error, response: response)
                    observer.onError(networkError)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    observer.onError(NetworkError.networkError(NSError(domain: "NetworkClient", code: NetworkConstants.ErrorCode.invalidResponseType, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])))
                    return
                }

                if let error = self.validateResponse(httpResponse, data: data) {
                    observer.onError(error)
                    return
                }

                guard let data = data else {
                    observer.onError(NetworkError.noData)
                    return
                }

                do {
                    let decodedResponse = try self.decoder.decode(T.Response.self, from: data)
                    observer.onNext(decodedResponse)
                    observer.onCompleted()
                } catch {
                    // 디버깅을 위한 로그 추가
                    print("=== DECODING ERROR ===")
                    print("Error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw JSON: \(jsonString)")
                    }
                    observer.onError(NetworkError.decodingError(error))
                }
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }

    // MARK: - Execute Request (API Response Wrapper)
    func execute<T: NetworkRequest>(_ request: T) -> Observable<APIResponse<T.Response>> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NetworkError.networkError(NSError(domain: "NetworkClient", code: NetworkConstants.ErrorCode.clientDeallocated, userInfo: [NSLocalizedDescriptionKey: "Client deallocated"])))
                return Disposables.create()
            }

            guard let urlRequest = self.buildURLRequest(from: request) else {
                observer.onError(NetworkError.invalidURL)
                return Disposables.create()
            }

            let task = self.session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    let networkError = self.mapError(error, response: response)
                    observer.onError(networkError)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    observer.onError(NetworkError.networkError(NSError(domain: "NetworkClient", code: NetworkConstants.ErrorCode.invalidResponseType, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])))
                    return
                }

                if let error = self.validateResponse(httpResponse, data: data) {
                    observer.onError(error)
                    return
                }

                guard let data = data else {
                    observer.onError(NetworkError.noData)
                    return
                }

                do {
                    let decodedResponse = try self.decoder.decode(APIResponse<T.Response>.self, from: data)
                    observer.onNext(decodedResponse)
                    observer.onCompleted()
                } catch {
                    observer.onError(NetworkError.decodingError(error))
                }
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }

    // MARK: - Execute Paginated Request
    func executePaginated<T: NetworkRequest>(_ request: T) -> Observable<PaginatedResponse<T.Response>> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NetworkError.networkError(NSError(domain: "NetworkClient", code: NetworkConstants.ErrorCode.clientDeallocated, userInfo: [NSLocalizedDescriptionKey: "Client deallocated"])))
                return Disposables.create()
            }

            guard let urlRequest = self.buildURLRequest(from: request) else {
                observer.onError(NetworkError.invalidURL)
                return Disposables.create()
            }

            let task = self.session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    let networkError = self.mapError(error, response: response)
                    observer.onError(networkError)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    observer.onError(NetworkError.networkError(NSError(domain: "NetworkClient", code: NetworkConstants.ErrorCode.invalidResponseType, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])))
                    return
                }

                if let error = self.validateResponse(httpResponse, data: data) {
                    observer.onError(error)
                    return
                }

                guard let data = data else {
                    observer.onError(NetworkError.noData)
                    return
                }

                do {
                    let decodedResponse = try self.decoder.decode(PaginatedResponse<T.Response>.self, from: data)
                    observer.onNext(decodedResponse)
                    observer.onCompleted()
                } catch {
                    observer.onError(NetworkError.decodingError(error))
                }
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }
}

// MARK: - Private Helper Methods
private extension URLSessionNetworkClient {
    func buildURLRequest<T: NetworkRequest>(from request: T) -> URLRequest? {
        let finalURL = request.path.isEmpty ? request.baseURL : request.baseURL.appendingPathComponent(request.path)
        var urlComponents = URLComponents(url: finalURL, resolvingAgainstBaseURL: false)

        if let queryParameters = request.queryParameters {
            urlComponents?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = urlComponents?.url else {
            return nil
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeout

        request.headers?.forEach { key, value in
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }

        if let body = request.body {
            urlRequest.httpBody = body
        } else if let parameters = request.parameters,
                  request.method != .GET {
            do {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                return nil
            }
        }
        dump(urlRequest)
        return urlRequest
    }

    func validateResponse(_ response: HTTPURLResponse, data: Data?) -> NetworkError? {
        switch response.statusCode {
        case NetworkConstants.StatusCode.successRange:
            return nil
        case NetworkConstants.StatusCode.badRequest:
            return .serverError(response.statusCode, extractErrorMessage(from: data))
        case NetworkConstants.StatusCode.unauthorized:
            return .unauthorized
        case NetworkConstants.StatusCode.forbidden:
            return .forbidden
        case NetworkConstants.StatusCode.notFound:
            return .notFound
        case NetworkConstants.StatusCode.rateLimited:
            return .rateLimited
        case NetworkConstants.StatusCode.serverErrorRange:
            return .serviceUnavailable
        default:
            return .serverError(response.statusCode, extractErrorMessage(from: data))
        }
    }

    func mapError(_ error: Error, response: URLResponse?) -> NetworkError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError(urlError)
            default:
                return .networkError(urlError)
            }
        }
        return .networkError(error)
    }

    func extractErrorMessage(from data: Data?) -> String? {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? String ?? json["error"] as? String else {
            return nil
        }
        return message
    }
}
