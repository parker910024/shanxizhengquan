//
//  StockTradeViewController.swift
//  zhengqaun
//
//  股票交易详情页：参考设计图实现买入流程
//  布局：代码行 → 盘中行 → 现价行 → 数量行 → 现金仓位 → 金额 → 有效期 → 五档盘口 → 市值/手续费/可用额度/可购买股数
//  底部固定：买入金额 + 买入按钮
//

import UIKit

class StockTradeViewController: ZQViewController {

    // MARK: - 入参（由上级 VC 赋值）
    var stockName:     String = "源杰科技"
    var stockCode:     String = "688498"
    var stockAllcode:  String = "sh688498"   // 完整 allcode，如 sh688498 / sz300170
    var exchange:      String = "北"          // 北/沪/深/科
    var currentPrice:  Double = 823.00
    var changeAmount:  String = "+13.96"
    var changePercent: String = "+1.72"

    // MARK: - 颜色
    private let themeRed   = UIColor(red: 230/255, green: 0,       blue: 18/255,  alpha: 1)
    private let themeGreen = UIColor(red: 0.13,    green: 0.73,    blue: 0.33,    alpha: 1)
    private let textPri    = UIColor(red: 43/255,  green: 44/255,  blue: 49/255,  alpha: 1)
    private let textSec    = UIColor(red: 0.55,    green: 0.56,    blue: 0.58,    alpha: 1)
    private let bgGray     = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1)
    private let btnGray    = UIColor(red: 0.94,    green: 0.94,    blue: 0.95,    alpha: 1)
    private let sepColor   = UIColor(red: 0.93,    green: 0.93,    blue: 0.94,    alpha: 1)

    // MARK: - UI
    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    // 数量
    private var quantityField: UITextField!
    private var quantity: Int = 0

    // 仓位按钮
    private var positionButtons: [UIButton] = []
    private var selectedPositionIdx = -1

    // 金额显示
    private var amountLabel: UILabel!

    // 五档盘口
    private struct OrderLevel { var vol: String; var price: String }
    private var sellLevels: [OrderLevel] = Array(repeating: .init(vol: "--", price: "--"), count: 5)
    private var buyLevels:  [OrderLevel] = Array(repeating: .init(vol: "--", price: "--"), count: 5)
    private var orderBoardRows: [UIView] = []     // 10 行视图（卖1 → 卖5，买1 → 买5）

    // 底部信息标签
    private var marketValueLabel:   UILabel!
    private var serviceFeeLabel:    UILabel!
    private var availableLabel:     UILabel!
    private var canBuySharesLabel:  UILabel!

    // 底部栏
    private var buyAmountLabel:     UILabel!
    private var accountBalanceLabel: UILabel!

    // 配置
    private var feePct: Double = 0.0001       // 默认 0.01%
    private var accountBalance: Double = 0
    private var availableMoney: Double = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavBar()
        setupScrollView()
        setupBottomBar()
        loadInitialData()
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

        // 右侧：客服 + 搜索
        let kfBtn  = makeNavIconButton(systemName: "headphones",  action: #selector(kfTapped))
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

    @objc private func kfTapped()     {}
    @objc private func searchTapped() {}

    // MARK: - ScrollView + 内容
    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor,
                                            constant: Constants.Navigation.contentTopBelowGKNavBar),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                               constant: -bottomBarHeight),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        buildContent()
    }

    private var bottomBarHeight: CGFloat {
        return 60 + Constants.Navigation.safeAreaBottom
    }

    // MARK: - 内容区构建
    private func buildContent() {
        var last: UIView? = nil

        // 1 — 代码行
        last = addCodeRow(after: last)

        // 2 — 盘中行（市场状态 + 涨跌）
        last = addMarketStatusRow(after: last)

        // 3 — 分隔
        last = addSep(after: last)

        // 4 — 现价行
        last = addPriceRow(after: last)

        // 5 — 数量行
        last = addQuantityRow(after: last)

        // 6 — 现金仓位行
        last = addPositionRow(after: last)

        // 7 — 金额大字显示
        last = addAmountDisplay(after: last)

        // 8 — 有效期行
        last = addValidityRow(after: last)

        // 9 — 分隔
        last = addSep(after: last)

        // 10 — 五档盘口
        last = addOrderBoard(after: last)

        // 11 — 分隔
        last = addSep(after: last)

        // 12 — 市值 / 手续费 / 可用额度 / 可购买股数
        last = addInfoRow(title: "市值", after: last) { lbl in
            lbl.text = String(format: "¥%.2f", self.currentPrice)
            self.marketValueLabel = lbl
        }
        last = addInfoRow(title: "手续费（\(Int(feePct * 10000) == 1 ? "0.01" : String(format: "%.2f", feePct * 100))%）", after: last) { lbl in
            lbl.text = String(format: "¥%.2f", self.currentPrice * self.feePct)
            self.serviceFeeLabel = lbl
        }
        last = addInfoRow(title: "可用额度", after: last) { lbl in
            lbl.text = String(format: "¥%.2f", self.currentPrice)
            self.availableLabel = lbl
        }
        last = addInfoRow(title: "可购买股数", after: last) { lbl in
            lbl.text = "--股"
            self.canBuySharesLabel = lbl
        }

        // 底部留白
        let pad = UIView()
        contentView.addSubview(pad)
        pad.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pad.topAnchor.constraint(equalTo: last!.bottomAnchor),
            pad.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pad.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pad.heightAnchor.constraint(equalToConstant: 20),
            pad.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - 行构建辅助

    /// 代码行：代码 | [北] 源杰科技688498
    private func addCodeRow(after prev: UIView?) -> UIView {
        let row = makeRow(height: 44, after: prev)

        let titleLbl   = makeLabel("代码", font: .systemFont(ofSize: 14), color: textSec)
        let badgeLbl   = makeBadge(exchange)
        let stockLabel = makeLabel("\(stockName)\(stockCode)",
                                   font: .systemFont(ofSize: 15, weight: .medium), color: textPri)

        let rightStack = UIStackView(arrangedSubviews: [badgeLbl, stockLabel])
        rightStack.spacing = 6
        rightStack.alignment = .center

        row.addSubview(titleLbl)
        row.addSubview(rightStack)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            rightStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            rightStack.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    /// 盘中状态行
    private func addMarketStatusRow(after prev: UIView?) -> UIView {
        let row = makeRow(height: 36, after: prev)

        let isRise = !changePercent.hasPrefix("-")
        let color  = isRise ? themeRed : themeGreen

        let statusLbl  = makeLabel("盘中", font: .systemFont(ofSize: 13), color: textSec)
        let priceLbl   = makeLabel(String(format: "%.2f", currentPrice),
                                    font: .boldSystemFont(ofSize: 15), color: color)
        let changeLbl  = makeLabel("\(isRise ? "+" : "")\(changePercent)%",
                                    font: .systemFont(ofSize: 13), color: color)

        let valStack = UIStackView(arrangedSubviews: [priceLbl, changeLbl])
        valStack.spacing = 8
        valStack.alignment = .center

        row.addSubview(statusLbl)
        row.addSubview(valStack)
        statusLbl.translatesAutoresizingMaskIntoConstraints = false
        valStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statusLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            statusLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valStack.leadingAnchor.constraint(equalTo: statusLbl.trailingAnchor, constant: 8),
            valStack.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    /// 现价行
    private func addPriceRow(after prev: UIView?) -> UIView {
        let row = makeRow(height: 48, after: prev)
        let titleLbl = makeLabel("现价", font: .systemFont(ofSize: 14), color: textSec)
        let valLbl   = makeLabel(String(format: "%.2f", currentPrice),
                                  font: .systemFont(ofSize: 15), color: textPri)
        row.addSubview(titleLbl)
        row.addSubview(valLbl)
        [titleLbl, valLbl].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 80),
            valLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        addSepLine(to: row)
        return row
    }

    /// 数量行：数量 — [field] +
    private func addQuantityRow(after prev: UIView?) -> UIView {
        let row = makeRow(height: 52, after: prev)

        let titleLbl = makeLabel("数量", font: .systemFont(ofSize: 14), color: textSec)

        // 减号按钮
        let minusBtn = makeStepButton(title: "－")
        minusBtn.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)

        // 输入框
        let field = UITextField()
        field.keyboardType   = .numberPad
        field.textAlignment  = .center
        field.font           = .systemFont(ofSize: 17)
        field.textColor      = textPri
        field.borderStyle    = .none
        field.placeholder    = "0"
        field.addTarget(self, action: #selector(quantityChanged), for: .editingChanged)
        quantityField = field

        // 加号按钮
        let plusBtn = makeStepButton(title: "＋")
        plusBtn.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)

        let inputWrap = UIView()
        inputWrap.layer.cornerRadius = 6
        inputWrap.layer.borderWidth  = 1
        inputWrap.layer.borderColor  = sepColor.cgColor
        inputWrap.backgroundColor    = .white
        [minusBtn, field, plusBtn].forEach {
            inputWrap.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            minusBtn.leadingAnchor.constraint(equalTo: inputWrap.leadingAnchor),
            minusBtn.topAnchor.constraint(equalTo: inputWrap.topAnchor),
            minusBtn.bottomAnchor.constraint(equalTo: inputWrap.bottomAnchor),
            minusBtn.widthAnchor.constraint(equalToConstant: 40),

            plusBtn.trailingAnchor.constraint(equalTo: inputWrap.trailingAnchor),
            plusBtn.topAnchor.constraint(equalTo: inputWrap.topAnchor),
            plusBtn.bottomAnchor.constraint(equalTo: inputWrap.bottomAnchor),
            plusBtn.widthAnchor.constraint(equalToConstant: 40),

            field.leadingAnchor.constraint(equalTo: minusBtn.trailingAnchor, constant: 4),
            field.trailingAnchor.constraint(equalTo: plusBtn.leadingAnchor, constant: -4),
            field.topAnchor.constraint(equalTo: inputWrap.topAnchor),
            field.bottomAnchor.constraint(equalTo: inputWrap.bottomAnchor)
        ])

        row.addSubview(titleLbl)
        row.addSubview(inputWrap)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        inputWrap.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            inputWrap.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            inputWrap.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            inputWrap.widthAnchor.constraint(equalToConstant: 160),
            inputWrap.heightAnchor.constraint(equalToConstant: 36)
        ])
        addSepLine(to: row)
        return row
    }

    /// 现金仓位行：现金  1/4  1/3  1/2  全仓
    private func addPositionRow(after prev: UIView?) -> UIView {
        let row = makeRow(height: 52, after: prev)

        let titleLbl = makeLabel("现金", font: .systemFont(ofSize: 14), color: textSec)
        row.addSubview(titleLbl)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        let labels = ["1/4", "1/3", "1/2", "全仓"]
        var lastBtn: UIButton? = nil
        positionButtons = []

        for (i, t) in labels.enumerated() {
            let btn = UIButton(type: .custom)
            btn.setTitle(t, for: .normal)
            btn.setTitleColor(textPri, for: .normal)
            btn.setTitleColor(.white, for: .selected)
            btn.titleLabel?.font = .systemFont(ofSize: 13)
            btn.backgroundColor  = btnGray
            btn.layer.cornerRadius = 6
            btn.tag = i
            btn.addTarget(self, action: #selector(positionTapped(_:)), for: .touchUpInside)
            row.addSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false

            if let prev2 = lastBtn {
                NSLayoutConstraint.activate([
                    btn.leadingAnchor.constraint(equalTo: prev2.trailingAnchor, constant: 8)
                ])
            } else {
                // 第一个按钮 align 靠近 titleLbl 右边但留 16 让 titleLbl 不遮住
                NSLayoutConstraint.activate([
                    btn.leadingAnchor.constraint(equalTo: titleLbl.trailingAnchor, constant: 16)
                ])
            }
            NSLayoutConstraint.activate([
                btn.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                btn.widthAnchor.constraint(equalToConstant: 52),
                btn.heightAnchor.constraint(equalToConstant: 32)
            ])
            positionButtons.append(btn)
            lastBtn = btn
        }
        addSepLine(to: row)
        return row
    }

    /// 金额大字行
    private func addAmountDisplay(after prev: UIView?) -> UIView {
        let row = makeRow(height: 72, after: prev)

        let lbl = UILabel()
        lbl.text = "¥ 0.00"
        lbl.font = .boldSystemFont(ofSize: 32)
        lbl.textColor = textPri
        lbl.textAlignment = .center
        row.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lbl.centerXAnchor.constraint(equalTo: row.centerXAnchor),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        amountLabel = lbl
        addSepLine(to: row)
        return row
    }

    /// 有效期行
    private func addValidityRow(after prev: UIView?) -> UIView {
        let row = makeRow(height: 48, after: prev)
        let lbl = makeLabel("有效期", font: .systemFont(ofSize: 14), color: textSec)
        row.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    // MARK: - 五档盘口
    private func addOrderBoard(after prev: UIView?) -> UIView {
        // 高度：5 卖行 + 5 买行，每行 34pt，中间 bar 区 10pt
        let rowH: CGFloat   = 34
        let boardH: CGFloat = rowH * 10 + 10
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

        // 中间竖线（红蓝渐变）
        let barW: CGFloat = 2
        let centerBar = UIView()
        centerBar.layer.cornerRadius = 1
        board.addSubview(centerBar)
        centerBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerBar.centerXAnchor.constraint(equalTo: board.centerXAnchor),
            centerBar.topAnchor.constraint(equalTo: board.topAnchor, constant: 4),
            centerBar.bottomAnchor.constraint(equalTo: board.bottomAnchor, constant: -4),
            centerBar.widthAnchor.constraint(equalToConstant: barW)
        ])

        DispatchQueue.main.async {
            let grad = CAGradientLayer()
            grad.frame = centerBar.bounds
            grad.colors = [self.themeRed.cgColor, self.themeGreen.cgColor]
            grad.startPoint = CGPoint(x: 0.5, y: 0)
            grad.endPoint   = CGPoint(x: 0.5, y: 1)
            centerBar.layer.insertSublayer(grad, at: 0)
        }

        // 中间"买"/"卖"标签
        let buyTag = makeLabel("买", font: .systemFont(ofSize: 11), color: .white)
        let selTag = makeLabel("卖", font: .systemFont(ofSize: 11), color: .white)
        for (tag, color, yOffset) in [(buyTag, themeRed, 0.3), (selTag, themeGreen, 0.7)] {
            let bg = UIView()
            bg.backgroundColor = color
            bg.layer.cornerRadius = 2
            board.addSubview(bg)
            bg.translatesAutoresizingMaskIntoConstraints = false
            bg.addSubview(tag)
            tag.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bg.centerXAnchor.constraint(equalTo: board.centerXAnchor),
                bg.centerYAnchor.constraint(equalTo: board.topAnchor,
                                             constant: boardH * yOffset),
                bg.widthAnchor.constraint(equalToConstant: 18),
                bg.heightAnchor.constraint(equalToConstant: 18),
                tag.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
                tag.centerYAnchor.constraint(equalTo: bg.centerYAnchor)
            ])
        }

        orderBoardRows = []

        // 卖行：卖5 ... 卖1（从上到下，卖5 在第 0 行）
        for i in 0..<5 {
            let lvIdx  = 4 - i   // 0=卖5,4=卖1
            let label  = "卖\(5 - i)"
            let row    = buildOrderRow(isSell: true, levelLabel: label, rowIndex: i,
                                       boardHeight: boardH, in: board)
            orderBoardRows.append(row)
            _ = lvIdx  // 用于后续刷新
        }

        // 买行：买1 ... 买5
        for i in 0..<5 {
            let label = "买\(i + 1)"
            let row   = buildOrderRow(isSell: false, levelLabel: label, rowIndex: i + 5,
                                      boardHeight: boardH, in: board)
            orderBoardRows.append(row)
        }

        return board
    }

    /// 构建盘口单行（固定布局，用 tag 在刷新时快速找到 label）
    private func buildOrderRow(isSell: Bool, levelLabel: String,
                                rowIndex: Int, boardHeight: CGFloat, in board: UIView) -> UIView {
        let rowH: CGFloat = 34
        let yOffset = CGFloat(rowIndex) * rowH + (rowIndex >= 5 ? 10 : 0)

        let row = UIView()
        board.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: board.topAnchor, constant: yOffset),
            row.leadingAnchor.constraint(equalTo: board.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: board.trailingAnchor),
            row.heightAnchor.constraint(equalToConstant: rowH)
        ])

        // 颜色：卖行红，买行绿（成交量字体颜色，价格红/绿）
        let accentColor = isSell ? themeRed : themeGreen

        // 左半：级别 | 量（红/绿）| 价格（右对齐近中线）
        let levelLbl = makeLabel(levelLabel, font: .systemFont(ofSize: 12), color: textSec)
        let volLbl   = makeLabel("--", font: .systemFont(ofSize: 13, weight: .medium), color: accentColor)
        let priceLbl = makeLabel("--", font: .systemFont(ofSize: 13), color: textPri)

        // tag 方案：每行基 offset = rowIndex * 10
        //   +1 = levelLbl, +2 = volLbl, +3 = priceLbl
        levelLbl.tag = rowIndex * 10 + 1
        volLbl.tag   = rowIndex * 10 + 2
        priceLbl.tag = rowIndex * 10 + 3

        [levelLbl, volLbl, priceLbl].forEach {
            row.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        if isSell {
            // 卖方：级别靠左，量在中间（居左），价靠近竖线
            NSLayoutConstraint.activate([
                levelLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 14),
                levelLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                volLbl.leadingAnchor.constraint(equalTo: levelLbl.trailingAnchor, constant: 12),
                volLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                priceLbl.trailingAnchor.constraint(equalTo: row.centerXAnchor, constant: -20),
                priceLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
            ])
        } else {
            // 买方：价靠近竖线，量在中间（居右），级别靠右
            NSLayoutConstraint.activate([
                priceLbl.leadingAnchor.constraint(equalTo: row.centerXAnchor, constant: 20),
                priceLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                volLbl.trailingAnchor.constraint(equalTo: levelLbl.leadingAnchor, constant: -12),
                volLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                levelLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -14),
                levelLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
            ])
        }

        return row
    }

    /// 刷新五档盘口显示
    private func refreshOrderBoard() {
        // 卖行 rowIndex 0-4  → sellLevels[4-0] (卖5 在第0行)
        for i in 0..<5 {
            let lvIdx = 4 - i
            let vol   = sellLevels.count > lvIdx ? sellLevels[lvIdx].vol : "--"
            let price = sellLevels.count > lvIdx ? sellLevels[lvIdx].price : "--"
            setOrderRow(rowIndex: i, vol: vol, price: price, isSell: true)
        }
        // 买行 rowIndex 5-9  → buyLevels[0-4]
        for i in 0..<5 {
            let vol   = buyLevels.count > i ? buyLevels[i].vol : "--"
            let price = buyLevels.count > i ? buyLevels[i].price : "--"
            setOrderRow(rowIndex: i + 5, vol: vol, price: price, isSell: false)
        }
    }

    private func setOrderRow(rowIndex: Int, vol: String, price: String, isSell: Bool) {
        guard rowIndex < orderBoardRows.count else { return }
        let row  = orderBoardRows[rowIndex]
        let accentColor = isSell ? themeRed : themeGreen
        if let v = row.viewWithTag(rowIndex * 10 + 2) as? UILabel { v.text = vol;   v.textColor = accentColor }
        if let p = row.viewWithTag(rowIndex * 10 + 3) as? UILabel { p.text = price }
    }

    // MARK: - 通用信息行（标题左，值右）
    @discardableResult
    private func addInfoRow(title: String, after prev: UIView?,
                             configure: ((UILabel) -> Void)? = nil) -> UIView {
        let row = makeRow(height: 48, after: prev)
        let titleLbl = makeLabel(title, font: .systemFont(ofSize: 14), color: textSec)
        let valLbl   = makeLabel("--",  font: .systemFont(ofSize: 14), color: textPri)
        valLbl.textAlignment = .right
        configure?(valLbl)

        row.addSubview(titleLbl)
        row.addSubview(valLbl)
        [titleLbl, valLbl].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            valLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        addSepLine(to: row)
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

        // 左侧：买入金额 + 账户余额
        let buyAmtTitle = makeLabel("买入金额", font: .systemFont(ofSize: 13), color: textSec)
        let buyAmtVal   = makeLabel("0.00",   font: .boldSystemFont(ofSize: 15), color: themeRed)
        buyAmountLabel  = buyAmtVal

        let balanceLbl  = makeLabel("（账户余额--元）",
                                     font: .systemFont(ofSize: 11), color: textSec)
        accountBalanceLabel = balanceLbl

        let leftStack = UIStackView(arrangedSubviews: [
            UIStackView(arrangedSubviews: [buyAmtTitle, buyAmtVal]).then {
                $0.spacing = 4; $0.alignment = .center
            },
            balanceLbl
        ])
        leftStack.axis    = .vertical
        leftStack.spacing = 2
        leftStack.alignment = .leading

        bar.addSubview(leftStack)
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 16),
            leftStack.topAnchor.constraint(equalTo: bar.topAnchor, constant: 10)
        ])

        // 右侧：买入按钮
        let buyBtn = UIButton(type: .custom)
        buyBtn.setTitle("  买入", for: .normal)
        buyBtn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        buyBtn.backgroundColor  = themeRed
        buyBtn.setTitleColor(.white, for: .normal)
        buyBtn.layer.cornerRadius = 8
        buyBtn.setImage(UIImage(systemName: "arrow.up.right"), for: .normal)
        buyBtn.tintColor = .white
        buyBtn.semanticContentAttribute = .forceLeftToRight
        buyBtn.addTarget(self, action: #selector(buyTapped), for: .touchUpInside)
        bar.addSubview(buyBtn)
        buyBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buyBtn.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -16),
            buyBtn.topAnchor.constraint(equalTo: bar.topAnchor, constant: 8),
            buyBtn.widthAnchor.constraint(equalToConstant: 120),
            buyBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - 数量 / 仓位 Actions

    @objc private func minusTapped() {
        if quantity > 0 { quantity -= 100 }
        if quantity < 0 { quantity = 0 }
        quantityField.text = quantity > 0 ? "\(quantity)" : ""
        updateAmount()
    }

    @objc private func plusTapped() {
        quantity += 100
        quantityField.text = "\(quantity)"
        updateAmount()
    }

    @objc private func quantityChanged() {
        let raw = Int(quantityField.text ?? "0") ?? 0
        // 对齐到 100 的整数倍（A 股最小单位 100 股）
        quantity = (raw / 100) * 100
        updateAmount()
    }

    @objc private func positionTapped(_ sender: UIButton) {
        selectedPositionIdx = sender.tag
        refreshPositionButtons()
        applyPositionToQuantity()
    }

    private func refreshPositionButtons() {
        for (i, btn) in positionButtons.enumerated() {
            let sel = (i == selectedPositionIdx)
            btn.backgroundColor = sel ? themeRed : btnGray
            btn.setTitleColor(sel ? .white : textPri, for: .normal)
        }
    }

    private func applyPositionToQuantity() {
        guard availableMoney > 0 && currentPrice > 0 else { return }
        let ratios: [Double] = [0.25, 1.0/3, 0.5, 1.0]
        guard selectedPositionIdx >= 0 && selectedPositionIdx < ratios.count else { return }
        let money = availableMoney * ratios[selectedPositionIdx]
        let shares = Int(money / currentPrice / 100) * 100
        quantity = max(shares, 0)
        quantityField.text = quantity > 0 ? "\(quantity)" : ""
        updateAmount()
    }

    private func updateAmount() {
        let total = Double(quantity) * currentPrice
        amountLabel.text = String(format: "¥ %.2f", total)
        buyAmountLabel?.text = String(format: "%.2f", total)

        // 更新手续费
        let fee = total * feePct
        serviceFeeLabel?.text = String(format: "¥%.2f", total == 0 ? currentPrice * feePct : fee)

        // 更新市值
        marketValueLabel?.text = String(format: "¥%.2f", total == 0 ? currentPrice : total)
    }

    // MARK: - 买入
    @objc private func buyTapped() {
        guard quantity > 0 else {
            showToast("请输入买入数量")
            return
        }
        let shareCount = quantity / 100  // 换算成手数（canBuy）
        let priceStr   = String(format: "%.2f", currentPrice)

        let params: [String: Any] = [
            "allcode":  stockAllcode,
            "buyprice": priceStr,
            "canBuy":   shareCount
        ]
        SecureNetworkManager.shared.request(
            api: "/api/deal/addStrategy",
            method: .post,
            params: params
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let res):
                    if let dict = res.decrypted,
                       let code = dict["code"] as? Int, code == 1 {
                        self?.showToast("买入委托成功")
                        self?.navigationController?.popViewController(animated: true)
                    } else {
                        let msg = res.decrypted?["msg"] as? String ?? "买入失败"
                        self?.showToast(msg)
                    }
                case .failure(let err):
                    self?.showToast(err.localizedDescription)
                }
            }
        }
    }

    private func showToast(_ msg: String) {
        Toast.show(msg)
    }

    // MARK: - 数据加载
    private func loadInitialData() {
        loadConfig()
        loadUserAsset()
        loadOrderBook()
    }

    /// 拉取系统配置（手续费）
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
                let feeStr = data["mai_fee"] as? String ?? "0.0001"
                self.feePct = Double(feeStr) ?? 0.0001
                DispatchQueue.main.async {
                    self.serviceFeeLabel?.text = String(format: "¥%.2f", self.currentPrice * self.feePct)
                    // 重建手续费标题
                    let pctDisplay = String(format: "%.2f", self.feePct * 100)
                    // 直接更新金额即可
                    self.updateAmount()
                }
            }
        }
    }

    /// 拉取账户资产（余额 / 可用额度）
    private func loadUserAsset() {
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
                self.accountBalance   = balance
                self.availableMoney   = balance
                DispatchQueue.main.async {
                    self.accountBalanceLabel?.text = String(format: "（账户余额%.2f元）", balance)
                    self.availableLabel?.text      = String(format: "¥%.2f", balance)
                    // 可购买股数
                    if self.currentPrice > 0 {
                        let shares = Int(balance / self.currentPrice / 100) * 100
                        self.canBuySharesLabel?.text = "\(shares)股"
                    }
                }
            }
        }
    }

    /// 拉取五档盘口（EastMoney 行情推送接口）
    private func loadOrderBook() {
        // 构造 secid：sh→1  sz/bj/kc→0
        let prefix = stockAllcode.prefix(2).lowercased()
        let market  = (prefix == "sh") ? "1" : "0"
        let secid   = "\(market).\(stockCode)"

        // 字段：f31-f40 为五档卖价/卖量，f19-f28 为五档买价/买量
        let fields = "f31,f32,f33,f34,f35,f36,f37,f38,f39,f40,f19,f20,f21,f22,f23,f24,f25,f26,f27,f28"
        let urlStr = "https://push2.eastmoney.com/api/qt/stock/get?fltt=2&invt=2&secid=\(secid)&fields=\(fields)"

        guard let url = URL(string: urlStr) else { return }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        req.setValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")

        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dData = dict["data"] as? [String: Any] else { return }

            func v(_ key: String) -> Double { return (dData[key] as? Double) ?? 0 }

            // EastMoney 返回价格已除以 100（fltt=2 模式为实际价格×100，需÷100）
            // f31/f32...f35 = 卖1量/卖1价 ~ 卖5量/卖5价
            // f36 = 卖5量，f37 = 卖5价（需按文档顺序验证，此处按通用约定）
            // 实际字段顺序（fltt=2）:
            //   卖五量=f31 卖五价=f32  卖四量=f33 卖四价=f34
            //   卖三量=f35 卖三价=f36  卖二量=f37 卖二价=f38
            //   卖一量=f39 卖一价=f40
            //   买一量=f19 买一价=f20  买二量=f21 买二价=f22
            //   买三量=f23 买三价=f24  买四量=f25 买四价=f26
            //   买五量=f27 买五价=f28

            let sells: [(String, String)] = [
                (self.fmtVol(v("f31")), self.fmtPrice(v("f32"))),   // 卖5
                (self.fmtVol(v("f33")), self.fmtPrice(v("f34"))),   // 卖4
                (self.fmtVol(v("f35")), self.fmtPrice(v("f36"))),   // 卖3
                (self.fmtVol(v("f37")), self.fmtPrice(v("f38"))),   // 卖2
                (self.fmtVol(v("f39")), self.fmtPrice(v("f40")))    // 卖1
            ]
            let buys: [(String, String)] = [
                (self.fmtVol(v("f19")), self.fmtPrice(v("f20"))),   // 买1
                (self.fmtVol(v("f21")), self.fmtPrice(v("f22"))),   // 买2
                (self.fmtVol(v("f23")), self.fmtPrice(v("f24"))),   // 买3
                (self.fmtVol(v("f25")), self.fmtPrice(v("f26"))),   // 买4
                (self.fmtVol(v("f27")), self.fmtPrice(v("f28")))    // 买5
            ]

            DispatchQueue.main.async {
                self.sellLevels = sells.map { OrderLevel(vol: $0.0, price: $0.1) }
                self.buyLevels  = buys.map  { OrderLevel(vol: $0.0, price: $0.1) }
                self.refreshOrderBoard()
            }
        }.resume()
    }

    private func fmtVol(_ v: Double) -> String {
        if v <= 0 { return "--" }
        let n = Int(v)
        return n >= 10000 ? "\(n / 10000)万" : "\(n)"
    }

    private func fmtPrice(_ v: Double) -> String {
        if v <= 0 { return "--" }
        return String(format: "%.2f", v)
    }

    // MARK: - 工厂方法

    private func makeRow(height: CGFloat, after prev: UIView?) -> UIView {
        let row = UIView()
        row.backgroundColor = .white
        contentView.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        let prevAnchor = prev?.bottomAnchor ?? contentView.topAnchor
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: prevAnchor),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
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

    private func addSepLine(to view: UIView) {
        let line = UIView()
        line.backgroundColor = sepColor
        view.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            line.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            line.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 0.5)
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
        bg.backgroundColor    = themeRed
        bg.layer.cornerRadius = 3
        bg.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bg.widthAnchor.constraint(equalToConstant: 18),
            bg.heightAnchor.constraint(equalToConstant: 18),
            lbl.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
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

// MARK: - UIView then() helper
private extension UIStackView {
    @discardableResult
    func then(_ configure: (UIStackView) -> Void) -> UIStackView {
        configure(self)
        return self
    }
}
