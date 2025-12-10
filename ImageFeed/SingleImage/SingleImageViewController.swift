import UIKit

final class SingleImageViewController: UIViewController {
    
    // MARK: Properties
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded, let image else { return }
            
            imageView.image = image
            imageView.frame.size = image.size
        }
    }
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var imageView: UIImageView!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let image else { return }
        imageView.image = image
        imageView.frame.size = image.size
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let image = imageView.image else { return }
        updateMinZoomScale(for: image)
    }
    
    // MARK: Actions
    
    @IBAction func didTapLikeButton(_ sender: UIButton) {
       print("like")
    }
    
    @IBAction func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapShareButton(_ sender: UIButton) {
        guard let image else { return }
        let share = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(share, animated: true, completion: nil)
    }
    
    // MARK: Private Methods
    
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
