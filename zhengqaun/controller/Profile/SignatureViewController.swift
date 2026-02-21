//
//  SignatureViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

class SignatureViewController: UIViewController {
    
    var onSignatureComplete: ((UIImage) -> Void)?
    var existingSignature: UIImage? // 已存在的签名
    
    private let canvasView = UIView()
    private var currentPath = UIBezierPath()
    private var paths: [CAShapeLayer] = [] // 保存所有路径
    private var lastPoint = CGPoint.zero
    private var strokeWidth: CGFloat = 3.0
    private var strokeColor = UIColor.black
    
    private let clearButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    private var currentLayer: CAShapeLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupOrientation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupOrientation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 不在这里恢复，等dismiss完成后再恢复
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 确保恢复竖屏 - 延迟执行以确保视图已完全消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.forceRestorePortrait()
        }
    }
    
    private func restorePortraitOrientation() {
        // 临时改变方向支持，允许恢复竖屏
        // 注意：这里不能直接修改 supportedInterfaceOrientations，所以使用其他方法
        
        // 先调用 attemptRotationToDeviceOrientation 来触发系统更新
        UIViewController.attemptRotationToDeviceOrientation()
        
        // 使用延迟确保视图控制器已经不在视图层次中
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if #available(iOS 16.0, *) {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    UIViewController.attemptRotationToDeviceOrientation()
                    return
                }
                // 获取当前最顶层的视图控制器
                if let topVC = self.getTopViewController() {
                    // 如果顶层视图控制器支持竖屏，则恢复
                    if topVC.supportedInterfaceOrientations.contains(.portrait) {
                        let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                        windowScene.requestGeometryUpdate(geometryPreferences) { (error: Error?) in
                            if let error = error {
                                print("Restore orientation error: \(error)")
                            } else {
                                DispatchQueue.main.async {
                                    UIViewController.attemptRotationToDeviceOrientation()
                                }
                            }
                        }
                    } else {
                        // 如果顶层不支持，直接调用 attemptRotationToDeviceOrientation
                        UIViewController.attemptRotationToDeviceOrientation()
                    }
                } else {
                    UIViewController.attemptRotationToDeviceOrientation()
                }
            } else {
                // iOS 15 及以下
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIViewController.attemptRotationToDeviceOrientation()
                }
            }
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        var topVC = window.rootViewController
        while let presented = topVC?.presentedViewController {
            topVC = presented
        }
        
        if let nav = topVC as? UINavigationController {
            topVC = nav.topViewController
        } else if let tab = topVC as? UITabBarController {
            topVC = tab.selectedViewController
            if let nav = topVC as? UINavigationController {
                topVC = nav.topViewController
            }
        }
        
        return topVC
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    private func setupOrientation() {
        // 强制横屏
        if #available(iOS 16.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
            windowScene.requestGeometryUpdate(geometryPreferences) { (error: Error?) in
                if let error = error {
                    print("Orientation error: \(error)")
                }
            }
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
    }
    
    private var backgroundImageView: UIImageView?
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 画布
        canvasView.backgroundColor = .white
        canvasView.isUserInteractionEnabled = true
        view.addSubview(canvasView)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        
        // 如果有已存在的签名，显示背景
        if let existingSignature = existingSignature {
            let signatureImageView = UIImageView(image: existingSignature)
            signatureImageView.contentMode = .scaleAspectFit
            signatureImageView.alpha = 0.3 // 半透明作为背景
            signatureImageView.tag = 9999 // 标记为背景图片
            canvasView.addSubview(signatureImageView)
            signatureImageView.translatesAutoresizingMaskIntoConstraints = false
            backgroundImageView = signatureImageView
            NSLayoutConstraint.activate([
                signatureImageView.topAnchor.constraint(equalTo: canvasView.topAnchor),
                signatureImageView.leadingAnchor.constraint(equalTo: canvasView.leadingAnchor),
                signatureImageView.trailingAnchor.constraint(equalTo: canvasView.trailingAnchor),
                signatureImageView.bottomAnchor.constraint(equalTo: canvasView.bottomAnchor)
            ])
        }
        
        // 确保画布在最上层，可以接收触摸事件
        canvasView.bringSubviewToFront(canvasView)
        
        // 清除按钮
        clearButton.setTitle("清除", for: .normal)
        clearButton.setTitleColor(.white, for: .normal)
        clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        clearButton.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        clearButton.layer.cornerRadius = 8
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        view.addSubview(clearButton)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 取消按钮
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 确认按钮
        confirmButton.setTitle("确认", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        confirmButton.backgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        confirmButton.layer.cornerRadius = 8
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        view.addSubview(confirmButton)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            canvasView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            canvasView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            canvasView.bottomAnchor.constraint(equalTo: clearButton.topAnchor, constant: -20),
            
            clearButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            clearButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            clearButton.widthAnchor.constraint(equalToConstant: 100),
            clearButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.trailingAnchor.constraint(equalTo: confirmButton.leadingAnchor, constant: -20),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            
            confirmButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            confirmButton.widthAnchor.constraint(equalToConstant: 100),
            confirmButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastPoint = touch.location(in: canvasView)
        
        // 创建新的路径
        currentPath = UIBezierPath()
        currentPath.move(to: lastPoint)
        
        // 创建新的layer
        currentLayer = CAShapeLayer()
        currentLayer?.strokeColor = strokeColor.cgColor
        currentLayer?.fillColor = UIColor.clear.cgColor
        currentLayer?.lineWidth = strokeWidth
        currentLayer?.lineCap = .round
        currentLayer?.lineJoin = .round
        
        if let layer = currentLayer {
            canvasView.layer.addSublayer(layer)
            paths.append(layer)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let layer = currentLayer else { return }
        let currentPoint = touch.location(in: canvasView)
        
        // 添加到当前路径
        currentPath.addLine(to: currentPoint)
        layer.path = currentPath.cgPath
        
        lastPoint = currentPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let layer = currentLayer else { return }
        let currentPoint = touch.location(in: canvasView)
        
        // 完成当前路径
        currentPath.addLine(to: currentPoint)
        layer.path = currentPath.cgPath
        
        currentLayer = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentLayer = nil
    }
    
    @objc private func clearTapped() {
        // 先停止当前绘制
        currentLayer = nil
        currentPath = UIBezierPath()
        lastPoint = CGPoint.zero
        
        // 清除所有已保存的路径
        paths.forEach { $0.removeFromSuperlayer() }
        paths.removeAll()
        
        // 清除所有layer中的CAShapeLayer（确保清除干净）
        // 需要从后往前遍历，避免在遍历时修改数组
        if let sublayers = canvasView.layer.sublayers {
            for layer in sublayers.reversed() {
                if layer is CAShapeLayer {
                    layer.removeFromSuperlayer()
                }
            }
        }
        
        // 清除背景图片（如果有的话，这样用户可以完全清除重新签名）
        if let backgroundImageView = backgroundImageView {
            backgroundImageView.removeFromSuperview()
            self.backgroundImageView = nil
        }
        
        // 强制刷新视图
        canvasView.setNeedsDisplay()
        canvasView.layer.displayIfNeeded()
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true) { [weak self] in
            // 关闭后恢复竖屏
            self?.forceRestorePortrait()
        }
    }
    
    @objc private func confirmTapped() {
        // 生成签名图片
        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        canvasView.layer.render(in: context)
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return }
        
        onSignatureComplete?(image)
        dismiss(animated: true) { [weak self] in
            // 关闭后恢复竖屏
            self?.forceRestorePortrait()
        }
    }
    
    private func forceRestorePortrait() {
        // 强制恢复竖屏 - 多次尝试确保生效
        func attemptRestore() {
            if #available(iOS 16.0, *) {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    // 备用方法
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    UIViewController.attemptRotationToDeviceOrientation()
                    return
                }
                
                let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                windowScene.requestGeometryUpdate(geometryPreferences) { _ in
                    DispatchQueue.main.async {
                        UIViewController.attemptRotationToDeviceOrientation()
                    }
                }
            } else {
                // iOS 15 及以下
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
        
        // 立即尝试
        DispatchQueue.main.async {
            attemptRestore()
        }
        
        // 延迟再次尝试，确保生效
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            attemptRestore()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            attemptRestore()
        }
    }
}

