//
//  StockTradeViewController.swift
//  zhengqaun
//
//  股票买入页 — 完全对齐 Android BuyActivity + activity_buy.xml
//  布局：代码 → 现价 → 买入价格(±) → 涨跌停 → 合位(1/4 1/3 1/2 全仓)
//        → 买入手数(±) → 服务费 → 可用金额 → 应付(元)
//  底部固定：买入下单按钮
//  5 秒轮询东方财富行情
//

import UIKit

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
    private let themeRed   = UIColor(red: 0xF4/255, green: 0x43/255, blue: 0x36/255, alpha: 1) // #F44336
    private let themeGreen = UIColor(red: 0x4C/255, green: 0xAF/255, blue: 0x50/255, alpha: 1) // #4CAF50
    private let textPri    = UIColor(red: 0x33/255, green: 0x33/255, blue: 0x33/255, alpha: 1) // #333333
    private let textSec    = UIColor(red: 0x99/255, green: 0x99/255, blue: 0x99/255, alpha: 1) // #999999
    private let dividerColor = UIColor(red: 0xF0/255, green: 0xF0/255, blue: 0xF0/255, alpha: 1) // #F0F0F0
    private let stepperBg   = UIColor(red: 0xF5/255, green: 0xF5/255, blue: 0xF5/255, alpha: 1)

    // MARK: - 常量
    private static let DEFAULT_FEE_RATE: Double = 0.0001
    private static let POLL_INTERVAL: TimeInterval = 5.0

    // MARK: - 数据（对齐安卓 BuyActivity 属性）
    private var tradePrice: Double = 0        // 委托价（可手动修改）
    private var lots: Int = 0                 // 手数（1手=100股）
    private var userBalance: Double = 0
    private var buyFeeRate: Double = 0.0001
    private var isEditBuyEnabled: Bool = true
    private var autoLotsApplied = false
    private var polling = false
    private var pollTimer: Timer?

    // MARK: - UI 标签引用
    private var stockInfoLabel: UILabel!       // 代码行值
    private var currentPriceLabel: UILabel!    // 现价值
    private var tradePriceField: UITextField!  // 买入价格输入框
    private var btnPriceDecrease: UIButton!
    private var btnPriceIncrease: UIButton!
    private var limitDownLabel: UILabel!       // 跌停值
    private var limitUpLabel: UILabel!         // 涨停值
    private var positionButtons: [UIButton] = []
    private var lotsLabel: UILabel!            // 手数显示
    private var feeLabelTitle: UILabel!        // 服务费标题（含百分比）
    private var feeValueLabel: UILabel!        // 服务费值
    private var availableBalanceLabel: UILabel! // 可用金额值
    private var totalAmountLabel: UILabel!     // 应付金额值
    private var confirmButton: UIButton!       // 买入下单按钮

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavBar()
        buildUI()
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
        gk_navBackgroundColor = .white
        gk_navTintColor = textPri
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = textPri
        gk_navTitle = "账户交易"
        gk_navLineHidden = false
        gk_statusBarStyle = .default
        gk_backStyle = .black
    }

    // ===================================================================
    // MARK: - UI 构建（完全对齐 activity_buy.xml）
    // ===================================================================
    private func buildUI() {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // 底部确认按钮
        confirmButton = UIButton(type: .custom)
        confirmButton.setTitle("买入下单", for: .normal)
        confirmButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        confirmButton.backgroundColor = themeRed
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 8
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        view.addSubview(confirmButton)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false

        let bottomPad = Constants.Navigation.safeAreaBottom

        NSLayoutConstraint.activate([
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(16 + bottomPad)),
            confirmButton.heightAnchor.constraint(equalToConstant: 48),

            scrollView.topAnchor.constraint(equalTo: gk_navigationBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -8),
        ])

        // 内容容器
        let content = UIView()
        scrollView.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scrollView.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        var lastView: UIView? = nil

        // 1. 代码行
        lastView = addRow(to: content, after: lastView) { row in
            let left = self.makeGrayLabel("代码")
            let right = UILabel()
            right.font = .systemFont(ofSize: 14)
            right.textColor = self.textPri
            let codeDisplay = self.stockName.isEmpty ? self.stockAllcode : "\(self.stockName)[\(self.stockAllcode)]"
            right.text = codeDisplay
            self.stockInfoLabel = right
            self.layoutLeftRight(row: row, left: left, right: right)
        }
        lastView = addDivider(to: content, after: lastView)

        // 2. 现价行
        lastView = addRow(to: content, after: lastView) { row in
            let left = self.makeGrayLabel("现价")
            let right = UILabel()
            right.font = .systemFont(ofSize: 14)
            right.textColor = self.themeRed
            right.text = self.currentPrice > 0 ? self.formatPrice(self.currentPrice) : "--"
            self.currentPriceLabel = right
            self.layoutLeftRight(row: row, left: left, right: right)
        }
        lastView = addDivider(to: content, after: lastView)

        // 3. 买入价格行（带 ± 步进器）
        lastView = addRow(to: content, after: lastView) { row in
            let left = self.makeGrayLabel("买入价格")
            let stepper = self.buildPriceStepper()
            self.layoutLeftRightView(row: row, left: left, right: stepper)
        }
        lastView = addDivider(to: content, after: lastView)

        // 4. 涨跌停行
        lastView = addRow(to: content, after: lastView) { row in
            let left = self.makeGrayLabel("涨跌停")
            let downLbl = UILabel()
            downLbl.font = .systemFont(ofSize: 14)
            downLbl.textColor = self.themeGreen
            downLbl.text = "跌停: --"
            self.limitDownLabel = downLbl

            let upLbl = UILabel()
            upLbl.font = .systemFont(ofSize: 14)
            upLbl.textColor = self.themeRed
            upLbl.text = "涨停: --"
            self.limitUpLabel = upLbl

            let rightStack = UIStackView(arrangedSubviews: [downLbl, upLbl])
            rightStack.spacing = 32
            self.layoutLeftRightView(row: row, left: left, right: rightStack)
        }
        lastView = addDivider(to: content, after: lastView)

        // 5. 合位行（仓位按钮）
        lastView = addRow(to: content, after: lastView) { row in
            let left = self.makeGrayLabel("合位")
            let btnStack = self.buildPositionButtons()
            self.layoutLeftRightView(row: row, left: left, right: btnStack)
        }
        lastView = addDivider(to: content, after: lastView)

        // 6. 买入手数行（带 ± 步进器）
        lastView = addRow(to: content, after: lastView) { row in
            let left = self.makeGrayLabel("买入手数")
            let stepper = self.buildLotsStepper()
            self.layoutLeftRightView(row: row, left: left, right: stepper)
        }
        lastView = addDivider(to: content, after: lastView)

        // 7. 服务费行
        lastView = addRow(to: content, after: lastView) { row in
            let left = UILabel()
            left.font = .systemFont(ofSize: 14)
            left.textColor = self.textSec
            left.text = "服务费(元)0.01%"
            self.feeLabelTitle = left

            let right = UILabel()
            right.font = .systemFont(ofSize: 14)
            right.textColor = self.textPri
            right.text = "0.00"
            self.feeValueLabel = right
            self.layoutLeftRight(row: row, left: left, right: right)
        }
        lastView = addDivider(to: content, after: lastView)

        // 8. 可用金额行
        lastView = addRow(to: content, after: lastView) { row in
            let left = self.makeGrayLabel("可用金额")
            let right = UILabel()
            right.font = .systemFont(ofSize: 14)
            right.textColor = self.textPri
            right.text = "--"
            self.availableBalanceLabel = right
            self.layoutLeftRight(row: row, left: left, right: right)
        }
        lastView = addDivider(to: content, after: lastView)

        // 9. 应付(元)行
        lastView = addRow(to: content, after: lastView) { row in
            let left = self.makeGrayLabel("应付(元)")
            let right = UILabel()
            right.font = .systemFont(ofSize: 14)
            right.textColor = self.textPri
            right.text = "0.00"
            self.totalAmountLabel = right
            self.layoutLeftRight(row: row, left: left, right: right)
        }

        // 底部约束
        lastView?.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20).isActive = true
    }

    // ===================================================================
    // MARK: - UI 组件构建
    // ===================================================================

    /// 价格步进器（对齐安卓 et_trade_price + btn_price_decrease/increase）
    private func buildPriceStepper() -> UIView {
        let wrap = UIStackView()
        wrap.axis = .horizontal
        wrap.spacing = 0
        wrap.alignment = .center

        let minus = makeStepperButton(title: "—")
        minus.addTarget(self, action: #selector(priceDecrease), for: .touchUpInside)
        btnPriceDecrease = minus

        let field = UITextField()
        field.keyboardType = .decimalPad
        field.textAlignment = .center
        field.font = .systemFont(ofSize: 14)
        field.textColor = themeRed
        field.backgroundColor = dividerColor
        field.text = currentPrice > 0 ? formatPrice(currentPrice) : ""
        field.addTarget(self, action: #selector(tradePriceChanged), for: .editingChanged)
        tradePriceField = field

        let plus = makeStepperButton(title: "+")
        plus.addTarget(self, action: #selector(priceIncrease), for: .touchUpInside)
        btnPriceIncrease = plus

        wrap.addArrangedSubview(minus)
        wrap.addArrangedSubview(field)
        wrap.addArrangedSubview(plus)

        minus.translatesAutoresizingMaskIntoConstraints = false
        field.translatesAutoresizingMaskIntoConstraints = false
        plus.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            minus.widthAnchor.constraint(equalToConstant: 32),
            minus.heightAnchor.constraint(equalToConstant: 32),
            field.widthAnchor.constraint(equalToConstant: 80),
            field.heightAnchor.constraint(equalToConstant: 32),
            plus.widthAnchor.constraint(equalToConstant: 32),
            plus.heightAnchor.constraint(equalToConstant: 32),
        ])
        return wrap
    }

    /// 手数步进器（对齐安卓 tv_lots + btn_decrease/increase）
    private func buildLotsStepper() -> UIView {
        let wrap = UIStackView()
        wrap.axis = .horizontal
        wrap.spacing = 0
        wrap.alignment = .center

        let minus = makeStepperButton(title: "—")
        minus.addTarget(self, action: #selector(lotsDecrease), for: .touchUpInside)

        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = textPri
        lbl.textAlignment = .center
        lbl.backgroundColor = dividerColor
        lbl.text = "0"
        lotsLabel = lbl

        let plus = makeStepperButton(title: "+")
        plus.addTarget(self, action: #selector(lotsIncrease), for: .touchUpInside)

        wrap.addArrangedSubview(minus)
        wrap.addArrangedSubview(lbl)
        wrap.addArrangedSubview(plus)

        minus.translatesAutoresizingMaskIntoConstraints = false
        lbl.translatesAutoresizingMaskIntoConstraints = false
        plus.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            minus.widthAnchor.constraint(equalToConstant: 32),
            minus.heightAnchor.constraint(equalToConstant: 32),
            lbl.widthAnchor.constraint(equalToConstant: 60),
            lbl.heightAnchor.constraint(equalToConstant: 32),
            plus.widthAnchor.constraint(equalToConstant: 32),
            plus.heightAnchor.constraint(equalToConstant: 32),
        ])
        return wrap
    }

    /// 仓位按钮组（对齐安卓 btn_position_1_4 / 1_3 / 1_2 / all）
    private func buildPositionButtons() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        positionButtons = []
        let labels = ["1/4", "1/3", "1/2", "全仓"]
        for (i, title) in labels.enumerated() {
            let btn = UIButton(type: .custom)
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(UIColor(red: 0x66/255, green: 0x66/255, blue: 0x66/255, alpha: 1), for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12)
            btn.backgroundColor = dividerColor
            btn.layer.cornerRadius = 4
            btn.tag = i
            btn.addTarget(self, action: #selector(positionTapped(_:)), for: .touchUpInside)
            btn.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 40),
                btn.heightAnchor.constraint(equalToConstant: 28),
            ])
            stack.addArrangedSubview(btn)
            positionButtons.append(btn)
        }
        return stack
    }

    // ===================================================================
    // MARK: - Actions（对齐安卓 BuyActivity）
    // ===================================================================

    @objc private func priceDecrease() {
        let p = max(tradePrice - 0.01, 0.01)
        tradePrice = (p * 100).rounded() / 100.0
        tradePriceField.text = formatPrice(tradePrice)
    }

    @objc private func priceIncrease() {
        let p = tradePrice + 0.01
        tradePrice = (p * 100).rounded() / 100.0
        tradePriceField.text = formatPrice(tradePrice)
    }

    @objc private func tradePriceChanged() {
        let v = Double(tradePriceField.text ?? "") ?? 0
        tradePrice = v
        recalculate()
        autoFillLotsIfNeeded()
    }

    @objc private func lotsDecrease() {
        if lots > 0 {
            lots -= 1
            lotsLabel.text = "\(lots)"
            recalculate()
            autoLotsApplied = true
        }
    }

    @objc private func lotsIncrease() {
        let maxLots = calcMaxBuyLots()
        if maxLots <= 0 || lots < maxLots {
            lots += 1
            lotsLabel.text = "\(lots)"
            recalculate()
            autoLotsApplied = true
        }
    }

    @objc private func positionTapped(_ sender: UIButton) {
        let ratios = [0.25, 1.0 / 3.0, 0.5, 1.0]
        let ratio = ratios[sender.tag]
        applyPositionRatio(ratio)
        highlightPositionButton(sender.tag)
        autoLotsApplied = true
    }

    // ===================================================================
    // MARK: - 计算（完全对齐安卓 BuyActivity）
    // ===================================================================

    /// 对齐安卓 applyPositionRatio
    private func applyPositionRatio(_ ratio: Double) {
        let effectivePrice = tradePrice > 0 ? tradePrice : currentPrice
        guard effectivePrice > 0 else {
            Toast.show("价格未加载，请稍后再试")
            return
        }
        guard userBalance > 0 else {
            lots = 0
            lotsLabel?.text = "0"
            Toast.show("可用余额不足，请手动输入买入手数")
            loadBalance()
            return
        }
        // 对齐安卓：可用金额 × 比例 ÷ (价格 × (1 + 手续费率) × 100)
        let costPerShare = effectivePrice * (1 + buyFeeRate)
        let availableForRatio = userBalance * ratio
        let calculatedLots = availableForRatio / costPerShare / 100
        lots = max(Int(floor(calculatedLots)), 1)
        lotsLabel?.text = "\(lots)"
        recalculate()
    }

    /// 对齐安卓 calcMaxBuyLots
    private func calcMaxBuyLots() -> Int {
        let effectivePrice = tradePrice > 0 ? tradePrice : currentPrice
        guard effectivePrice > 0, userBalance > 0 else { return 0 }
        let costPerShare = effectivePrice * (1 + buyFeeRate)
        return Int(floor(userBalance / costPerShare / 100))
    }

    /// 对齐安卓 recalculate
    private func recalculate() {
        let shares = lots * 100
        let price = tradePrice > 0 ? tradePrice : currentPrice
        let amount = Double(shares) * price
        let fee = amount * buyFeeRate
        let total = amount + fee

        feeValueLabel?.text = formatMoney(fee)
        totalAmountLabel?.text = formatMoney(total)
    }

    /// 对齐安卓 autoFillLotsIfNeeded
    private func autoFillLotsIfNeeded() {
        guard !autoLotsApplied else { return }
        guard lots == 0 else { autoLotsApplied = true; return }
        let effectivePrice = tradePrice > 0 ? tradePrice : currentPrice
        guard effectivePrice > 0 else { return }
        lots = 1
        autoLotsApplied = true
        lotsLabel?.text = "\(lots)"
        recalculate()
    }

    /// 对齐安卓 updateLimitPrices
    private func updateLimitPrices() {
        guard currentPrice > 0 else { return }
        let limitRate = isGrowthOrStar(stockAllcode) ? 0.20 : 0.10
        let up = currentPrice * (1 + limitRate)
        let down = currentPrice * (1 - limitRate)
        limitUpLabel?.text = "涨停: \(formatPrice(up))"
        limitDownLabel?.text = "跌停: \(formatPrice(down))"
    }

    /// 对齐安卓 isGrowthOrStar
    private func isGrowthOrStar(_ allcode: String) -> Bool {
        let code = extractCode(allcode)
        return code.hasPrefix("30") || code.hasPrefix("68")
    }

    private func highlightPositionButton(_ selectedIndex: Int) {
        for (i, btn) in positionButtons.enumerated() {
            if i == selectedIndex {
                btn.backgroundColor = themeRed
                btn.setTitleColor(.white, for: .normal)
            } else {
                btn.backgroundColor = dividerColor
                btn.setTitleColor(UIColor(red: 0x66/255, green: 0x66/255, blue: 0x66/255, alpha: 1), for: .normal)
            }
        }
    }

    /// 对齐安卓 ensureTradePrice
    private func ensureTradePrice() {
        guard tradePrice <= 0, currentPrice > 0 else { return }
        tradePrice = currentPrice
        if !(tradePriceField?.isFirstResponder ?? false) {
            tradePriceField?.text = formatPrice(tradePrice)
        }
        updateLimitPrices()
        recalculate()
        autoFillLotsIfNeeded()
    }

    // ===================================================================
    // MARK: - 确认弹窗 + 提交（对齐安卓 showConfirmDialog / submitBuy）
    // ===================================================================

    @objc private func confirmTapped() {
        guard lots > 0 else {
            Toast.show("请输入买入手数")
            return
        }
        let price = tradePrice > 0 ? tradePrice : currentPrice
        guard price > 0 else {
            Toast.show("价格异常，请稍后重试")
            return
        }
        guard !stockAllcode.isEmpty else {
            Toast.show("股票代码不能为空")
            return
        }
        // 对齐安卓：余额校验
        if userBalance > 0 {
            let total = Double(lots) * 100 * price * (1 + buyFeeRate)
            if total > userBalance {
                Toast.show("可用余额不足，最多可买\(calcMaxBuyLots())手")
                return
            }
        }
        showConfirmDialog(price: price)
    }

    private func showConfirmDialog(price: Double) {
        let shares = lots * 100
        let amount = Double(shares) * price
        let total = amount * (1 + buyFeeRate)

        let alert = UIAlertController(title: "确认买入吗", message: nil, preferredStyle: .alert)
        let msg = """
        名称：\(stockName.isEmpty ? stockAllcode : stockName)
        价格：\(formatPrice(price))
        数量：\(shares)股
        金额：¥\(formatMoney(total))
        """
        alert.message = msg
        alert.addAction(UIAlertAction(title: "返回", style: .cancel))
        alert.addAction(UIAlertAction(title: "买入", style: .default) { [weak self] _ in
            self?.submitBuy(price: price)
        })
        present(alert, animated: true)
    }

    private func submitBuy(price: Double) {
        confirmButton?.isEnabled = false
        let params: [String: Any] = [
            "allcode":  stockAllcode,
            "buyprice": price,
            "canBuy":   lots
        ]
        SecureNetworkManager.shared.request(
            api: "/api/deal/addStrategy",
            method: .post,
            params: params
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.confirmButton?.isEnabled = true
                switch result {
                case .success(let res):
                    if let dict = res.decrypted,
                       let code = dict["code"] as? Int, code == 1 {
                        Toast.show("买入成功")
                        // 对齐安卓：买入成功后跳转委托列表
                        let vc = EntrustmentListViewController()
                        vc.hidesBottomBarWhenPushed = true
                        self?.navigationController?.pushViewController(vc, animated: true)
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

    // ===================================================================
    // MARK: - 数据加载（对齐安卓 BuyActivity）
    // ===================================================================

    private func loadInitialData() {
        loadConfig()
        loadBalance()
        loadUserInfo()
        if currentPrice > 0 {
            tradePrice = currentPrice
            tradePriceField?.text = formatPrice(currentPrice)
        }
        refreshMarket()
    }

    /// 对齐安卓 loadConfig：加载费率配置
    private func loadConfig() {
        SecureNetworkManager.shared.request(
            api: "/api/stock/getconfig",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            if case .success(let res) = result,
               let dict = res.decrypted,
               let data = dict["data"] as? [String: Any] {
                if let buyStr = data["mai_fee"] as? String,
                   let buy = Double(buyStr), buy > 0 {
                    self.buyFeeRate = buy
                }
                DispatchQueue.main.async {
                    let pct = String(format: "%.2f", self.buyFeeRate * 100)
                    self.feeLabelTitle?.text = "服务费(元)\(pct)%"
                    self.recalculate()
                }
            }
        }
    }

    /// 对齐安卓 loadUserInfo：获取 isEditBuy 配置
    private func loadUserInfo() {
        SecureNetworkManager.shared.request(
            api: "/api/stock/info",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            if case .success(let res) = result,
               let dict = res.decrypted,
               let data = dict["data"] as? [String: Any],
               let list = data["list"] as? [String: Any] {
                let isEditBuy = list["isEditBuy"] as? String ?? "1"
                self.isEditBuyEnabled = (isEditBuy != "0")
                DispatchQueue.main.async {
                    self.updateTradePriceEditability()
                }
            }
        }
    }

    /// 对齐安卓 updateTradePriceEditability
    private func updateTradePriceEditability() {
        let editable = isEditBuyEnabled
        tradePriceField?.isEnabled = editable
        btnPriceDecrease?.isEnabled = editable
        btnPriceIncrease?.isEnabled = editable
        btnPriceDecrease?.alpha = editable ? 1.0 : 0.4
        btnPriceIncrease?.alpha = editable ? 1.0 : 0.4
    }

    /// 对齐安卓 loadBalance（扣除委托资金 weituozj）
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
                let weituozj = list["weituozj"] as? Double ?? 0
                self.userBalance = balance - weituozj
                DispatchQueue.main.async {
                    self.availableBalanceLabel?.text = self.formatMoney(self.userBalance)
                    self.recalculate()
                    self.autoFillLotsIfNeeded()
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

    /// 对齐安卓 refreshMarket（使用新浪财经 API 获取现价）
    private func refreshMarket() {
        guard !stockAllcode.isEmpty else { return }
        let code = extractCode(stockAllcode)
        let prefix = stockAllcode.prefix(2).lowercased()
        let market = (prefix == "sh") ? "sh" : (prefix == "bj" ? "bj" : "sz")
        let sinaCode = "\(market)\(code)"

        let urlStr = "https://hq.sinajs.cn/list=\(sinaCode)"
        guard let url = URL(string: urlStr) else { return }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        req.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")

        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }

            // 新浪财经接口返回的是 GBK 编码
            let cfEnc = CFStringEncodings.GB_18030_2000
            let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEnc.rawValue))
            guard let rawStr = String(data: data, encoding: String.Encoding(rawValue: enc)),
                  let startIdx = rawStr.firstIndex(of: "\""),
                  let endIdx = rawStr.lastIndex(of: "\""),
                  startIdx < endIdx else { return }

            let content = String(rawStr[rawStr.index(after: startIdx)..<endIdx])
            let fields = content.components(separatedBy: ",")
            guard fields.count >= 4 else { return }

            let name     = fields[0]
            let preClose = Double(fields[2]) ?? 0.0
            let price    = Double(fields[3]) ?? 0.0

            DispatchQueue.main.async {
                if price > 0 {
                    self.currentPrice = price
                    self.currentPriceLabel?.text = self.formatPrice(price)
                    
                    if self.tradePrice <= 0 {
                        self.tradePrice = price
                        if !(self.tradePriceField?.isFirstResponder ?? false) {
                            self.tradePriceField?.text = self.formatPrice(price)
                        }
                    }
                    self.updateLimitPrices()
                    self.recalculate()
                    self.autoFillLotsIfNeeded()
                }
                if !name.isEmpty && self.stockName.isEmpty {
                    self.stockName = name
                    self.stockInfoLabel?.text = "\(name)[\(self.stockAllcode)]"
                }
                self.ensureTradePrice()
            }
        }.resume()
    }

    // ===================================================================
    // MARK: - 工具方法
    // ===================================================================

    private func extractCode(_ allcode: String) -> String {
        var s = allcode.lowercased()
        for prefix in ["sh", "sz", "bj"] {
            if s.hasPrefix(prefix) { s.removeFirst(prefix.count); break }
        }
        return s
    }

    private func formatPrice(_ v: Double) -> String { String(format: "%.2f", v) }
    private func formatMoney(_ v: Double) -> String { String(format: "%.2f", v) }

    // ===================================================================
    // MARK: - 布局辅助
    // ===================================================================

    private func makeGrayLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = textSec
        return lbl
    }

    private func makeStepperButton(title: String) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(UIColor(red: 0x66/255, green: 0x66/255, blue: 0x66/255, alpha: 1), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.backgroundColor = stepperBg
        btn.layer.cornerRadius = 2
        return btn
    }

    /// 添加通用数据行（高度 48，padding 16）
    private func addRow(to container: UIView, after prev: UIView?, configure: (UIView) -> Void) -> UIView {
        let row = UIView()
        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        let topAnchor = prev?.bottomAnchor ?? container.topAnchor
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            row.heightAnchor.constraint(equalToConstant: 48),
        ])
        configure(row)
        return row
    }

    /// 添加分隔线
    private func addDivider(to container: UIView, after prev: UIView?) -> UIView {
        let line = UIView()
        line.backgroundColor = dividerColor
        container.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: prev!.bottomAnchor),
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            line.heightAnchor.constraint(equalToConstant: 1),
        ])
        return line
    }

    /// 左标签 + 右标签布局
    private func layoutLeftRight(row: UIView, left: UILabel, right: UILabel) {
        row.addSubview(left)
        row.addSubview(right)
        left.translatesAutoresizingMaskIntoConstraints = false
        right.translatesAutoresizingMaskIntoConstraints = false
        left.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        NSLayoutConstraint.activate([
            left.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            left.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            right.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            right.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
    }

    /// 左标签 + 右侧自定义视图布局
    private func layoutLeftRightView(row: UIView, left: UILabel, right: UIView) {
        row.addSubview(left)
        row.addSubview(right)
        left.translatesAutoresizingMaskIntoConstraints = false
        right.translatesAutoresizingMaskIntoConstraints = false
        left.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        NSLayoutConstraint.activate([
            left.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            left.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            right.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            right.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
    }
}
