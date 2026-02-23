// ProfileImageService.swift

import UIKit

// MARK: - Structs

struct UserResult: Codable {
    let profileImage: ProfileImage
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String
    
    enum CodingKeys: String, CodingKey {
        case small
        case medium
        case large
    }
}

final class ProfileImageService {
    
    // MARK: - Properties
    
    static let shared = ProfileImageService()
    private init() {}
    
    private(set) var avatarURL: String?
    private var currentTask: URLSessionTask?
    private var profileImageServiceObserver: NSObjectProtocol?
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    
    // MARK: - Methods
    
    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        currentTask?.cancel()
        
        guard let token = OAuth2TokenStorage.shared.token else {
            completion(.failure(NSError(domain: "ProfileImageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authorization token missing"])))
            return
        }
        
        guard let request = makeProfileImageRequest(username: username, token: token) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let dataTask = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let result):
                    guard let self = self else { return }
                    self.avatarURL = result.profileImage.small
                    completion(.success(result.profileImage.small))
                    
                    NotificationCenter.default
                        .post(
                            name: ProfileImageService.didChangeNotification,
                            object: self,
                            userInfo: ["URL": self.avatarURL ?? ""]
                        )
                    
                case .failure(let error):
                    print("[fetchProfileImageURL]: Ошибка запроса: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        self.currentTask = dataTask
        dataTask.resume()
    }
    
    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.unsplash.com"
        urlComponents.path = "/users/\(username)"
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

