import UIKit

final class SingleImageViewController: UIViewController {
    
    // MARK: UI Elements
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let shareButton = UIButton()
    private let likeButton = UIButton()
    
    // MARK: Properties
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
    
    // MARK: Private Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor(resource: .ypBlack)
        setupScrollView()
        setupImageView()
        setupButtons()
    }
    
    private func setupNavigationBar() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(resource: .iconBackChevronWV), for: .normal)
        backButton.tintColor = UIColor(resource: .ypWhite)

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
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.delegate = self
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])
        
        imageView.contentMode = .scaleAspectFit
    }
    
    private func setupButtons() {
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        
        likeButton.setImage(UIImage(resource: .iconCircleLike), for: .normal)
        shareButton.setImage(UIImage(resource: .iconCircleShare), for: .normal)

        likeButton.addTarget(self, action: #selector(didTapLike), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)

        view.addSubview(likeButton)
        view.addSubview(shareButton)

        NSLayoutConstraint.activate([
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
