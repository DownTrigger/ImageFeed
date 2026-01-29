import UIKit
import Kingfisher
import Logging

final class ProfileViewController: UIViewController {

    // MARK: - Logger
    private let logger = Logger(label: "ProfileViewController")

    // MARK: - Dependencies
    var presenter: ProfilePresenterProtocol?

    private lazy var defaultPresenter: ProfilePresenterProtocol = ProfilePresenter(
        view: self,
        profileService: ProfileService.shared,
        profileImageService: ProfileImageService.shared,
        imagesListService: ImagesListService.shared,
        tokenStorage: OAuth2TokenStorage.shared,
        dataCleaner: WebViewDataCleaner.shared
    )

    private var currentPresenter: ProfilePresenterProtocol {
        presenter ?? defaultPresenter
    }
    private var application: UIApplication {
        UIApplication.shared
    }

    // MARK: - Private Properties
    private var state: ProfileState = .empty

    // MARK: - Constants
    private let dateFormatter = DateFormatterProvider.shared

    // MARK: - UI
    private lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .userProfile)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var logoutButton: UIButton = {
        let buttonImage = UIImage(resource: .iconLogout)
        let button = UIButton(type: .system)
        button.setImage(buttonImage, for: .normal)
        button.tintColor = UIColor(resource: .ypRed)
        button.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 14.0, *) {
            button.addAction(UIAction { [weak self] _ in self?.didTapLogoutButton() }, for: .touchUpInside)
        } else {
            button.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
        }

        return button
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.textColor = UIColor(resource: .ypWhite)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var loginNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(resource: .ypGray)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(resource: .ypWhite)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var favoritesLabel: UILabel = {
        let label = UILabel()
        label.text = ProfileConstants.favoritesTitle
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.textColor = UIColor(resource: .ypWhite)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var favoritesValueLabel: UILabel = {
        let label = UILabel()
        label.text = ProfileConstants.favoritesCount
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(resource: .ypWhite)
        label.backgroundColor = UIColor(resource: .ypBlue)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        return label
    }()

    private lazy var favoritesTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(PhotoCell.self, forCellReuseIdentifier: PhotoCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(resource: .ypBlack)
        tableView.separatorStyle = .none
        return tableView
    }()

    private lazy var emptyFavoritesImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .emptyState)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // MARK: - Constants
    private enum ProfileConstants {
        static let favoritesTitle = "Избранное"
        static let favoritesCount = "27"
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupConstraints()
        currentPresenter.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: - UI Setup
    private func setupConstraints() {
        view.addSubview(profileImageView)
        view.addSubview(logoutButton)
        view.addSubview(nameLabel)
        view.addSubview(loginNameLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(favoritesLabel)
        view.addSubview(favoritesValueLabel)
        view.addSubview(favoritesTableView)
        view.addSubview(emptyFavoritesImageView)

        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            profileImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),

            logoutButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),

            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),

            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),

            favoritesLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 22),
            favoritesLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),

            favoritesValueLabel.centerYAnchor.constraint(equalTo: favoritesLabel.centerYAnchor),
            favoritesValueLabel.leadingAnchor.constraint(equalTo: favoritesLabel.trailingAnchor, constant: 8),
            favoritesValueLabel.heightAnchor.constraint(equalToConstant: 22),
            favoritesValueLabel.widthAnchor.constraint(equalToConstant: 40),

            favoritesTableView.topAnchor.constraint(equalTo: favoritesLabel.bottomAnchor, constant: 12),
            favoritesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            favoritesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            favoritesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyFavoritesImageView.topAnchor.constraint(equalTo: favoritesLabel.bottomAnchor, constant: 110),
            emptyFavoritesImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyFavoritesImageView.heightAnchor.constraint(equalToConstant: 115),
            emptyFavoritesImageView.widthAnchor.constraint(equalToConstant: 115)
        ])
    }

    // MARK: - Actions
    @objc private func didTapLogoutButton() {
        AlertPresenter.showLogoutConfirmationAlert(on: self) { [weak self] in
            guard let self else { return }
            currentPresenter.didConfirmLogout()
        }
    }

    private func didTapUnlike(at indexPath: IndexPath, cell: PhotoCell) {
        let photoId = currentPresenter.likedPhotoId(at: indexPath.row)
        cell.setLikeButtonEnabled(false)

        currentPresenter.didTapUnlike(photoId: photoId) { [weak self] result in
            DispatchQueue.main.async {
                cell.setLikeButtonEnabled(true)
                if case .failure(let error) = result {
                    self?.logger.error("[didTapUnlike]: Error \(error) photoId=\(photoId)")
                }
            }
        }
    }

    // MARK: - Navigation
    private func resetRootController() {
        guard
            let windowScene = application.connectedScenes.first as? UIWindowScene,
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

// MARK: - UITableViewDataSource
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currentPresenter.likedPhotosCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotoCell.reuseIdentifier, for: indexPath)
        
        guard let photoCell = cell as? PhotoCell else {
            return UITableViewCell()
        }
        
        configCell(for: photoCell, with: indexPath)
        return photoCell
    }
}

