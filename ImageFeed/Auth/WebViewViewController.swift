import UIKit
import WebKit
import Logging

// MARK: - Constants
enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
    static let redirectPath = "/oauth/authorize/native"
}

// MARK: - Protocols
protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

// MARK: - Class
final class WebViewViewController: UIViewController {
    
    // MARK: - UI
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = UIColor(resource: .ypBlack)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        return progressView
    }()
    
    // MARK: - Logger
    private let logger = Logger(label: "WebViewViewController")
    
    // MARK: - Dependencies
    weak var delegate: WebViewViewControllerDelegate?
    
    // MARK: - Private Properties
    private var estimatedProgressObservation: NSKeyValueObservation?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadAuthPage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeWebViewProgress()
    }
    
    deinit {
        estimatedProgressObservation?.invalidate()
    }
    
    // MARK: - Actions
    @objc private func didTapBack() {
        dismiss(animated: true)
    }
    
    // MARK: - Navigation
    private func setupNavigationBar() {
        let backButton = UIButton(type: .system)
        backButton.setImage(
            UIImage(resource: .iconBackChevron).withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        backButton.tintColor = UIColor(resource: .ypBlack)
        
        if #available(iOS 14.0, *) {
            backButton.addAction(UIAction { [weak self] _ in self?.didTapBack() }, for: .touchUpInside)
        } else {
            backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        configureTransparentNavigationBar()
    }
    
    private func configureTransparentNavigationBar() {
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(progressView)
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Loading
    private func loadAuthPage() {
        guard var components = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
            logger.error("[loadAuthPage]: Error – failed to create URLComponents")
            return
        }
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: APIConstants.accessKey),
            URLQueryItem(name: "redirect_uri", value: APIConstants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: APIConstants.accessScope)
        ]
        
        guard let url = components.url else {
            logger.error("[loadAuthPage]: Error – failed to build auth URL")
            return
        }
        webView.load(URLRequest(url: url))
    }
    
    // MARK: - Observing
    private func observeWebViewProgress() {
        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
             options: [.new]
        ) { [weak self] webView, _ in
            guard let self else { return }
            self.updateProgress()
        }
        updateProgress()
    }
    
    private func updateProgress() {
        progressView.progress = Float(webView.estimatedProgress)
        progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
    }
    
    // MARK: - Helpers
    private func extractCode(from navigationAction: WKNavigationAction) -> String? {
        guard
            let url = navigationAction.request.url,
            let components = URLComponents(string: url.absoluteString),
            components.path == WebViewConstants.redirectPath,
            let queryItems = components.queryItems,
            let codeItem = queryItems.first(where: { $0.name == "code" })
        else {
            return nil
        }
        
        return codeItem.value
    }
}

// MARK: - Extensions
extension WebViewViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let code = extractCode(from: navigationAction) {
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
