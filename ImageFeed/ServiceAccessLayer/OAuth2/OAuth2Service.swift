//  OAuth2Service.swift

import UIKit

final class OAuth2Service {
    
    // MARK: - Properties
    
    static let shared = OAuth2Service()
    private init() {}
    
    private let tokenStorage = OAuth2TokenStorage()
    
    private enum NetworkError: Error {
        case codeError
    }
    
    // MARK: - Methods
    
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
        request.httpMethod = "POST"
        return request
        
    }
    
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
                let decoder = JSONDecoder()
                let responseBody = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                let token = responseBody.accessToken
                self?.tokenStorage.token = token
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
    
}

// MARK: - Struct

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
