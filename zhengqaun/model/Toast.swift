//
//  Toast.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

/// Toast 提示组件
class Toast {
    
    private static var currentToast: UIView?
    
    /// 显示Toast提示
    /// - Parameters:
    ///   - message: 提示信息
    ///   - duration: 显示时长，默认2秒
    ///   - position: 显示位置，默认居中
    static func show(_ message: String, duration: TimeInterval = 2.0, position: ToastPosition = .center) {
        // 移除之前的Toast
        currentToast?.removeFromSuperview()
        
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return
        }
        
        // 创建Toast容器
        let toastView = UIView()
        toastView.backgroundColor = UIColor(white: 0, alpha: 0.8)
        toastView.layer.cornerRadius = 8
        toastView.layer.masksToBounds = true
        toastView.alpha = 0
        
        // 创建文字标签
        let label = UILabel()
        label.text = message
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        toastView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        window.addSubview(toastView)
        toastView.translatesAutoresizingMaskIntoConstraints = false
        
        // 计算文字大小
        let horizontalPadding: CGFloat = 32 // 左右各16
        let verticalPadding: CGFloat = 24 // 上下各12
        let maxWidth = window.bounds.width - 80
        let availableWidth = maxWidth - horizontalPadding
        
        let textSize = (message as NSString).boundingRect(
            with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: label.font!],
            context: nil
        )
        
        // ToastView的宽度：文字宽度+padding，但不超过最大宽度
        let toastWidth = min(ceil(textSize.width) + horizontalPadding, maxWidth)
        // ToastView的高度：文字高度+padding
        let toastHeight = ceil(textSize.height) + verticalPadding
        
        NSLayoutConstraint.activate([
            // Label约束：填充toastView，留出padding
            label.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -12),
            
            // ToastView尺寸约束
            toastView.widthAnchor.constraint(equalToConstant: toastWidth),
            toastView.heightAnchor.constraint(equalToConstant: toastHeight)
        ])
        
        // 设置位置约束
        switch position {
        case .top:
            NSLayoutConstraint.activate([
                toastView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                toastView.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 100)
            ])
        case .center:
            NSLayoutConstraint.activate([
                toastView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                toastView.centerYAnchor.constraint(equalTo: window.centerYAnchor)
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                toastView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                toastView.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -100)
            ])
        }
        
        currentToast = toastView
        
        // 显示动画
        UIView.animate(withDuration: 0.3, animations: {
            toastView.alpha = 1.0
        }) { _ in
            // 延迟隐藏
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.3, animations: {
                    toastView.alpha = 0
                }) { _ in
                    toastView.removeFromSuperview()
                    if currentToast == toastView {
                        currentToast = nil
                    }
                }
            }
        }
    }
    
    /// 显示成功提示
    static func showSuccess(_ message: String, duration: TimeInterval = 2.0) {
        show("✓ \(message)", duration: duration)
    }
    
    /// 显示错误提示
    static func showError(_ message: String, duration: TimeInterval = 2.0) {
        show("✕ \(message)", duration: duration)
    }
    
    /// 显示信息提示
    static func showInfo(_ message: String, duration: TimeInterval = 2.0) {
        show("ℹ \(message)", duration: duration)
    }
    
    enum ToastPosition {
        case top
        case center
        case bottom
    }
}

