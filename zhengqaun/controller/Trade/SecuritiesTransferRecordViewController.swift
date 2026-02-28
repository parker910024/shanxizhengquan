//
//  SecuritiesTransferRecordViewController.swift
//  zhengqaun
//
//  资金记录：三 Tab（资金明细/转入记录/转出记录），统一 Cell 布局对齐安卓
//

import UIKit
import SafariServices

/// 统一资金记录数据模型（对齐安卓 FundRecord）
struct FundRecord {
    let type: String       // 类型名称，如"平仓收益"、"银证转入"
    let amount: Double     // 变动资金
    let dateTime: String   // 时间
    let detail: String     // 详情描述
}

enum FundRecordTab: Int {
    case detail = 0   // 资金明细
    case transferIn   // 转入记录
    case transferOut  // 转出记录
}

class SecuritiesTransferRecordViewController: ZQViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)

    // 标签页：资金明细 | 转入记录 | 转出记录
    private let tabContainer = UIView()
    private let tabDetail = UIButton(type: .custom)
    private let tabTransferIn = UIButton(type: .custom)
    private let tabTransferOut = UIButton(type: .custom)
    private let tabIndicator = UIView()
    private var selectedTab: FundRecordTab = .detail
    private var indicatorCenterXConstraint: NSLayoutConstraint!

    // 统一数据源（对齐安卓：三个 Tab 复用同一模型）
    private var records: [FundRecord] = []
    
    // 空状态标签（对齐安卓）
    private let emptyLabel = UILabel()

    private let tabOrange = UIColor(red: 1.0, green: 0.55, blue: 0.2, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadData()
    }

    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "资金记录"
        gk_navLineHidden = false
        gk_statusBarStyle = .default
        gk_backStyle = .black
        let serviceBtn = UIBarButtonItem(image: UIImage(systemName: "headphones"), style: .plain, target: self, action: #selector(serviceTapped))
        serviceBtn.tintColor = Constants.Color.textSecondary
        gk_navRightBarButtonItem = serviceBtn
    }

    @objc private func serviceTapped() {
        SecureNetworkManager.shared.request(
            api: "/api/stock/getconfig",
            method: .get,
            params: [:]
        ) { result in
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      var kfUrl = data["kf_url"] as? String,
                      !kfUrl.isEmpty else {
                    DispatchQueue.main.async { Toast.show("获取客服地址失败") }
                    return
                }
                if !kfUrl.hasPrefix("http") { kfUrl = "https://" + kfUrl }
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

    private func setupUI() {
        view.backgroundColor = .white
        setupTabs()
        setupTableView()
        setupEmptyLabel()
    }

    // MARK: - 三 Tab：资金明细 | 转入记录 | 转出记录
    private func setupTabs() {
        tabContainer.backgroundColor = .clear
        view.addSubview(tabContainer)
        tabContainer.translatesAutoresizingMaskIntoConstraints = false

        tabDetail.setTitle("资金明细", for: .normal)
        tabTransferIn.setTitle("转入记录", for: .normal)
        tabTransferOut.setTitle("转出记录", for: .normal)
        let emptyImg = UIImage()
        for (btn, tag) in [(tabDetail, 0), (tabTransferIn, 1), (tabTransferOut, 2)] {
            btn.tag = tag
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            btn.setTitleColor(Constants.Color.textSecondary, for: .normal)
            btn.setTitleColor(tabOrange, for: .selected)
            btn.backgroundColor = .clear
            btn.setBackgroundImage(emptyImg, for: .normal)
            btn.setBackgroundImage(emptyImg, for: .selected)
            btn.setBackgroundImage(emptyImg, for: .highlighted)
            btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            tabContainer.addSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
        }

        tabIndicator.backgroundColor = tabOrange
        tabContainer.addSubview(tabIndicator)
        tabIndicator.translatesAutoresizingMaskIntoConstraints = false

        let sep = UIView()
        sep.backgroundColor = Constants.Color.separator
        tabContainer.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false

        let w = UIScreen.main.bounds.width / 3
        NSLayoutConstraint.activate([
            tabContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tabContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabContainer.heightAnchor.constraint(equalToConstant: 44),

            tabDetail.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
            tabDetail.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            tabDetail.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tabDetail.widthAnchor.constraint(equalToConstant: w),

            tabTransferIn.leadingAnchor.constraint(equalTo: tabDetail.trailingAnchor),
            tabTransferIn.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            tabTransferIn.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tabTransferIn.widthAnchor.constraint(equalToConstant: w),

            tabTransferOut.leadingAnchor.constraint(equalTo: tabTransferIn.trailingAnchor),
            tabTransferOut.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            tabTransferOut.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tabTransferOut.widthAnchor.constraint(equalToConstant: w),

            tabIndicator.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tabIndicator.heightAnchor.constraint(equalToConstant: 2),
            tabIndicator.widthAnchor.constraint(equalToConstant: 40),

            sep.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        indicatorCenterXConstraint = tabIndicator.centerXAnchor.constraint(equalTo: tabDetail.centerXAnchor)
        indicatorCenterXConstraint.isActive = true
        updateTabAppearance()
    }

    @objc private func tabTapped(_ sender: UIButton) {
        guard let t = FundRecordTab(rawValue: sender.tag) else { return }
        selectedTab = t
        indicatorCenterXConstraint.isActive = false
        switch t {
        case .detail:
            indicatorCenterXConstraint = tabIndicator.centerXAnchor.constraint(equalTo: tabDetail.centerXAnchor)
        case .transferIn:
            indicatorCenterXConstraint = tabIndicator.centerXAnchor.constraint(equalTo: tabTransferIn.centerXAnchor)
        case .transferOut:
            indicatorCenterXConstraint = tabIndicator.centerXAnchor.constraint(equalTo: tabTransferOut.centerXAnchor)
        }
        indicatorCenterXConstraint.isActive = true
        updateTabAppearance()
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
        
        loadData()
    }

    private func updateTabAppearance() {
        tabDetail.isSelected = selectedTab == .detail
        tabTransferIn.isSelected = selectedTab == .transferIn
        tabTransferOut.isSelected = selectedTab == .transferOut
    }

    // MARK: - TableView
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.register(UnifiedFundRecordCell.self, forCellReuseIdentifier: "UnifiedFundRecordCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - 空状态（对齐安卓）
    private func setupEmptyLabel() {
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

    // MARK: - 数据加载（对齐安卓）
    private func loadData() {
        // 对齐安卓：资金明细不传 type，转入 type=0，转出 type=1
        var params: [String: Any] = [:]
        switch selectedTab {
        case .detail:
            params = [:]
        case .transferIn:
            params = ["type": "0"]
        case .transferOut:
            params = ["type": "1"]
        }
        
        // 对齐安卓：加载时显示"加载中..."
        records = []
        tableView.reloadData()
        tableView.isHidden = true
        emptyLabel.text = "加载中..."
        emptyLabel.isHidden = false
        
        SecureNetworkManager.shared.request(
            api: "/api/user/capitalLog",
            method: .get,
            params: params
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        self.records = []
                        self.tableView.reloadData()
                        self.showEmptyState()
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.parseAndReload(list: list)
                }
            case .failure(let err):
                DispatchQueue.main.async {
                    self.records = []
                    self.tableView.reloadData()
                    self.emptyLabel.text = "获取记录失败"
                    self.emptyLabel.isHidden = false
                    self.tableView.isHidden = true
                    Toast.show("获取记录失败: \(err.localizedDescription)")
                }
            }
        }
    }
    
    /// 对齐安卓 toFundRecord() 转换逻辑
    private func parseAndReload(list: [[String: Any]]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var parsed: [FundRecord] = []
        
        for item in list {
            let payTypeName = item["pay_type_name"] as? String ?? ""
            // 兼容多种 JSON 类型：Double、Int、String
            let moneyVal: Double
            if let d = item["money"] as? Double {
                moneyVal = d
            } else if let n = item["money"] as? NSNumber {
                moneyVal = n.doubleValue
            } else if let s = item["money"] as? String, let d = Double(s) {
                moneyVal = d
            } else {
                moneyVal = 0.0
            }
            
            let timeVal = item["createtime"] as? TimeInterval ?? 0
            let dateStr: String
            if timeVal > 0 {
                let date = Date(timeIntervalSince1970: timeVal)
                dateStr = formatter.string(from: date)
            } else {
                dateStr = ""
            }
            
            // 对齐安卓：detail = pay_type_name + is_pay_name + reject
            let isPayName = item["is_pay_name"] as? String ?? ""
            let reject = item["reject"] as? String ?? ""
            var detailParts: [String] = []
            if !payTypeName.isEmpty { detailParts.append(payTypeName) }
            if !isPayName.isEmpty { detailParts.append(isPayName) }
            if !reject.isEmpty { detailParts.append(reject) }
            let detail = detailParts.isEmpty ? "—" : detailParts.joined(separator: "，")
            
            parsed.append(FundRecord(
                type: payTypeName.isEmpty ? "资金变动" : payTypeName,
                amount: moneyVal,
                dateTime: dateStr,
                detail: detail
            ))
        }
        
        records = parsed
        tableView.reloadData()
        
        if records.isEmpty {
            showEmptyState()
        } else {
            tableView.isHidden = false
            emptyLabel.isHidden = true
        }
    }
    
    private func showEmptyState() {
        emptyLabel.text = "暂无数据"
        emptyLabel.isHidden = false
        tableView.isHidden = true
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SecuritiesTransferRecordViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UnifiedFundRecordCell", for: indexPath) as! UnifiedFundRecordCell
        cell.configure(with: records[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK: - 统一资金记录 Cell（对齐安卓 item_fund_record.xml）
// 第1行：类型(左) + "变动资金：" + 金额(右，粗体)
// 第2行：日期时间（灰色）
// 第3行：详情（灰色，多行）
// 底部分割线
class UnifiedFundRecordCell: UITableViewCell {

    private let typeLabel = UILabel()
    private let changePrefixLabel = UILabel()
    private let amountLabel = UILabel()
    private let dateLabel = UILabel()
    private let detailLabel = UILabel()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white

        // 类型标签（左侧）
        typeLabel.font = UIFont.systemFont(ofSize: 15)
        typeLabel.textColor = UIColor(red: 0x30/255, green: 0x30/255, blue: 0x30/255, alpha: 1.0)
        contentView.addSubview(typeLabel)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false

        // "变动资金："前缀标签
        changePrefixLabel.text = "变动资金："
        changePrefixLabel.font = UIFont.systemFont(ofSize: 15)
        changePrefixLabel.textColor = UIColor(red: 0x30/255, green: 0x30/255, blue: 0x30/255, alpha: 1.0)
        changePrefixLabel.setContentHuggingPriority(.required, for: .horizontal)
        changePrefixLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(changePrefixLabel)
        changePrefixLabel.translatesAutoresizingMaskIntoConstraints = false

        // 金额标签（粗体，18sp）
        amountLabel.font = UIFont.boldSystemFont(ofSize: 18)
        amountLabel.textColor = UIColor(red: 0x30/255, green: 0x30/255, blue: 0x30/255, alpha: 1.0)
        amountLabel.textAlignment = .right
        amountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(amountLabel)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        // 日期标签（灰色 13sp）
        dateLabel.font = UIFont.systemFont(ofSize: 13)
        dateLabel.textColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 1.0)
        contentView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        // 详情标签（灰色 13sp，多行）
        detailLabel.font = UIFont.systemFont(ofSize: 13)
        detailLabel.textColor = UIColor(red: 0x60/255, green: 0x60/255, blue: 0x60/255, alpha: 1.0)
        detailLabel.numberOfLines = 0
        contentView.addSubview(detailLabel)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        // 分割线
        separator.backgroundColor = UIColor(red: 0xF0/255, green: 0xF0/255, blue: 0xF0/255, alpha: 1.0)
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // 第1行：类型(左) + 变动资金：金额(右)
            typeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            typeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            amountLabel.centerYAnchor.constraint(equalTo: typeLabel.centerYAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            changePrefixLabel.centerYAnchor.constraint(equalTo: typeLabel.centerYAnchor),
            changePrefixLabel.trailingAnchor.constraint(equalTo: amountLabel.leadingAnchor, constant: -2),
            changePrefixLabel.leadingAnchor.constraint(greaterThanOrEqualTo: typeLabel.trailingAnchor, constant: 8),

            // 第2行：日期
            dateLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 10),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // 第3行：详情
            detailLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10),
            detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // 分割线
            separator.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with record: FundRecord) {
        typeLabel.text = record.type
        // 对齐安卓：使用 NumberFormatter 格式化金额（带逗号分隔）
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2
        amountLabel.text = nf.string(from: NSNumber(value: record.amount)) ?? String(format: "%.2f", record.amount)
        dateLabel.text = record.dateTime
        detailLabel.text = record.detail
    }
}
