import UIKit

final class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
            super.viewDidLoad()
        configureTabBarAppearance()
            setupViewControllers()
        }
        
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(resource: .ypBlack)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(resource: .ypWhite)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(resource: .ypGray)
        
        tabBar.standardAppearance = appearance
        tabBar.tintColor = UIColor(resource: .ypWhite)
        tabBar.unselectedItemTintColor = UIColor(resource: .ypWhite)
        
        if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
    }
    
    private func setupViewControllers() {
        let imagesListViewController = ImagesListViewController()
        let imagesListNavController = UINavigationController(
            rootViewController: imagesListViewController
        )
        
        imagesListViewController.view.backgroundColor = UIColor(resource: .ypBlack)
        imagesListNavController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(resource: .iconFeedFilled),
            selectedImage: nil
        )
        
        let profileViewController = ProfileViewController()
        let profileNavController = UINavigationController(
            rootViewController: profileViewController
        )
        
        profileViewController.view.backgroundColor = UIColor(resource: .ypBlack)
        profileNavController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(resource: .iconUserFilled),
            selectedImage: nil
        )
        
        self.viewControllers = [imagesListNavController, profileNavController]
    }
}
