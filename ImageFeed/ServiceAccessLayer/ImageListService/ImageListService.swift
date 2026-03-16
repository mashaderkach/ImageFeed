// ImageListService.swift

import Foundation

final class ImageListService {
    
    // MARK: - Properties
    
    static let shared = ImageListService()
    private init() {}
    
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    private let tokenStorage = OAuth2TokenStorage.shared
    
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    private let isoDateFormatter = ISO8601DateFormatter()
    
    // MARK: - Methods
    
    func fetchPhotosNextPage() {
        guard task == nil else { return }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        guard let request = makePhotosRequest(page: nextPage) else { return }
        
        task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.handleFetchResult(result, nextPage: nextPage)
            }
        }
        
        task?.resume()
    }

    private func makePhotosRequest(page: Int) -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.unsplash.com"
        urlComponents.path = "/photos"
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        
        guard let url = urlComponents.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        
        guard let token = OAuth2Service.shared.authToken else { return nil }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }

    private func handleFetchResult(
        _ result: Result<[PhotoResult], Error>,
        nextPage: Int
    ) {
        switch result {
            
        case .success(let photoResult):
            let newPhotos = photoResult.map { mapPhoto($0) }
            
            photos.append(contentsOf: newPhotos)
            lastLoadedPage = nextPage
            task = nil
            
            NotificationCenter.default.post(
                name: Self.didChangeNotification,
                object: nil
            )
            
        case .failure(let error):
            print(error)
        }
    }

    private func mapPhoto(_ result: PhotoResult) -> Photo {
        Photo(
            id: result.id,
            size: CGSize(width: result.width, height: result.height),
            createdAt: isoDateFormatter.date(from: result.createdAt ?? ""),
            welcomeDescription: result.description,
            thumbImageURL: result.urls.thumb,
            largeImageURL: result.urls.full,
            fullImageURL: result.urls.full,
            isLiked: result.likedByUser
        )
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.unsplash.com"
        urlComponents.path = "/photos/\(photoId)/like"
        
        guard let url = urlComponents.url else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? HTTPMethod.post.rawValue : HTTPMethod.delete.rawValue
        
        guard let token = OAuth2Service.shared.authToken else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let dataTask = URLSession.shared.data(for: request) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    if let index = self.photos.firstIndex(where: { $0.id == photoId}) {
                        let photo = self.photos[index]
                        let newPhoto = Photo(
                            id: photo.id,
                            size: photo.size,
                            createdAt: photo.createdAt,
                            welcomeDescription: photo.welcomeDescription,
                            thumbImageURL: photo.thumbImageURL,
                            largeImageURL: photo.largeImageURL,
                            fullImageURL: photo.fullImageURL,
                            isLiked: !photo.isLiked
                        )
                        self.photos[index] = newPhoto
                    }
                    
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        dataTask.resume()
    }
    
    func resetPhotos() {
        photos.removeAll()
    }
}