// MARK: - UITableViewDelegate
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let singleImageViewController = SingleImageViewController()
        let photo = currentPresenter.likedPhoto(at: indexPath.row)
        singleImageViewController.photo = photo
        singleImageViewController.hidesBottomBarWhenPushed = true
        singleImageViewController.imageURL = photo.largeImageURL
        
        navigationController?.pushViewController(singleImageViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = currentPresenter.likedPhoto(at: indexPath.row)
        
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = view.frame.width - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        return photo.size.height * scale + imageInsets.top + imageInsets.bottom
    }
}

// MARK: - Cell Configuration
extension ProfileViewController {
    func configCell(for cell: PhotoCell, with indexPath: IndexPath) {
        let photo = currentPresenter.likedPhoto(at: indexPath.row)
        let dateText = photo.createdAt.map { dateFormatter.string(from: $0) } ?? ""
        
        cell.configure(
                imageURL: photo.regularImageURL,
                dateText: dateText,
                isLiked: photo.isLiked
            )
        
        cell.onLikeButtonTapped = { [weak self, weak cell] in
            guard
                let self,
                let cell,
                let indexPath = self.favoritesTableView.indexPath(for: cell)
            else { return }

            self.didTapUnlike(at: indexPath, cell: cell)
        }
    }
}

// MARK: - ProfileViewProtocol
extension ProfileViewController: ProfileViewProtocol {
    func render(state: ProfileState) {
        self.state = state

        nameLabel.text = state.nameText
        loginNameLabel.text = state.loginText
        descriptionLabel.text = state.bioText

        favoritesValueLabel.text = "\(state.favoritesCount)"
        favoritesValueLabel.isHidden = state.favoritesCount == 0
        emptyFavoritesImageView.isHidden = state.favoritesCount > 0

        if let avatarURL = state.avatarURL {
            let placeholderImage = UIImage(resource: .avatarPlaceholder)
                .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large))

            let processor = RoundCornerImageProcessor(cornerRadius: 35)
            profileImageView.kf.indicatorType = .activity
            profileImageView.kf.setImage(
                with: avatarURL,
                placeholder: placeholderImage,
                options: [
                    .processor(processor),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage,
                    .forceRefresh
                ]
            )
        } else {
            profileImageView.image = UIImage(resource: .userProfile)
        }
    }

    func applyFavoritesUpdates(deleted: [IndexPath], inserted: [IndexPath]) {
        favoritesTableView.performBatchUpdates {
            if !deleted.isEmpty {
                favoritesTableView.deleteRows(at: deleted, with: .automatic)
            }
            if !inserted.isEmpty {
                favoritesTableView.insertRows(at: inserted, with: .automatic)
            }
        }
    }

    func reloadFavorites() {
        favoritesTableView.reloadData()
    }

    func resetToSplash() {
        resetRootController()
    }
}
