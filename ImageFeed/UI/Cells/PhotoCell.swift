import UIKit
import Kingfisher

final class PhotoCell: UITableViewCell {
    
    // MARK: - Public API
    var onLikeButtonTapped: (() -> Void)?
    
    func configure(
        imageURL: String,
        dateText: String,
        isLiked: Bool
    ) {
        if let url = URL(string: imageURL) {
            cellImage.kf.setImage(
                with: url,
                placeholder: UIImage(resource: .photoPlaceholder)
            )
        } else {
            cellImage.image = nil
        }
        dateLabel.text = dateText
        
        let likeImage = isLiked
            ? UIImage(resource: .iconLikeFilled)
            : UIImage(resource: .iconLike)
        
        likeButton.setImage(likeImage, for: .normal)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
        cellImage.image = UIImage(resource: .photoPlaceholder)
    }
    
    func setLikeButtonEnabled(_ isEnabled: Bool) {
        likeButton.isEnabled = isEnabled
        let alphaValue: CGFloat = isEnabled ? 1.0 : 0.5
        likeButton.alpha = alphaValue
    }
    
    // MARK: - Identifier
    static let reuseIdentifier = "PhotoCell"
    
    // MARK: - UI
    private lazy var cellImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.tintColor = UIColor(resource: .ypRed)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 14.0, *) {
            button.addAction(UIAction { [weak self] _ in self?.didTapLikeButton() }, for: .touchUpInside)
        } else {
            button.addTarget(self, action: #selector(didTapLikeButton), for: .touchUpInside)
        }
        
        return button
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(resource: .ypWhite)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let gradientView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let gradientLayer = CAGradientLayer()
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
        setupGradient()
        
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    @objc private func didTapLikeButton() {
        onLikeButtonTapped?()
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradientView.bounds
    }
    
    // MARK: - Setup
    private func setupViews() {
        backgroundColor = UIColor(resource: .ypBlack)
        contentView.addSubview(cellImage)
        contentView.addSubview(gradientView)
        contentView.addSubview(dateLabel)
        contentView.addSubview(likeButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cellImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cellImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cellImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            likeButton.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            likeButton.topAnchor.constraint(equalTo: cellImage.topAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            likeButton.heightAnchor.constraint(equalToConstant: 44),
            
            dateLabel.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor, constant: 8),
            dateLabel.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor, constant: -8),
            
            gradientView.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupGradient() {
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.3).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        gradientView.layer.addSublayer(gradientLayer)
    }
}
