//
//  StockTradeViewController.swift
//  zhengqaun
//
//  股票买入页 — 参考 Android BuyActivity 逻辑实现
//  布局：代码行 → 盘中行 → 分隔 → 现价行 → 数量行（手数 ±1）→ 现金仓位 →
//        金额标签 → 大金额显示 → 有效期（当日有效）→ 五档盘口（左卖右买）→
//        市值/手续费/可用额度/可购买股数
//  底部固定：买入金额 + 买入按钮（点击弹出确认弹窗后提交）
//  5 秒轮询东方财富行情 + 五档数据
//

import UIKit
import SafariServices

class StockTradeViewController: ZQViewController {

    // MARK: - 入参（由上级 VC 赋值）
    var stockName:     String = ""
    var stockCode:     String = ""
    var stockAllcode:  String = ""       // 完整 allcode，如 sh688498 / sz300170
    var exchange:      String = ""       // 北/沪/深/科
    var currentPrice:  Double = 0
    var changeAmount:  Double = 0
    var changePercent: Double = 0

    // MARK: - 颜色（与 Android activity_buy.xml 对齐）
    private let themeRed   = UIColor(red: 0xE0/255, green: 0x42/255, blue: 0x30/255, alpha: 1) // #E04230
    private let themeGreen = UIColor(red: 0x2C/255, green: 0xC7/255, blue: 0x84/255, alpha: 1) // #2CC784
    private let tagBlue    = UIColor(red: 0x4A/255, green: 0x90/255, blue: 0xD9/255, alpha: 1) // #4A90D9
    private let textPri    = UIColor(red: 0x23/255, green: 0x23/255, blue: 0x23/255, alpha: 1) // #232323
    private let textSec    = UIColor(red: 0xA5/255, green: 0xA5/255, blue: 0xA5/255, alpha: 1) // #A5A5A5
    private let bgGray     = UIColor(red: 0xF5/255, green: 0xF5/255, blue: 0xF5/255, alpha: 1) // #F5F5F5
    private let btnGray    = UIColor(red: 0xEE/255, green: 0xEE/255, blue: 0xEE/255, alpha: 1) // #EEEEEE
    private let sepColor   = UIColor(red: 0xEE/255, green: 0xEE/255, blue: 0xEE/255, alpha: 1)

    // MARK: - 常量
    private static let FEE_RATE: Double = 0.0001   // 0.01 %
    private static let POLL_INTERVAL: TimeInterval = 5.0

    // MARK: - UI
    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    // 盘中行（需要轮询刷新）
    private var priceHeaderLabel: UILabel!
    private var currentPriceLabel: UILabel!
    private var stockNameLabel: UILabel!

    // 数量（单位：手，1 手 = 100 股）
    private var quantityField: UITextField!
    private var quantity: Int = 0
    private var ignoreQuantityChange = false

    // 仓位按钮
    private var positionButtons: [UIButton] = []

    // 金额显示
    private var amountLabel: UILabel!

    // 五档盘口 — 各档 vol / price 标签
    private struct OrderLevel { var vol: String; var price: String }
    private var askVolLabels:   [UILabel] = []    // 卖5→卖1 (index 0=卖5, 4=卖1)
    private var askPriceLabels: [UILabel] = []
    private var bidVolLabels:   [UILabel] = []    // 买1→买5 (index 0=买1, 4=买5)
    private var bidPriceLabels: [UILabel] = []

    // 底部信息标签
    private var marketValueLabel:   UILabel!
    private var serviceFeeLabel:    UILabel!
    private var availableLabel:     UILabel!
    private var canBuySharesLabel:  UILabel!

    // 底部栏
    private var buyAmountLabel:      UILabel!
    private var accountBalanceLabel: UILabel!
    private var buyButton:           UIButton!

