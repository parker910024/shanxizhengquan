//
//  BankTransferIntroViewController.swift
//  zhengqaun
//
//  银证转账页：双 tab（银证转入 / 银证转出），严格按 UI 图实现
//

import UIKit

class BankTransferIntroViewController: ZQViewController {

    // MARK: - 颜色常量
    private let themeBlue  = Constants.Color.themeBlue
    private let textPri    = Constants.Color.textPrimary
    private let textSec    = Constants.Color.textSecondary
    private let textTer    = Constants.Color.textTertiary
    private let redColor   = Constants.Color.stockRise
    private let orangeRed  = UIColor(red: 0.92, green: 0.35, blue: 0.14, alpha: 1.0)
    private let sepColor   = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)

    // MARK: - Tab
    private var tabInBtn  = UIButton()
    private var tabOutBtn = UIButton()
    private var tabIndicator = UIView()
    private var tabIndicatorLeading: NSLayoutConstraint!

    // MARK: - 两个内容容器
    private let transferInView  = UIScrollView()
    private let transferOutView = UIScrollView()
    private let transferInContent  = UIView()
    private let transferOutContent = UIView()

    // MARK: - 转入数据
    private var channelList: [[String: Any]] = []
    private var introText: String = ""
    private let channelStack = UIStackView()

    // MARK: - 转出数据
    private let t1ValueLabel     = UILabel()
    private let outValueLabel    = UILabel()
    private let bankCardLabel    = UILabel()
    private let amountField      = UITextField()
    private var availableBalance: Double = 0
    private var freezeProfit: Double = 0
    private let historyStack     = UIStackView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavBar()
        setupTabs()
        setupTransferInView()
        setupTransferOutView()
        switchToTab(0)
        loadTransferInData()
        loadTransferOutData()
    }

    // MARK: - 导航栏（蓝色）
    private func setupNavBar() {
        gk_navBackgroundColor = themeBlue
        gk_navTintColor       = .white
        gk_navTitleFont       = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor      = .white
        gk_navTitle           = "银证转账"
        gk_navLineHidden      = true
        gk_backStyle          = .white
    }

    // MARK: - Tab 栏
    private func setupTabs() {
        let tabBar = UIView()
        tabBar.backgroundColor = .white
        view.addSubview(tabBar)
        tabBar.translatesAutoresizingMaskIntoConstraints = false

        tabInBtn  = makeTabButton(title: "银证转入", tag: 0)
        tabOutBtn = makeTabButton(title: "银证转出", tag: 1)

        tabBar.addSubview(tabInBtn)
        tabBar.addSubview(tabOutBtn)
        tabInBtn.translatesAutoresizingMaskIntoConstraints = false
        tabOutBtn.translatesAutoresizingMaskIntoConstraints = false

        // 指示线
        tabIndicator.backgroundColor = themeBlue
        tabIndicator.layer.cornerRadius = 1.5
        tabBar.addSubview(tabIndicator)
        tabIndicator.translatesAutoresizingMaskIntoConstraints = false

        // 底部分隔线
        let sep = UIView()
        sep.backgroundColor = sepColor
        tabBar.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false

        let navH = Constants.Navigation.totalNavigationHeight
        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: 48),

            tabInBtn.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            tabInBtn.topAnchor.constraint(equalTo: tabBar.topAnchor),
            tabInBtn.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
            tabInBtn.widthAnchor.constraint(equalTo: tabBar.widthAnchor, multiplier: 0.5),

            tabOutBtn.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            tabOutBtn.topAnchor.constraint(equalTo: tabBar.topAnchor),
            tabOutBtn.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
            tabOutBtn.widthAnchor.constraint(equalTo: tabBar.widthAnchor, multiplier: 0.5),

            sep.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        tabIndicatorLeading = tabIndicator.centerXAnchor.constraint(equalTo: tabInBtn.centerXAnchor)
        NSLayoutConstraint.activate([
            tabIndicatorLeading,
            tabIndicator.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: -1),
            tabIndicator.widthAnchor.constraint(equalToConstant: 40),
            tabIndicator.heightAnchor.constraint(equalToConstant: 3)
        ])

        // 两个 ScrollView 共用同一区域
        let contentTop = navH + 48
        for sv in [transferInView, transferOutView] {
            sv.showsVerticalScrollIndicator = false
            view.addSubview(sv)
            sv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                sv.topAnchor.constraint(equalTo: view.topAnchor, constant: contentTop),
                sv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                sv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                sv.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }

        // 添加 contentView
        transferInView.addSubview(transferInContent)
        transferOutView.addSubview(transferOutContent)
        for (cv, sv) in [(transferInContent, transferInView), (transferOutContent, transferOutView)] {
            cv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                cv.topAnchor.constraint(equalTo: sv.topAnchor),
                cv.leadingAnchor.constraint(equalTo: sv.leadingAnchor),
                cv.trailingAnchor.constraint(equalTo: sv.trailingAnchor),
                cv.bottomAnchor.constraint(equalTo: sv.bottomAnchor),
                cv.widthAnchor.constraint(equalTo: sv.widthAnchor)
            ])
        }
    }

    private func makeTabButton(title: String, tag: Int) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.tag = tag
        btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func tabTapped(_ sender: UIButton) {
        switchToTab(sender.tag)
    }

    private func switchToTab(_ index: Int) {
        let isIn = (index == 0)
        transferInView.isHidden  = !isIn
        transferOutView.isHidden = isIn

        tabInBtn.setTitleColor(isIn ? themeBlue : textSec, for: .normal)
        tabOutBtn.setTitleColor(isIn ? textSec : themeBlue, for: .normal)
        tabInBtn.titleLabel?.font  = UIFont.systemFont(ofSize: 15, weight: isIn  ? .bold : .medium)
        tabOutBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: isIn ? .medium : .bold)

        tabIndicatorLeading.isActive = false
        tabIndicatorLeading = tabIndicator.centerXAnchor.constraint(
            equalTo: isIn ? tabInBtn.centerXAnchor : tabOutBtn.centerXAnchor
        )
        tabIndicatorLeading.isActive = true
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }

    // MARK: - 银证转入 Tab UI
    private func setupTransferInView() {
        let pad: CGFloat = 16

        // 通道列表容器（带边框圆角）
        let listContainer = UIView()
        listContainer.layer.borderWidth = 1
        listContainer.layer.borderColor = sepColor.cgColor
        listContainer.layer.cornerRadius = 8
        listContainer.clipsToBounds = true
        transferInContent.addSubview(listContainer)
        listContainer.translatesAutoresizingMaskIntoConstraints = false

        channelStack.axis = .vertical
        channelStack.spacing = 0
        listContainer.addSubview(channelStack)
        channelStack.translatesAutoresizingMaskIntoConstraints = false

        // 加载中占位
        let loadingLabel = UILabel()
        loadingLabel.text = "加载中..."
        loadingLabel.font = UIFont.systemFont(ofSize: 14)
        loadingLabel.textColor = textTer
        loadingLabel.textAlignment = .center
        channelStack.addArrangedSubview(loadingLabel)
        NSLayoutConstraint.activate([
            loadingLabel.heightAnchor.constraint(equalToConstant: 44)
        ])

        // 简介说明标题
        let introTitle = UILabel()
        introTitle.text = "简介说明"
        introTitle.font = UIFont.boldSystemFont(ofSize: 18)
        introTitle.textColor = orangeRed
        transferInContent.addSubview(introTitle)
        introTitle.translatesAutoresizingMaskIntoConstraints = false

        // 简介说明正文
        let introLabel = UILabel()
        introLabel.text = "由于该账户受证券监管部门监督，根据证监部门2021反洗黑钱金融条例，为了避免出现不法分子黑钱投入机构单元账户，导致三方存管账户全面冻结带来的损失，因采取更高效审查机制支付通道，用户需通过三方存管和银行之间搭建的支付通道风控机制，进行出入金交易，三方存管账户进行一道关卡过滤黑钱！"
        introLabel.font = UIFont.systemFont(ofSize: 14)
        introLabel.textColor = orangeRed
        introLabel.numberOfLines = 0
        introLabel.tag = 999
        transferInContent.addSubview(introLabel)
        introLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            listContainer.topAnchor.constraint(equalTo: transferInContent.topAnchor, constant: 16),
            listContainer.leadingAnchor.constraint(equalTo: transferInContent.leadingAnchor, constant: pad),
            listContainer.trailingAnchor.constraint(equalTo: transferInContent.trailingAnchor, constant: -pad),

            channelStack.topAnchor.constraint(equalTo: listContainer.topAnchor),
            channelStack.leadingAnchor.constraint(equalTo: listContainer.leadingAnchor),
            channelStack.trailingAnchor.constraint(equalTo: listContainer.trailingAnchor),
            channelStack.bottomAnchor.constraint(equalTo: listContainer.bottomAnchor),

            introTitle.topAnchor.constraint(equalTo: listContainer.bottomAnchor, constant: 24),
            introTitle.leadingAnchor.constraint(equalTo: transferInContent.leadingAnchor, constant: pad),
            introTitle.trailingAnchor.constraint(equalTo: transferInContent.trailingAnchor, constant: -pad),

            introLabel.topAnchor.constraint(equalTo: introTitle.bottomAnchor, constant: 12),
            introLabel.leadingAnchor.constraint(equalTo: transferInContent.leadingAnchor, constant: pad),
            introLabel.trailingAnchor.constraint(equalTo: transferInContent.trailingAnchor, constant: -pad),
            introLabel.bottomAnchor.constraint(equalTo: transferInContent.bottomAnchor, constant: -32)
        ])
    }

    // MARK: - 银证转出 Tab UI
    private func setupTransferOutView() {
        let pad: CGFloat = 16

        // T+1资金
        let t1Row = makeInfoRow(title: "T+1资金", valueLabel: t1ValueLabel, valueColor: redColor)
        // 可转出金额
        let outRow = makeInfoRow(title: "可转出金额", valueLabel: outValueLabel, valueColor: textPri)
        // 银行卡
        let bankRow = makeBankCardRow()
        // 转出金额输入
        let inputRow = makeAmountInputRow()
        // 最小转出金额提示
        let hintLabel = UILabel()
        hintLabel.text = "最小转出金额100"
        hintLabel.font = UIFont.systemFont(ofSize: 12)
        hintLabel.textColor = textTer
        transferOutContent.addSubview(hintLabel)
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        // 转出按钮
        let submitBtn = UIButton(type: .system)
        submitBtn.setTitle("转出", for: .normal)
        submitBtn.setTitleColor(.white, for: .normal)
        submitBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        submitBtn.backgroundColor = themeBlue
        submitBtn.layer.cornerRadius = 8
        submitBtn.addTarget(self, action: #selector(transferOutTapped), for: .touchUpInside)
        transferOutContent.addSubview(submitBtn)
        submitBtn.translatesAutoresizingMaskIntoConstraints = false

        // 转出历史记录
        historyStack.axis = .vertical
        historyStack.spacing = 0
        transferOutContent.addSubview(historyStack)
        historyStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            t1Row.topAnchor.constraint(equalTo: transferOutContent.topAnchor, constant: 16),
            t1Row.leadingAnchor.constraint(equalTo: transferOutContent.leadingAnchor, constant: pad),
            t1Row.trailingAnchor.constraint(equalTo: transferOutContent.trailingAnchor, constant: -pad),
            t1Row.heightAnchor.constraint(equalToConstant: 44),

            outRow.topAnchor.constraint(equalTo: t1Row.bottomAnchor),
            outRow.leadingAnchor.constraint(equalTo: transferOutContent.leadingAnchor, constant: pad),
            outRow.trailingAnchor.constraint(equalTo: transferOutContent.trailingAnchor, constant: -pad),
            outRow.heightAnchor.constraint(equalToConstant: 44),

            bankRow.topAnchor.constraint(equalTo: outRow.bottomAnchor),
            bankRow.leadingAnchor.constraint(equalTo: transferOutContent.leadingAnchor, constant: pad),
            bankRow.trailingAnchor.constraint(equalTo: transferOutContent.trailingAnchor, constant: -pad),
            bankRow.heightAnchor.constraint(equalToConstant: 44),

            inputRow.topAnchor.constraint(equalTo: bankRow.bottomAnchor),
            inputRow.leadingAnchor.constraint(equalTo: transferOutContent.leadingAnchor, constant: pad),
            inputRow.trailingAnchor.constraint(equalTo: transferOutContent.trailingAnchor, constant: -pad),
            inputRow.heightAnchor.constraint(equalToConstant: 48),

            hintLabel.topAnchor.constraint(equalTo: inputRow.bottomAnchor, constant: 4),
            hintLabel.leadingAnchor.constraint(equalTo: transferOutContent.leadingAnchor, constant: pad),

            submitBtn.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 20),
            submitBtn.leadingAnchor.constraint(equalTo: transferOutContent.leadingAnchor, constant: pad),
            submitBtn.trailingAnchor.constraint(equalTo: transferOutContent.trailingAnchor, constant: -pad),
            submitBtn.heightAnchor.constraint(equalToConstant: 48),

            historyStack.topAnchor.constraint(equalTo: submitBtn.bottomAnchor, constant: 24),
            historyStack.leadingAnchor.constraint(equalTo: transferOutContent.leadingAnchor, constant: pad),
            historyStack.trailingAnchor.constraint(equalTo: transferOutContent.trailingAnchor, constant: -pad),
            historyStack.bottomAnchor.constraint(lessThanOrEqualTo: transferOutContent.bottomAnchor, constant: -20)
        ])
    }

    // MARK: - 转出 UI 辅助

    private func makeInfoRow(title: String, valueLabel: UILabel, valueColor: UIColor) -> UIView {
        let row = UIView()
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = UIFont.systemFont(ofSize: 15)
        titleLbl.textColor = textPri
        row.addSubview(titleLbl)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.text = "0.00"
        valueLabel.font = UIFont.systemFont(ofSize: 15)
        valueLabel.textColor = valueColor
        valueLabel.textAlignment = .right
        row.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        transferOutContent.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    private func makeBankCardRow() -> UIView {
        let row = UIView()
        let titleLbl = UILabel()
        titleLbl.text = "银行卡"
        titleLbl.font = UIFont.systemFont(ofSize: 15)
        titleLbl.textColor = textPri
        row.addSubview(titleLbl)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        bankCardLabel.text = "加载中..."
        bankCardLabel.font = UIFont.systemFont(ofSize: 15)
        bankCardLabel.textColor = textPri
        row.addSubview(bankCardLabel)
        bankCardLabel.translatesAutoresizingMaskIntoConstraints = false

        let arrow = UIImageView(image: UIImage(named: "up_common_more_arrow") ?? UIImage(systemName: "chevron.right"))
        arrow.tintColor = textTer
        arrow.contentMode = .scaleAspectFit
        row.addSubview(arrow)
        arrow.translatesAutoresizingMaskIntoConstraints = false

        transferOutContent.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            arrow.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            arrow.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 14),
            arrow.heightAnchor.constraint(equalToConstant: 14),
            bankCardLabel.trailingAnchor.constraint(equalTo: arrow.leadingAnchor, constant: -4),
            bankCardLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    private func makeAmountInputRow() -> UIView {
        let row = UIView()
        let titleLbl = UILabel()
        titleLbl.text = "转出金额"
        titleLbl.font = UIFont.systemFont(ofSize: 15)
        titleLbl.textColor = textPri
        row.addSubview(titleLbl)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        amountField.placeholder = "转出金额"
        amountField.font = UIFont.systemFont(ofSize: 15)
        amountField.textColor = textPri
        amountField.textAlignment = .right
        amountField.keyboardType = .decimalPad
        amountField.attributedPlaceholder = NSAttributedString(
            string: "转出金额",
            attributes: [.foregroundColor: textTer]
        )
        row.addSubview(amountField)
        amountField.translatesAutoresizingMaskIntoConstraints = false

        let yenLbl = UILabel()
        yenLbl.text = "¥"
        yenLbl.font = UIFont.systemFont(ofSize: 15)
        yenLbl.textColor = textPri
        row.addSubview(yenLbl)
        yenLbl.translatesAutoresizingMaskIntoConstraints = false

        // 底部分隔线
        let sep = UIView()
        sep.backgroundColor = sepColor
        row.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false

        transferOutContent.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            yenLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            yenLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            amountField.trailingAnchor.constraint(equalTo: yenLbl.leadingAnchor, constant: -4),
            amountField.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            amountField.leadingAnchor.constraint(equalTo: titleLbl.trailingAnchor, constant: 12),
            sep.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        return row
    }

    // MARK: - 通道行（银证转入列表）
    private func makeChannelRow(name: String, minAmount: Int, maxAmount: Int, index: Int) -> UIView {
        let row = UIView()
        row.tag = index

        // 蓝色小图标
        let icon = UIImageView(image: UIImage(systemName: "rectangle.fill"))
        icon.tintColor = themeBlue
        icon.contentMode = .scaleAspectFit
        row.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "\(name)(银证转入金额\(minAmount)-\(maxAmount))"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = textPri
        label.numberOfLines = 1
        row.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        // 底部分隔线
        let sep = UIView()
        sep.backgroundColor = sepColor
        row.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
            icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            row.heightAnchor.constraint(equalToConstant: 44),
            sep.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
            sep.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            sep.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        // 点击跳转银证账户
        let tap = UITapGestureRecognizer(target: self, action: #selector(channelRowTapped(_:)))
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true

        return row
    }

    @objc private func channelRowTapped(_ g: UITapGestureRecognizer) {
        guard let row = g.view, row.tag >= 0, row.tag < channelList.count else { return }
        let channel = channelList[row.tag]
        let vc = BankTransferInViewController()
        // 传入通道信息
        vc.sysbankId = channel["id"] as? Int
        vc.minLimit = Double("\(channel["minlow"] ?? 100)") ?? 100
        vc.maxLimit = Double("\(channel["maxhigh"] ?? 0)") ?? 0
        vc.channelName = channel["tdname"] as? String ?? "银证转入"
        vc.yzmima = channel["yzmima"] as? String ?? ""
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 转出历史记录行
    private func makeHistoryRow(typeName: String, statusName: String, statusColor: UIColor, amount: String, time: String) -> UIView {
        let row = UIView()

        let titleLbl = UILabel()
        titleLbl.text = typeName
        titleLbl.font = UIFont.boldSystemFont(ofSize: 15)
        titleLbl.textColor = textPri
        row.addSubview(titleLbl)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let statusLbl = UILabel()
        statusLbl.text = statusName
        statusLbl.font = UIFont.systemFont(ofSize: 12)
        statusLbl.textColor = statusColor
        row.addSubview(statusLbl)
        statusLbl.translatesAutoresizingMaskIntoConstraints = false

        let timeLbl = UILabel()
        timeLbl.text = time
        timeLbl.font = UIFont.systemFont(ofSize: 12)
        timeLbl.textColor = textTer
        row.addSubview(timeLbl)
        timeLbl.translatesAutoresizingMaskIntoConstraints = false

        let amountLbl = UILabel()
        amountLbl.text = amount
        amountLbl.font = UIFont.systemFont(ofSize: 16)
        amountLbl.textColor = orangeRed
        amountLbl.textAlignment = .right
        row.addSubview(amountLbl)
        amountLbl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            titleLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),

            statusLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 4),
            statusLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),

            timeLbl.topAnchor.constraint(equalTo: statusLbl.bottomAnchor, constant: 2),
            timeLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            timeLbl.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12),

            amountLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            amountLbl.topAnchor.constraint(equalTo: row.topAnchor, constant: 12)
        ])

        return row
    }

    // MARK: - 加载银证转入数据
    private func loadTransferInData() {
        SecureNetworkManager.shared.request(
            api: "/api/user/capitalLog",
            method: .get,
            params: ["type": "0"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any] else { return }

                let bankList = data["bank_list"] as? [[String: Any]] ?? []
                let yhxy = data["yhxy"] as? String ?? ""

                self.channelList = bankList
                self.introText = yhxy

                DispatchQueue.main.async {
                    self.refreshChannelList()
                    // 如果 API 返回了简介说明，更新
                    if !yhxy.isEmpty, let introLbl = self.transferInContent.viewWithTag(999) as? UILabel {
                        // 去除 HTML 标签，纯文本显示
                        let plainText = yhxy.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        if !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            introLbl.text = plainText
                        }
                    }
                }
            case .failure(_): break
            }
        }
    }

    private func refreshChannelList() {
        // 清空旧内容
        channelStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if channelList.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "暂无可用通道"
            emptyLabel.font = UIFont.systemFont(ofSize: 14)
            emptyLabel.textColor = textTer
            emptyLabel.textAlignment = .center
            channelStack.addArrangedSubview(emptyLabel)
            NSLayoutConstraint.activate([emptyLabel.heightAnchor.constraint(equalToConstant: 44)])
            return
        }

        for (i, channel) in channelList.enumerated() {
            let name = channel["tdname"] as? String ?? "银证转入"
            let minLow = channel["minlow"] as? Int ?? Int(Double("\(channel["minlow"] ?? 100)") ?? 100)
            let maxHigh = channel["maxhigh"] as? Int ?? Int(Double("\(channel["maxhigh"] ?? 0)") ?? 0)
            let row = makeChannelRow(name: name, minAmount: minLow, maxAmount: maxHigh, index: i)
            channelStack.addArrangedSubview(row)
        }
    }

    // MARK: - 加载银证转出数据
    private func loadTransferOutData() {
        // 加载资金数据
        SecureNetworkManager.shared.request(
            api: "/api/user/capitalLog",
            method: .get,
            params: ["type": "1"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any] else { return }

                if let userInfo = data["userInfo"] as? [String: Any] {
                    let balance = userInfo["balance"] as? Double ?? 0
                    let freeze = userInfo["freeze_profit"] as? Double ?? 0
                    self.availableBalance = balance
                    self.freezeProfit = freeze

                    DispatchQueue.main.async {
                        self.t1ValueLabel.text = String(format: "%.2f", balance + freeze)
                        self.outValueLabel.text = String(format: "%.2f", balance)
                    }
                }

                // 转出历史记录
                if let list = data["list"] as? [[String: Any]] {
                    DispatchQueue.main.async {
                        self.refreshHistory(list)
                    }
                }

            case .failure(_): break
            }
        }

        // 加载银行卡
        SecureNetworkManager.shared.request(
            api: "/api/user/accountLst",
            method: .post,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let listObj = data["list"] as? [String: Any],
                      let cards = listObj["data"] as? [[String: Any]],
                      let first = cards.first,
                      let account = first["account"] as? String else {
                    DispatchQueue.main.async {
                        self.bankCardLabel.text = "未绑定"
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.bankCardLabel.text = account
                }
            case .failure(_):
                DispatchQueue.main.async {
                    self.bankCardLabel.text = "加载失败"
                }
            }
        }
    }

    private func refreshHistory(_ list: [[String: Any]]) {
        historyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in list {
            let typeName = item["pay_type_name"] as? String ?? "银证转出"
            let statusName = item["is_pay_name"] as? String ?? ""
            let money = item["money"] as? Double ?? 0
            let timestamp = item["createtime"] as? Int ?? 0
            let txtColor = item["txtcolor"] as? String ?? "blue"
            let reject = item["reject"] as? String ?? ""

            // 时间格式化
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timeStr = fmt.string(from: date)

            // 状态颜色
            var sColor: UIColor = themeBlue
            if txtColor == "red" { sColor = redColor }
            else if txtColor == "green" { sColor = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1) }

            // 状态文字（含驳回原因）
            var statusText = statusName
            if !reject.isEmpty { statusText += ":\(reject)" }

            let amountStr = "-\(Int(money))"
            let row = makeHistoryRow(typeName: typeName, statusName: statusText, statusColor: sColor, amount: amountStr, time: timeStr)
            historyStack.addArrangedSubview(row)
        }
    }

    // MARK: - 提交转出
    @objc private func transferOutTapped() {
        guard let text = amountField.text, let amount = Double(text), amount > 0 else {
            Toast.show("请输入有效的转出金额")
            return
        }
        if amount > availableBalance {
            Toast.show("转出金额不能超过可转出余额")
            return
        }
        if amount < 100 {
            Toast.show("最小转出金额为100")
            return
        }

        let passwordView = PaymentPasswordInputView()
        passwordView.onComplete = { [weak self] password in
            self?.submitWithdraw(amount: amount, password: password)
        }
        passwordView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passwordView)
        NSLayoutConstraint.activate([
            passwordView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            passwordView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passwordView.topAnchor.constraint(equalTo: view.topAnchor),
            passwordView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func submitWithdraw(amount: Double, password: String) {
        SecureNetworkManager.shared.request(
            api: "/api/user/sendCode",
            method: .post,
            params: ["account_id": "1", "money": "\(amount)", "pass": password]
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let res):
                    if let dict = res.decrypted, let code = dict["code"] as? Int, code == 1 {
                        Toast.show("转出申请已提交")
                        self.amountField.text = ""
                        self.loadTransferOutData()
                    } else {
                        let msg = res.decrypted?["msg"] as? String ?? "转出失败"
                        Toast.show(msg)
                    }
                case .failure(let error):
                    Toast.show("请求失败: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - 支付密码输入视图
class PaymentPasswordInputView: UIView {

    private let dimView = UIView()
    private let containerView = UIView()
    var onComplete: ((String) -> Void)?
    private var dotLabels: [UILabel] = []
    private var password: String = "" {
        didSet { updateDots() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        addSubview(dimView)
        dimView.translatesAutoresizingMaskIntoConstraints = false

        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 360)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "请输入支付密码"
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = Constants.Color.textPrimary
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let dotsStack = UIStackView()
        dotsStack.axis = .horizontal
        dotsStack.alignment = .center
        dotsStack.distribution = .fillEqually
        dotsStack.spacing = 18
        containerView.addSubview(dotsStack)
        dotsStack.translatesAutoresizingMaskIntoConstraints = false

        for _ in 0..<6 {
            let underline = UIView()
            underline.backgroundColor = Constants.Color.separator
            underline.heightAnchor.constraint(equalToConstant: 2).isActive = true
            let dot = UILabel()
            dot.text = ""
            dot.font = UIFont.systemFont(ofSize: 22)
            dot.textAlignment = .center
            dot.textColor = Constants.Color.textPrimary
            let wrapper = UIStackView(arrangedSubviews: [dot, underline])
            wrapper.axis = .vertical
            wrapper.alignment = .fill
            wrapper.distribution = .fill
            wrapper.spacing = 10
            dotsStack.addArrangedSubview(wrapper)
            dotLabels.append(dot)
        }

        let keypad = createKeypad()
        containerView.addSubview(keypad)
        keypad.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dotsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            dotsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 50),
            dotsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50),
            keypad.topAnchor.constraint(equalTo: dotsStack.bottomAnchor, constant: 32),
            keypad.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            keypad.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            keypad.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func createKeypad() -> UIView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.distribution = .fillEqually
        grid.spacing = 0
        let numbers = [["1","2","3"],["4","5","6"],["7","8","9"],["取消","0","⌫"]]
        for row in numbers {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 0
            for title in row {
                let btn = UIButton(type: .system)
                btn.setTitle(title, for: .normal)
                btn.titleLabel?.font = UIFont.systemFont(ofSize: 24)
                btn.setTitleColor(Constants.Color.textPrimary, for: .normal)
                btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
            }
            grid.addArrangedSubview(rowStack)
        }
        return grid
    }

    private func updateDots() {
        for (i, label) in dotLabels.enumerated() {
            label.text = i < password.count ? "•" : ""
        }
        if password.count == 6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                let pwd = self.password
                self.removeFromSuperview()
                self.onComplete?(pwd)
            }
        }
    }

    @objc private func keyTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        switch title {
        case "取消": removeFromSuperview()
        case "⌫": if !password.isEmpty { password.removeLast() }
        default: if password.count < 6, Int(title) != nil { password.append(title) }
        }
    }
}
