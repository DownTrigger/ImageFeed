import UIKit
import Logging

final class ImagesListViewController: UIViewController {
    
    // MARK: - Logger
    private let logger = Logger(label: "ImagesListViewController")

    // MARK: - Dependencies
    private lazy var presenter: ImagesListPresenterProtocol = ImagesListPresenter(
        view: self,
        imagesListService: ImagesListService.shared
    )
    private let dateFormatter = DateFormatterProvider.shared

    // MARK: - State
    private var state: ImagesListState = .empty
    private var didAdjustInitialContentOffset = false
    private var photos: [Photo] = []

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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        presenter.viewDidLoad()
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
    
    // MARK: - Actions
    private func didTapLikeButton(from cell: PhotoCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]

        cell.setLikeButtonEnabled(false)

        presenter.didTapLike(photoId: photo.id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                cell.setLikeButtonEnabled(true)

                if case .failure(let error) = result {
                    self.logger.error("[didTapLikeButton]: error changing like \(error.localizedDescription)")
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
        
        guard let photoCell = cell as? PhotoCell else {
            return UITableViewCell()
        }
        
        configCell(for: photoCell, with: indexPath)
        return photoCell
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
        presenter.willDisplayRow(at: indexPath.row, totalCount: photos.count)
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

// MARK: - ImagesListViewProtocol
extension ImagesListViewController: ImagesListViewProtocol {
    func render(state: ImagesListState) {
        self.state = state
        self.photos = state.photos
    }

    func insertRows(at indexPaths: [IndexPath]) {
        tableView.insertRows(at: indexPaths, with: .automatic)
    }

    func reloadVisibleRows() {
        let visibleIndexPaths = tableView.indexPathsForVisibleRows ?? []
        guard !visibleIndexPaths.isEmpty else { return }
        tableView.reloadRows(at: visibleIndexPaths, with: .none)
    }
}
