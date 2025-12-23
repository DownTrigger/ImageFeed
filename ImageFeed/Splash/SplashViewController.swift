import UIKit

final class SplashViewController: UIViewController {
    
    private let tokenStorage = OAuth2TokenStorage.shared
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if tokenStorage.token != nil {
            switchToMainInterface()
        } else {
            presentAuthFlow()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    // MARK: - Navigation
    private func presentAuthFlow() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        guard let navigationController = storyboard
            .instantiateViewController(withIdentifier: "AuthNavigationController") as? UINavigationController
        else {
            assertionFailure("Failed to instantiate Auth flow")
            return
        }
        
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    private func switchToMainInterface() {
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController = tabBarController
    }
}
