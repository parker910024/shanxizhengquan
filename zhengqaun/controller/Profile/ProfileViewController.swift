//
//  ProfileViewController.swift
//  zhengqaun
//
//  个人中心 - 按 UI 图严格布局
//

import UIKit
import SafariServices

class ProfileViewController: ZQViewController {

    private let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
    private let textPrimary = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    private let textSecondary = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    private let cardBg = UIColor.white
    private let separatorColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var headerView: UIView!
    private var functionsCard: UIView!
    private var channelKeyOverlay: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Color.backgroundMain
        navigationController?.navigationBar.isHidden = true
        gk_navigationBar.isHidden = true
        gk_navigationBar.isUserInteractionEnabled = false
        setupScroll()
        setupHeader()
        setupQuickActionsCard()
        setupAssetsCard()
        setupFunctionsCard()
    }

    func requestUserInfo() {
        SecureNetworkManager.shared.request(api: Api.user_info_api, method: .get, params: [:]) { result in
            switch result {
                case .success(let res):
                    print("status =", res.statusCode)
                    print("raw =", res.raw)          // 原始响应
                    print("decrypted =", res.decrypted ?? "无法解密") // 解密后的明文（如果能解）
                    let dict = res.decrypted
                    print(dict)
                if dict?["code"] as? NSNumber != 1 {

                        DispatchQueue.main.async {
                            Toast.showInfo(dict?["msg"] as? String ?? "")
                        }
                        return
                    }
            case .failure(let error):
                print("error =", error.localizedDescription)
                Toast.showError(error.localizedDescription)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gk_navigationBar.isHidden = true
        gk_navigationBar.isUserInteractionEnabled = false
        gk_navigationBar.layer.zPosition = -1
        scrollView.layer.zPosition = 1
        view.bringSubviewToFront(scrollView)
        
        requestUserInfo()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.bringSubviewToFront(scrollView)
    }

    private func setupScroll() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - Header（白底、红 Logo、手机号、账号、消息/设置）
    private func setupHeader() {
        let header = UIView()
        header.backgroundColor = .white
        contentView.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false
        headerView = header

        let logoView = UIView()
        logoView.backgroundColor = themeRed
        logoView.layer.cornerRadius = 22
        header.addSubview(logoView)
        logoView.translatesAutoresizingMaskIntoConstraints = false
        let logoLabel = UILabel()
        logoLabel.text = "证"
        logoLabel.font = UIFont.boldSystemFont(ofSize: 18)
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        logoView.addSubview(logoLabel)
        logoLabel.translatesAutoresizingMaskIntoConstraints = false

        let phoneLabel = UILabel()
        let phone = UserAuthManager.shared.currentPhone ?? "1877777718"
        phoneLabel.text = maskPhone(phone)
        phoneLabel.font = UIFont.boldSystemFont(ofSize: 16)
        phoneLabel.textColor = textPrimary
        header.addSubview(phoneLabel)
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false

        let accountLabel = UILabel()
        let uid = UserAuthManager.shared.userID
        accountLabel.text = uid.isEmpty ? "T007975614" : "T\(uid)"
        accountLabel.font = UIFont.systemFont(ofSize: 13)
        accountLabel.textColor = textPrimary
        header.addSubview(accountLabel)
        accountLabel.translatesAutoresizingMaskIntoConstraints = false

        let messageBtn = UIButton(type: .system)
        messageBtn.setImage(UIImage(systemName: "envelope"), for: .normal)
        messageBtn.tintColor = textPrimary
        messageBtn.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
        header.addSubview(messageBtn)
        messageBtn.translatesAutoresizingMaskIntoConstraints = false

        let settingsBtn = UIButton(type: .system)
        settingsBtn.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsBtn.tintColor = textPrimary
        settingsBtn.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        header.addSubview(settingsBtn)
        settingsBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: contentView.topAnchor),
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 88),

            logoView.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            logoView.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 44),
            logoView.heightAnchor.constraint(equalToConstant: 44),
            logoLabel.centerXAnchor.constraint(equalTo: logoView.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),

            phoneLabel.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 14),
            phoneLabel.bottomAnchor.constraint(equalTo: logoView.centerYAnchor, constant: -2),
            accountLabel.leadingAnchor.constraint(equalTo: phoneLabel.leadingAnchor),
            accountLabel.topAnchor.constraint(equalTo: logoView.centerYAnchor, constant: 4),

            settingsBtn.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            settingsBtn.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            settingsBtn.widthAnchor.constraint(equalToConstant: 44),
            settingsBtn.heightAnchor.constraint(equalToConstant: 44),
            messageBtn.trailingAnchor.constraint(equalTo: settingsBtn.leadingAnchor, constant: -4),
            messageBtn.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            messageBtn.widthAnchor.constraint(equalToConstant: 44),
            messageBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func maskPhone(_ phone: String) -> String {
        guard phone.count >= 11 else { return phone }
        let start = phone.prefix(3)
        let end = phone.suffix(4)
        return "\(start)****\(end)"
    }

    @objc private func messageTapped() {
        let vc = MessageCenterViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func settingsTapped() {
        let vc = SettingsViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 快捷入口（银证转入、银证转出、持仓记录、在线客服）
    private func setupQuickActionsCard() {
        let card = makeCard()
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        quickActionsCard = card

        let items: [(String, String)] = [
            ("银证转入", "yinzhengzhuanru"),
            ("银证转出", "yinzhengzhuanchu"),
            ("持仓记录", "chicangjilu"),
            ("在线客服", "zaixiankefu")
        ]
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        for (index, item) in items.enumerated() {
            let cell = makeQuickCell(title: item.0, systemIcon: item.1)
            cell.tag = index
            let tap = UITapGestureRecognizer(target: self, action: #selector(quickActionTapped(_:)))
            tap.cancelsTouchesInView = true
            cell.addGestureRecognizer(tap)
            cell.isUserInteractionEnabled = true
            stack.addArrangedSubview(cell)
        }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.heightAnchor.constraint(equalToConstant: 100),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    private func makeQuickCell(title: String, systemIcon: String) -> UIView {
        let c = UIView()
        let iconBg = UIView()
        c.addSubview(iconBg)
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        let iv = UIImageView(image: UIImage(named: systemIcon))
//        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iconBg.addSubview(iv)
        iv.translatesAutoresizingMaskIntoConstraints = false
        let lbl = UILabel()
        lbl.text = title
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.textColor = textPrimary
        lbl.textAlignment = .center
        c.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconBg.topAnchor.constraint(equalTo: c.topAnchor),
            iconBg.centerXAnchor.constraint(equalTo: c.centerXAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 30),
            iconBg.heightAnchor.constraint(equalToConstant: 27),
            iv.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 30),
            iv.heightAnchor.constraint(equalToConstant: 27),
            lbl.topAnchor.constraint(equalTo: iconBg.bottomAnchor, constant: 8),
            lbl.leadingAnchor.constraint(equalTo: c.leadingAnchor),
            lbl.trailingAnchor.constraint(equalTo: c.trailingAnchor)
        ])
        return c
    }

    @objc private func quickActionTapped(_ g: UITapGestureRecognizer) {
        guard let v = g.view else { return }
        let titles = ["银证转入", "银证转出", "持仓记录", "在线客服"]
        guard v.tag >= 0, v.tag < titles.count else { return }
        let title = titles[v.tag]
        switch title {
        case "银证转入":
            let vc = BankTransferInViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "银证转出":
            let vc = BankSecuritiesTransferViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "持仓记录":
            let vc = MyHoldingsViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "在线客服":
            openCustomerService()
        default:
            break
        }
    }

    // MARK: - 我的资产
    private var quickActionsCard: UIView!
    private var assetsCard: UIView!
    private var balanceLabel: UILabel!
    private var balanceHidden = false

    private func setupAssetsCard() {
        let card = makeCard()
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        assetsCard = card

        let titleLabel = UILabel()
        titleLabel.text = "我的资产"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = textPrimary
        card.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let eyeBtn = UIButton(type: .system)
        eyeBtn.setImage(UIImage(systemName: "eye"), for: .normal)
        eyeBtn.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        eyeBtn.tintColor = textSecondary
        eyeBtn.addTarget(self, action: #selector(toggleBalanceVisibility), for: .touchUpInside)
        card.addSubview(eyeBtn)
        eyeBtn.translatesAutoresizingMaskIntoConstraints = false

        balanceLabel = UILabel()
        balanceLabel.text = "0.00"
        balanceLabel.font = UIFont.boldSystemFont(ofSize: 28)
        balanceLabel.textColor = textPrimary
        balanceLabel.textAlignment = .left
        card.addSubview(balanceLabel)
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false

        let row1Labels = ["可用", "可取", "股质余额"]
        let row2Labels = ["总市值", "总盈亏", "浮动盈亏"]
        let alignments: [NSTextAlignment] = [.left, .center, .right]
        let row1Stack = UIStackView()
        row1Stack.axis = .horizontal
        row1Stack.distribution = .fillEqually
        row1Stack.alignment = .fill
        row1Stack.spacing = 0
        let row2Stack = UIStackView()
        row2Stack.axis = .horizontal
        row2Stack.distribution = .fillEqually
        row2Stack.alignment = .fill
        row2Stack.spacing = 0
        for (i, l) in row1Labels.enumerated() {
            row1Stack.addArrangedSubview(makeAssetItem(label: l, value: "0.00", alignment: alignments[i]))
        }
        for (i, l) in row2Labels.enumerated() {
            row2Stack.addArrangedSubview(makeAssetItem(label: l, value: "0.00", alignment: alignments[i]))
        }
        card.addSubview(row1Stack)
        card.addSubview(row2Stack)
        row1Stack.translatesAutoresizingMaskIntoConstraints = false
        row2Stack.translatesAutoresizingMaskIntoConstraints = false

        let btn1 = makePillButton(title: "资金记录", imageName: "zijinjilu", color: UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0))
        let btn2 = makePillButton(title: "交易记录", imageName: "jiaoyijilu", color: themeRed)
        let btn3 = makePillButton(title: "持仓记录", imageName: "chicangjilu_small", color: UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0))
        btn1.addTarget(self, action: #selector(fundRecordTapped), for: .touchUpInside)
        btn2.addTarget(self, action: #selector(tradeRecordTapped), for: .touchUpInside)
        btn3.addTarget(self, action: #selector(holdingRecordTapped), for: .touchUpInside)
        let btnStack = UIStackView(arrangedSubviews: [btn1, btn2, btn3])
        btnStack.axis = .horizontal
        btnStack.distribution = .fillEqually
        btnStack.spacing = 12
        card.addSubview(btnStack)
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: quickActionsCard.bottomAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 17),
            eyeBtn.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            eyeBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            eyeBtn.widthAnchor.constraint(equalToConstant: 44),
            eyeBtn.heightAnchor.constraint(equalToConstant: 44),

            balanceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            balanceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 17),
            balanceLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -17),

            row1Stack.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 20),
            row1Stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 17),
            row1Stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -17),
            row2Stack.topAnchor.constraint(equalTo: row1Stack.bottomAnchor, constant: 16),
            row2Stack.leadingAnchor.constraint(equalTo: row1Stack.leadingAnchor),
            row2Stack.trailingAnchor.constraint(equalTo: row1Stack.trailingAnchor),

            btnStack.topAnchor.constraint(equalTo: row2Stack.bottomAnchor, constant: 20),
            btnStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            btnStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            btnStack.heightAnchor.constraint(equalToConstant: 40),
            btnStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
    }

    private func makeAssetItem(label: String, value: String, alignment: NSTextAlignment = .center) -> UIView {
        let wrap = UIStackView()
        wrap.axis = .vertical
        wrap.spacing = 4
        wrap.alignment = alignment == .left ? .leading : (alignment == .right ? .trailing : .center)
        wrap.distribution = .equalSpacing
        let l = UILabel()
        l.text = label
        l.font = UIFont.systemFont(ofSize: 17)
        l.textColor = textSecondary
        l.textAlignment = alignment
        l.numberOfLines = 1
        let v = UILabel()
        v.text = value
        v.font = UIFont.systemFont(ofSize: 16)
        v.textColor = textPrimary
        v.textAlignment = alignment
        v.numberOfLines = 1
        wrap.addArrangedSubview(l)
        wrap.addArrangedSubview(v)
        let container = UIView()
        container.addSubview(wrap)
        wrap.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrap.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            wrap.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            wrap.topAnchor.constraint(equalTo: container.topAnchor),
            wrap.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func makePillButton(title: String, imageName: String, color: UIColor) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(color, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.layer.cornerRadius = 20
        b.layer.borderWidth = 1
        b.layer.borderColor = color.cgColor
        b.semanticContentAttribute = .forceLeftToRight
        if let img = UIImage(named: imageName) {
            let size = CGSize(width: 15, height: 15)
            let renderer = UIGraphicsImageRenderer(size: size)
            let resized = renderer.image { _ in img.draw(in: CGRect(origin: .zero, size: size)) }.withRenderingMode(.alwaysOriginal)
            b.setImage(resized, for: .normal)
            b.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 6)
            b.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        }
        return b
    }

    @objc private func toggleBalanceVisibility(_ sender: UIButton) {
        balanceHidden.toggle()
        sender.isSelected = balanceHidden
        balanceLabel.text = balanceHidden ? "****" : "0.00"
    }

    @objc private func fundRecordTapped() {
        let vc = SecuritiesTransferRecordViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func tradeRecordTapped() {
        let vc = TradeRecordViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func holdingRecordTapped() {
        let vc = MyHoldingsViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 我的功能（8 宫格）
    private func setupFunctionsCard() {
        let card = makeCard()
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        functionsCard = card

        let titleLabel = UILabel()
        titleLabel.text = "我的功能"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = textPrimary
        card.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let items: [(String, String)] = [
            ("实名认证", "person"),
            ("个人资料", "doc.text"),
            ("银行卡", "creditcard"),
            ("线上合同", "envelope"),
            ("交易密码", "lock"),
            ("客服中心", "headphones"),
            ("退出账户", "rectangle.portrait.and.arrow.right")
        ]
        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.distribution = .fillEqually
        row1.spacing = 0
        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.distribution = .fillEqually
        row2.spacing = 0
        for i in 0..<min(4, items.count) { row1.addArrangedSubview(makeFunctionCell(items[i], tag: i)) }
        for i in 4..<items.count { row2.addArrangedSubview(makeFunctionCell(items[i], tag: i)) }
        let row2Wrapper = UIView()
        row2Wrapper.addSubview(row2)
        row2.translatesAutoresizingMaskIntoConstraints = false
        let col = UIStackView(arrangedSubviews: [row1, row2Wrapper])
        col.axis = .vertical
        col.spacing = 24
        col.distribution = .fillEqually
        card.addSubview(col)
        col.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: assetsCard.bottomAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            col.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            col.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            col.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            col.heightAnchor.constraint(equalToConstant: 140),
            col.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),

            row2.leadingAnchor.constraint(equalTo: row2Wrapper.leadingAnchor),
            row2.topAnchor.constraint(equalTo: row2Wrapper.topAnchor),
            row2.bottomAnchor.constraint(equalTo: row2Wrapper.bottomAnchor),
            row2.widthAnchor.constraint(equalTo: row1.widthAnchor, multiplier: 0.75),

            contentView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: 20)
        ])
    }

    private func makeFunctionCell(_ item: (String, String), tag: Int) -> UIView {
        let c = UIView()
        c.tag = tag
        let iv = UIImageView(image: UIImage(systemName: item.1))
        iv.tintColor = textPrimary
        iv.contentMode = .scaleAspectFit
        c.addSubview(iv)
        iv.translatesAutoresizingMaskIntoConstraints = false
        let lbl = UILabel()
        lbl.text = item.0
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.textColor = textPrimary
        lbl.textAlignment = .center
        c.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(functionTapped(_:)))
        tap.cancelsTouchesInView = true
        c.addGestureRecognizer(tap)
        c.isUserInteractionEnabled = true
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: c.topAnchor),
            iv.centerXAnchor.constraint(equalTo: c.centerXAnchor),
            iv.widthAnchor.constraint(equalToConstant: 28),
            iv.heightAnchor.constraint(equalToConstant: 28),
            lbl.topAnchor.constraint(equalTo: iv.bottomAnchor, constant: 8),
            lbl.leadingAnchor.constraint(equalTo: c.leadingAnchor),
            lbl.trailingAnchor.constraint(equalTo: c.trailingAnchor)
        ])
        return c
    }

    @objc private func functionTapped(_ g: UITapGestureRecognizer) {
        guard let v = g.view else { return }
        let titles = ["实名认证", "个人资料", "银行卡", "线上合同", "交易密码", "客服中心", "退出账户"]
        guard v.tag >= 0, v.tag < titles.count else { return }
        let title = titles[v.tag]
        switch title {
        case "实名认证":
            let vc = RealNameAuthViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "个人资料":
            let vc = PersonalProfileViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "银行卡":
            let vc = BankCardViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "线上合同":
            let vc = ContractListViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "交易密码":
            let vc = TransactionPasswordViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case "客服中心":
            openCustomerService()
        case "退出账户":
            let alert = UIAlertController(title: "提示", message: "确定要退出登录吗？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
                UserAuthManager.shared.logout()
                if let scene = self?.view.window?.windowScene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let delegate = scene.delegate as? SceneDelegate {
                    delegate.switchToLogin()
                }
            })
            present(alert, animated: true)
        default:
            break
        }
    }

    /// 打开客服页面（与「在线客服」「客服中心」共用）
    private func openCustomerService() {
        guard let url = URL(string: "https://www.htsc.com.cn") else { return }
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }

    // MARK: - 通道密钥弹窗（类似首页弹窗：遮罩 + 白卡片 + 标题 + 输入 + 返回/确认）
    private func showChannelKeyPopupIfNeeded() {
        guard channelKeyOverlay == nil else { return }
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.layer.zPosition = 100
        view.addSubview(overlay)
        view.bringSubviewToFront(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        channelKeyOverlay = overlay

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(card)

        let titleLabel = UILabel()
        titleLabel.text = "通道密钥"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        let inputWrap = UIView()
        inputWrap.backgroundColor = .white
        inputWrap.layer.cornerRadius = 8
        inputWrap.layer.borderWidth = 1
        inputWrap.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1).cgColor
        inputWrap.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inputWrap)

        let leftLabel = UILabel()
        leftLabel.text = "通道密钥"
        leftLabel.font = UIFont.systemFont(ofSize: 15)
        leftLabel.textColor = textPrimary
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        inputWrap.addSubview(leftLabel)

        let textField = UITextField()
        textField.placeholder = "请输入通道密钥"
        textField.font = UIFont.systemFont(ofSize: 15)
        textField.textColor = textPrimary
        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        inputWrap.addSubview(textField)

        let backBtn = UIButton(type: .system)
        backBtn.setTitle("返回", for: .normal)
        backBtn.setTitleColor(textPrimary, for: .normal)
        backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        backBtn.backgroundColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        backBtn.layer.cornerRadius = 22
        backBtn.addTarget(self, action: #selector(dismissChannelKeyPopup), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(backBtn)

        let confirmBtn = UIButton(type: .system)
        confirmBtn.setTitle("确认", for: .normal)
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        confirmBtn.backgroundColor = UIColor(red: 0.9, green: 0.2, blue: 0.15, alpha: 1)
        confirmBtn.layer.cornerRadius = 22
        confirmBtn.addTarget(self, action: #selector(channelKeyConfirmTapped), for: .touchUpInside)
        confirmBtn.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(confirmBtn)

        let cardW: CGFloat = 315
        let cardH: CGFloat = 240
        let cardPadding: CGFloat = 20
        let titleTop: CGFloat = 24
        let titleToInput: CGFloat = 20
        let inputH: CGFloat = 44
        let inputToBtns: CGFloat = 24
        let btnBottom: CGFloat = 24
        let btnH: CGFloat = 44
        let btnSpacing: CGFloat = 12
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -20),
            card.widthAnchor.constraint(equalToConstant: cardW),
            card.heightAnchor.constraint(equalToConstant: cardH),

            titleLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: titleTop),

            inputWrap.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPadding),
            inputWrap.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPadding),
            inputWrap.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: titleToInput),
            inputWrap.heightAnchor.constraint(equalToConstant: inputH),

            leftLabel.leadingAnchor.constraint(equalTo: inputWrap.leadingAnchor, constant: 12),
            leftLabel.centerYAnchor.constraint(equalTo: inputWrap.centerYAnchor),
            textField.leadingAnchor.constraint(equalTo: leftLabel.trailingAnchor, constant: 10),
            textField.trailingAnchor.constraint(equalTo: inputWrap.trailingAnchor, constant: -12),
            textField.centerYAnchor.constraint(equalTo: inputWrap.centerYAnchor),

            backBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPadding),
            backBtn.trailingAnchor.constraint(equalTo: card.centerXAnchor, constant: -btnSpacing/2),
            backBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -btnBottom),
            backBtn.heightAnchor.constraint(equalToConstant: btnH),

            confirmBtn.leadingAnchor.constraint(equalTo: card.centerXAnchor, constant: btnSpacing/2),
            confirmBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPadding),
            confirmBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -btnBottom),
            confirmBtn.heightAnchor.constraint(equalToConstant: btnH)
        ])
    }

    @objc private func dismissChannelKeyPopup() {
        view.endEditing(true)
        channelKeyOverlay?.removeFromSuperview()
        channelKeyOverlay = nil
    }

    @objc private func channelKeyConfirmTapped() {
        view.endEditing(true)
        channelKeyOverlay?.removeFromSuperview()
        channelKeyOverlay = nil
    }

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = cardBg
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        v.layer.shadowOpacity = 0.08
        return v
    }
}
