//
//  RealNameAuthResultViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

enum RealNameAuthStatus {
    case pending    // 等待审核
    case approved   // 审核通过
    case rejected   // 审核失败
}

class RealNameAuthResultViewController: ZQViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 证件信息
    private let nameLabel = UILabel()
    private let idCardLabel = UILabel()
    private let statusStamp = UIView() // 审核状态印章
    private var idCardContainer: UIView! // 证件号容器
    
    // 状态按钮
    private let statusButton = UIButton(type: .system)
    
    // 注意事项
    private let noticeLabel = UILabel()
    
    // 状态印章标签
    private let stampLabel = UILabel()
    
    // 状态
    var authStatus: RealNameAuthStatus = .approved {
        didSet {
            // 如果视图已加载，立即更新UI
            if isViewLoaded {
                updateUI()
            }
        }
    }
    var name: String = ""
    var idCard: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "实名认证"
        gk_navLineHidden = true
        gk_backStyle = .black
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupCertificateInfo()
        setupStatusButton()
        setupNotice()
    }
    
    // MARK: - 证件信息
    private func setupCertificateInfo() {
        let sectionLabel = UILabel()
        sectionLabel.text = "证件信息"
        sectionLabel.font = UIFont.systemFont(ofSize: 15)
        sectionLabel.textColor = Constants.Color.textSecondary
        contentView.addSubview(sectionLabel)
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 姓名容器
        let nameContainer = createInfoRow(label: "姓名", valueLabel: nameLabel)
        contentView.addSubview(nameContainer)
        nameContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 证件号容器
        idCardContainer = createInfoRow(label: "证件号", valueLabel: idCardLabel)
        contentView.addSubview(idCardContainer)
        idCardContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 审核状态印章（带锯齿效果）
        statusStamp.clipsToBounds = false
        contentView.addSubview(statusStamp)
        statusStamp.translatesAutoresizingMaskIntoConstraints = false
        
        stampLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        stampLabel.textColor = .white
        stampLabel.textAlignment = .center
        statusStamp.addSubview(stampLabel)
        stampLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            sectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            nameContainer.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 16),
            nameContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameContainer.heightAnchor.constraint(equalToConstant: 50),
            
            idCardContainer.topAnchor.constraint(equalTo: nameContainer.bottomAnchor, constant: 12),
            idCardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            idCardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            idCardContainer.heightAnchor.constraint(equalToConstant: 50),
            
            statusStamp.trailingAnchor.constraint(equalTo: idCardContainer.trailingAnchor, constant: -10),
            statusStamp.centerYAnchor.constraint(equalTo: idCardContainer.centerYAnchor),
            statusStamp.widthAnchor.constraint(equalToConstant: 70),
            statusStamp.heightAnchor.constraint(equalToConstant: 30),
            
            stampLabel.topAnchor.constraint(equalTo: statusStamp.topAnchor, constant: 4),
            stampLabel.leadingAnchor.constraint(equalTo: statusStamp.leadingAnchor, constant: 8),
            stampLabel.trailingAnchor.constraint(equalTo: statusStamp.trailingAnchor, constant: -8),
            stampLabel.bottomAnchor.constraint(equalTo: statusStamp.bottomAnchor, constant: -4)
        ])
    }
    
    private func createInfoRow(label: String, valueLabel: UILabel) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.borderWidth = 1
        container.layer.borderColor = Constants.Color.separator.cgColor
        container.layer.cornerRadius = 8
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 15)
        labelView.textColor = Constants.Color.textPrimary
        container.addSubview(labelView)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        valueLabel.font = UIFont.systemFont(ofSize: 15)
        valueLabel.textColor = Constants.Color.textPrimary
        container.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            labelView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            labelView.widthAnchor.constraint(equalToConstant: 60),
            
            valueLabel.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    // MARK: - 状态按钮
    private func setupStatusButton() {
        statusButton.layer.cornerRadius = 8
        statusButton.addTarget(self, action: #selector(statusButtonTapped), for: .touchUpInside)
        contentView.addSubview(statusButton)
        statusButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            statusButton.topAnchor.constraint(equalTo: idCardContainer.bottomAnchor, constant: 40),
            statusButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            statusButton.widthAnchor.constraint(equalToConstant: 200),
            statusButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - 注意事项
    private func setupNotice() {
        noticeLabel.text = "注意事项:\n务必使用真实的本人姓名、身份证号码信息进行填写。系统会校验信息的真实性,如果信息有误将直接会影响到山西证券为您提供的服务的正常使用。"
        noticeLabel.font = UIFont.systemFont(ofSize: 12)
        noticeLabel.textColor = Constants.Color.stockRise // 红色
        noticeLabel.numberOfLines = 0
        contentView.addSubview(noticeLabel)
        noticeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            noticeLabel.topAnchor.constraint(equalTo: statusButton.bottomAnchor, constant: 30),
            noticeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            noticeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            noticeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Update UI
    private func updateUI() {
        // 根据状态更新UI
        switch authStatus {
        case .pending:
            updatePendingUI()
        case .approved:
            updateApprovedUI()
        case .rejected:
            updateRejectedUI()
        }
        
        // 更新证件信息（显示星号）
        nameLabel.text = maskString(name, showCount: 0)
        idCardLabel.text = maskString(idCard, showCount: 0)
    }
    
    private func updatePendingUI() {
        // 等待审核
        statusStamp.isHidden = true
        
        statusButton.setTitle("等待审核", for: .normal)
        statusButton.setTitleColor(Constants.Color.textSecondary, for: .normal)
        statusButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusButton.backgroundColor = Constants.Color.backgroundMain
        statusButton.isEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateStampShape()
    }
    
    private func updateStampShape() {
        // 创建锯齿边缘的路径
        let width: CGFloat = 70
        let height: CGFloat = 30
        let jaggedDepth: CGFloat = 2.0 // 锯齿深度（向外突出）
        let jaggedWidth: CGFloat = 3.0 // 锯齿宽度
        
        let path = UIBezierPath()
        
        // 顶部边缘（从左到右，带锯齿）
        path.move(to: CGPoint(x: jaggedDepth, y: 0))
        var x: CGFloat = jaggedDepth
        while x < width - jaggedDepth {
            // 锯齿向上突出
            path.addLine(to: CGPoint(x: x + jaggedWidth / 2, y: -jaggedDepth))
            path.addLine(to: CGPoint(x: x + jaggedWidth, y: 0))
            x += jaggedWidth
        }
        path.addLine(to: CGPoint(x: width - jaggedDepth, y: 0))
        
        // 右侧边缘（从上到下，带锯齿）
        path.addLine(to: CGPoint(x: width, y: jaggedDepth))
        var y: CGFloat = jaggedDepth
        while y < height - jaggedDepth {
            // 锯齿向右突出
            path.addLine(to: CGPoint(x: width + jaggedDepth, y: y + jaggedWidth / 2))
            path.addLine(to: CGPoint(x: width, y: y + jaggedWidth))
            y += jaggedWidth
        }
        path.addLine(to: CGPoint(x: width, y: height - jaggedDepth))
        
        // 底部边缘（从右到左，带锯齿）
        path.addLine(to: CGPoint(x: width - jaggedDepth, y: height))
        x = width - jaggedDepth
        while x > jaggedDepth {
            // 锯齿向下突出
            path.addLine(to: CGPoint(x: x - jaggedWidth / 2, y: height + jaggedDepth))
            path.addLine(to: CGPoint(x: x - jaggedWidth, y: height))
            x -= jaggedWidth
        }
        path.addLine(to: CGPoint(x: jaggedDepth, y: height))
        
        // 左侧边缘（从下到上，带锯齿）
        path.addLine(to: CGPoint(x: 0, y: height - jaggedDepth))
        y = height - jaggedDepth
        while y > jaggedDepth {
            // 锯齿向左突出
            path.addLine(to: CGPoint(x: -jaggedDepth, y: y - jaggedWidth / 2))
            path.addLine(to: CGPoint(x: 0, y: y - jaggedWidth))
            y -= jaggedWidth
        }
        path.addLine(to: CGPoint(x: 0, y: jaggedDepth))
        path.close()
        
        // 创建形状层
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = getCurrentStampColor().cgColor
        shapeLayer.frame = statusStamp.bounds
        
        // 移除旧的形状层
        statusStamp.layer.sublayers?.forEach { layer in
            if layer.name == "stampShape" {
                layer.removeFromSuperlayer()
            }
        }
        
        shapeLayer.name = "stampShape"
        statusStamp.layer.insertSublayer(shapeLayer, at: 0)
        statusStamp.backgroundColor = .clear
    }
    
    private func getCurrentStampColor() -> UIColor {
        switch authStatus {
        case .approved:
            return UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0) // 蓝色
        case .rejected:
            return Constants.Color.stockRise // 红色
        case .pending:
            return UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0) // 默认蓝色
        }
    }
    
    private func updateApprovedUI() {
        // 审核通过
        statusStamp.isHidden = false
        stampLabel.text = "审核通过"
        statusStamp.transform = CGAffineTransform(rotationAngle: -0.1) // 稍微旋转
        
        // 更新印章颜色和形状
        updateStampColor(UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)) // 蓝色
        
        statusButton.setTitle("审核通过", for: .normal)
        statusButton.setTitleColor(Constants.Color.textSecondary, for: .normal)
        statusButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusButton.backgroundColor = Constants.Color.backgroundMain
        statusButton.isEnabled = false
        
        // 强制更新布局
        DispatchQueue.main.async { [weak self] in
            self?.updateStampShape()
            self?.addStampTexture()
        }
    }
    
    private func updateRejectedUI() {
        // 审核失败
        statusStamp.isHidden = false
        stampLabel.text = "审核失败"
        statusStamp.transform = CGAffineTransform(rotationAngle: -0.1) // 稍微旋转
        
        // 更新印章颜色和形状
        updateStampColor(Constants.Color.stockRise) // 红色
        
        statusButton.setTitle("审核失败", for: .normal)
        statusButton.setTitleColor(.white, for: .normal)
        statusButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusButton.backgroundColor = Constants.Color.stockRise // 红色
        statusButton.isEnabled = true
        
        // 强制更新布局
        DispatchQueue.main.async { [weak self] in
            self?.updateStampShape()
            self?.addStampTexture()
        }
    }
    
    private func updateStampColor(_ color: UIColor) {
        // 更新形状层的颜色并重新绘制
        updateStampShape()
    }
    
    private func addStampTexture() {
        // 移除之前的纹理层
        statusStamp.layer.sublayers?.forEach { layer in
            if layer.name == "stampTexture" {
                layer.removeFromSuperlayer()
            }
        }
        
        // 创建纹理层（模拟印章的破损效果）
        let textureLayer = CALayer()
        textureLayer.name = "stampTexture"
        textureLayer.frame = statusStamp.bounds
        textureLayer.opacity = 0.2
        
        // 创建一些随机的小点来模拟纹理
        let texturePath = UIBezierPath()
        let pointCount = 15
        for _ in 0..<pointCount {
            let x = CGFloat.random(in: 3..<statusStamp.bounds.width - 3)
            let y = CGFloat.random(in: 3..<statusStamp.bounds.height - 3)
            let radius = CGFloat.random(in: 0.3..<1.2)
            texturePath.append(UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true))
        }
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = texturePath.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
        textureLayer.addSublayer(shapeLayer)
        
        statusStamp.layer.addSublayer(textureLayer)
    }
    
    private func maskString(_ string: String, showCount: Int = 0) -> String {
        guard string.count > showCount else {
            return String(repeating: "*", count: string.count)
        }
        
        let visiblePart = String(string.prefix(showCount))
        let maskedPart = String(repeating: "*", count: string.count - showCount)
        return visiblePart + maskedPart
    }
    
    @objc private func statusButtonTapped() {
        if authStatus == .rejected {
            // 审核失败，可以重新提交
            navigationController?.popViewController(animated: true)
        }
    }
}

