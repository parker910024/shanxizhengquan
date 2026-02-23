//
//  SceneDelegate.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate , FloatViewDelegate{

    var window: UIWindow?
    var floatView : FloatView?

    /// 当前场景对应的 SceneDelegate（多场景时取第一个）
    static var current: SceneDelegate? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = scene.delegate as? SceneDelegate else { return nil }
        return delegate
    }

    /// 从 SceneDelegate 获取 window，任意处可调
    static var currentWindow: UIWindow? {
        current?.window
    }


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // 默认先显示启动页，3 秒后根据登录状态跳转登录页或 TabBar
        let launchVC = LaunchViewController()
        launchVC.onFinish = { [weak self] in
            self?.switchFromLaunchToMain()
        }
        window?.rootViewController = launchVC
        window?.makeKeyAndVisible()
        
        
    }

    /// 启动页结束后：已登录 → TabBar，未登录 → 登录页
    private func switchFromLaunchToMain() {
        guard let window = window else { return }
        let next: UIViewController
        if UserAuthManager.shared.isLoggedIn {
            next = MainTabBarController()
        } else {
            next = LoginViewController()
        }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = next
        }, completion: nil)
        
        let floatView = FloatView(radius: 30, point: CGPointMake(window.frame.size.width-70, 120), image: UIImage(named: "logoIcon"), in: window)
        floatView?.subViewShowType = .horizontal
        floatView?.delegate = self
        self.floatView = floatView
        window.addSubview(floatView!)
        
        updateDataModel()
    }
    
    func updateDataModel(){
        var index = 0
        for item in vpnDataModel.shared.ipDataArray ?? [] {
            guard let dic = item as? Dictionary<String, Any> else { continue }
            // 使用 str
            let value = dic["value"] as? String ?? ""
            self.floatView?.addSubFloatView(with: .lightGray, url: value, title: String(format: "线路%d", index), titleColor: .black, tag: 100+index)
            index += 1
        }
    }


    func floatViewSubViewClicked(withTag tag: Int) {
        let dic = vpnDataModel.shared.ipDataArray?[tag-100]
        guard let dict = dic as? Dictionary<String, Any> else {return}
        vpnDataModel.shared.selectAddress = dict["value"] as? String ?? ""
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    func switchToLogin() {
        let loginViewController = LoginViewController()
        window?.rootViewController = loginViewController
        window?.makeKeyAndVisible()
    }

    /// 登录/注册成功后切换到主界面 TabBar（由 SceneDelegate 持有 window，保证能切到）
    func switchToTabBar() {
        guard let window = window else { return }
        let tabBarController = MainTabBarController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = tabBarController
        }, completion: nil)
    }
}

