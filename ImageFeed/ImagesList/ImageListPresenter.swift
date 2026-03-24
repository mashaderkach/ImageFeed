// ImageListPresenter.swift

import UIKit

// MARK: - Protocol

protocol ImageListPresenterProtocol {
    var view: ImageListViewControllerProtocol? { get set }
    
    var photos: [Photo] { get }
    
    func viewDidLoad()
    func fetchNextPage()
    func toggleLike(at index: Int, completion: (() -> Void)?)
    
}

// MARK: - Class

final class ImageListPresenter: ImageListPresenterProtocol {
    weak var view: ImageListViewControllerProtocol?
    
    private let imageListService: ImageListService
    
    private(set) var photos: [Photo] = []
    
    private var observer: NSObjectProtocol?
    
    init(service: ImageListService = .shared) {
        self.imageListService = service
    }
    
    // MARK: - Lifecycle
    
    func viewDidLoad() {
        photos = imageListService.photos
        
        observer = NotificationCenter.default.addObserver(
            forName: ImageListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTableView()
        }
        fetchNextPage()
    }
    
    // MARK: - Methods
    
    func updateTableView() {
        let oldCount = photos.count
        let newPhotos = imageListService.photos
        let newCount = newPhotos.count
        
        photos = newPhotos
        
        guard oldCount != newCount else { return }
        
        if newCount > oldCount {
            let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0)
            }
            view?.insertRows(at: indexPaths)
        } else {
            view?.reloadTable()
        }
    }
    
    func fetchNextPage() {
        imageListService.fetchPhotosNextPage()
    }
    
    func toggleLike(at index: Int, completion: (() -> Void)?) {
        let photo = photos[index]
        let newIsLiked = !photo.isLiked
        
        imageListService.changeLike(photoId: photo.id, isLike: newIsLiked) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                self.photos = self.imageListService.photos
                completion?()
                
            case .failure:
                self.view?.showLikeError(message: "Не удалось поставить лайк. Попробуйте снова.")
                completion?()
            }
        }
    }
}
