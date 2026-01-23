import UIKit

final class SingleImageViewController: UIViewController {
    
    // MARK: UI Elements
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(resource: .iconCircleShare), for: .normal)
        
        if #available(iOS 14.0, *) {
            button.addAction(UIAction { [weak self] _ in self?.didTapShare() }, for: .touchUpInside)
        } else {
            button.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)
        }
        
        return button
    }()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(resource: .iconCircleLike), for: .normal)
        
        if #available(iOS 14.0, *) {
            button.addAction(UIAction { [weak self] _ in self?.didTapLike() }, for: .touchUpInside)
        } else {
            button.addTarget(self, action: #selector(didTapLike), for: .touchUpInside)
        }
        
        return button
    }()
    
    // MARK: Properties
    var imageURL: String?
    var image: UIImage? {
        didSet {
            updateImage()
        }
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        updateImage()
        
        loadImage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let image = imageView.image else { return }
        updateMinZoomScale(for: image)
    }
    
    // MARK: Actions
    @objc private func didTapLike() {
        print("like")
    }
    
    @objc private func didTapBack() {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func didTapShare() {
        guard let image = image else { return }
        let share = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(share, animated: true, completion: nil)
    }
    
    // MARK: - Image Loading
    private func loadImage() {
        guard
            let imageURL,
            let url = URL(string: imageURL)
        else {
            return
        }

        imageView.kf.setImage(
            with: url,
            placeholder: UIImage(resource: .photoPlaceholder)
        )
    }
    
    // MARK: Private Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor(resource: .ypBlack)
        setupConstraints()
    }
    
    private func setupNavigationBar() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(resource: .iconBackChevronWV), for: .normal)
        backButton.tintColor = UIColor(resource: .ypWhite)
        
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
    
    private func setupConstraints() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(likeButton)
        view.addSubview(shareButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            
            likeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            likeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 68),
            likeButton.widthAnchor.constraint(equalToConstant: 51),
            likeButton.heightAnchor.constraint(equalToConstant: 51),
            
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -17),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -68),
            shareButton.widthAnchor.constraint(equalToConstant: 50),
            shareButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func updateImage() {
        guard isViewLoaded, let image else { return }
        imageView.image = image
        imageView.frame.size = image.size
    }
    
    private func updateMinZoomScale(for image: UIImage) {
        let widthScale = scrollView.bounds.width / image.size.width
        let heightScale = scrollView.bounds.height / image.size.height
        let scale = max(widthScale, heightScale)
        
        scrollView.minimumZoomScale = scale
        scrollView.maximumZoomScale = scale * 3
        scrollView.zoomScale = scale
        
        centerImage()
    }
    
    private func centerImage() {
        guard let image = imageView.image else { return }
        
        let scrollViewSize = scrollView.bounds.size
        let imageSize = CGSize(
            width: image.size.width * scrollView.zoomScale,
            height: image.size.height * scrollView.zoomScale
        )
        
        let horizontalOffset = max(0, (imageSize.width - scrollViewSize.width) / 2)
        let verticalOffset = max(0, (imageSize.height - scrollViewSize.height) / 2)
        
        scrollView.contentInset = .zero
        scrollView.contentOffset = CGPoint(x: horizontalOffset, y: verticalOffset)
    }
}

// MARK: UIScrollViewDelegate
extension SingleImageViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
