//
//  MainTabBarController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    /// 选中态颜色（与参考图红色、个人中心图标/文字一致）
    private let tabSelectedRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
    
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
        tabBar.backgroundColor = .white
        tabBar.tintColor = tabSelectedRed
        tabBar.unselectedItemTintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.shadowColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.iconColor = tabSelectedRed
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: tabSelectedRed]
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
            image: resizeTabBarIcon(UIImage(named: "house"), to: CGSize(width: 20, height: 20), template: false),
            selectedImage: resizeTabBarIcon(UIImage(named: "house.fill"), to: CGSize(width: 20, height: 20), template: false)
        )
        
        // 行情
        let marketVC = MarketViewController()
        let marketNav = UINavigationController(rootViewController: marketVC)
        marketNav.tabBarItem = UITabBarItem(
            title: "行情",
            image: resizeTabBarIcon(UIImage(named: "chart.line.uptrend.xyaxis"), to: CGSize(width: 20, height: 20), template: false),
            selectedImage: resizeTabBarIcon(UIImage(named: "chart.line.uptrend.xyaxis_sel"), to: CGSize(width: 20, height: 20), template: false)
        )
        
        // 交易
        let tradeVC = TradeViewController()
        let tradeNav = UINavigationController(rootViewController: tradeVC)
        tradeNav.tabBarItem = UITabBarItem(
            title: "交易",
            image: resizeTabBarIcon(UIImage(named: "arrow.triangle.2.circlepath"), to: CGSize(width: 20, height: 20), template: false),
            selectedImage: resizeTabBarIcon(UIImage(named: "arrow.triangle.2.circlepath_sel"), to: CGSize(width: 20, height: 20), template: false)
        )
        
        // 自选
        let zixuan = ZixuanViewController()
        let zixuanNav = UINavigationController(rootViewController: zixuan)
        zixuanNav.tabBarItem = UITabBarItem(
            title: "自选",
            image: resizeTabBarIcon(UIImage(named: "zixuan_tab"), to: CGSize(width: 20, height: 20), template: false),
            selectedImage: resizeTabBarIcon(UIImage(named: "zixuan_tab_sel"), to: CGSize(width: 20, height: 20), template: false)
        )
        
        // 个人中心（系统图标，使用 tint 着色）
        let profileVC = ProfileViewController()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: "我的",
            image: resizeTabBarIcon(UIImage(systemName: "person"), to: CGSize(width: 20, height: 20), template: true),
            selectedImage: resizeTabBarIcon(UIImage(systemName: "person.fill"), to: CGSize(width: 20, height: 20), template: true)
        )
        
        viewControllers = [homeNav, marketNav, tradeNav,zixuanNav, profileNav]
    }
    
    // MARK: - 辅助方法：调整 TabBar 图标大小
    /// - Parameter template: true 使用系统 tint 着色（个人中心等系统图标）；false 保持图片原色，不重新着色
    private func resizeTabBarIcon(_ image: UIImage?, to size: CGSize, template: Bool = false) -> UIImage? {
        guard let image = image else { return nil }
        
        let widthRatio = size.width / image.size.width
        let heightRatio = size.height / image.size.height
        let scaleFactor = min(widthRatio, heightRatio)
        let scaledSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)
        let x = (size.width - scaledSize.width) / 2.0
        let y = (size.height - scaledSize.height) / 2.0
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: CGPoint(x: x, y: y), size: scaledSize))
        }
        return template ? resized.withRenderingMode(.alwaysTemplate) : resized.withRenderingMode(.alwaysOriginal)
    }
}

