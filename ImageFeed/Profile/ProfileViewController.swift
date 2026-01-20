import UIKit
import WebKit
import Kingfisher

class ProfileViewController: UIViewController {
    
    // MARK: - Dependencies
    private let tokenStorage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared
    
    // MARK: - State
    private var profileImageServiceObserver: NSObjectProtocol?
    private var profileObserver: NSObjectProtocol?

    // MARK: - UI Elements
    private var profileImageView: UIImageView!
    private var logoutButton: UIButton!
    private var nameLabel: UILabel!
    private var loginNameLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var favoritesLabel: UILabel!
    private var favoritesValueLabel: UILabel!
    private var favoritesTableView: UITableView!
    
    // MARK: - Constants
    private enum ProfileConstants {
        static let favoritesTitle = "Избранное"
        static let favoritesCount = "27"
    }
    
    // MARK: - Formatters
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Properties
    private let photosName: [String] = Array(0..<20).map{ "\($0)" }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
 
        setupUI()
        setupObservers()
        
        updateProfileUI()
        updateAvatar()
        
        requestAvatarIfNeeded()
    }
    
    deinit {
        if let profileObserver {
            NotificationCenter.default.removeObserver(profileObserver)
        }
        if let profileImageServiceObserver {
            NotificationCenter.default.removeObserver(profileImageServiceObserver)
        }
    }
    
    // MARK: - Screen Logic
    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let imageUrl = URL(string: profileImageURL)
        else { return }

        print("imageUrl: \(imageUrl)")

        let placeholderImage = UIImage(resource: .avatarPlaceholder)
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large))

        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        profileImageView.kf.indicatorType = .activity
        profileImageView.kf.setImage(
            with: imageUrl,
            placeholder: placeholderImage,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage,
                .forceRefresh
            ])
    }
    
    private func requestAvatarIfNeeded() {
        guard let profile = profileService.profile else { return }
        ProfileImageService.shared.fetchProfileImageURL(
            username: profile.username
        ) { _ in }
    }
    
    private func updateProfileDetails(with profile: Profile) {
        nameLabel.text = profile.name.isEmpty ? "Имя не указано" : profile.name
        loginNameLabel.text = profile.loginName.isEmpty ? "@неизвестный_пользователь" : profile.loginName
        descriptionLabel.text = (profile.bio?.isEmpty ?? true) ? "Профиль не заполнен" : profile.bio
       
    }
    
    private func updateProfileUI()  {
        guard let profile = profileService.profile else { return }
        updateProfileDetails(with: profile)
    }
    
    // MARK: - Observers
    private func setupObservers() {
        profileObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileService.profileDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.updateProfileUI()
            }
        
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                self.updateAvatar()
            }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        setupProfileImageView()
        setupLogoutButton()
        setupNameLabel()
        setupLoginNameLabel()
        setupDescriptionLabel()
        setupFavorites()
        setupFavoritesValue()
        setupFavoritesTableView()
    }
    
    private func setupProfileImageView() {
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
    
    private func setupLogoutButton() {
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
    
    private func setupNameLabel() {
        nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        nameLabel.textColor = UIColor(resource: .ypWhite)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor)
        ])
    }
    
    private func setupLoginNameLabel() {
        loginNameLabel = UILabel()
        loginNameLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        loginNameLabel.textColor = UIColor(resource: .ypGray)
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginNameLabel)
        
        NSLayoutConstraint.activate([
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor)
        ])
    }
    
    private func setupDescriptionLabel() {
        descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.textColor = UIColor(resource: .ypWhite)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor)
        ])
    }
    
    private func setupFavorites() {
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
    
    private func setupFavoritesValue() {
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
    
    private func setupFavoritesTableView() {
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
        tokenStorage.token = nil

        clearWebViewData { [weak self] in
            guard self != nil else { return }

            guard
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first
            else {
                assertionFailure("Не удалось получить window")
                return
            }

            let splashViewController = SplashViewController()
            window.rootViewController = splashViewController
            window.makeKeyAndVisible()
        }
    }
}

// MARK: - WebView Cleanup
extension ProfileViewController {
    private func clearWebViewData(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()
        
        let dataTypes: Set<String> = [
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeWebSQLDatabases
        ]
        
        dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
            dataStore.removeData(ofTypes: dataTypes, for: records) {
                completion()
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photosName.count
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

// MARK: - UITableViewDelegate
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let singleImageVC = storyboard.instantiateViewController(withIdentifier: "SingleImageViewController") as? SingleImageViewController else {
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
        let scale = imageViewWidth / imageWidth
        let cellHeight = image.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
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
