// ImageListTests.swift

@testable import ImageFeed
import XCTest

final class ImageListTests: XCTestCase {
    
    func testImagesListViewControllerCallsViewDidLoad() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        
        let presenter = ImageListPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController
        
        _ = viewController.view
        
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    func testWillDisplayCellCallsFetchNextPage() {
        let viewController = ImagesListViewController()
        let presenter = ImageListPresenterSpy()
        
        viewController.presenter = presenter
        presenter.view = viewController
        
        let tableView = UITableView()
        viewController.setValue(tableView, forKey: "tableView")
        tableView.delegate = viewController
        tableView.dataSource = viewController
        
        presenter.photos = (0..<5).map { i in
            Photo(
                id: "\(i)",
                size: CGSize(width: 100, height: 100),
                createdAt: nil,
                welcomeDescription: nil,
                thumbImageURL: "",
                largeImageURL: "",
                fullImageURL: "",
                isLiked: false
            )
        }
        
        let cell = UITableViewCell()
        let indexPath = IndexPath(row: 2, section: 0)
        
        let tv: UITableView = viewController.value(forKey: "tableView") as! UITableView
        viewController.tableView(tv, willDisplay: cell, forRowAt: indexPath)
        
        XCTAssertTrue(presenter.fetchNextPageCalled)
    }
    
    func testPresenterViewDidLoadCallsFetchNextPage() {
        let presenter = ImageListPresenterSpy()
        let viewSpy = ImagesListViewControllerSpy()
        presenter.view = viewSpy
        
        presenter.viewDidLoad()
        
        XCTAssertTrue(presenter.viewDidLoadCalled)
        XCTAssertTrue(presenter.fetchNextPageCalled)
    }
    
    func testToggleLikeCallsCompletion() {
        let presenter = ImageListPresenterSpy()
        presenter.photos = [Photo(id: "1", size: .zero, createdAt: nil,
                                  welcomeDescription: nil,
                                  thumbImageURL: "", largeImageURL: "",
                                  fullImageURL: "", isLiked: false)]
        
        var completionCalled = false
        presenter.toggleLike(at: 0) {
            completionCalled = true
        }
        
        XCTAssertTrue(presenter.toggleLikeCalled)
        XCTAssertTrue(completionCalled)
    }
}

final class ImageListPresenterSpy: ImageListPresenterProtocol {
    var view: ImageListViewControllerProtocol?
    
    var viewDidLoadCalled = false
    var fetchNextPageCalled = false
    var toggleLikeCalled = false
    
    var photos: [Photo] = []
    
    func viewDidLoad() {
        viewDidLoadCalled = true
        fetchNextPage()
    }
    
    func fetchNextPage() {
        fetchNextPageCalled = true
    }
    
    func toggleLike(at index: Int, completion: (() -> Void)?) {
        toggleLikeCalled = true
        completion?()
    }
}

final class ImagesListViewControllerSpy: ImageListViewControllerProtocol {
    var reloadTableCalled = false
    var insertRowsCalled = false
    var showLikeErrorCalled = false
    
    func reloadTable() {
        reloadTableCalled = true
    }
    
    func insertRows(at indexPath: [IndexPath]) {
        insertRowsCalled = true
    }
    
    func showLikeError(message: String) {
        showLikeErrorCalled = true
    }
}
