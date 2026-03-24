// ProfilePresenter.swift

import UIKit

public protocol ProfilePresenterProtocol {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogout()
}

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    private var observer: NSObjectProtocol?
    
    private var profileForTesting: Profile?
    init(profileForTesting: Profile? = nil) {
            self.profileForTesting = profileForTesting
        }
    
    func viewDidLoad() {
        updateProfile()
        updateAvatar()
        
        observer = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.updateAvatar()
            }
    }
    
    private func updateProfile() {
        let profile = profileForTesting ?? ProfileService.shared.profile
            guard let profile else { return }
        
        view?.updateProfileDetails(
            name: profile.name,
            login: profile.loginName,
            bio: profile.bio ?? ""
        )
    }
    
    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL)
        else {
            view?.updateAvatar(url: nil)
            return
        }
        
        view?.updateAvatar(url: url)
    }
    
    func didTapLogout() {
        ProfileLogoutService.shared.logout()
    }
}
