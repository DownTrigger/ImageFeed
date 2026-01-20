import UIKit
import Logging

// MARK: - AuthViewControllerDelegate
protocol AuthViewControllerDelegate: AnyObject {
    func authViewController(_ vc: AuthViewController, didReceiveCode code: String)
}

// MARK: - AuthViewController
final class AuthViewController: UIViewController {

    private let logoImageView = UIImageView()
    private let loginButton = UIButton()
    
    // MARK: - Logger
    private let logger = Logger(label: "AuthViewController")
    
    // MARK: - Public properties
    weak var delegate: AuthViewControllerDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .ypBlack)
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Navigation
    private func showWebView() {
        let webViewViewController = WebViewViewController()
        webViewViewController.delegate = self
        
        let navigationController = UINavigationController(
            rootViewController: webViewViewController
        )
        navigationController.modalPresentationStyle = .fullScreen

        present(navigationController, animated: true)
    }
    
    // MARK: - Action
    @objc private func didTapLoginButton() {
        showWebView()
    }
    
    // MARK: - UI Elements
    private func setupLogoImageView() {
        logoImageView.image = UIImage(resource: .logoAauthScreen)
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupLoginButton() {
        loginButton.setTitle("Войти", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        loginButton.setTitleColor(.black, for: .normal)
        loginButton.backgroundColor = .white
        loginButton.layer.cornerRadius = 16
        loginButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        setupLogoImageView()
        setupLoginButton()
        
        view.addSubview(logoImageView)
        view.addSubview(loginButton)
        loginButton.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -124),
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
}

// MARK: - WebViewViewControllerDelegate
extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
//        vc.dismiss(animated: true)
        delegate?.authViewController(self, didReceiveCode: code)
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
}
