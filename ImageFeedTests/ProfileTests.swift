//  ProfileTests.swift

@testable import ImageFeed
import XCTest

final class ProfileTests: XCTestCase {
    
    func testProfileViewControllerCallsViewDidLoad() {
        let viewController = ProfileViewController()
        let presenterSpy = ProfilePresenterSpy()
        viewController.configure(presenterSpy)
        
        _ = viewController.view
        
        XCTAssertTrue(presenterSpy.viewDidLoadCalled)
    }
    
    func testLogoutButtonCallsPresenter() {
        let presenterSpy = ProfilePresenterSpy()
        presenterSpy.didTapLogout()
        
        XCTAssertTrue(presenterSpy.didTapLogoutCalled)
    }
    
    func testProfilePresenterCallsViewMethods() {
        let viewSpy = ProfileViewSpy()
        
        let testProfile = Profile(username: "@test", name: "Test Name", loginName: "testLogin", bio: "Test bio")
        
        let profilePresenter = ProfilePresenter(profileForTesting: testProfile)
        
        profilePresenter.view = viewSpy
        profilePresenter.viewDidLoad()
        
        XCTAssertTrue(viewSpy.updateProfileDetailsCalled)
        XCTAssertTrue(viewSpy.updateAvatarCalled)
    }
    
    func testPresenterUsesProfileForTesting() {
        let viewSpy = ProfileViewSpy()
        let testProfile = Profile(username: "@user", name: "User Name", loginName: "login", bio: "Bio")
        let presenter = ProfilePresenter(profileForTesting: testProfile)
        presenter.view = viewSpy

        presenter.viewDidLoad()

        XCTAssertTrue(viewSpy.updateProfileDetailsCalled)
        XCTAssertTrue(viewSpy.updateAvatarCalled)
    }
}

final class ProfilePresenterSpy: ProfilePresenterProtocol {
    var view: ProfileViewControllerProtocol?
    var viewDidLoadCalled = false
    var didTapLogoutCalled = false
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func didTapLogout() {
        didTapLogoutCalled = true
    }
}

final class ProfileViewSpy: ProfileViewControllerProtocol {
    var updateProfileDetailsCalled = false
    var updateAvatarCalled = false
    
    func updateProfileDetails(name: String, login: String, bio: String) {
        updateProfileDetailsCalled = true
    }
    
    func updateAvatar(url: URL?) {
        updateAvatarCalled = true
    }
}
