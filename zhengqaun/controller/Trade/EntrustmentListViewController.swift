//
//  EntrustmentListViewController.swift
//  zhengqaun
//
//  委托列表：交易所图标+股票名/代码，买卖类别(红)、当前状态、委托数量、委托价格
//

import UIKit

/// 单条委托
struct EntrustmentItem {
    let id: Int
    let stockName: String
    let stockCode: String
    let buySellCategory: String  // 如 "证券买入(大宗)"
    let isBuy: Bool
    let currentStatus: String    // 如 "挂单"
    let statusId: Int            // 2为委托中，其他为完结
    let entrustedQuantity: String
    let entrustedPrice: String
}

class EntrustmentListViewController: ZQViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private var list: [EntrustmentItem] = []
    
    private var blockTradeName: String = "大宗"
    private var cancelingIds = Set<Int>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        loadData()
    }

    private func setupNavigationBar() {
        gk_navTitle = "委托列表"
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navLineHidden = false
        gk_statusBarStyle = .default
        gk_backStyle = .black
    }

    private func setupTableView() {
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(EntrustmentListCell.self, forCellReuseIdentifier: "Cell")
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        emptyLabel.text = "加载中..."
        emptyLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textAlignment = .center
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: gk_navigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadData() {
        SecureNetworkManager.shared.request(api: "/api/deal/getConfig", method: .get, params: [:]) { [weak self] res in
            if case .success(let success) = res,
               let dict = success.decrypted,
               let data = dict["data"] as? [String: Any],
               let name = data["dz_syname"] as? String, !name.isEmpty {
                self?.blockTradeName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            self?.fetchList()
        }
    }

    private func fetchList() {
        SecureNetworkManager.shared.request(
            api: "/api/deal/getNowWarehouse_weituo",
            method: .get,
            params: ["buytype": "1,7", "page": "1", "size": "50", "status": "2"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let items = data["list"] as? [[String: Any]] else {
                    return
                }
                
                self.list = items.compactMap { item in
                    let id = item["id"] as? Int ?? 0
                    let title = item["title"] as? String ?? "--"
                    let code = item["code"] as? String ?? "--"
                    let buyPrice = item["buyprice"] as? Double ?? 0
                    let number = item["number"] as? String ?? "\(item["number"] as? Int ?? 0)"
                    let cjlx = item["cjlx"] as? String ?? "--"
                    let buytype = "\(item["buytype"] ?? "1")"
                    
                    let statusId = item["status"] as? Int ?? 2
                    let isBuy = true // 委托界面目前仅限买入展示红色
                    
                    let categoryText: String
                    if buytype == "7" {
                        categoryText = "证券买入(\(self.blockTradeName))"
                    } else if buytype == "1" {
                        categoryText = "证券买入"
                    } else {
                        categoryText = buytype.isEmpty ? "--" : buytype
                    }
                    
                    return EntrustmentItem(
                        id: id,
                        stockName: title,
                        stockCode: code,
                        buySellCategory: categoryText,
                        isBuy: isBuy,
                        currentStatus: cjlx.isEmpty ? "委托" : cjlx,
                        statusId: statusId,
                        entrustedQuantity: number,
                        entrustedPrice: buyPrice > 0 ? String(format: "%.2f", buyPrice) : "--"
                    )
                }
                
                self.tableView.reloadData()
                self.emptyLabel.text = "暂无委托记录"
                self.emptyLabel.isHidden = !self.list.isEmpty
                
            case .failure(_):
                self.emptyLabel.text = "加载失败"
                self.emptyLabel.isHidden = !self.list.isEmpty
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension EntrustmentListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! EntrustmentListCell
        let item = list[indexPath.row]
        let isCanceling = cancelingIds.contains(item.id)
        cell.configure(with: item, isCanceling: isCanceling)
        cell.onCancelAction = { [weak self] in
            self?.performCancel(for: item)
        }
        return cell
    }
    
    private func performCancel(for item: EntrustmentItem) {
        guard item.statusId == 2 && item.id > 0 else { return }
        guard !cancelingIds.contains(item.id) else { return }
        
        cancelingIds.insert(item.id)
        tableView.reloadData()
        
        SecureNetworkManager.shared.request(api: "/api/deal/cheAll", method: .get, params: ["id": "\(item.id)"]) { [weak self] result in
            guard let self = self else { return }
            self.cancelingIds.remove(item.id)
            if case .success(let res) = result, res.statusCode == 200 {
                DispatchQueue.main.async {
                    Toast.show("撤单成功")
                    self.fetchList()
                }
            } else {
                DispatchQueue.main.async {
                    Toast.show("撤单失败")
                    self.tableView.reloadData()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}

// MARK: - EntrustmentListCell
class EntrustmentListCell: UITableViewCell {

    var onCancelAction: (() -> Void)?

    private let card = UIView()
    
    // 行1
    private let titleLabel = UILabel()
    private let statusHintLabel = UILabel()
    private let statusValueLabel = UILabel()
    
    // 行2
    private let categoryHintLabel = UILabel()
    private let categoryTagContainer = UIView()
    private let categoryTagLabel = UILabel()
    
    private let priceHintLabel = UILabel()
    private let priceValueLabel = UILabel()
    
    // 行3
    private let quantityHintLabel = UILabel()
    private let quantityValueLabel = UILabel()
    private let cancelButton = UIButton(type: .custom)
    
    private let divider = UIView()

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
        contentView.backgroundColor = .clear

        card.backgroundColor = .white
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        let darkColor = UIColor(red: 0.19, green: 0.19, blue: 0.19, alpha: 1.0)
        let grayColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        titleLabel.textColor = darkColor
        
        statusHintLabel.font = UIFont.systemFont(ofSize: 12)
        statusHintLabel.textColor = grayColor
        statusHintLabel.text = "当前状态"
        
        statusValueLabel.font = UIFont.systemFont(ofSize: 12)
        statusValueLabel.textColor = darkColor

        let row1 = UIStackView(arrangedSubviews: [titleLabel, UIView(), statusHintLabel, statusValueLabel])
        row1.axis = .horizontal
        row1.alignment = .center
        row1.spacing = 4
        
        categoryHintLabel.font = UIFont.systemFont(ofSize: 12)
        categoryHintLabel.textColor = grayColor
        categoryHintLabel.text = "买卖类型 "
        
        categoryTagContainer.layer.borderWidth = 0.5
        categoryTagContainer.layer.cornerRadius = 2
        categoryTagLabel.font = UIFont.systemFont(ofSize: 11)
        categoryTagContainer.addSubview(categoryTagLabel)
        categoryTagLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            categoryTagLabel.leadingAnchor.constraint(equalTo: categoryTagContainer.leadingAnchor, constant: 4),
            categoryTagLabel.trailingAnchor.constraint(equalTo: categoryTagContainer.trailingAnchor, constant: -4),
            categoryTagLabel.topAnchor.constraint(equalTo: categoryTagContainer.topAnchor, constant: 1),
            categoryTagLabel.bottomAnchor.constraint(equalTo: categoryTagContainer.bottomAnchor, constant: -1)
        ])
        
        priceHintLabel.font = UIFont.systemFont(ofSize: 12)
        priceHintLabel.textColor = grayColor
        priceHintLabel.text = "委托价格 "
        
        priceValueLabel.font = UIFont.systemFont(ofSize: 12)
        priceValueLabel.textColor = darkColor
        
        let row2 = UIStackView(arrangedSubviews: [categoryHintLabel, categoryTagContainer, UIView(), priceHintLabel, priceValueLabel])
        row2.axis = .horizontal
        row2.alignment = .center
        
        quantityHintLabel.font = UIFont.systemFont(ofSize: 12)
        quantityHintLabel.textColor = grayColor
        quantityHintLabel.text = "委托数量 "
        
        quantityValueLabel.font = UIFont.systemFont(ofSize: 12)
        quantityValueLabel.textColor = darkColor
        
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        cancelButton.layer.cornerRadius = 4
        cancelButton.clipsToBounds = true
        cancelButton.addTarget(self, action: #selector(onCancelBtnTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.widthAnchor.constraint(equalToConstant: 54),
            cancelButton.heightAnchor.constraint(equalToConstant: 26)
        ])
        
        let row3 = UIStackView(arrangedSubviews: [quantityHintLabel, quantityValueLabel, UIView(), cancelButton])
        row3.axis = .horizontal
        row3.alignment = .center
        
        divider.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
        card.addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        let mainStack = UIStackView(arrangedSubviews: [row1, row2, row3])
        mainStack.axis = .vertical
        mainStack.spacing = 6
        card.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            mainStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: divider.topAnchor, constant: -12),
            
            divider.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    @objc private func onCancelBtnTapped() {
        onCancelAction?()
    }

    func configure(with item: EntrustmentItem, isCanceling: Bool) {
        titleLabel.text = "\(item.stockName)  \(item.stockCode)"
        statusValueLabel.text = item.currentStatus
        
        categoryTagLabel.text = item.buySellCategory
        let riseRed = UIColor(red: 230/255.0, green: 0, blue: 18/255.0, alpha: 1.0)
        if item.isBuy {
            categoryTagLabel.textColor = riseRed
            categoryTagContainer.layer.borderColor = riseRed.cgColor
            categoryTagContainer.backgroundColor = riseRed.withAlphaComponent(0.05)
        } else {
            let fallGreen = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
            categoryTagLabel.textColor = fallGreen
            categoryTagContainer.layer.borderColor = fallGreen.cgColor
            categoryTagContainer.backgroundColor = fallGreen.withAlphaComponent(0.05)
        }
        
        priceValueLabel.text = item.entrustedPrice
        quantityValueLabel.text = item.entrustedQuantity
        
        let canCancel = item.statusId == 2 && item.id > 0
        cancelButton.isHidden = !canCancel
        cancelButton.isEnabled = !isCanceling
        
        if canCancel {
            if isCanceling {
                cancelButton.setTitle("撤单中", for: .normal)
                cancelButton.backgroundColor = riseRed.withAlphaComponent(0.5)
            } else {
                cancelButton.setTitle("撤 单", for: .normal)
                cancelButton.backgroundColor = riseRed
            }
        }
    }
}
