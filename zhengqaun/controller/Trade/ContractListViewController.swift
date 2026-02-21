//
//  ContractListViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

class ContractListViewController: ZQViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var contracts: [Contract] = []
    private var tableViewTopConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadData()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // 在布局前按 GK 导航栏实际高度更新，表头才能完整露在导航栏下方
        let navH = gk_navigationBar.frame.maxY
        if navH > 0 {
            tableViewTopConstraint?.constant = navH
        }
    }

    private func setupNavigationBar() {
        gk_navTitle = "线上合同"
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navLineHidden = false
        gk_statusBarStyle = .default
        gk_backStyle = .black

    }

    @objc private func searchTapped() {
        // 可扩展：合同搜索
    }

    private func setupUI() {
        view.backgroundColor = .white

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.tableHeaderView = makeTableHeader()
        tableView.register(ContractCell.self, forCellReuseIdentifier: "ContractCell")
        view.insertSubview(tableView, belowSubview: gk_navigationBar)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // 刘海屏约 103，非刘海约 88；若 safeArea 未就绪取 100 避免表头被挡
        let topOffset = max(Constants.Navigation.contentTopBelowGKNavBar, 100)
        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topOffset)
        NSLayoutConstraint.activate([
            tableViewTopConstraint!,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func makeTableHeader() -> UIView {
        let header = UIView()
        header.backgroundColor = .white
        let margin: CGFloat = 16
        let h: CGFloat = 44

        let nameLabel = UILabel()
        nameLabel.text = "合同名称"
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = Constants.Color.textSecondary
        header.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let statusLabel = UILabel()
        statusLabel.text = "合同状态"
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = Constants.Color.textSecondary
        statusLabel.textAlignment = .center
        header.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        let actionLabel = UILabel()
        actionLabel.text = "操作"
        actionLabel.font = UIFont.systemFont(ofSize: 14)
        actionLabel.textColor = Constants.Color.textSecondary
        actionLabel.textAlignment = .right
        header.addSubview(actionLabel)
        actionLabel.translatesAutoresizingMaskIntoConstraints = false

        let sep = UIView()
        sep.backgroundColor = Constants.Color.separator
        header.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false

        let w = Constants.Screen.width
        let col1End = w * 0.50
        let col2End = w * 0.78
        NSLayoutConstraint.activate([
            header.widthAnchor.constraint(equalToConstant: w),
            header.heightAnchor.constraint(equalToConstant: h),
            nameLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: margin),
            nameLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            statusLabel.centerXAnchor.constraint(equalTo: header.leadingAnchor, constant: (col1End + col2End) / 2),
            statusLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            actionLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -margin),
            actionLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            sep.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: margin),
            sep.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -margin),
            sep.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        // 必须给 tableHeaderView 明确 frame，否则 UITableView 可能按 (0,0,0,0) 处理导致表头不显示
        header.frame = CGRect(x: 0, y: 0, width: w, height: h)
        return header
    }

    private func loadData() {
        contracts = Contract.mockContracts()
        tableView.reloadData()
    }

    func openContractDetail(_ contract: Contract) {
        let vc = ContractDetailViewController()
        vc.contract = contract
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    /// 点击签订时弹出「合同信息」弹框，确认后进入合同详情
    func showContractSignPopup(for contract: Contract) {
        let popup = ContractSignInfoViewController()
        popup.contract = contract
        popup.modalPresentationStyle = .overFullScreen
        popup.modalTransitionStyle = .crossDissolve
        popup.onConfirm = { [weak self] _, _, _ in
            self?.openContractDetail(contract)
        }
        present(popup, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ContractListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contracts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContractCell", for: indexPath) as! ContractCell
        let contract = contracts[indexPath.row]
        cell.configure(with: contract) { [weak self] in
            self?.showContractSignPopup(for: contract)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ContractListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openContractDetail(contracts[indexPath.row])
    }
}

// MARK: - ContractCell（表格式：合同名称 | 合同状态 | 操作）
class ContractCell: UITableViewCell {

    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let signButton = UIButton(type: .system)
    private let separator = UIView()

    var onSignTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white

        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.textColor = Constants.Color.textPrimary
        nameLabel.numberOfLines = 2
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textAlignment = .center
        contentView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        signButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        signButton.setTitle("签订", for: .normal)
        signButton.setTitleColor(.white, for: .normal)
        signButton.backgroundColor = Constants.Color.stockRise
        signButton.layer.cornerRadius = 4
        signButton.addTarget(self, action: #selector(signButtonTapped), for: .touchUpInside)
        contentView.addSubview(signButton)
        signButton.translatesAutoresizingMaskIntoConstraints = false

        separator.backgroundColor = Constants.Color.separator
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        let margin: CGFloat = 16
        let w = Constants.Screen.width
        let col1End = w * 0.50
        let col2End = w * 0.78
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.leadingAnchor, constant: col1End - 8),

            statusLabel.centerXAnchor.constraint(equalTo: contentView.leadingAnchor, constant: (col1End + col2End) / 2),
            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            signButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            signButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            signButton.widthAnchor.constraint(equalToConstant: 56),
            signButton.heightAnchor.constraint(equalToConstant: 32),

            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }

    @objc private func signButtonTapped() {
        onSignTapped?()
    }

    func configure(with contract: Contract, onSign: (() -> Void)?) {
        nameLabel.text = contract.name
        onSignTapped = onSign

        switch contract.status {
        case .signed:
            statusLabel.text = "已签订"
            statusLabel.textColor = Constants.Color.textSecondary
            signButton.isHidden = true
        case .unsigned:
            statusLabel.text = "未签订"
            statusLabel.textColor = Constants.Color.stockRise
            signButton.isHidden = false
        }
    }
}


