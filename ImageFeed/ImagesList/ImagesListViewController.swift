import UIKit
import Logging

final class ImagesListViewController: UIViewController {
    
    private let logger = Logger(label: "ImagesListViewController")
    
    // MARK: - UI
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(resource: .ypBlack)
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(PhotoCell.self, forCellReuseIdentifier: PhotoCell.reuseIdentifier)
        return tableView
    }()
    
    private var didAdjustInitialContentOffset = false
    private let imagesListService = ImagesListService.shared
    
    // MARK: - Properties
    private var photos: [Photo] = []
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveImagesUpdate),
            name: ImagesListService.didChangeNotification,
            object: nil
        )
        
        imagesListService.fetchPhotosNextPage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let topInset = view.safeAreaInsets.top
        
        if tableView.contentInset.top != topInset {
            tableView.contentInset.top = topInset
            tableView.verticalScrollIndicatorInsets.top = topInset
        }
        
        if !didAdjustInitialContentOffset {
            tableView.contentOffset = CGPoint(x: 0, y: -topInset)
            didAdjustInitialContentOffset = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @objc private func didReceiveImagesUpdate() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            let newPhotos = self.imagesListService.photos
            let oldCount = self.photos.count
            let newCount = newPhotos.count

            self.photos = newPhotos

            if newCount > oldCount {
                // Подгрузка новой страницы
                let indexPaths = (oldCount..<newCount).map {
                    IndexPath(row: $0, section: 0)
                }
                self.tableView.insertRows(at: indexPaths, with: .automatic)
            } else {
                // Изменение состояния лайков — обновляем видимые ячейки
                let visibleIndexPaths = self.tableView.indexPathsForVisibleRows ?? []
                self.tableView.reloadRows(at: visibleIndexPaths, with: .none)
            }
        }
    }
    
    private func didTapLikeButton(from cell: PhotoCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]

        cell.setLikeButtonEnabled(false)

        imagesListService.changeLike(
            photoId: photo.id,
            shouldLike: !photo.isLiked
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                cell.setLikeButtonEnabled(true)

                if case .success = result {
                    self.photos = self.imagesListService.photos
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
    }
    
    // MARK: - Setup
    private func setupTableView() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotoCell.reuseIdentifier, for: indexPath)
        
        guard let PhotoCell = cell as? PhotoCell else {
            return UITableViewCell()
        }
        
        configCell(for: PhotoCell, with: indexPath)
        return PhotoCell
    }
}

// MARK: - Cell Configuration
extension ImagesListViewController {
    func configCell(for cell: PhotoCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        let dateText = photo.createdAt.map { dateFormatter.string(from: $0) } ?? ""
        
        cell.configure(
            imageURL: photo.regularImageURL,
            dateText: dateText,
            isLiked: photo.isLiked
        )
        
        cell.onLikeButtonTapped = { [weak self, weak cell] in
            guard let self, let cell else { return }
            self.didTapLikeButton(from: cell)
        }
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let singleImageViewController = SingleImageViewController()
        let photo = photos[indexPath.row]
        singleImageViewController.photo = photo
        singleImageViewController.hidesBottomBarWhenPushed = true
        singleImageViewController.imageURL = photo.largeImageURL
        navigationController?.pushViewController(singleImageViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = view.frame.width - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        return photo.size.height * scale + imageInsets.top + imageInsets.bottom
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row + 1 == photos.count else { return }
        imagesListService.fetchPhotosNextPage()
    }
}
