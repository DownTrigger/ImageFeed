import UIKit
import WebKit
import Logging

// MARK: - Constants
enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
    static let redirectPath = "/oauth/authorize/native"
}

// MARK: - Delegate
protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

// MARK: - WebViewViewController
final class WebViewViewController: UIViewController {
    
    private let webView = WKWebView()
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    // MARK: - Logger
    private let logger = Logger(label: "WebViewViewController")
    
    // MARK: - Dependencies
    weak var delegate: WebViewViewControllerDelegate?
    
    // MARK: - Private properties
    private var estimatedProgressObservation: NSKeyValueObservation?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        configureWebView()
        loadAuthPage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeWebViewProgress()
    }
    
    @objc private func didTapBack() {
        dismiss(animated: true)
    }
    
    
    private func setupNavigationBar() {
        let backButton = UIButton(type: .system)
        backButton.setImage(
            UIImage(resource: .iconBackChevron).withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        backButton.tintColor = UIColor(resource: .ypBlack)

        backButton.addTarget(
            self,
            action: #selector(didTapBack),
            for: .touchUpInside
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)

        configureTransparentNavigationBar()
    }
    
    private func configureTransparentNavigationBar() {
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor(resource: .ypBlack)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        
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
    
    private func configureWebView() {
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }
    
    private func loadAuthPage() {
        guard var components = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
            //            self.logger.error("[WebViewViewController.loadAuthPage]: Error – failed to create URLComponents")
            print("[WebViewViewController.loadAuthPage]: Error – failed to create URLComponents")
            return
        }
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        
        guard let url = components.url else {
            //            self.logger.error("[WebViewViewController.loadAuthPage]: Error – failed to build auth URL")
            print("[WebViewViewController.loadAuthPage]: Error – failed to build auth URL")
            return
        }
        webView.load(URLRequest(url: url))
    }
    
    
    
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
    
    deinit {
        estimatedProgressObservation?.invalidate()
    }
    
    private func updateProgress() {
        progressView.progress = Float(webView.estimatedProgress)
        progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
    }
    
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



// MARK: - WKNavigationDelegate
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

