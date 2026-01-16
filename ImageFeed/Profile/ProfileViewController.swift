import UIKit

final class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    private var profileImageView: UIImageView!
    private var logoutButton: UIButton!
    private var nameLabel: UILabel!
    private var loginLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var favoritesLabel: UILabel!
    private var favoritesValueLabel: UILabel!
    private var favoritesTableView: UITableView!
    
    // MARK: - Constants
    private let userName = "Екатерина Новикова"
    private let userLogin = "@ekaterina_nov"
    private let descriptionText = "Hello, world!"
    private let favoritesTitle = "Избранное"
    private let favoritesValue = "27"
    
    // MARK: - Properties
    private let photosName: [String] = Array(0..<20).map{ "\($0)" }
    
    // MARK: - Constants
    private enum ProfileConstants {
        static let nameText = "Екатерина Новикова"
        static let loginText = "@ekaterina_nov"
        static let descriptionText = "Hello, world!"
        static let favoritesTitle = "Избранное"
        static let favoritesCount = "27"
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProfileImageView()
        setupLogoutButton()
        setupNameLabel()
        setupLoginNameLabel()
        setupDescriptionLabel()
        setupFavorites()
        setupFavoritesValue()
        setupFavoritesTableView()
    }
    
    // MARK: - UI Setup
    func setupProfileImageView() {
        let profileImage = UIImage(resource: .userProfile)
        profileImageView = UIImageView(image: profileImage)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileImageView)
        
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            profileImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16)
        ])
    }
    
    func setupLogoutButton() {
        let buttonImage = UIImage(resource: .iconLogout)
        logoutButton = UIButton.systemButton(with: buttonImage, target: self, action: #selector(didTapLogoutButton))
        logoutButton.tintColor = UIColor(resource: .ypRed)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            logoutButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            logoutButton.widthAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func setupNameLabel() {
        nameLabel = UILabel()
        nameLabel.text = ProfileConstants.nameText
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        nameLabel.textColor = UIColor(resource: .ypWhite)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor)
        ])
    }
    
    func setupLoginNameLabel() {
        loginNameLabel = UILabel()
        loginNameLabel.text = ProfileConstants.loginText
        loginNameLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        loginNameLabel.textColor = UIColor(resource: .ypGray)
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginNameLabel)
        
        NSLayoutConstraint.activate([
            loginLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor)
        ])
    }
    
    func setupDescriptionLabel() {
        descriptionLabel = UILabel()
        descriptionLabel.text = ProfileConstants.descriptionText
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.textColor = UIColor(resource: .ypWhite)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor)
        ])
    }
    
    func setupFavorites() {
        favoritesLabel = UILabel()
        favoritesLabel.text = ProfileConstants.favoritesTitle
        favoritesLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        favoritesLabel.textColor = UIColor(resource: .ypWhite)
        favoritesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(favoritesLabel)
        
        NSLayoutConstraint.activate([
            favoritesLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 22),
            favoritesLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor)
        ])
    }
    
    func setupFavoritesValue() {
        favoritesValueLabel = UILabel()
        favoritesValueLabel.text = ProfileConstants.favoritesCount
        favoritesValueLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        favoritesValueLabel.textColor = UIColor(resource: .ypWhite)
        favoritesValueLabel.backgroundColor = UIColor(resource: .ypBlue)
        favoritesValueLabel.textAlignment = .center
        favoritesValueLabel.translatesAutoresizingMaskIntoConstraints = false
        favoritesValueLabel.layer.cornerRadius = 12
        favoritesValueLabel.layer.masksToBounds = true
        view.addSubview(favoritesValueLabel)
        
        NSLayoutConstraint.activate([
            favoritesValueLabel.centerYAnchor.constraint(equalTo: favoritesLabel.centerYAnchor),
            favoritesValueLabel.leadingAnchor.constraint(equalTo: favoritesLabel.trailingAnchor, constant: 8),
            favoritesValueLabel.heightAnchor.constraint(equalToConstant: 22),
            favoritesValueLabel.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func setupFavoritesTableView() {
        favoritesTableView = UITableView()
        favoritesTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(favoritesTableView)
        favoritesTableView.register(ProfileCell.self, forCellReuseIdentifier: ProfileCell.reuseIdentifier)
        favoritesTableView.delegate = self
        favoritesTableView.dataSource = self
        favoritesTableView.backgroundColor = UIColor(resource: .ypBlack)
        favoritesTableView.separatorStyle = .none
        
        NSLayoutConstraint.activate([
            favoritesTableView.topAnchor.constraint(equalTo: favoritesLabel.bottomAnchor, constant: 12),
            favoritesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            favoritesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            favoritesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func didTapLogoutButton() {
        print("logout")
    }
}

// MARK: - UITableViewDataSource
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photosName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileCell.reuseIdentifier, for: indexPath)
        
        guard let ProfileCell = cell as? ProfileCell else {
            return UITableViewCell()
        }
        
        configCell(for: ProfileCell, with: indexPath)
        return ProfileCell
    }
}

// MARK: - Cell Configuration
extension ProfileViewController {
    func configCell(for cell: ProfileCell, with indexPath: IndexPath) {
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return
        }
        
        cell.cellImage.image = image
        cell.dateLabel.text = dateFormatter.string(from: Date())
        
        let likeImage = UIImage(resource: .iconLikeFilled)
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}

// MARK: - UITableViewDelegate
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let singleImageVC = storyboard.instantiateViewController(withIdentifier: SingleImageViewController.reuseIdentifier) as? SingleImageViewController else {
            return
        }
        
        let imageName = photosName[indexPath.row]
        singleImageVC.image = UIImage(named: imageName)
        
        present(singleImageVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return 0
        }
        
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = view.frame.width - imageInsets.left - imageInsets.right
        let imageWidth = image.size.width
        
        guard imageWidth > 0 else {
            print("Image width is zero")
            return 0
        }
        
        let scale = imageViewWidth / imageWidth
        let cellHeight = image.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
}

