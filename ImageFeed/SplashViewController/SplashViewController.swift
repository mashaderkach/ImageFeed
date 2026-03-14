// SplashViewController.swift

import UIKit

final class SplashViewController: UIViewController {
    
    // MARK: - Properties
    
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let storage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(resource: .appIcon)
        return iv
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupImageView()
        
        if let token = storage.token, !token.isEmpty {
            switchToTabBarController()
            fetchProfile(token: token)
        } else {
            presentAuthViewController()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    // MARK: - Methods
    
    private func setupImageView() {
        view.backgroundColor = UIColor(hex: "#1A1B22")
        
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func presentAuthViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authViewController = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            assertionFailure("Не удалось найти AuthViewController по идентификатору")
            return
        }
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        present(authViewController, animated: true)
    }
    
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController = tabBarController
    }
}

// MARK: - Extension

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        UIBlockingProgressHUD.show()
        
        vc.navigationController?.dismiss(animated: true)
        
        guard let token = storage.token else { return }
        fetchProfile(token: token)
    }
    
    func fetchProfile(token: String) {
        profileService.fetchProfile(token: token) { [weak self] result in
            guard let self else { return }
            
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success(let profile):
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                self.switchToTabBarController()
            case .failure(let error):
                print(error)
            }
        }
    }
}
