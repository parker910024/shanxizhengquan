//
//  BankSecuritiesTransferViewController.swift
//  zhengqaun
//
//  转出页：严格按 UI 图，仅含导航栏、T+1/可转出、金额输入、全部提现、转出按钮。
//

import UIKit

class BankSecuritiesTransferViewController: ZQViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let orangeRed = UIColor(red: 0.92, green: 0.35, blue: 0.14, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavBar()
        setupScrollView()
        setupContent()
    }

    private func setupNavBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "转出"
        gk_navLineHidden = false
        gk_statusBarStyle = .default
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
        let searchBtn = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: #selector(searchTapped))
        searchBtn.tintColor = Constants.Color.textSecondary
        gk_navRightBarButtonItem = searchBtn
    }

    @objc private func searchTapped() {}

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let navH = Constants.Navigation.totalNavigationHeight
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupContent() {
        let pad: CGFloat = 16
        let redColor = Constants.Color.stockRise

        // 一行两列：T+1资金 0.00（左）| 可转出金额 0.00（右），整块红色
        let fundRow = UIView()
        let t1Label = UILabel()
        t1Label.text = "T+1资金"
        t1Label.font = UIFont.systemFont(ofSize: 15)
        t1Label.textColor = redColor
        fundRow.addSubview(t1Label)
        t1Label.translatesAutoresizingMaskIntoConstraints = false
        let t1Value = UILabel()
        t1Value.text = "0.00"
        t1Value.font = UIFont.systemFont(ofSize: 15)
        t1Value.textColor = redColor
        fundRow.addSubview(t1Value)
        t1Value.translatesAutoresizingMaskIntoConstraints = false
        let outLabel = UILabel()
        outLabel.text = "可转出金额"
        outLabel.font = UIFont.systemFont(ofSize: 15)
        outLabel.textColor = redColor
        fundRow.addSubview(outLabel)
        outLabel.translatesAutoresizingMaskIntoConstraints = false
        let outValue = UILabel()
        outValue.text = "0.00"
        outValue.font = UIFont.systemFont(ofSize: 15)
        outValue.textColor = redColor
        fundRow.addSubview(outValue)
        outValue.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            t1Label.leadingAnchor.constraint(equalTo: fundRow.leadingAnchor),
            t1Label.centerYAnchor.constraint(equalTo: fundRow.centerYAnchor),
            t1Value.leadingAnchor.constraint(equalTo: t1Label.trailingAnchor, constant: 4),
            t1Value.centerYAnchor.constraint(equalTo: fundRow.centerYAnchor),
            outValue.trailingAnchor.constraint(equalTo: fundRow.trailingAnchor),
            outValue.centerYAnchor.constraint(equalTo: fundRow.centerYAnchor),
            outLabel.trailingAnchor.constraint(equalTo: outValue.leadingAnchor, constant: -4),
            outLabel.centerYAnchor.constraint(equalTo: fundRow.centerYAnchor)
        ])
        contentView.addSubview(fundRow)
        fundRow.translatesAutoresizingMaskIntoConstraints = false

        // ¥ + 请输入转出金额
        let inputRow = UIView()
        let yenLbl = UILabel()
        yenLbl.text = "¥"
        yenLbl.font = UIFont.systemFont(ofSize: 20)
        yenLbl.textColor = Constants.Color.textPrimary
        inputRow.addSubview(yenLbl)
        yenLbl.translatesAutoresizingMaskIntoConstraints = false
        let amountField = UITextField()
        amountField.placeholder = "请输入转出金额"
        amountField.font = UIFont.systemFont(ofSize: 18)
        amountField.textColor = Constants.Color.textPrimary
        amountField.keyboardType = .decimalPad
        amountField.attributedPlaceholder = NSAttributedString(string: "请输入转出金额", attributes: [.foregroundColor: Constants.Color.textTertiary])
        inputRow.addSubview(amountField)
        amountField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            yenLbl.leadingAnchor.constraint(equalTo: inputRow.leadingAnchor),
            yenLbl.centerYAnchor.constraint(equalTo: inputRow.centerYAnchor),
            amountField.leadingAnchor.constraint(equalTo: yenLbl.trailingAnchor, constant: 8),
            amountField.trailingAnchor.constraint(equalTo: inputRow.trailingAnchor),
            amountField.centerYAnchor.constraint(equalTo: inputRow.centerYAnchor),
            amountField.heightAnchor.constraint(equalToConstant: 44)
        ])
        contentView.addSubview(inputRow)
        inputRow.translatesAutoresizingMaskIntoConstraints = false

        // 全部提现（红色）
        let withdrawAllBtn = UIButton(type: .system)
        withdrawAllBtn.setTitle("全部提现", for: .normal)
        withdrawAllBtn.setTitleColor(redColor, for: .normal)
        withdrawAllBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        withdrawAllBtn.addTarget(self, action: #selector(withdrawAllTapped), for: .touchUpInside)
        contentView.addSubview(withdrawAllBtn)
        withdrawAllBtn.translatesAutoresizingMaskIntoConstraints = false

        // 转出按钮（橙红底白字）
        let submit = UIButton(type: .system)
        submit.setTitle("转出", for: .normal)
        submit.setTitleColor(.white, for: .normal)
        submit.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        submit.backgroundColor = orangeRed
        submit.layer.cornerRadius = 8
        submit.addTarget(self, action: #selector(transferOutTapped), for: .touchUpInside)
        contentView.addSubview(submit)
        submit.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            fundRow.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            fundRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            fundRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            fundRow.heightAnchor.constraint(equalToConstant: 44),

            inputRow.topAnchor.constraint(equalTo: fundRow.bottomAnchor, constant: 24),
            inputRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            inputRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            inputRow.heightAnchor.constraint(equalToConstant: 48),

            withdrawAllBtn.topAnchor.constraint(equalTo: inputRow.bottomAnchor, constant: 8),
            withdrawAllBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),

            submit.topAnchor.constraint(equalTo: withdrawAllBtn.bottomAnchor, constant: 32),
            submit.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            submit.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            submit.heightAnchor.constraint(equalToConstant: 48),
            submit.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    @objc private func withdrawAllTapped() {}

    @objc private func transferOutTapped() {
        let passwordView = PaymentPasswordView()
        passwordView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passwordView)
        NSLayoutConstraint.activate([
            passwordView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            passwordView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passwordView.topAnchor.constraint(equalTo: view.topAnchor),
            passwordView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - 支付密码输入视图（6位数字 + 自定义数字键盘）
private class PaymentPasswordView: UIView {

    private let dimView = UIView()
    private let containerView = UIView()
    private let titleLabel = UILabel()
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
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 12
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true

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
        let numbers = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["取消", "0", "⌫"]
        ]
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.removeFromSuperview()
            }
        }
    }

    @objc private func keyTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        switch title {
        case "取消":
            removeFromSuperview()
        case "⌫":
            if !password.isEmpty { password.removeLast() }
        default:
            if password.count < 6, Int(title) != nil { password.append(title) }
        }
    }
}
