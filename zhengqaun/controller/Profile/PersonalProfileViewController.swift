//
//  PersonalProfileViewController.swift
//  zhengqaun
//
//  个人资料页：头像、手机号、账号、登录密码/交易密码/系统版本、退出登录
//

import UIKit

class PersonalProfileViewController: ZQViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let avatarContainer = UIView()
    private let avatarImageView = UIImageView()
    private let avatarHintLabel = UILabel()

    private let listStack = UIStackView()
    private let separatorColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0)
    private let logoutButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }
    
    

    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "个人资料"
        gk_navLineHidden = false
        gk_statusBarStyle = .default
        gk_backStyle = .black
    }

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // 头像区域
        avatarContainer.backgroundColor = .clear
        contentView.addSubview(avatarContainer)
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false

        avatarImageView.image = UIImage.init(named: "logoIcon")
        avatarImageView.layer.cornerRadius = 40
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.isUserInteractionEnabled = true
        avatarContainer.addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        avatarHintLabel.text = "点击更换头像"
        avatarHintLabel.font = UIFont.systemFont(ofSize: 14)
        avatarHintLabel.textColor = Constants.Color.textTertiary
        avatarContainer.addSubview(avatarHintLabel)
        avatarHintLabel.translatesAutoresizingMaskIntoConstraints = false

        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatarContainer.addGestureRecognizer(avatarTap)
        avatarContainer.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            avatarContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            avatarContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatarImageView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            avatarHintLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            avatarHintLabel.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarHintLabel.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor)
        ])

        // 信息列表：手机号、账号、登录密码、交易密码、系统版本
        listStack.axis = .vertical
        listStack.spacing = 0
        listStack.backgroundColor = .white
        contentView.addSubview(listStack)
        listStack.translatesAutoresizingMaskIntoConstraints = false

        let rowHeight: CGFloat = 52
        let phone = UserAuthManager.shared.currentPhone ?? "1877777777"
        let account = UserAuthManager.shared.userID.isEmpty ? "T008754664" : "T\(UserAuthManager.shared.userID)"
        let items: [(String, String?, Bool)] = [
            ("手机号", maskPhone(phone), false),
            ("账号", account, false),
            ("交易密码", "修改>", true),
            ("登录密码", "修改>", true),
            ("系统版本", "V25.1.1>", true)
        ]
        for (idx, item) in items.enumerated() {
            let row = makeInfoRow(title: item.0, value: item.1, showArrow: item.2, tag: idx)
            listStack.addArrangedSubview(row)
            row.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true
            if idx < items.count - 1 {
                let sep = UIView()
                sep.backgroundColor = separatorColor
                listStack.addArrangedSubview(sep)
                sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
            }
        }

        NSLayoutConstraint.activate([
            listStack.topAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 32),
            listStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            listStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        // 退出登录
        logoutButton.setTitle("退出登录", for: .normal)
        logoutButton.setTitleColor(.red, for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        contentView.addSubview(logoutButton)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            logoutButton.topAnchor.constraint(equalTo: listStack.bottomAnchor, constant: 40),
            logoutButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }

    private func makeInfoRow(title: String, value: String?, showArrow: Bool, tag: Int) -> UIView {
        let row = UIView()
        row.backgroundColor = .white
        row.tag = tag

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = Constants.Color.textPrimary
        row.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value ?? ""
        valueLabel.font = UIFont.systemFont(ofSize: 15)
        valueLabel.textColor = showArrow ? Constants.Color.textSecondary : Constants.Color.textPrimary
        valueLabel.tag = 100 + tag
        row.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12)
        ])

        if showArrow {
            let tap = UITapGestureRecognizer(target: self, action: #selector(infoRowTapped(_:)))
            row.addGestureRecognizer(tap)
            row.isUserInteractionEnabled = true
        }
        return row
    }

    private func maskPhone(_ phone: String) -> String {
        guard phone.count >= 11 else { return phone }
        let start = phone.prefix(3)
        let end = phone.suffix(4)
        return "\(start)****\(end)"
    }

    @objc private func avatarTapped() {
        // TODO: 选择/拍照更换头像
    }

    @objc private func infoRowTapped(_ g: UITapGestureRecognizer) {
        guard let row = g.view else { return }
        switch row.tag {
        case 2:
            let vc = TransactionPasswordViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 3:
            let vc = LoginPasswordViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
            break
        case 4:
            // 系统版本 -> 关于/版本说明（若有）
            break
        default:
            break
        }
    }

    @objc private func logoutTapped() {
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
    }
}
