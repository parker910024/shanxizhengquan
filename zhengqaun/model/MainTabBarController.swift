//
//  MainTabBarController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        // 设置TabBar外观
        tabBar.backgroundColor = .white
        tabBar.tintColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // 蓝色选中色
        tabBar.unselectedItemTintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0) // 灰色未选中色
        
        // 移除顶部边框
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.shadowColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
            tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
        }
    }
    
    private func setupViewControllers() {
        // 首页
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "首页",
            image: resizeTabBarIcon(UIImage(systemName: "house"), to: CGSize(width: 20, height: 20)),
            selectedImage: resizeTabBarIcon(UIImage(systemName: "house.fill"), to: CGSize(width: 20, height: 20))
        )
        
        // 行情
        let marketVC = MarketViewController()
        let marketNav = UINavigationController(rootViewController: marketVC)
        marketNav.tabBarItem = UITabBarItem(
            title: "行情",
            image: resizeTabBarIcon(UIImage(systemName: "chart.line.uptrend.xyaxis"), to: CGSize(width: 20, height: 20)),
            selectedImage: resizeTabBarIcon(UIImage(systemName: "chart.line.uptrend.xyaxis"), to: CGSize(width: 20, height: 20))
        )
        
        // 交易
        let tradeVC = TradeViewController()
        let tradeNav = UINavigationController(rootViewController: tradeVC)
        tradeNav.tabBarItem = UITabBarItem(
            title: "交易",
            image: resizeTabBarIcon(UIImage(systemName: "arrow.triangle.2.circlepath"), to: CGSize(width: 20, height: 20)),
            selectedImage: resizeTabBarIcon(UIImage(systemName: "arrow.triangle.2.circlepath"), to: CGSize(width: 20, height: 20))
        )
        
        // 个人中心
        let profileVC = ProfileViewController()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: "个人中心",
            image: resizeTabBarIcon(UIImage(systemName: "person"), to: CGSize(width: 20, height: 20)),
            selectedImage: resizeTabBarIcon(UIImage(systemName: "person.fill"), to: CGSize(width: 20, height: 20))
        )
        
        viewControllers = [homeNav, marketNav, tradeNav, profileNav]
    }
    
    // MARK: - 辅助方法：调整 TabBar 图标大小
    private func resizeTabBarIcon(_ image: UIImage?, to size: CGSize) -> UIImage? {
        guard let image = image else { return nil }
        
        // 计算缩放比例，保持宽高比
        let widthRatio = size.width / image.size.width
        let heightRatio = size.height / image.size.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        // 计算新的尺寸（保持宽高比）
        let scaledSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)
        
        // 计算居中位置
        let x = (size.width - scaledSize.width) / 2.0
        let y = (size.height - scaledSize.height) / 2.0
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: CGPoint(x: x, y: y), size: scaledSize))
        }.withRenderingMode(.alwaysTemplate)
    }
}

