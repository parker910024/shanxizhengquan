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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navTitle = "合同"
        gk_navBackgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // #1976D2
        gk_navTitleColor = .white
        gk_statusBarStyle = .lightContent
    }
    
    private func setupUI() {
        view.backgroundColor = Constants.Color.backgroundMain
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = Constants.Color.backgroundMain
        tableView.register(ContractCell.self, forCellReuseIdentifier: "ContractCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func loadData() {
        contracts = Contract.mockContracts()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension ContractListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contracts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContractCell", for: indexPath) as! ContractCell
        cell.configure(with: contracts[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ContractListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let contract = contracts[indexPath.row]
        let vc = ContractDetailViewController()
        vc.contract = contract
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - ContractCell
class ContractCell: UITableViewCell {
    
    private let containerView = UIView()
    private let documentIcon = UIImageView()
    private let nameLabel = UILabel()
    private let statusButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 8
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 文档图标
        documentIcon.image = UIImage(systemName: "doc.text")
        documentIcon.tintColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        documentIcon.contentMode = .scaleAspectFit
        containerView.addSubview(documentIcon)
        documentIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // 合同名称
        nameLabel.text = "证券投资顾问咨询服务协议"
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.textColor = Constants.Color.textPrimary
        nameLabel.numberOfLines = 2
        containerView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 状态按钮
        statusButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        statusButton.layer.cornerRadius = 4
        statusButton.isUserInteractionEnabled = false
        containerView.addSubview(statusButton)
        statusButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            documentIcon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            documentIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            documentIcon.widthAnchor.constraint(equalToConstant: 24),
            documentIcon.heightAnchor.constraint(equalToConstant: 24),
            
            nameLabel.leadingAnchor.constraint(equalTo: documentIcon.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusButton.leadingAnchor, constant: -12),
            
            statusButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusButton.widthAnchor.constraint(equalToConstant: 60),
            statusButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    func configure(with contract: Contract) {
        nameLabel.text = contract.name
        
        switch contract.status {
        case .signed:
            statusButton.setTitle("已签", for: .normal)
            statusButton.setTitleColor(.white, for: .normal)
            statusButton.backgroundColor = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0) // 绿色
        case .unsigned:
            statusButton.setTitle("签订", for: .normal)
            statusButton.setTitleColor(.white, for: .normal)
            statusButton.backgroundColor = Constants.Color.stockRise // 红色
        }
    }
}


