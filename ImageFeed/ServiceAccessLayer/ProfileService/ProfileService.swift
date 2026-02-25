//  ProfileService.swift

import UIKit

// MARK: - Structs

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
}

struct ProfileResult: Codable {
    let username: String
    let firstName: String
    let lastName: String
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

final class ProfileService {
    
    // MARK: - Properties
    
    static let shared = ProfileService()
    private init() {}
    
    private var currentTask: URLSessionTask?
    
    private(set) var profile: Profile?
    
    // MARK: - Methods
    
    func fetchProfile(token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        currentTask?.cancel()
        
        guard let request = makeProfileRequest(token: token) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let dataTask = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let result):
                    let profile = Profile(
                        username: result.username,
                        name: "\(result.firstName) \(result.lastName)"
                            .trimmingCharacters(in: .whitespaces),
                        loginName: "@\(result.username)",
                        bio: result.bio
                    )
                    
                    self?.profile = profile
                    completion(.success(profile))
                    
                case .failure(let error):
                    print("[fetchProfile]: Ошибка запроса: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                self?.currentTask = nil
            }
        }
            self.currentTask = dataTask
            dataTask.resume()
    }
    
    func makeProfileRequest(token: String) -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.unsplash.com"
        urlComponents.path = "/me"
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

