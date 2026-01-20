import UIKit
import Logging

final class SplashViewController: UIViewController {
    
    // MARK: - Logger
    private let logger = Logger(label: "SplashViewController")
    
    // MARK: - Dependencies
    private let profileService = ProfileService.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    private let authService = OAuth2Service.shared
    
    // MARK: - State
    private var isAuthInProgress = false
    
    // MARK: - UI
    private var imageView: UIImageView!
    
    // MARK: - Lifecycle
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupImageView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !isAuthInProgress else { return }

        if let token = tokenStorage.token {
            fetchProfile(token: token)
            isAuthInProgress = true
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
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authViewController = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            assertionFailure("Не удалось найти AuthViewController по идентификатору")
            return
        }
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
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController = tabBarController
    }
    
    // MARK: - Network
    private func fetchProfile(token: String) {
        profileService.fetchProfile(token) { [weak self] result in

            guard let self else { return }

            switch result {
            case let .success(profile):
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                self.switchToTabBarController()

            case let .failure(error):
//                self.logger.error("[SplashViewController.fetchProfile]: Error – \(error.localizedDescription)")
                print("[SplashViewController.fetchProfile]: Error – \(error.localizedDescription)")
                break
            }
        }
    }
    
    // MARK: - UI Helpers
    
    func setupImageView() {
        let imageSplashScreenLogo = UIImage(resource: .logoSplashScreen)
        imageView = UIImageView(image: imageSplashScreenLogo)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
}

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didReceiveCode code: String) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            
            UIBlockingProgressHUD.show()
            authService.fetchOAuthToken(code) { [weak self] result in
                UIBlockingProgressHUD.dismiss()
                
                guard let self else { return }
                
                switch result {
                case .success:
                    guard let token = self.tokenStorage.token else {
//                        self.logger.error("[SplashViewController.fetchOAuthToken]: Error – token is nil after successful auth")
                        print("[SplashViewController.fetchOAuthToken]: Error – token is nil after successful auth")
                        return
                    }
                    self.fetchProfile(token: token)
                    
                case let .failure(error):
//                    self.logger.error("[SplashViewController.fetchOAuthToken]: Error – \(error)")
                    print("[SplashViewController.fetchOAuthToken]: Error – \(error)")
                    self.showAuthErrorAlert {
                        self.showAuthViewController()
                    }
                }
            }
        }
    }
    
    func showAuthErrorAlert(onDismiss: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        
        let action = UIAlertAction(title: "Ок", style: .default) { _ in
            onDismiss()
        }

        alert.addAction(action)
        present(alert, animated: true)
    }
}
