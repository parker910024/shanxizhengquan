//
//  HomePopupView.swift
//  zhengqaun
//
//  首页弹窗组件
//

import UIKit

/// 弹窗数据模型
struct HomePopupData {
    let title: String              // 标题，如"恭喜您中签"
    let subtitle: String           // 副标题，如"今日中签1只新股"
    let stockName: String          // 股票名称，如"科马材料"
    let stockCode: String         // 股票代码，如"920086"
    let quantity: String           // 数量，如"10000手"
    let amount: String             // 金额，如"1166000"
    let buttonTitle: String        // 按钮文字，如"前往认缴"
}

class HomePopupView: UIView {
    
    private let overlayView = UIView() // 遮罩层
    private let containerView = UIView() // 弹窗容器
    private let iconView = UIView() // 图标容器
    private let checkmarkIcon = UIImageView() // 对勾图标
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stockNameLabel = UILabel()
    private let stockCodeLabel = UILabel()
    private let quantityLabel = UILabel()
    private let amountLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let leftContainerView = UIView() // 左侧容器（股票名称+代码）
    private let rightContainerView = UIView() // 右侧容器（数量+金额）
    
    var onButtonTapped: (() -> Void)? // 按钮点击回调
    var onDismiss: (() -> Void)? // 关闭回调
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 遮罩层
        overlayView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        
        // 点击遮罩层关闭
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        overlayView.addGestureRecognizer(tapGesture)
        
        // 弹窗容器 - 使用 clipsToBounds 来确保圆角，但图标会添加到外层
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true // 容器内容需要圆角裁剪
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 图标容器（蓝色发光效果）- 添加到主视图，确保不被 containerView 裁剪
        iconView.backgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0) // 蓝色
        iconView.layer.cornerRadius = 40
        iconView.layer.shadowColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 0.5).cgColor
        iconView.layer.shadowOffset = CGSize(width: 0, height: 0)
        iconView.layer.shadowRadius = 20
        iconView.layer.shadowOpacity = 0.8
        iconView.clipsToBounds = false // 图标本身不裁剪
        addSubview(iconView) // 添加到主视图，而不是 containerView
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // 对勾图标
        checkmarkIcon.image = UIImage(systemName: "checkmark")
        checkmarkIcon.tintColor = .white
        checkmarkIcon.contentMode = .scaleAspectFit
        iconView.addSubview(checkmarkIcon)
        checkmarkIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // 标题
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = Constants.Color.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 副标题
        subtitleLabel.font = UIFont.systemFont(ofSize: 15)
        subtitleLabel.textColor = Constants.Color.textPrimary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        containerView.addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 左侧容器（股票名称+代码）
        leftContainerView.backgroundColor = .clear
        containerView.addSubview(leftContainerView)
        leftContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票名称
        stockNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        stockNameLabel.textColor = Constants.Color.textPrimary
        stockNameLabel.textAlignment = .left
        leftContainerView.addSubview(stockNameLabel)
        stockNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票代码
        stockCodeLabel.font = UIFont.systemFont(ofSize: 14)
        stockCodeLabel.textColor = Constants.Color.textSecondary
        stockCodeLabel.textAlignment = .left
        leftContainerView.addSubview(stockCodeLabel)
        stockCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 右侧容器（数量+金额）
        rightContainerView.backgroundColor = .clear
        containerView.addSubview(rightContainerView)
        rightContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 数量标签
        quantityLabel.font = UIFont.systemFont(ofSize: 14)
        quantityLabel.textColor = Constants.Color.textPrimary
        quantityLabel.textAlignment = .right
        quantityLabel.numberOfLines = 1
        rightContainerView.addSubview(quantityLabel)
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 金额（红色）
        amountLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        amountLabel.textColor = .systemRed
        amountLabel.textAlignment = .right
        amountLabel.numberOfLines = 1
        rightContainerView.addSubview(amountLabel)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 操作按钮
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        actionButton.backgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0) // 蓝色
        actionButton.layer.cornerRadius = 8
        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        containerView.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 遮罩层
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // 弹窗容器
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40),
            
            // 图标（向上延伸）
            iconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -40),
            iconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),
            
            checkmarkIcon.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            checkmarkIcon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            checkmarkIcon.widthAnchor.constraint(equalToConstant: 40),
            checkmarkIcon.heightAnchor.constraint(equalToConstant: 40),
            
            // 标题（图标下方）
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // 副标题
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // 股票信息区域
            // 左侧容器
            leftContainerView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            leftContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            leftContainerView.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -24),
            
            stockNameLabel.topAnchor.constraint(equalTo: leftContainerView.topAnchor),
            stockNameLabel.leadingAnchor.constraint(equalTo: leftContainerView.leadingAnchor),
            stockNameLabel.trailingAnchor.constraint(equalTo: leftContainerView.trailingAnchor),
            
            stockCodeLabel.topAnchor.constraint(equalTo: stockNameLabel.bottomAnchor, constant: 6),
            stockCodeLabel.leadingAnchor.constraint(equalTo: leftContainerView.leadingAnchor),
            stockCodeLabel.trailingAnchor.constraint(equalTo: leftContainerView.trailingAnchor),
            stockCodeLabel.bottomAnchor.constraint(equalTo: leftContainerView.bottomAnchor),
            
            // 右侧容器（相对于左侧容器垂直居中）
            rightContainerView.centerYAnchor.constraint(equalTo: leftContainerView.centerYAnchor),
            rightContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            rightContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: leftContainerView.trailingAnchor, constant: 20),
            
            // 数量和金额垂直堆叠，都右对齐
            quantityLabel.topAnchor.constraint(equalTo: rightContainerView.topAnchor),
            quantityLabel.leadingAnchor.constraint(equalTo: rightContainerView.leadingAnchor),
            quantityLabel.trailingAnchor.constraint(equalTo: rightContainerView.trailingAnchor),
            
            amountLabel.topAnchor.constraint(equalTo: quantityLabel.bottomAnchor, constant: 6),
            amountLabel.leadingAnchor.constraint(equalTo: rightContainerView.leadingAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: rightContainerView.trailingAnchor),
            amountLabel.bottomAnchor.constraint(equalTo: rightContainerView.bottomAnchor),
            
            // 操作按钮
            actionButton.topAnchor.constraint(equalTo: stockCodeLabel.bottomAnchor, constant: 24),
            actionButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            actionButton.heightAnchor.constraint(equalToConstant: 44),
            actionButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    func configure(with data: HomePopupData) {
        titleLabel.text = data.title
        subtitleLabel.text = data.subtitle
        stockNameLabel.text = data.stockName
        stockCodeLabel.text = data.stockCode
        quantityLabel.text = "数量: \(data.quantity)"
        amountLabel.text = data.amount
        actionButton.setTitle(data.buttonTitle, for: .normal)
    }
    
    func show(in view: UIView) {
        view.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 初始状态：透明
        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // 显示动画
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 1.0
            self.containerView.transform = .identity
        })
    }
    
    @objc private func dismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.removeFromSuperview()
            self.onDismiss?()
        }
    }
    
    @objc private func buttonTapped() {
        onButtonTapped?()
        dismiss()
    }
}
