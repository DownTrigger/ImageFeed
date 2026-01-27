import UIKit
import Logging

// MARK: - Protocols
protocol AuthViewControllerDelegate: AnyObject {
    func authViewController(_ vc: AuthViewController, didReceiveCode code: String)
}

// MARK: - Class
final class AuthViewController: UIViewController {
    
    // MARK: - UI
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .logoAuthScreen)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Войти", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 14.0, *) {
            button.addAction(UIAction { [weak self] _ in self?.didTapLoginButton() }, for: .touchUpInside)
        } else {
            button.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
        }
        return button
    }()
    
    // MARK: - Logger
    private let logger = Logger(label: "AuthViewController")
    
    // MARK: - Public Properties
    weak var delegate: AuthViewControllerDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .ypBlack)
        
        setupConstraints()
    }
    
    // MARK: - Actions
    @objc private func didTapLoginButton() {
        showWebView()
    }
    
    // MARK: - Navigation
    private func showWebView() {
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)

        let webViewViewController = WebViewViewController()
        webViewViewController.presenter = presenter
        webViewViewController.delegate = self
        presenter.view = webViewViewController
        
        navigationController?.pushViewController(webViewViewController, animated: true)
        logger.info("[showWebView]: Presented WebViewViewController")
    }
    
    // MARK: - Layout
    private func setupConstraints() {
        view.addSubview(logoImageView)
        view.addSubview(loginButton)
        
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

// MARK: - Extensions
extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        logger.info("[webViewViewController(_:didAuthenticateWithCode:)]: Success code: \(code)")
        delegate?.authViewController(self, didReceiveCode: code)
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        logger.info("[webViewViewControllerDidCancel]: User cancelled authentication")
        vc.dismiss(animated: true)
    }
}
