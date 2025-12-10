import UIKit

final class ImagesListCell: UITableViewCell {
    
    // MARK: - Identifier
    static let reuseIdentifier = "ImagesListCell"
    
    // MARK: - IBOutlets
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var gradientView: UIView!
    
    // MARK: - Private Properties
    private let gradientLayer = CAGradientLayer()
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupGradient()
        selectionStyle = .none
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradientView.bounds
    }
    
    // MARK: - Private Methods
    private func setupGradient() {
        guard let blackColor = UIColor(named: "YP Black") else { return }
        
        gradientLayer.colors = [blackColor.withAlphaComponent(1).cgColor, blackColor.withAlphaComponent(0).cgColor]
        
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
    }
}
