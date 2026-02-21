//
//  TradeViewController.swift
//  zhengqaun
//

import UIKit

/// 交易页：红卡(持仓市值)+资产区+10宫格+理财2x2+功能列表，间距紧凑(10)
class TradeViewController: ZQViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let sectionSpacing: CGFloat = 10

    /// 功能列表项
    private let menuItems: [(icon: String, title: String)] = [
        ("up_trade_main_pt_phdjjy", "科创板"),
        ("up_trade_main_pt_cnjj", "龙虎榜"),
        ("up_trade_main_pt_tjd", "消息通知"),
        ("up_trade_main_pt_xgmm", "修改交易密码"),
        ("up_trade_main_pt_wltp", "银行卡管理"),
        ("up_trade_main_pt_lcjy", "银证转出"),
        ("up_trade_main_pt_gzxsb", "更多功能")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let header = tableView.tableHeaderView, tableView.bounds.width > 0 && header.frame.width != tableView.bounds.width {
            var f = header.frame
            f.size.width = tableView.bounds.width
            header.frame = f
            tableView.tableHeaderView = header
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
        setupNavigationBar()
        setupTableView()
    }

    private func setupNavigationBar() {
        gk_navTitle = "交易"
        gk_navBackgroundColor = .white
        gk_navTintColor = .black
        gk_navTitleColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 15)
        gk_statusBarStyle = .default
        gk_navLineHidden = true
        gk_navItemRightSpace = 12
        let refreshImg = UIImage(named: "refresh-icon") ?? UIImage(systemName: "arrow.clockwise")
        let refreshWrap = UIButton(type: .system)
        refreshWrap.tintColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        refreshWrap.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        let iconSize: CGFloat = 22
        let iv = UIImageView(image: refreshImg)
        iv.contentMode = .scaleAspectFit
        iv.tintColor = refreshWrap.tintColor
        refreshWrap.addSubview(iv)
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            refreshWrap.widthAnchor.constraint(equalToConstant: 44),
            refreshWrap.heightAnchor.constraint(equalToConstant: 44),
            iv.centerXAnchor.constraint(equalTo: refreshWrap.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: refreshWrap.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: iconSize),
            iv.heightAnchor.constraint(equalToConstant: iconSize)
        ])
        gk_navRightBarButtonItem = UIBarButtonItem(customView: refreshWrap)
    }

    @objc private func refreshTapped() {
        // 刷新持仓/资产数据
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(TradeMenuCell.self, forCellReuseIdentifier: "TradeMenuCell")
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        tableView.contentInset = .zero
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let header = buildHeaderView()
        tableView.tableHeaderView = header

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func buildHeaderView() -> UIView {
        let wrap = UIView()
        wrap.backgroundColor = .clear

        let redCard = buildRedCard()
        let assetRow = buildAssetRow()
        let grid = buildQuickActionsGrid()
        let products = buildFinancialProducts()

        wrap.addSubview(redCard)
        wrap.addSubview(assetRow)
        wrap.addSubview(grid)
        wrap.addSubview(products)
        redCard.translatesAutoresizingMaskIntoConstraints = false
        assetRow.translatesAutoresizingMaskIntoConstraints = false
        grid.translatesAutoresizingMaskIntoConstraints = false
        products.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            redCard.topAnchor.constraint(equalTo: wrap.topAnchor,constant: 20),
            redCard.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 16),
            redCard.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -16),
            redCard.heightAnchor.constraint(equalToConstant: 118),

            assetRow.topAnchor.constraint(equalTo: redCard.bottomAnchor, constant: sectionSpacing),
            assetRow.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            assetRow.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            assetRow.heightAnchor.constraint(equalToConstant: 88),

            grid.topAnchor.constraint(equalTo: assetRow.bottomAnchor, constant: sectionSpacing),
            grid.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            grid.heightAnchor.constraint(equalToConstant: 168),

            products.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: sectionSpacing),
            products.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            products.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            products.heightAnchor.constraint(equalToConstant: 204),
            products.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -sectionSpacing)
        ])

        let w = UIScreen.main.bounds.width
        wrap.frame = CGRect(x: 0, y: 0, width: w, height: 118 + sectionSpacing + 88 + sectionSpacing + 168 + sectionSpacing + 204 + sectionSpacing)
        return wrap
    }

    private func buildRedCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.9, green: 0.22, blue: 0.22, alpha: 1.0)
        card.layer.cornerRadius = 12
        card.clipsToBounds = true

        let titleLabel = UILabel()
        titleLabel.text = "持仓市值 (元)"
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        card.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let eyeBtn = UIButton(type: .system)
        eyeBtn.setImage(UIImage(systemName: "eye"), for: .normal)
        eyeBtn.tintColor = .white
        card.addSubview(eyeBtn)
        eyeBtn.translatesAutoresizingMaskIntoConstraints = false

        let accountLabel = UILabel()
        accountLabel.text = "T007975614"
        accountLabel.font = UIFont.systemFont(ofSize: 15)
        accountLabel.textColor = .white
        card.addSubview(accountLabel)
        accountLabel.translatesAutoresizingMaskIntoConstraints = false

        let stackBtn = UIButton(type: .system)
        stackBtn.setImage(UIImage(named: "jy-icon"), for: .normal)
        stackBtn.tintColor = .white
        card.addSubview(stackBtn)
        stackBtn.translatesAutoresizingMaskIntoConstraints = false

        let amountLabel = UILabel()
        amountLabel.text = "0.00"
        amountLabel.font = UIFont.boldSystemFont(ofSize: 33)
        amountLabel.textColor = .white
        card.addSubview(amountLabel)
        amountLabel.textAlignment = .left
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        let todayLabel = UILabel()
        todayLabel.text = "今日盈亏+0.00"
        todayLabel.font = UIFont.systemFont(ofSize: 15)
        todayLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        card.addSubview(todayLabel)
        todayLabel.translatesAutoresizingMaskIntoConstraints = false

        let holdLabel = UILabel()
        holdLabel.text = "持仓盈亏+0.00"
        holdLabel.font = UIFont.systemFont(ofSize: 15)
        holdLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        card.addSubview(holdLabel)
        holdLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            eyeBtn.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 4),
            eyeBtn.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            eyeBtn.widthAnchor.constraint(equalToConstant: 20),
            eyeBtn.heightAnchor.constraint(equalToConstant: 14),
            accountLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            accountLabel.trailingAnchor.constraint(equalTo: stackBtn.leadingAnchor, constant: -6),
            stackBtn.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            stackBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stackBtn.widthAnchor.constraint(equalToConstant: 20),
            stackBtn.heightAnchor.constraint(equalToConstant: 20),
            amountLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            amountLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: -4),
            todayLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            todayLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            holdLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            holdLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        return card
    }

    private func buildAssetRow() -> UIView {
        let row = UIView()
        row.backgroundColor = .white
        let arrowImg = UIImage(named: "up_common_more_arrow")

        let leftStack = UIStackView()
        leftStack.axis = .vertical
        leftStack.spacing = 16
        leftStack.alignment = .leading
        let accountTitle = UILabel()
        accountTitle.text = "账户资产 0.00"
        accountTitle.font = UIFont.systemFont(ofSize: 16)
        accountTitle.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        let availableTitle = UILabel()
        availableTitle.text = "可用资产 0.00"
        availableTitle.font = UIFont.systemFont(ofSize: 16)
        availableTitle.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        leftStack.addArrangedSubview(accountTitle)
        leftStack.addArrangedSubview(availableTitle)
        row.addSubview(leftStack)
        leftStack.translatesAutoresizingMaskIntoConstraints = false

        let rightStack = UIStackView()
        rightStack.axis = .vertical
        rightStack.spacing = 16
        rightStack.alignment = .trailing
        let fundRecordRow = makeAssetRightRow(text: "资金记录", arrow: arrowImg, tag: 0)
        let bankInRow = makeAssetRightRow(text: "银证转入", arrow: arrowImg, tag: 1)
        rightStack.addArrangedSubview(fundRecordRow)
        rightStack.addArrangedSubview(bankInRow)
        row.addSubview(rightStack)
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(assetRowTapped(_:)))
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(assetRowTapped(_:)))
        fundRecordRow.addGestureRecognizer(tap1)
        fundRecordRow.tag = 0
        bankInRow.addGestureRecognizer(tap2)
        bankInRow.tag = 1
        fundRecordRow.isUserInteractionEnabled = true
        bankInRow.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            leftStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            rightStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            rightStack.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    private func makeAssetRightRow(text: String, arrow: UIImage?, tag: Int) -> UIView {
        let wrap = UIView()
        wrap.tag = tag
        let lb = UILabel()
        lb.text = text
        lb.font = UIFont.systemFont(ofSize: 16)
        lb.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        let iv = UIImageView(image: arrow)
        iv.contentMode = .scaleAspectFit
        wrap.addSubview(lb)
        wrap.addSubview(iv)
        lb.translatesAutoresizingMaskIntoConstraints = false
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lb.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            lb.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
            lb.trailingAnchor.constraint(equalTo: iv.leadingAnchor, constant: -6),
            iv.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            iv.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 16),
            iv.heightAnchor.constraint(equalToConstant: 16),
            wrap.heightAnchor.constraint(equalToConstant: 24)
        ])
        return wrap
    }

    @objc private func assetRowTapped(_ g: UITapGestureRecognizer) {
        guard let wrap = g.view else { return }
        if wrap.tag == 0 {
            let vc = SecuritiesTransferRecordViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = BankSecuritiesTransferViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func buildQuickActionsGrid() -> UIView {
        let wrap = UIView()
        wrap.backgroundColor = .white
        let titlesRow1 = ["买入", "卖出", "撤单", "持仓", "查询"]
        let titlesRow2 = ["委托", "成交", "对账单", "银证转账", "更多"]
        let icons = ["jy-icon-1", "jy-icon-2", "jy-icon-5", "jy-icon-4", "jy-icon-3",
                    "jy-icon-6", "jy-icon-7", "jy-icon-8", "jy-icon-9", "jy-icon-10"]
        var row1Views: [UIView] = []
        var row2Views: [UIView] = []
        let row1Colors: [UIColor] = [
            UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0),
            UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0),
            UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
            UIColor(red: 0.55, green: 0.38, blue: 0.25, alpha: 1.0),
            UIColor(red: 0.85, green: 0.5, blue: 0.2, alpha: 1.0)
        ]
        let row2TextColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        for (i, t) in titlesRow1.enumerated() {
            row1Views.append(makeGridButton(title: t, iconName: icons[i], color: row1Colors[i], index: i, isRow1: true))
        }
        for (i, t) in titlesRow2.enumerated() {
            row2Views.append(makeGridButton(title: t, iconName: icons[i + 5], color: row2TextColor, index: i + 5, isRow1: false))
        }
        let row1 = UIStackView(arrangedSubviews: row1Views)
        row1.axis = .horizontal
        row1.distribution = .fillEqually
        row1.spacing = 0
        let row2 = UIStackView(arrangedSubviews: row2Views)
        row2.axis = .horizontal
        row2.distribution = .fillEqually
        row2.spacing = 0
        wrap.addSubview(row1)
        wrap.addSubview(row2)
        row1.translatesAutoresizingMaskIntoConstraints = false
        row2.translatesAutoresizingMaskIntoConstraints = false
        let rowHeight: CGFloat = 58
        let wrapTop: CGFloat = 18
        let rowGap: CGFloat = 18
        let wrapBottom: CGFloat = 18
        NSLayoutConstraint.activate([
            row1.topAnchor.constraint(equalTo: wrap.topAnchor, constant: wrapTop),
            row1.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            row1.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            row1.heightAnchor.constraint(equalToConstant: rowHeight),
            row2.topAnchor.constraint(equalTo: row1.bottomAnchor, constant: rowGap),
            row2.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            row2.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            row2.heightAnchor.constraint(equalToConstant: rowHeight)
        ])
        return wrap
    }

    private func makeGridButton(title: String, iconName: String, color: UIColor, index: Int, isRow1: Bool) -> UIView {
        let wrap = UIView()
        wrap.tag = index
        let iv = UIImageView(image: UIImage(named: iconName))
        iv.tintColor = isRow1 ? color : nil
        iv.contentMode = .scaleAspectFit
        let lb = UILabel()
        lb.text = title
        lb.font = UIFont.systemFont(ofSize: 16)
        lb.textColor = color
        lb.textAlignment = .center
        wrap.addSubview(iv)
        wrap.addSubview(lb)
        iv.translatesAutoresizingMaskIntoConstraints = false
        lb.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 8),
            iv.centerXAnchor.constraint(equalTo: wrap.centerXAnchor),
            iv.widthAnchor.constraint(equalToConstant: 26),
            iv.heightAnchor.constraint(equalToConstant: 26),
            lb.topAnchor.constraint(equalTo: iv.bottomAnchor, constant: 8),
            lb.centerXAnchor.constraint(equalTo: wrap.centerXAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(quickActionTapped(_:)))
        wrap.addGestureRecognizer(tap)
        wrap.isUserInteractionEnabled = true
        return wrap
    }

    @objc private func quickActionTapped(_ g: UITapGestureRecognizer) {
        guard let wrap = g.view else { return }
        let index = wrap.tag
        switch index {
        case 0: // 买入
            let vc = AccountTradeViewController()
            vc.tradeType = .buy
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 1: // 卖出
            let vc = AccountTradeViewController()
            vc.tradeType = .sell
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 2: // 撤单
            let vc = AccountTradeViewController()
            vc.tradeType = .buy
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 3: // 持仓
            let vc = MyHoldingsViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 4: // 查询
            let vc = StockSearchViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 5: // 委托
            let vc = AccountTradeViewController()
            vc.tradeType = .buy
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 6: // 成交
            let vc = AccountTradeViewController()
            vc.tradeType = .sell
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 7: // 对账单
            let vc = SecuritiesTransferRecordViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 8: // 银证转账
            let vc = BankSecuritiesTransferViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 9: // 更多
            let vc = SettingsViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }

    private func buildFinancialProducts() -> UIView {
        let wrap = UIView()
        wrap.backgroundColor = .white
        let container = UIView()
        container.backgroundColor = .clear
        wrap.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false

        let items: [(String, String, String, String)] = [
            ("up_trade_new_stk_apply_icon", "新股新债", "1新股, 0申购", "NEW"),
            ("up_trade_main_wdzh_icon", "场外撮合交易", "暂无股票", ""),
            ("up_trade_main_gznhg_icon", "国债逆回购", "年化利率 1.585%", ""),
            ("up_trade_main_zhbjhg_icon", "智汇现金理财", "年化利率6.88%", "")
        ]
        let cardW = (UIScreen.main.bounds.width - 16 * 2 - 12) / 2
        let cardH: CGFloat = 82
        let rowGap: CGFloat = 12
        let contentHeight = cardH * 2 + rowGap
        for (idx, it) in items.enumerated() {
            let card = makeProductCard(icon: it.0, title: it.1, subtitle: it.2, badge: it.3)
            card.tag = idx
            card.isUserInteractionEnabled = true
            card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(productCardTapped(_:))))
            container.addSubview(card)
            card.translatesAutoresizingMaskIntoConstraints = false
            let row = idx / 2
            let col = idx % 2
            NSLayoutConstraint.activate([
                card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: CGFloat(col) * (cardW + 12)),
                card.topAnchor.constraint(equalTo: container.topAnchor, constant: CGFloat(row) * (cardH + rowGap)),
                card.widthAnchor.constraint(equalToConstant: cardW),
                card.heightAnchor.constraint(equalToConstant: cardH)
            ])
        }
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -16),
            container.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: contentHeight)
        ])
        return wrap
    }

    @objc private func productCardTapped(_ g: UITapGestureRecognizer) {
        guard let card = g.view else { return }
        switch card.tag {
        case 0: // 新股新债
            let vc = NewStockSubscriptionViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 1: // 场外撮合交易
            let vc = BlockTradingListViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 2, 3: // 国债逆回购、智汇现金理财
            break
        default:
            break
        }
    }

    private func makeProductCard(icon: String, title: String, subtitle: String, badge: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
        card.layer.cornerRadius = 8
        let iv = UIImageView(image: UIImage(named: icon))
        iv.tintColor = nil
        iv.contentMode = .scaleAspectFit
        let titleL = UILabel()
        titleL.text = title
        titleL.font = UIFont.systemFont(ofSize: 16)
        titleL.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        let subL = UILabel()
        subL.text = subtitle
        subL.font = UIFont.systemFont(ofSize: 14)
        subL.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.52, alpha: 1.0)
        let textStack = UIStackView(arrangedSubviews: [titleL, subL])
        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.alignment = .leading
        card.addSubview(iv)
        card.addSubview(textStack)
        iv.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = [
            iv.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iv.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 30),
            iv.heightAnchor.constraint(equalToConstant: 30),
            textStack.leadingAnchor.constraint(equalTo: iv.trailingAnchor, constant: 10),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -10)
        ]
        if !badge.isEmpty {
            let badgeL = UILabel()
            badgeL.text = badge
            badgeL.font = UIFont.boldSystemFont(ofSize: 8)
            badgeL.textColor = .white
            badgeL.backgroundColor = UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1.0)
            badgeL.layer.cornerRadius = 3
            badgeL.clipsToBounds = true
            badgeL.textAlignment = .center
            card.addSubview(badgeL)
            badgeL.translatesAutoresizingMaskIntoConstraints = false
            constraints += [
                badgeL.leadingAnchor.constraint(equalTo: titleL.trailingAnchor, constant: 6),
                badgeL.centerYAnchor.constraint(equalTo: titleL.centerYAnchor),
                badgeL.widthAnchor.constraint(equalToConstant: 26),
                badgeL.heightAnchor.constraint(equalToConstant: 15)
            ]
        }
        NSLayoutConstraint.activate(constraints)
        return card
    }
}

