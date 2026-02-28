//
//  TradeRecordViewController.swift
//  zhengqaun
//
//  交易记录：买卖记录列表，卖出绿色、买入红色，股票名/代码、金额、股数、时间
//

import SafariServices
import UIKit

/// 单条交易记录
struct TradeRecordItem {
    let isSell: Bool // true=卖出(绿), false=买入(红)
    let stockName: String
    let stockCode: String
    let amount: String // 如 "142,120.00"
    let shares: String // 如 "15200"
    let dateTime: String // 如 "2026-01-20 14:01:23"
}

class TradeRecordViewController: ZQViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var records: [TradeRecordItem] = []
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        loadData()
    }

    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "交易记录"
        gk_navLineHidden = false
        gk_statusBarStyle = .default
        gk_backStyle = .black
        let serviceBtn = UIBarButtonItem(image: UIImage(systemName: "headphones"), style: .plain, target: self, action: #selector(serviceTapped))
        serviceBtn.tintColor = Constants.Color.textSecondary
        gk_navRightBarButtonItem = serviceBtn
    }

    @objc private func serviceTapped() {
        // 从配置接口获取客服 URL
        SecureNetworkManager.shared.request(
            api: "/api/stock/getconfig",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      var kfUrl = data["kf_url"] as? String,
                      !kfUrl.isEmpty else {
                    DispatchQueue.main.async { Toast.show("获取客服地址失败") }
                    return
                }
                // 补全协议头
                if !kfUrl.hasPrefix("http") {
                    kfUrl = "https://" + kfUrl
                }
                guard let url = URL(string: kfUrl) else { return }
                DispatchQueue.main.async {
                    let safari = SFSafariViewController(url: url)
                    self.navigationController?.present(safari, animated: true)
                }
            case .failure(_):
                DispatchQueue.main.async { Toast.show("获取客服地址失败") }
            }
        }
    }

    private func setupTableView() {
        view.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.register(TradeRecordCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // 空状态
        emptyLabel.text = "暂无数据"
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadData() {
//        records = [
//            TradeRecordItem(isSell: true, stockName: "盈方微", stockCode: "000670", amount: "142,120.00", shares: "15200", dateTime: "2026-01-20 14:01:23"),
//            TradeRecordItem(isSell: false, stockName: "盈方微", stockCode: "000670", amount: "142,120.00", shares: "15200", dateTime: "2026-01-20 14:01:23"),
//            TradeRecordItem(isSell: true, stockName: "盈方微", stockCode: "000670", amount: "142,120.00", shares: "15200", dateTime: "2026-01-20 14:01:23"),
//            TradeRecordItem(isSell: false, stockName: "盈方微", stockCode: "000670", amount: "142,120.00", shares: "15200", dateTime: "2026-01-20 14:01:23"),
//            TradeRecordItem(isSell: true, stockName: "盈方微", stockCode: "000670", amount: "142,120.00", shares: "15200", dateTime: "2026-01-20 14:01:23"),
//            TradeRecordItem(isSell: false, stockName: "盈方微", stockCode: "000670", amount: "142,120.00", shares: "15200", dateTime: "2026-01-20 14:01:23")
//        ]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let endDate = formatter.string(from: Date())
        let startDate = formatter.string(from: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date())
        
        SecureNetworkManager.shared.request(
            api: "/api/deal/getNowWarehouse_lishi",
            method: .get,
            params: ["buytype": "1", "page": "1", "size": "50", "status": "2", "s_time": startDate, "e_time": endDate]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else { return }
                var tempRecords: [TradeRecordItem] = []
                list.forEach { item in
                    let name = item["title"] as? String ?? "--"
                    let code = item["code"] as? String ?? "--"
                    let allcode = item["allcode"] as? String ?? ""
                    
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
                    
                    let buyPrice = item["buyprice"] as? Double ?? 0
                    let sellPrice = Double("\(item["cai_buy"] ?? 0)") ?? 0
                    let number = item["number"] as? String ?? "\(item["number"] as? Int ?? 0)"
                    let money = item["money"] as? String ?? "--"
                    let pl = item["profitLose"] as? String ?? "0"
                    let createTime = item["createtime_name"] as? String ?? "--"
                    let outTime = item["outtime_name"] as? String ?? "--"
                    
                    let sell = String(format: "%.2f", sellPrice * (Double(number) ?? 0))
                    tempRecords.append(TradeRecordItem(isSell: false,
                                                       stockName: name,
                                                       stockCode: code,
                                                       amount: money,
                                                       shares: number,
                                                       dateTime: createTime))
                    tempRecords.append(TradeRecordItem(isSell: true,
                                                       stockName: name,
                                                       stockCode: code,
                                                       amount: sell,
                                                       shares: number,
                                                       dateTime: outTime))
                }
                
                self.records = tempRecords
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.emptyLabel.isHidden = !self.records.isEmpty
                }
                    
            case .failure(let err):
                DispatchQueue.main.async {
                    Toast.showInfo(err.localizedDescription)
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension TradeRecordViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TradeRecordCell
        cell.configure(with: records[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
}

// MARK: - TradeRecordCell

class TradeRecordCell: UITableViewCell {
    private let typeLabel = UILabel()
    private let stockLabel = UILabel()
    private let dateLabel = UILabel()
    private let amountLabel = UILabel()
    private let sharesLabel = UILabel()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white

        typeLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        contentView.addSubview(typeLabel)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false

        stockLabel.font = UIFont.systemFont(ofSize: 15)
        stockLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(stockLabel)
        stockLabel.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = Constants.Color.textTertiary
        contentView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        amountLabel.font = UIFont.boldSystemFont(ofSize: 15)
        amountLabel.textColor = Constants.Color.textPrimary
        amountLabel.textAlignment = .right
        contentView.addSubview(amountLabel)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        sharesLabel.font = UIFont.systemFont(ofSize: 12)
        sharesLabel.textColor = Constants.Color.textTertiary
        sharesLabel.textAlignment = .right
        contentView.addSubview(sharesLabel)
        sharesLabel.translatesAutoresizingMaskIntoConstraints = false

        separator.backgroundColor = Constants.Color.separator
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            typeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            typeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            stockLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stockLabel.leadingAnchor.constraint(equalTo: typeLabel.trailingAnchor, constant: 8),
            stockLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -12),

            dateLabel.topAnchor.constraint(equalTo: stockLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: stockLabel.leadingAnchor),

            amountLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: stockLabel.trailingAnchor, constant: 12),

            sharesLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 8),
            sharesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }

    func configure(with item: TradeRecordItem) {
        typeLabel.text = item.isSell ? "卖出" : "买入"
        typeLabel.textColor = item.isSell ? Constants.Color.stockFall : Constants.Color.stockRise
        stockLabel.text = "\(item.stockName)(\(item.stockCode))"
        dateLabel.text = item.dateTime
        amountLabel.text = "\(item.amount)元"
        sharesLabel.text = "\(item.shares)股"
    }
}
