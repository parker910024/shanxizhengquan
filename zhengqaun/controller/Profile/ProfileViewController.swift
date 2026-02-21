//
//  ProfileViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

private struct AssociatedKeys {
    static var quickAccessTitle = "quickAccessTitle"
}

class ProfileViewController: ZQViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var quickAccessView: UIView!
    private var summaryView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = Constants.Color.backgroundMain
        navigationController?.navigationBar.isHidden = true
        self.gk_navigationBar.isHidden = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // 确保 scrollView 可以滚动
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // contentView 的底部约束使用低优先级，允许内容超出时自动扩展
        let bottomConstraint = contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        bottomConstraint.priority = UILayoutPriority(250) // 默认低优先级
        bottomConstraint.isActive = true

        setupHeader()
        setupQuickAccess()
        setupAccountSummary()
        setupServiceGrid()
    }

    // MARK: - Header（深蓝 #1976D2、红 S 白底红边、专业版红徽章白字、待实名白字）
    private func setupHeader() {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // #1976D2
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        headerView.addGestureRecognizer(tapGesture)
        headerView.isUserInteractionEnabled = true

        let logoView = UIView()
        logoView.backgroundColor = .white
        logoView.layer.cornerRadius = 20
        logoView.layer.borderWidth = 1
        logoView.layer.borderColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        headerView.addSubview(logoView)
        logoView.translatesAutoresizingMaskIntoConstraints = false

        let logoSymbol = UILabel()
        logoSymbol.text = "S"
        logoSymbol.font = UIFont.boldSystemFont(ofSize: 20)
        logoSymbol.textColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        logoSymbol.textAlignment = .center
        logoView.addSubview(logoSymbol)
        logoSymbol.translatesAutoresizingMaskIntoConstraints = false
      
        let userNameLabel = UILabel()
        userNameLabel.text = "测试 (138****8008)"
        userNameLabel.font = UIFont.systemFont(ofSize: 16)
        userNameLabel.textColor = .white
        headerView.addSubview(userNameLabel)
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false

        let authLabel = UILabel()
        authLabel.text = "待实名"
        authLabel.font = UIFont.systemFont(ofSize: 12)
        authLabel.textColor = .white
        headerView.addSubview(authLabel)
        authLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加右箭头图标
        let arrowIcon = UIImageView()
        arrowIcon.image = UIImage(systemName: "chevron.right")
        arrowIcon.tintColor = .white
        arrowIcon.contentMode = .scaleAspectFit
        headerView.addSubview(arrowIcon)
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 150),

            logoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            logoView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            logoView.widthAnchor.constraint(equalToConstant: 40),
            logoView.heightAnchor.constraint(equalToConstant: 40),
            logoSymbol.centerXAnchor.constraint(equalTo: logoView.centerXAnchor),
            logoSymbol.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),

            userNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            userNameLabel.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 16),
            authLabel.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 4),
            authLabel.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 16),
            
            arrowIcon.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            arrowIcon.centerYAnchor.constraint(equalTo: headerView.centerYAnchor,constant: 15),
            arrowIcon.widthAnchor.constraint(equalToConstant: 20),
            arrowIcon.heightAnchor.constraint(equalToConstant: 20)
        ])

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
    }
    
    @objc private func headerTapped() {
        let vc = SettingsViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 快捷入口（四色圆角方块图标：紫/蓝/橙/粉，等分、左右边距）
    private func setupQuickAccess() {
        let wrap = UIView()
        wrap.backgroundColor = .white
        contentView.addSubview(wrap)
        wrap.translatesAutoresizingMaskIntoConstraints = false
        quickAccessView = wrap

        let items: [(String, String, UIColor)] = [
            ("我的持仓", "doc.text", UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1.0)),   // 紫
            ("打新记录", "star", UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)),       // 蓝
            ("配售记录", "square.and.arrow.up", UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0)), // 橙
            ("大宗交易", "yensign", UIColor(red: 0.96, green: 0.35, blue: 0.38, alpha: 1.0))    // 粉红
        ]

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        wrap.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        for item in items {
            let cell = makeQuickAccessCell(title: item.0, iconName: item.1, tint: item.2)
            stack.addArrangedSubview(cell)
        }

        NSLayoutConstraint.activate([
            wrap.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            wrap.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            wrap.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            wrap.heightAnchor.constraint(equalToConstant: 92),
            stack.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -16)
        ])
    }

    private func makeQuickAccessCell(title: String, iconName: String, tint: UIColor) -> UIView {
        let c = UIView()
        let iconBg = UIView()
        iconBg.backgroundColor = tint
        iconBg.layer.cornerRadius = 10
        c.addSubview(iconBg)
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let iv = UIImageView(image: UIImage(systemName: iconName))
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false
        iconBg.addSubview(iv)
        iv.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = title
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.textColor = Constants.Color.textPrimary
        lbl.textAlignment = .center
        lbl.isUserInteractionEnabled = false
        c.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        iconBg.isUserInteractionEnabled = false
        
        // 使用关联对象存储标题，避免通过查找 label 获取
        objc_setAssociatedObject(c, &AssociatedKeys.quickAccessTitle, title, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(quickAccessTapped(_:)))
        c.addGestureRecognizer(tapGesture)
        c.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            iconBg.topAnchor.constraint(equalTo: c.topAnchor),
            iconBg.centerXAnchor.constraint(equalTo: c.centerXAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 44),
            iconBg.heightAnchor.constraint(equalToConstant: 44),
            iv.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 22),
            iv.heightAnchor.constraint(equalToConstant: 22),
            lbl.topAnchor.constraint(equalTo: iconBg.bottomAnchor, constant: 6),
            lbl.leadingAnchor.constraint(equalTo: c.leadingAnchor),
            lbl.trailingAnchor.constraint(equalTo: c.trailingAnchor)
        ])
        return c
    }
    
    @objc private func quickAccessTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view,
              let title = objc_getAssociatedObject(view, &AssociatedKeys.quickAccessTitle) as? String else {
            return
        }
        
        switch title {
        case "我的持仓":
            let vc = MyHoldingsViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "打新记录":
            let vc = MyNewStocksViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "配售记录":
            let vc = AllotmentRecordsViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "大宗交易":
            let vc = BlockTradingListViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }

    // MARK: - 账户总资产卡片（大容器：米白/淡黄底 + 顶部金额区 + 内嵌白底：6 项 + 银证转入/转出）
    private func setupAccountSummary() {
        let card = UIView()
        card.backgroundColor = UIColor(red: 1.0, green: 0.98, blue: 0.93, alpha: 1.0) // 米白/淡黄，外框
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 8
        card.layer.shadowOpacity = 0.06
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        summaryView = card

        let pad: CGFloat = 20
        let gap: CGFloat = 16
        let innerInset: CGFloat = 12

        let titleLabel = UILabel()
        titleLabel.text = "账户总资产(元)"
        titleLabel.font = UIFont.systemFont(ofSize: 13)
        titleLabel.textColor = Constants.Color.textSecondary
        card.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let amountLabel = UILabel()
        amountLabel.text = "¥ 6946.39"
        amountLabel.font = UIFont.boldSystemFont(ofSize: 28)
        amountLabel.textColor = Constants.Color.textPrimary
        card.addSubview(amountLabel)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        let decorLabel = UILabel()
        decorLabel.text = "¥"
        decorLabel.font = UIFont.boldSystemFont(ofSize: 48)
        decorLabel.textColor = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)
        decorLabel.alpha = 0.5
        card.addSubview(decorLabel)
        decorLabel.translatesAutoresizingMaskIntoConstraints = false

        // 内嵌白底容器：可用金额、新股申购、可取金额、总盈利、浮动盈利、持仓市值、银证转入、银证转出
        let innerWhite = UIView()
        innerWhite.backgroundColor = .white
        innerWhite.layer.cornerRadius = 12
        card.addSubview(innerWhite)
        innerWhite.translatesAutoresizingMaskIntoConstraints = false

        let col1 = makeSummaryColumn([("可用金额", "¥ 6946.39"), ("总盈利", "¥ 0.00")])
        let col2 = makeSummaryColumn([("新股申购", "¥ 0.00"), ("浮动盈利", "¥ 0.00")])
        let col3 = makeSummaryColumn([("可取金额", "¥ 6946.39"), ("持仓市值", "¥ 0.00")])
        let grid = UIStackView(arrangedSubviews: [col1, col2, col3])
        grid.axis = .horizontal
        grid.distribution = .fillEqually
        grid.spacing = 0
        innerWhite.addSubview(grid)
        grid.translatesAutoresizingMaskIntoConstraints = false

        let btnIn = UIButton(type: .system)
        btnIn.setTitle("银证转入", for: .normal)
        btnIn.setTitleColor(.white, for: .normal)
        btnIn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btnIn.backgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        btnIn.layer.cornerRadius = 8
        btnIn.addTarget(self, action: #selector(openBankSecTransferIn), for: .touchUpInside)

        let btnOut = UIButton(type: .system)
        btnOut.setTitle("银证转出", for: .normal)
        btnOut.setTitleColor(.white, for: .normal)
        btnOut.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btnOut.backgroundColor = UIColor(red: 0.2, green: 0.68, blue: 0.35, alpha: 1.0)
        btnOut.layer.cornerRadius = 8
        btnOut.addTarget(self, action: #selector(openBankSecTransferOut), for: .touchUpInside)

        let btnStack = UIStackView(arrangedSubviews: [btnIn, btnOut])
        btnStack.axis = .horizontal
        btnStack.distribution = .fillEqually
        btnStack.spacing = gap
        innerWhite.addSubview(btnStack)
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: quickAccessView.bottomAnchor, constant: 20),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: pad),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            amountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            amountLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),

            decorLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: 8),
            decorLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),

            innerWhite.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: innerInset),
            innerWhite.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: innerInset),
            innerWhite.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -innerInset),
            innerWhite.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -innerInset),

            grid.topAnchor.constraint(equalTo: innerWhite.topAnchor, constant: pad),
            grid.leadingAnchor.constraint(equalTo: innerWhite.leadingAnchor, constant: pad),
            grid.trailingAnchor.constraint(equalTo: innerWhite.trailingAnchor, constant: -pad),

            btnStack.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: pad),
            btnStack.leadingAnchor.constraint(equalTo: innerWhite.leadingAnchor, constant: pad),
            btnStack.trailingAnchor.constraint(equalTo: innerWhite.trailingAnchor, constant: -pad),
            btnStack.heightAnchor.constraint(equalToConstant: 44),
            btnStack.bottomAnchor.constraint(equalTo: innerWhite.bottomAnchor, constant: -pad)
        ])
    }

    private func makeSummaryColumn(_ items: [(String, String)]) -> UIView {
        let col = UIStackView()
        col.axis = .vertical
        col.spacing = 12
        col.alignment = .leading
        for (t, v) in items {
            let lab = UILabel()
            lab.text = t
            lab.font = UIFont.systemFont(ofSize: 12)
            lab.textColor = Constants.Color.textTertiary
            let val = UILabel()
            val.text = v
            val.font = UIFont.systemFont(ofSize: 14)
            val.textColor = Constants.Color.textPrimary
            let block = UIStackView(arrangedSubviews: [lab, val])
            block.axis = .vertical
            block.spacing = 4
            block.alignment = .leading
            col.addArrangedSubview(block)
        }
        return col
    }

    // MARK: - 菜单（左圆蓝图标 + 右文字，2 列，行间分割线）
    private func setupServiceGrid() {
        let wrap = UIView()
        wrap.backgroundColor = .white
        contentView.addSubview(wrap)
        wrap.translatesAutoresizingMaskIntoConstraints = false

        let pad: CGFloat = 15
        let rowH: CGFloat = 56
        let sepH = 1 / UIScreen.main.scale

        let services: [(String, String)] = [
            ("在线客服", "message"),
            ("历史持仓", "clock"),
            ("实名认证", "checkmark.shield"),
            ("银行卡", "creditcard"),
            ("银证记录", "doc.text"),
            ("支付密码", "lock"),
            ("线上合同", "doc")
        ]

        var prev: UIView?
        for i in 0..<4 {
            let left = services[safe: i * 2]
            let right = services[safe: i * 2 + 1]
            let leftCell = left.map { makeMenuItem(title: $0.0, icon: $0.1) }
            let rightCell = right.map { makeMenuItem(title: $0.0, icon: $0.1) }

            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 0
            row.alignment = .fill
            if let l = leftCell { row.addArrangedSubview(l) }
            if let r = rightCell { row.addArrangedSubview(r) }
            if leftCell == nil, rightCell == nil { continue }
            if leftCell == nil, rightCell != nil { row.insertArrangedSubview(UIView(), at: 0) }
            if leftCell != nil, rightCell == nil { row.addArrangedSubview(UIView()) }

            wrap.addSubview(row)
            row.translatesAutoresizingMaskIntoConstraints = false

            let rowTop: NSLayoutYAxisAnchor = prev == nil ? wrap.topAnchor : prev!.bottomAnchor
            let rowTopC: CGFloat = prev == nil ? 15 : 0
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: rowTop, constant: rowTopC),
                row.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: pad),
                row.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -pad),
                row.heightAnchor.constraint(equalToConstant: rowH)
            ])

            if i < 3 {
                let sep = UIView()
                sep.backgroundColor = Constants.Color.separator
                wrap.addSubview(sep)
                sep.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    sep.topAnchor.constraint(equalTo: row.bottomAnchor),
                    sep.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: pad),
                    sep.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -pad),
                    sep.heightAnchor.constraint(equalToConstant: sepH)
                ])
                prev = sep
            } else {
                prev = row
            }
        }

        // 确保最后一行或分隔线约束到 wrap 的底部
        NSLayoutConstraint.activate([
            wrap.topAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: 24),
            wrap.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            wrap.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        if let p = prev {
            // 最后一行或分隔线约束到 wrap 底部，优先级必需（1000），确保能推动 contentView 扩展
            NSLayoutConstraint.activate([
                p.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -15)
            ])
        }
        
        // wrap 底部约束到 contentView，优先级必需（1000），确保内容超出时能推动 contentView 扩展
        let wrapBottomConstraint = wrap.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        wrapBottomConstraint.priority = .required
        wrapBottomConstraint.isActive = true

        let vLine = UIView()
        vLine.backgroundColor = Constants.Color.separator
        wrap.addSubview(vLine)
        vLine.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vLine.centerXAnchor.constraint(equalTo: wrap.centerXAnchor,constant: -20),
            vLine.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            vLine.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 15),
            vLine.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -15)
        ])
    }

    private func makeMenuItem(title: String, icon: String) -> UIView {
        let c = UIView()
        let iconV = UIView()
        iconV.backgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        iconV.layer.cornerRadius = 15
        c.addSubview(iconV)
        iconV.translatesAutoresizingMaskIntoConstraints = false

        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = .white
        img.contentMode = .scaleAspectFit
        iconV.addSubview(img)
        img.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = title
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = Constants.Color.textPrimary
        c.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(menuItemTapped(_:)))
        c.addGestureRecognizer(tapGesture)
        c.isUserInteractionEnabled = true
        c.tag = title.hashValue // 使用title的hash作为标识

        NSLayoutConstraint.activate([
            iconV.leadingAnchor.constraint(equalTo: c.leadingAnchor),
            iconV.centerYAnchor.constraint(equalTo: c.centerYAnchor),
            iconV.widthAnchor.constraint(equalToConstant: 30),
            iconV.heightAnchor.constraint(equalToConstant: 30),
            img.centerXAnchor.constraint(equalTo: iconV.centerXAnchor),
            img.centerYAnchor.constraint(equalTo: iconV.centerYAnchor),
            img.widthAnchor.constraint(equalToConstant: 18),
            img.heightAnchor.constraint(equalToConstant: 18),
            lbl.leadingAnchor.constraint(equalTo: iconV.trailingAnchor, constant: 12),
            lbl.centerYAnchor.constraint(equalTo: c.centerYAnchor)
        ])
        return c
    }
    
    @objc private func menuItemTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view,
              let titleLabel = view.subviews.compactMap({ $0 as? UILabel }).first,
              let title = titleLabel.text else {
            return
        }
        
        switch title {
        case "历史持仓":
            let vc = HistoricalHoldingsViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "在线客服":
            // TODO: 跳转到在线客服
            break
        case "实名认证":
            let vc = RealNameAuthViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "银行卡":
            let vc = BankCardViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "银证记录":
            let vc = SecuritiesTransferRecordViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "支付密码":
            let vc = ModifyPaymentPasswordViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "线上合同":
            let vc = ContractListViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
            break
        default:
            break
        }
    }

    @objc private func openBankSecTransferIn() {
        let vc = BankSecuritiesTransferViewController()
        vc.initialTabIndex = 0
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func openBankSecTransferOut() {
        let vc = BankSecuritiesTransferViewController()
        vc.initialTabIndex = 1
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? {
        return i >= 0 && i < count ? self[i] : nil
    }
}
