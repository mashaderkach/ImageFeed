//  OAuth2Service.swift

import UIKit

final class OAuth2Service {
    
    // MARK: - Properties
    
    static let shared = OAuth2Service()
    private init() {}
    
    private let tokenStorage = OAuth2TokenStorage.shared
    private let decoder = JSONDecoder()
    
    private enum NetworkError: Error {
        case codeError
    }
    
    private enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    // MARK: - Methods
    
    func fetchOAuthToken(code: String, handler: @escaping (Result<String, Error>) -> Void) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Сетевая ошибка: \(error)")
                handler(.failure(error))
                return
            }
            
            if let response = response as? HTTPURLResponse,
               response.statusCode < 200 || response.statusCode >= 300 {
                print("Ошибка сервера")
                handler(.failure(NetworkError.codeError))
                return
            }
            
            guard let data = data else {
                print("Ошибка сервера")
                handler(.failure(NetworkError.codeError))
                return
            }
            
            do {
                guard let self else { return }
                let responseBody = try self.decoder.decode(OAuthTokenResponseBody.self, from: data)
                let token = responseBody.accessToken
                tokenStorage.token = token
                DispatchQueue.main.async {
                    handler(.success(token))
                }
            } catch {
                DispatchQueue.main.async {
                    print("Сетевая декодирования: \(error)")
                    handler(.failure(error))
                }
            }
        }
        dataTask.resume()
    }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "unsplash.com"
        urlComponents.path = "/oauth/token"
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        return request
    }
    
}

// MARK: - Struct

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