    // 数据
    private var userBalance: Double = 0
    private var polling = false
    private var pollTimer: Timer?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavBar()
        setupScrollView()
        setupBottomBar()
        loadInitialData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPolling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPolling()
    }

    // MARK: - 导航栏
    private func setupNavBar() {
        gk_navTitle            = "交易"
        gk_navBackgroundColor  = .white
        gk_navTintColor        = textPri
        gk_navTitleColor       = textPri
        gk_navTitleFont        = .boldSystemFont(ofSize: 17)
        gk_navLineHidden       = false
        gk_statusBarStyle      = .default
        gk_backStyle = .black

        let kfBtn  = makeNavIconButton(systemName: "headphones",      action: #selector(kfTapped))
        let schBtn = makeNavIconButton(systemName: "magnifyingglass", action: #selector(searchTapped))
        let stack  = UIStackView(arrangedSubviews: [kfBtn, schBtn])
        stack.spacing = 4
        gk_navRightBarButtonItem = UIBarButtonItem(customView: stack)
    }

    private func makeNavIconButton(systemName: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.tintColor = textPri
        btn.setImage(UIImage(systemName: systemName), for: .normal)
        btn.addTarget(self, action: action, for: .touchUpInside)
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: 36),
            btn.heightAnchor.constraint(equalToConstant: 36)
        ])
        return btn
    }

    @objc private func kfTapped() {
        SecureNetworkManager.shared.request(
            api: "/api/stock/getconfig",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      var kfUrl = data["kf_url"] as? String,
                      !kfUrl.isEmpty else {
                    DispatchQueue.main.async { Toast.show("获取客服地址失败") }
                    return
                }
                if !kfUrl.hasPrefix("http") { kfUrl = "https://" + kfUrl }
                guard let url = URL(string: kfUrl) else { return }
                DispatchQueue.main.async {
                    let vc = SFSafariViewController(url: url)
                    self.present(vc, animated: true)
                }
            case .failure(_):
                DispatchQueue.main.async { Toast.show("获取客服地址失败") }
            }
        }
    }
    @objc private func searchTapped() {
        let vc = StockSearchViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - ScrollView
    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = bgGray
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor,
                                            constant: Constants.Navigation.contentTopBelowGKNavBar),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomBarHeight),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        buildContent()
    }

    private var bottomBarHeight: CGFloat {
        return 72 + Constants.Navigation.safeAreaBottom
    }

    // MARK: - 内容区构建
    private func buildContent() {
        var last: UIView? = nil

        // 白色卡片容器（代码 → 有效期）
        let card = UIView()
        card.backgroundColor = .white
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        var cardLast: UIView? = nil

        // 1 — 代码行
        cardLast = addCodeRow(in: card, after: cardLast)
        // 2 — 盘中行
        cardLast = addMarketStatusRow(in: card, after: cardLast)
        // 3 — 分隔线
        cardLast = addSepLineRow(in: card, after: cardLast)
        // 4 — 现价行
        cardLast = addPriceRow(in: card, after: cardLast)
        // 5 — 数量行
        cardLast = addQuantityRow(in: card, after: cardLast)
        // 6 — 现金仓位
        cardLast = addPositionRow(in: card, after: cardLast)
        // 7 — 金额标签行
        cardLast = addAmountLabelRow(in: card, after: cardLast)
        // 8 — 金额大字
        cardLast = addAmountDisplay(in: card, after: cardLast)
        // 9 — 有效期
        cardLast = addValidityRow(in: card, after: cardLast)

        // 卡片底部约束
        card.bottomAnchor.constraint(equalTo: cardLast!.bottomAnchor).isActive = true
        last = card

        // 8dp 间距
        last = addSep(after: last)

        // 五档盘口（已隐藏）
        // last = addOrderBoard(after: last)

        // 8dp 间距
        // last = addSep(after: last)

        // 底部信息卡片
        let infoCard = UIView()
        infoCard.backgroundColor = .white
        contentView.addSubview(infoCard)
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoCard.topAnchor.constraint(equalTo: last!.bottomAnchor),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        var infoLast: UIView? = nil
        infoLast = addInfoRow(title: "市值", in: infoCard, after: infoLast) { [weak self] lbl in
            lbl.text = "--"
            self?.marketValueLabel = lbl
        }
        infoLast = addInfoRow(title: "手续费（0.01%）", in: infoCard, after: infoLast) { [weak self] lbl in
            lbl.text = "--"
            self?.serviceFeeLabel = lbl
        }
        infoLast = addInfoRow(title: "可用额度", in: infoCard, after: infoLast) { [weak self] lbl in
            lbl.text = "--"
            self?.availableLabel = lbl
        }
        infoLast = addInfoRow(title: "可购买股数", in: infoCard, after: infoLast, showSep: false) { [weak self] lbl in
            lbl.text = "--"
            self?.canBuySharesLabel = lbl
        }

        infoCard.bottomAnchor.constraint(equalTo: infoLast!.bottomAnchor).isActive = true

        // 底部留白
        let pad = UIView()
        contentView.addSubview(pad)
        pad.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pad.topAnchor.constraint(equalTo: infoCard.bottomAnchor),
            pad.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pad.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pad.heightAnchor.constraint(equalToConstant: 20),
            pad.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - 行构建辅助

    /// 代码行：代码 | [北] 源杰科技 688498
    private func addCodeRow(in container: UIView, after prev: UIView?) -> UIView {
        let row = makeRow(height: 40, in: container, after: prev, padH: 16)

        let titleLbl = makeLabel("代码", font: .systemFont(ofSize: 13), color: textSec)
        let badgeLbl = makeBadge(exchange.isEmpty ? stockAllcode.prefix(2).uppercased() : exchange)
        let nameLbl  = makeLabel("--", font: .systemFont(ofSize: 15, weight: .medium), color: textPri)
        stockNameLabel = nameLbl
        if !stockName.isEmpty { nameLbl.text = stockName }

        let rightStack = UIStackView(arrangedSubviews: [badgeLbl, nameLbl])
        rightStack.spacing = 4; rightStack.alignment = .center

        row.addSubview(titleLbl)
        row.addSubview(rightStack)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            rightStack.leadingAnchor.constraint(equalTo: titleLbl.trailingAnchor, constant: 8),
            rightStack.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    /// 盘中行
    private func addMarketStatusRow(in container: UIView, after prev: UIView?) -> UIView {
        let row = makeRow(height: 30, in: container, after: prev, padH: 16)

        let statusLbl = makeLabel("盘中", font: .systemFont(ofSize: 13), color: textSec)
        let priceLbl  = makeLabel("--", font: .systemFont(ofSize: 15), color: themeRed)
        priceHeaderLabel = priceLbl

        row.addSubview(statusLbl)
        row.addSubview(priceLbl)
        statusLbl.translatesAutoresizingMaskIntoConstraints = false
        priceLbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            statusLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            priceLbl.leadingAnchor.constraint(equalTo: statusLbl.trailingAnchor, constant: 12),
            priceLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        if currentPrice > 0 { renderHeader() }
        return row
    }

    /// 现价行
    private func addPriceRow(in container: UIView, after prev: UIView?) -> UIView {
        let row = makeRow(height: 48, in: container, after: prev, padH: 16)
        let titleLbl = makeLabel("现价", font: .systemFont(ofSize: 14), color: textSec)
        let valLbl   = makeLabel(currentPrice > 0 ? formatPrice(currentPrice) : "--",
                                  font: .systemFont(ofSize: 15), color: textPri)
        currentPriceLabel = valLbl
        titleLbl.setContentHuggingPriority(.required, for: .horizontal)

        row.addSubview(titleLbl)
        row.addSubview(valLbl)
        [titleLbl, valLbl].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            titleLbl.widthAnchor.constraint(equalToConstant: 64),
            valLbl.leadingAnchor.constraint(equalTo: titleLbl.trailingAnchor),
            valLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        addSepLine(to: row, inset: 0)
        return row
    }

    /// 数量行（手数 stepper）
    private func addQuantityRow(in container: UIView, after prev: UIView?) -> UIView {
        let row = makeRow(height: 56, in: container, after: prev, padH: 16)

        let titleLbl = makeLabel("数量（手）", font: .systemFont(ofSize: 14), color: textSec)
        titleLbl.setContentHuggingPriority(.required, for: .horizontal)

        let minusBtn = makeStepButton(title: "−")
        minusBtn.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)

        let field = UITextField()
        field.keyboardType   = .numberPad
        field.textAlignment  = .center
        field.font           = .boldSystemFont(ofSize: 16)
        field.textColor      = textPri
        field.borderStyle    = .none
        field.text           = "0"
        field.addTarget(self, action: #selector(quantityChanged), for: .editingChanged)
        quantityField = field

        let plusBtn = makeStepButton(title: "+")
        plusBtn.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)

        // stepper 容器
        let stepWrap = UIView()
        stepWrap.layer.cornerRadius = 4
        stepWrap.layer.borderWidth  = 1
        stepWrap.layer.borderColor  = sepColor.cgColor
        [minusBtn, field, plusBtn].forEach {
            stepWrap.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            minusBtn.leadingAnchor.constraint(equalTo: stepWrap.leadingAnchor),
            minusBtn.topAnchor.constraint(equalTo: stepWrap.topAnchor),
            minusBtn.bottomAnchor.constraint(equalTo: stepWrap.bottomAnchor),
            minusBtn.widthAnchor.constraint(equalToConstant: 36),

            plusBtn.trailingAnchor.constraint(equalTo: stepWrap.trailingAnchor),
            plusBtn.topAnchor.constraint(equalTo: stepWrap.topAnchor),
            plusBtn.bottomAnchor.constraint(equalTo: stepWrap.bottomAnchor),
            plusBtn.widthAnchor.constraint(equalToConstant: 36),

            field.leadingAnchor.constraint(equalTo: minusBtn.trailingAnchor),
            field.trailingAnchor.constraint(equalTo: plusBtn.leadingAnchor),
            field.topAnchor.constraint(equalTo: stepWrap.topAnchor),
            field.bottomAnchor.constraint(equalTo: stepWrap.bottomAnchor)
        ])

        row.addSubview(titleLbl)
        row.addSubview(stepWrap)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        stepWrap.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            titleLbl.widthAnchor.constraint(equalToConstant: 64),
            stepWrap.leadingAnchor.constraint(equalTo: titleLbl.trailingAnchor),
            stepWrap.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            stepWrap.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            stepWrap.heightAnchor.constraint(equalToConstant: 36)
        ])
        addSepLine(to: row, inset: 0)
        return row
    }

    /// 现金仓位行
    private func addPositionRow(in container: UIView, after prev: UIView?) -> UIView {
        let row = makeRow(height: 48, in: container, after: prev, padH: 16)

        let titleLbl = makeLabel("现金", font: .systemFont(ofSize: 14), color: textSec)
        titleLbl.setContentHuggingPriority(.required, for: .horizontal)
        row.addSubview(titleLbl)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            titleLbl.widthAnchor.constraint(equalToConstant: 64)
        ])

        let labels = ["1/4", "1/3", "1/2", "全仓"]
        let btnStack = UIStackView()
        btnStack.axis = .horizontal
        btnStack.spacing = 6
        btnStack.distribution = .fillEqually

        positionButtons = []
        for (i, t) in labels.enumerated() {
            let btn = UIButton(type: .custom)
            btn.setTitle(t, for: .normal)
            btn.setTitleColor(textPri, for: .normal)
            btn.titleLabel?.font = .boldSystemFont(ofSize: 12)
            btn.backgroundColor  = btnGray
            btn.layer.cornerRadius = 4
            btn.tag = i
            btn.addTarget(self, action: #selector(positionTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.heightAnchor.constraint(equalToConstant: 30).isActive = true
            btnStack.addArrangedSubview(btn)
            positionButtons.append(btn)
        }

        row.addSubview(btnStack)
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btnStack.leadingAnchor.constraint(equalTo: titleLbl.trailingAnchor),
            btnStack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            btnStack.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        addSepLine(to: row, inset: 0)
        return row
    }

    /// 金额标签行
    private func addAmountLabelRow(in container: UIView, after prev: UIView?) -> UIView {
        let row = makeRow(height: 48, in: container, after: prev, padH: 16)
        let lbl = makeLabel("金额", font: .systemFont(ofSize: 14), color: textSec)
        row.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            lbl.widthAnchor.constraint(equalToConstant: 64)
        ])
        return row
    }

    /// 大金额显示
    private func addAmountDisplay(in container: UIView, after prev: UIView?) -> UIView {
        let row = makeRow(height: 48, in: container, after: prev, padH: 16)
        let lbl = UILabel()
        lbl.text = "￥0.00"
        lbl.font = .boldSystemFont(ofSize: 28)
        lbl.textColor = textPri
        lbl.textAlignment = .center
        row.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lbl.centerXAnchor.constraint(equalTo: row.centerXAnchor),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        amountLabel = lbl
        addSepLine(to: row, inset: 0)
        return row
    }

    /// 有效期行（当日有效）
    private func addValidityRow(in container: UIView, after prev: UIView?) -> UIView {
        let row = makeRow(height: 48, in: container, after: prev, padH: 16)
        let titleLbl = makeLabel("有效期", font: .systemFont(ofSize: 14), color: textSec)
        let valLbl   = makeLabel("当日有效", font: .systemFont(ofSize: 14), color: textPri)
        row.addSubview(titleLbl)
        row.addSubview(valLbl)
        [titleLbl, valLbl].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            titleLbl.widthAnchor.constraint(equalToConstant: 64),
            valLbl.leadingAnchor.constraint(equalTo: titleLbl.trailingAnchor),
            valLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    // MARK: - 五档盘口（Android 横向布局：左卖 | 中轴 | 右买）
    private func addOrderBoard(after prev: UIView?) -> UIView {
        let rowH: CGFloat  = 28
        let boardH: CGFloat = rowH * 5 + 16   // 5行 + 上下 padding 各 8

        let board = UIView()
        board.backgroundColor = .white
        contentView.addSubview(board)
        board.translatesAutoresizingMaskIntoConstraints = false
        let prevAnchor = prev?.bottomAnchor ?? contentView.topAnchor
        NSLayoutConstraint.activate([
            board.topAnchor.constraint(equalTo: prevAnchor),
            board.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            board.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            board.heightAnchor.constraint(equalToConstant: boardH)
        ])

        // 左半（卖盘）
        let sellStack = UIStackView()
        sellStack.axis = .vertical; sellStack.distribution = .fillEqually
        board.addSubview(sellStack)
        sellStack.translatesAutoresizingMaskIntoConstraints = false

        // 中轴
        let centerCol = UIView()
        board.addSubview(centerCol)
        centerCol.translatesAutoresizingMaskIntoConstraints = false

        // 右半（买盘）
        let buyStack = UIStackView()
        buyStack.axis = .vertical; buyStack.distribution = .fillEqually
        board.addSubview(buyStack)
        buyStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            sellStack.topAnchor.constraint(equalTo: board.topAnchor, constant: 8),
            sellStack.bottomAnchor.constraint(equalTo: board.bottomAnchor, constant: -8),
            sellStack.leadingAnchor.constraint(equalTo: board.leadingAnchor, constant: 12),

            centerCol.topAnchor.constraint(equalTo: board.topAnchor, constant: 8),
            centerCol.bottomAnchor.constraint(equalTo: board.bottomAnchor, constant: -8),
            centerCol.centerXAnchor.constraint(equalTo: board.centerXAnchor),
            centerCol.widthAnchor.constraint(equalToConstant: 28),
            centerCol.leadingAnchor.constraint(equalTo: sellStack.trailingAnchor),

            buyStack.topAnchor.constraint(equalTo: board.topAnchor, constant: 8),
            buyStack.bottomAnchor.constraint(equalTo: board.bottomAnchor, constant: -8),
            buyStack.leadingAnchor.constraint(equalTo: centerCol.trailingAnchor),
            buyStack.trailingAnchor.constraint(equalTo: board.trailingAnchor, constant: -12)
        ])

        // 中轴内容：买 label + red bar + green bar + 卖 label
        let buyTagLbl  = makeLabel("买", font: .systemFont(ofSize: 10), color: themeRed)
        buyTagLbl.textAlignment = .center
        let sellTagLbl = makeLabel("卖", font: .systemFont(ofSize: 10), color: themeGreen)
        sellTagLbl.textAlignment = .center
        let redBar  = UIView(); redBar.backgroundColor = themeRed
        let grnBar  = UIView(); grnBar.backgroundColor = themeGreen

        let centerStack = UIStackView(arrangedSubviews: [buyTagLbl, redBar, grnBar, sellTagLbl])
        centerStack.axis = .vertical
        centerStack.alignment = .center
        centerCol.addSubview(centerStack)
        centerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerStack.topAnchor.constraint(equalTo: centerCol.topAnchor),
            centerStack.bottomAnchor.constraint(equalTo: centerCol.bottomAnchor),
            centerStack.centerXAnchor.constraint(equalTo: centerCol.centerXAnchor),
            centerStack.widthAnchor.constraint(equalTo: centerCol.widthAnchor),
            buyTagLbl.heightAnchor.constraint(equalTo: centerStack.heightAnchor, multiplier: 0.15),
            sellTagLbl.heightAnchor.constraint(equalTo: centerStack.heightAnchor, multiplier: 0.15),
            redBar.widthAnchor.constraint(equalToConstant: 2),
            grnBar.widthAnchor.constraint(equalToConstant: 2),
            redBar.heightAnchor.constraint(equalTo: centerStack.heightAnchor, multiplier: 0.35),
            grnBar.heightAnchor.constraint(equalTo: centerStack.heightAnchor, multiplier: 0.35)
        ])

        askVolLabels   = []
        askPriceLabels = []
        bidVolLabels   = []
        bidPriceLabels = []

        // 卖盘行（卖5→卖1）
        let sellTitles = ["卖5", "卖4", "卖3", "卖2", "卖1"]
        for title in sellTitles {
            let (rowView, volLbl, priceLbl) = buildOrderBoardRow(levelTitle: title, accentColor: themeRed)
            sellStack.addArrangedSubview(rowView)
            askVolLabels.append(volLbl)
            askPriceLabels.append(priceLbl)
        }

        // 买盘行（买1→买5）
        let buyTitles = ["买1", "买2", "买3", "买4", "买5"]
        for title in buyTitles {
            let (rowView, volLbl, priceLbl) = buildOrderBoardRow(levelTitle: title, accentColor: themeRed)
            buyStack.addArrangedSubview(rowView)
            bidVolLabels.append(volLbl)
            bidPriceLabels.append(priceLbl)
        }

        return board
    }

    private func buildOrderBoardRow(levelTitle: String, accentColor: UIColor) -> (UIView, UILabel, UILabel) {
        let row = UIView()
        let levelLbl = makeLabel(levelTitle, font: .systemFont(ofSize: 12), color: textSec)
        let volLbl   = makeLabel("--", font: .systemFont(ofSize: 12), color: accentColor)
        volLbl.textAlignment = .center
        let priceLbl = makeLabel("--", font: .systemFont(ofSize: 12), color: textPri)
        priceLbl.textAlignment = .right

        [levelLbl, volLbl, priceLbl].forEach {
            row.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            levelLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            levelLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            levelLbl.widthAnchor.constraint(equalToConstant: 28),
            volLbl.leadingAnchor.constraint(equalTo: levelLbl.trailingAnchor),
            volLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            priceLbl.leadingAnchor.constraint(equalTo: volLbl.trailingAnchor),
            priceLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            priceLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            volLbl.widthAnchor.constraint(equalTo: priceLbl.widthAnchor)
        ])
        return (row, volLbl, priceLbl)
    }

    /// 刷新五档盘口
    private func refreshOrderBook(asks: [(price: Double, vol: Int)], bids: [(price: Double, vol: Int)]) {
        // 盘口隐藏时 label 数组为空，直接跳过
        guard askVolLabels.count == 5, bidVolLabels.count == 5 else { return }
        // asks[0]=卖1 ... asks[4]=卖5，UI 卖5(index0) → 卖1(index4)
        for i in 0..<5 {
            let askIdx = 4 - i  // UI row i shows ask level (4-i)
            let ask = asks.count > askIdx ? asks[askIdx] : nil
            askVolLabels[i].text   = ask != nil && ask!.vol > 0 ? "\(ask!.vol)" : "--"
            askPriceLabels[i].text = ask != nil && ask!.price > 0 ? formatPrice(ask!.price) : "--"
        }
        for i in 0..<5 {
            let bid = bids.count > i ? bids[i] : nil
            bidVolLabels[i].text   = bid != nil && bid!.vol > 0 ? "\(bid!.vol)" : "--"
            bidPriceLabels[i].text = bid != nil && bid!.price > 0 ? formatPrice(bid!.price) : "--"
        }
    }

    // MARK: - 通用信息行
    @discardableResult
    private func addInfoRow(title: String, in container: UIView, after prev: UIView?,
                            showSep: Bool = true,
                            configure: ((UILabel) -> Void)? = nil) -> UIView {
        let row = makeRow(height: 44, in: container, after: prev, padH: 16)
        let titleLbl = makeLabel(title, font: .systemFont(ofSize: 13), color: textSec)
        let valLbl   = makeLabel("--",  font: .systemFont(ofSize: 14), color: textPri)
        valLbl.textAlignment = .right
        configure?(valLbl)

        row.addSubview(titleLbl)
        row.addSubview(valLbl)
        [titleLbl, valLbl].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            valLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valLbl.leadingAnchor.constraint(greaterThanOrEqualTo: titleLbl.trailingAnchor, constant: 8)
        ])
        if showSep { addSepLine(to: row, inset: 0) }
        return row
    }

    // MARK: - 底部固定栏
    private func setupBottomBar() {
        let bar = UIView()
        bar.backgroundColor = .white
        bar.layer.shadowColor   = UIColor.black.withAlphaComponent(0.08).cgColor
        bar.layer.shadowOffset  = CGSize(width: 0, height: -1)
        bar.layer.shadowRadius  = 4
        bar.layer.shadowOpacity = 1
        view.addSubview(bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bar.heightAnchor.constraint(equalToConstant: bottomBarHeight)
        ])

        // 左侧
        let buyAmtTitle = makeLabel("买入金额  ", font: .systemFont(ofSize: 14), color: textPri)
        let buyAmtVal   = makeLabel("0.00", font: .boldSystemFont(ofSize: 15), color: themeRed)
        buyAmountLabel  = buyAmtVal

        let titleRow = UIStackView(arrangedSubviews: [buyAmtTitle, buyAmtVal])
        titleRow.spacing = 0; titleRow.alignment = .center

        let balanceLbl = makeLabel("(账户余额加载中...)", font: .systemFont(ofSize: 11), color: textSec)
        accountBalanceLabel = balanceLbl

        let leftStack = UIStackView(arrangedSubviews: [titleRow, balanceLbl])
        leftStack.axis = .vertical; leftStack.spacing = 2; leftStack.alignment = .leading

        bar.addSubview(leftStack)
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 16),
            leftStack.centerYAnchor.constraint(equalTo: bar.topAnchor, constant: 36)
        ])

        // 右侧买入按钮
        let buyBtn = UIButton(type: .custom)
        buyBtn.setTitle("↑ 买入", for: .normal)
        buyBtn.titleLabel?.font = .boldSystemFont(ofSize: 15)
        buyBtn.backgroundColor  = themeRed
        buyBtn.setTitleColor(.white, for: .normal)
        buyBtn.layer.cornerRadius = 8
        buyBtn.addTarget(self, action: #selector(buyTapped), for: .touchUpInside)
        bar.addSubview(buyBtn)
        buyBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buyBtn.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -16),
            buyBtn.centerYAnchor.constraint(equalTo: bar.topAnchor, constant: 36),
            buyBtn.widthAnchor.constraint(equalToConstant: 120),
            buyBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
        buyButton = buyBtn
    }

    // MARK: - 数量 / 仓位 Actions（手数单位）

    @objc private func minusTapped() {
        if quantity > 0 { quantity -= 1 }
        syncQuantityField()
        recalculate()
    }

    @objc private func plusTapped() {
        quantity += 1
        syncQuantityField()
        recalculate()
    }

    @objc private func quantityChanged() {
        if ignoreQuantityChange { return }
        let raw = Int(quantityField.text ?? "0") ?? 0
        quantity = max(raw, 0)
        recalculate()
    }

    private func syncQuantityField() {
        ignoreQuantityChange = true
        quantityField.text = "\(quantity)"
        ignoreQuantityChange = false
    }

    @objc private func positionTapped(_ sender: UIButton) {
        applyRatio(ratioForIndex(sender.tag))
    }

    private func ratioForIndex(_ idx: Int) -> Double {
        switch idx {
        case 0: return 0.25
        case 1: return 1.0 / 3.0
        case 2: return 0.5
        case 3: return 1.0
        default: return 0
        }
    }

    private func applyRatio(_ ratio: Double) {
        guard currentPrice > 0 && userBalance > 0 else { return }
        let shares = Int(floor(userBalance * ratio / currentPrice / 100)) * 100
        quantity = shares / 100   // 转手数
        syncQuantityField()
        recalculate()
    }

    // MARK: - 计算（与 Android recalculate 对齐）
    private func recalculate() {
        let shares = quantity * 100
        let price  = currentPrice > 0 ? currentPrice : 0
        let amount = Double(shares) * price
        let fee    = amount * Self.FEE_RATE

        amountLabel?.text      = "￥\(formatMoney(amount))"
        buyAmountLabel?.text   = formatMoney(amount)
        serviceFeeLabel?.text  = "￥\(formatMoney(fee))"
        marketValueLabel?.text = amount > 0 ? "￥\(formatMoney(amount))" : "--"

        if userBalance > 0 {
            availableLabel?.text = "￥\(formatMoney(userBalance))"
            let maxShares = price > 0 ? Int(floor(userBalance / price / 100)) * 100 : 0
            canBuySharesLabel?.text = "\(maxShares)股"
        }
    }

    // MARK: - 渲染
    private func renderPrice(_ price: Double) {
        currentPriceLabel?.text = formatPrice(price)
        recalculate()
    }

    private func renderHeader() {
        let priceText = formatPrice(currentPrice)
        if changePercent != 0 {
            let sign = changePercent >= 0 ? "+" : ""
            priceHeaderLabel?.text = "\(priceText) \(sign)\(String(format: "%.2f", changePercent))%"
        } else {
            priceHeaderLabel?.text = priceText
        }
        let color: UIColor
        if changeAmount > 0 { color = themeRed }
        else if changeAmount < 0 { color = themeGreen }
        else { color = textSec }
        priceHeaderLabel?.textColor = color
    }

    // MARK: - 买入（弹出确认弹窗 → 提交）
    @objc private func buyTapped() {
        guard quantity > 0 else {
            Toast.show("请输入买入数量")
            return
        }
        guard currentPrice > 0 else {
            Toast.show("当前价格异常，请稍后重试")
            return
        }
        guard !stockAllcode.isEmpty else {
            Toast.show("股票代码不能为空")
            return
        }
        showOrderConfirmDialog()
    }

    private func showOrderConfirmDialog() {
        let shares = quantity * 100
        let amount = Double(shares) * currentPrice
        let fee    = amount * Self.FEE_RATE

        let alert = UIAlertController(title: "订单明细", message: nil, preferredStyle: .alert)

        let msg = """
        名称：\(stockName.isEmpty ? "--" : stockName)
        代码：\(stockAllcode)
        买入价格：\(formatPrice(currentPrice))
        买入数量：\(shares)股
        金额(估算)：¥\(formatMoney(amount))
        手续费：¥\(formatMoney(fee))
        """
        alert.message = msg

        alert.addAction(UIAlertAction(title: "返回", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.submitBuy()
        })
        present(alert, animated: true)
    }

    private func submitBuy() {
        buyButton?.isEnabled = false

        let params: [String: Any] = [
            "allcode":  stockAllcode,
            "buyprice": currentPrice,
            "canBuy":   quantity          // 手数
        ]
        SecureNetworkManager.shared.request(
            api: "/api/deal/addStrategy",
            method: .post,
            params: params
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.buyButton?.isEnabled = true
                switch result {
                case .success(let res):
                    if let dict = res.decrypted,
                       let code = dict["code"] as? Int, code == 1 {
                        Toast.show("买入委托已提交")
                        self?.navigationController?.popViewController(animated: true)
                    } else {
                        let msg = res.decrypted?["msg"] as? String ?? "买入失败"
                        Toast.show(msg)
                    }
                case .failure(let err):
                    Toast.show(err.localizedDescription)
                }
            }
        }
    }

    // MARK: - 数据加载
    private func loadInitialData() {
        loadBalance()
        if currentPrice > 0 { renderPrice(currentPrice); renderHeader() }
        refreshMarket()
    }

    /// 拉取账户余额
    private func loadBalance() {
        SecureNetworkManager.shared.request(
            api: "/api/user/getUserPrice_all1",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            if case .success(let res) = result,
               let dict = res.decrypted,
               let data = dict["data"] as? [String: Any],
               let list = data["list"] as? [String: Any] {
                let balance = list["balance"] as? Double ?? 0
                self.userBalance = balance
                DispatchQueue.main.async {
                    self.accountBalanceLabel?.text = "(账户余额\(self.formatMoney(balance))元)"
                    self.recalculate()
                }
            }
        }
    }

    // MARK: - 行情轮询（5 秒间隔，与 Android 一致）
    private func startPolling() {
        guard !polling else { return }
        polling = true
        pollTimer = Timer.scheduledTimer(withTimeInterval: Self.POLL_INTERVAL, repeats: true) { [weak self] _ in
            self?.refreshMarket()
        }
    }

    private func stopPolling() {
        polling = false
        pollTimer?.invalidate()
        pollTimer = nil
    }

    /// 拉取东方财富快照 + 五档盘口
    private func refreshMarket() {
        guard !stockAllcode.isEmpty else { return }

        let code   = extractCode(stockAllcode)
        let prefix = stockAllcode.prefix(2).lowercased()
        let market = (prefix == "sh") ? "1" : "0"
        let secid  = "\(market).\(code)"

        // 快照字段：f43(现价) f58(名称) f169(涨跌额) f170(涨跌幅)
        // 五档字段（与 Android EastMoneyDetailRepository 完全一致）：
        //   买: f19(买1价) f20(买1量) f17(买2价) f18(买2量) f15(买3价) f16(买3量) f13(买4价) f14(买4量) f11(买5价) f12(买5量)
        //   卖: f39(卖1价) f40(卖1量) f37(卖2价) f38(卖2量) f35(卖3价) f36(卖3量) f33(卖4价) f34(卖4量) f31(卖5价) f32(卖5量)
        let fields = "f43,f58,f169,f170,f39,f40,f37,f38,f35,f36,f33,f34,f31,f32,f19,f20,f17,f18,f15,f16,f13,f14,f11,f12"
        let urlStr = "https://push2.eastmoney.com/api/qt/stock/get?fltt=2&invt=2&secid=\(secid)&fields=\(fields)"

        guard let url = URL(string: urlStr) else { return }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        req.setValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")

        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = root["data"] as? [String: Any] else { return }

            func dbl(_ k: String) -> Double { return (d[k] as? Double) ?? 0 }
            func str(_ k: String) -> String { return (d[k] as? String) ?? "" }

            // 快照
            let price     = dbl("f43")
            let name      = str("f58")
            let change    = dbl("f169")
            let changePct = dbl("f170")

            // 五档（asks[0]=卖1, bids[0]=买1）— 与 Android 完全一致
            let asks: [(price: Double, vol: Int)] = [
                (dbl("f39"), Int(dbl("f40"))),   // 卖1
                (dbl("f37"), Int(dbl("f38"))),   // 卖2
                (dbl("f35"), Int(dbl("f36"))),   // 卖3
                (dbl("f33"), Int(dbl("f34"))),   // 卖4
                (dbl("f31"), Int(dbl("f32")))    // 卖5
            ]
            let bids: [(price: Double, vol: Int)] = [
                (dbl("f19"), Int(dbl("f20"))),   // 买1
                (dbl("f17"), Int(dbl("f18"))),   // 买2
                (dbl("f15"), Int(dbl("f16"))),   // 买3
                (dbl("f13"), Int(dbl("f14"))),   // 买4
                (dbl("f11"), Int(dbl("f12")))    // 买5
            ]

            DispatchQueue.main.async {
                if price > 0 {
                    self.currentPrice  = price
                    self.changeAmount  = change
                    self.changePercent = changePct
                    self.renderPrice(price)
                    self.renderHeader()
                }
                if !name.isEmpty && self.stockName.isEmpty {
                    self.stockName = name
                    self.stockNameLabel?.text = name
                }
                self.refreshOrderBook(asks: asks, bids: bids)
            }
        }.resume()
    }

    private func extractCode(_ allcode: String) -> String {
        var s = allcode.lowercased()
        for prefix in ["sh", "sz", "bj"] {
            if s.hasPrefix(prefix) { s.removeFirst(prefix.count); break }
        }
        return s
    }

    // MARK: - 格式化
    private func formatPrice(_ v: Double) -> String { String(format: "%.2f", v) }
    private func formatMoney(_ v: Double) -> String { String(format: "%.2f", v) }

    // MARK: - 工厂方法

    /// 在指定容器内创建一行
    private func makeRow(height: CGFloat, in container: UIView, after prev: UIView?, padH: CGFloat = 0) -> UIView {
        let row = UIView()
        row.backgroundColor = .clear
        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        let prevAnchor = prev?.bottomAnchor ?? container.topAnchor
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: prevAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padH),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padH),
            row.heightAnchor.constraint(equalToConstant: height)
        ])
        return row
    }

    private func addSep(after prev: UIView?) -> UIView {
        let sep = UIView()
        sep.backgroundColor = bgGray
        contentView.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false
        let prevAnchor = prev?.bottomAnchor ?? contentView.topAnchor
        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: prevAnchor),
            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 8)
        ])
        return sep
    }

    private func addSepLineRow(in container: UIView, after prev: UIView?) -> UIView {
        let row = UIView()
        row.backgroundColor = .clear
        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        let prevAnchor = prev?.bottomAnchor ?? container.topAnchor
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: prevAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.heightAnchor.constraint(equalToConstant: 11)
        ])
        let line = UIView()
        line.backgroundColor = sepColor
        row.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            line.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1)
        ])
        return row
    }

    private func addSepLine(to view: UIView, inset: CGFloat = 16) {
        let line = UIView()
        line.backgroundColor = sepColor
        view.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            line.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            line.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func makeLabel(_ text: String, font: UIFont, color: UIColor) -> UILabel {
        let l = UILabel()
        l.text      = text
        l.font      = font
        l.textColor = color
        return l
    }

    private func makeBadge(_ text: String) -> UIView {
        let lbl = makeLabel(text, font: .boldSystemFont(ofSize: 11), color: .white)
        lbl.textAlignment = .center
        let bg = UIView()
        bg.backgroundColor    = tagBlue
        bg.layer.cornerRadius = 2
        bg.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bg.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
            bg.heightAnchor.constraint(equalToConstant: 18),
            lbl.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 4),
            lbl.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -4),
            lbl.centerYAnchor.constraint(equalTo: bg.centerYAnchor)
        ])
        return bg
    }

    private func makeStepButton(title: String) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(textPri, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20)
        btn.backgroundColor  = .clear
        return btn
    }
}
