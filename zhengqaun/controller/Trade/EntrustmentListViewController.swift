//
//  EntrustmentListViewController.swift
//  zhengqaun
//
//  委托列表：交易所图标+股票名/代码，买卖类别(红)、当前状态、委托数量、委托价格
//

import UIKit

/// 单条委托
struct EntrustmentItem {
    let exchange: String   // 京、深、沪
    let stockName: String
    let stockCode: String
    let buySellCategory: String  // 如 "证券买入(大宗)"，买入类用红色
    let isBuy: Bool
    let currentStatus: String   // 如 "挂单"
    let entrustedQuantity: String
    let entrustedPrice: String
}

class EntrustmentListViewController: ZQViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var list: [EntrustmentItem] = []

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
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func loadData() {
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
                    let title = item["title"] as? String ?? "--"
                    let code = item["code"] as? String ?? "--"
                    let allcode = item["allcode"] as? String ?? ""
                    let buyPrice = item["buyprice"] as? Double ?? 0
                    let number = item["number"] as? String ?? "\(item["number"] as? Int ?? 0)"
                    let cjlx = item["cjlx"] as? String ?? "--"
                    let buytype = "\(item["buytype"] ?? "1")"
                    
                    // 根据 type 推导交易所
                    let typeVal = item["type"] as? Int ?? 0
                    let exchangeStr: String
                    switch typeVal {
                    case 1, 5: exchangeStr = "沪"
                    case 2, 3: exchangeStr = "深"
                    case 4:    exchangeStr = "京"
                    default:
                        if allcode.lowercased().hasPrefix("sh") { exchangeStr = "沪" }
                        else if allcode.lowercased().hasPrefix("bj") { exchangeStr = "京" }
                        else { exchangeStr = "深" }
                    }
                    
                    // 判断买卖类别
                    let isBuy = (item["status"] as? Int ?? 2) == 2  // 委托中
                    let categoryText: String
                    if buytype == "7" {
                        categoryText = isBuy ? "证券买入(大宗)" : "证券卖出(大宗)"
                    } else {
                        categoryText = isBuy ? "证券买入" : "证券卖出"
                    }
                    
                    return EntrustmentItem(
                        exchange: exchangeStr,
                        stockName: title,
                        stockCode: code,
                        buySellCategory: categoryText,
                        isBuy: isBuy,
                        currentStatus: cjlx,
                        entrustedQuantity: number,
                        entrustedPrice: String(format: "%.2f", buyPrice)
                    )
                }
                
                self.tableView.reloadData()
                
            case .failure(_): break
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
        cell.configure(with: list[indexPath.row])
        return cell
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

    private let card = UIView()
    private let exchangeBadge = UILabel()
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let categoryLabel = UILabel()
    private let categoryValueLabel = UILabel()
    private let statusLabel = UILabel()
    private let statusValueLabel = UILabel()
    private let quantityLabel = UILabel()
    private let quantityValueLabel = UILabel()
    private let priceLabel = UILabel()
    private let priceValueLabel = UILabel()

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
        card.layer.cornerRadius = 8
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        exchangeBadge.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        exchangeBadge.textColor = .white
        exchangeBadge.textAlignment = .center
        exchangeBadge.layer.cornerRadius = 4
        exchangeBadge.clipsToBounds = true
        card.addSubview(exchangeBadge)
        exchangeBadge.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        card.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        codeLabel.font = UIFont.systemFont(ofSize: 14)
        codeLabel.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
        card.addSubview(codeLabel)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        let row1 = makeDetailRow(label: categoryLabel, value: categoryValueLabel)
        let row2 = makeDetailRow(label: statusLabel, value: statusValueLabel)
        let row3 = makeDetailRow(label: quantityLabel, value: quantityValueLabel)
        let row4 = makeDetailRow(label: priceLabel, value: priceValueLabel)
        categoryLabel.text = "买卖类别"
        statusLabel.text = "当前状态"
        quantityLabel.text = "委托数量"
        priceLabel.text = "委托价格"

        let leftStack = UIStackView(arrangedSubviews: [row1, row3])
        leftStack.axis = .vertical
        leftStack.spacing = 10
        leftStack.alignment = .leading
        let rightStack = UIStackView(arrangedSubviews: [row2, row4])
        rightStack.axis = .vertical
        rightStack.spacing = 10
        rightStack.alignment = .leading
        let detailRow = UIStackView(arrangedSubviews: [leftStack, rightStack])
        detailRow.axis = .horizontal
        detailRow.distribution = .fillEqually
        detailRow.spacing = 16
        detailRow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(detailRow)

        let pad: CGFloat = 16
        let headerBottom: CGFloat = 12
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            exchangeBadge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            exchangeBadge.topAnchor.constraint(equalTo: card.topAnchor, constant: pad),
            exchangeBadge.widthAnchor.constraint(equalToConstant: 28),
            exchangeBadge.heightAnchor.constraint(equalToConstant: 22),

            nameLabel.leadingAnchor.constraint(equalTo: exchangeBadge.trailingAnchor, constant: 10),
            nameLabel.centerYAnchor.constraint(equalTo: exchangeBadge.centerYAnchor),

            codeLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            codeLabel.centerYAnchor.constraint(equalTo: exchangeBadge.centerYAnchor),
            codeLabel.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -pad),

            detailRow.topAnchor.constraint(equalTo: exchangeBadge.bottomAnchor, constant: headerBottom),
            detailRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: pad),
            detailRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -pad),
            detailRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -pad)
        ])
    }

    private func makeDetailRow(label: UILabel, value: UILabel) -> UIView {
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1)
        value.font = UIFont.systemFont(ofSize: 13)
        value.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        let row = UIStackView(arrangedSubviews: [label, value])
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center
        return row
    }

    private static func exchangeColor(_ exchange: String) -> UIColor {
        switch exchange {
        case "京": return UIColor(red: 0.85, green: 0.45, blue: 0.75, alpha: 1.0)
        case "深": return UIColor(red: 0.25, green: 0.45, blue: 0.85, alpha: 1.0)
        case "沪": return UIColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 1.0)
        default: return UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        }
    }

    func configure(with item: EntrustmentItem) {
        exchangeBadge.text = item.exchange
        exchangeBadge.backgroundColor = Self.exchangeColor(item.exchange)
        nameLabel.text = item.stockName
        codeLabel.text = item.stockCode
        categoryValueLabel.text = item.buySellCategory
        categoryValueLabel.textColor = item.isBuy ? UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0) : UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        statusValueLabel.text = item.currentStatus
        quantityValueLabel.text = item.entrustedQuantity
        priceValueLabel.text = item.entrustedPrice
    }
}
