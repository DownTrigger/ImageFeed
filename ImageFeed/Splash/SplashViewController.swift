import UIKit
import Logging

final class SplashViewController: UIViewController {
    
    // MARK: - Logger
    private let logger = Logger(label: "SplashViewController")
    
    // MARK: - Dependencies
    private let profileService = ProfileService.shared
    private let imagesListService = ImagesListService.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    private let authService = OAuth2Service.shared
    
    // MARK: - State
    private var isAuthInProgress = false
    
    // MARK: - UI
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .logoSplashScreen)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Lifecycle
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !isAuthInProgress else { return }
        
        if let token = tokenStorage.token {
            isAuthInProgress = true
            UIBlockingProgressHUD.show()
            fetchProfile(token: token)
        } else {
            isAuthInProgress = true
            showAuthViewController()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - Navigation
    private func showAuthViewController() {
        let authViewController = AuthViewController()
        authViewController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: authViewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    private func switchToTabBarController() {
        guard
            let windowScene = view.window?.windowScene,
            let sceneDelegate = windowScene.delegate as? SceneDelegate,
            let window = sceneDelegate.window
        else {
            //            self.logger.error("[SplashViewController.switchToTabBarController]: Error – window is nil")
            print("[SplashViewController.switchToTabBarController]: Error – window is nil")
            return
        }
        
        let tabBarController = TabBarController()
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
    
    // MARK: - Network
    private func fetchProfile(token: String) {
        profileService.fetchProfile(token) { [weak self] result in
            
            guard let self else { return }
            
            switch result {
            case let .success(profile):
                UIBlockingProgressHUD.dismiss()
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                self.imagesListService.fetchLikedPhotos(username: profile.username) { result in
                    if case .failure(let error) = result {
                        print("[SplashViewController.fetchLikedPhotos]: \(error)")
                    }
                }
                
                self.switchToTabBarController()
                
            case let .failure(error):
                UIBlockingProgressHUD.dismiss()
                //                self.logger.error("[SplashViewController.fetchProfile]: Error – \(error.localizedDescription)")
                print("[SplashViewController.fetchProfile]: Error – \(error.localizedDescription)")
                self.showAuthViewController()
            }
        }
    }
    
    // MARK: - UI Helpers
    func setupConstraints() {
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
        ])
    }
    
}

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didReceiveCode code: String) {
        UIBlockingProgressHUD.show()
        authService.fetchOAuthToken(code) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    UIBlockingProgressHUD.dismiss()
                    return
                }

                self.dismiss(animated: true) {
                    UIBlockingProgressHUD.dismiss()

                    switch result {
                    case .success:
                        guard let token = self.tokenStorage.token else {
                            print("[SplashViewController.fetchOAuthToken]: Error – token is nil after successful auth")
                            return
                        }
                        self.fetchProfile(token: token)

                    case let .failure(error):
                        print("[SplashViewController.fetchOAuthToken]: Error – \(error)")
                        AlertPresenter.showAuthErrorAlert(on: self) { [weak self] in
                            guard let self else { return }
                            self.showAuthViewController()
                        }
                    }
                }
            }
        }
    }
}
