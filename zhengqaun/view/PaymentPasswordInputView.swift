//
//  PaymentPasswordInputView.swift
//  zhengqaun
//
//  支付密码输入通用视图
//

import UIKit

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
