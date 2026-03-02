// ImageListService.swift

import Foundation

final class ImageListService {
    
    // MARK: - Properties
    
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    private let tokenStorage = OAuth2TokenStorage.shared
    
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    // MARK: - Methods
    
    func fetchPhotosNextPage() {
        
        guard task == nil else { return }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.unsplash.com"
        urlComponents.path = "/photos"
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(nextPage)"),
        ]
        
        guard let url = urlComponents.url else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        
        guard let token = OAuth2Service.shared.authToken else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let photoResult):
                    let newPhotos = photoResult.map { result in
                        Photo(
                            id: result.id,
                            size: CGSize(width: result.width, height: result.height),
                            createdAt: ISO8601DateFormatter().date(from: result.createdAt ?? ""),
                            welcomeDescription: result.description,
                            thumbImageURL: result.urls.thumb,
                            largeImageURL: result.urls.full,
                            isLiked: result.likedByUser
                        )
                    }
                    
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    self.task = nil
                    
                    NotificationCenter.default.post(
                        name: Self.didChangeNotification,
                        object: nil
                    )
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}
