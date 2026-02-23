//  OAuth2Service.swift

import UIKit

final class OAuth2Service {
    
    // MARK: - Properties
    
    static let shared = OAuth2Service()
    private init() {}
    
    private let tokenStorage = OAuth2TokenStorage.shared
    private let decoder = JSONDecoder()
    
    private var currentTask: URLSessionTask?
    private var lastCode: String?
    
    private(set) var authToken: String? {
        get {
            return tokenStorage.token
        }
        set {
            tokenStorage.token = newValue
        }
    }
    
    // MARK: - Methods
    
    func fetchOAuthToken(
        code: String, handler: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)
        guard lastCode != code else {
            handler(.failure(NetworkError.invalidRequest))
            return
        }
        currentTask?.cancel()
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            handler(.failure(NetworkError.invalidRequest))
            return
        }
        
        let dataTask = URLSession.shared.objectTask(for: request) {
            [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let responseBody):
                    let authToken = responseBody.accessToken
                    self.authToken = authToken
                    handler(.success(authToken))
                    
                    self.currentTask = nil
                    self.lastCode = nil
                    
                case .failure(let error):
                    print("[fetchOAuthToken]: Ошибка запроса: \(error.localizedDescription)")
                    handler(.failure(error))
                    
                    self.currentTask = nil
                    self.lastCode = nil
                }
            }
        }
        self.currentTask = dataTask
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
            URLQueryItem(name: "grant_type", value: "authorization_code"),
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