// MARK: - UITableViewDataSource
extension TradeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TradeMenuCell", for: indexPath) as! TradeMenuCell
        let item = menuItems[indexPath.row]
        cell.configure(icon: item.icon, title: item.title)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TradeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let title = menuItems[indexPath.row].title
        var vc: UIViewController?
        switch title {
        case "科创板":
            vc = AccountTradeViewController()
            (vc as? AccountTradeViewController)?.tradeType = .buy
        case "龙虎榜":
            vc = NewsDetailViewController()
        case "消息通知":
            vc = MessageCenterViewController()
        case "修改交易密码":
            vc = TransactionPasswordViewController()
        case "银行卡管理":
            vc = BankCardViewController()
        case "银证转出":
            vc = BankSecuritiesTransferViewController()
        case "更多功能":
            vc = SettingsViewController()
        default:
            break
        }
        if let vc = vc {
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - TradeMenuCell（图标 + 标题 + 箭头）
class TradeMenuCell: UITableViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let arrow = UIImageView(image: UIImage(named: "up_common_more_arrow"))
    private let line = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(arrow)
        contentView.addSubview(line)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        arrow.translatesAutoresizingMaskIntoConstraints = false
        line.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = nil
        iconView.contentMode = .scaleAspectFit
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        arrow.tintColor = nil
        arrow.contentMode = .scaleAspectFit
        line.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrow.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 18),
            arrow.heightAnchor.constraint(equalToConstant: 18),
            line.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            line.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1/UIScreen.main.scale)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(icon: String, title: String) {
        iconView.image = UIImage(named: icon)
        titleLabel.text = title
    }
}
