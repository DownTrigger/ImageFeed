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
    
    // MARK: - Properties
    private let photosName: [String] = Array(0..<20).map{ "\($0)" }
    private let today = Date()
    
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
        return photosName.count
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
        let image = UIImage(named: photosName[indexPath.row])
        let dateText = dateFormatter.string(from: today)
        let isLiked = true
        
        cell.configure(
            image: image,
            dateText: dateText,
            isLiked: isLiked
        )
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let singleImageViewController = SingleImageViewController()
        singleImageViewController.hidesBottomBarWhenPushed = true
        singleImageViewController.image = UIImage(named: photosName[indexPath.row])
        navigationController?.pushViewController(singleImageViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            //            self.logger.error("[ImagesListViewController.heightForRow]: Error – image not found with name \(photosName[indexPath.row])")
            print("[ImagesListViewController.heightForRow]: Error – image not found with name \(photosName[indexPath.row])")
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
