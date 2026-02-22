//
//  SecuritiesTransferRecordViewController.swift
//  zhengqaun
//
//  资金记录：三 Tab（资金明细/转入记录/转出记录），列表展示变动资金与详情
//

import UIKit

/// 资金明细单条数据
struct FundDetailRecord {
    let type: String           // 如 "平仓收益"、"普通下单"
    let capitalChange: String  // 变动资金，如 "9,039,600.00"
    let dateTime: String       // 如 "2026-01-07 20:37:37"
    let detailText: String     // 多行详情描述
}

/// 银证转账记录数据模型
struct TransferRecord {
    let type: TransferType
    let status: TransferStatus
    let amount: Double
    let timestamp: Date

    enum TransferType: String {
        case transferIn = "银证转入"
        case transferOut = "银证转出"
    }

    enum TransferStatus: String {
        case success = "处理成功"
        case failed = "处理失败"
        case processing = "处理中"
    }
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

    // 数据
    private var fundDetails: [FundDetailRecord] = []
    private var transferInRecords: [TransferRecord] = []
    private var transferOutRecords: [TransferRecord] = []

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

    @objc private func serviceTapped() {}

    private func setupUI() {
        view.backgroundColor = .white
        setupTabs()
        setupTableView()
    }

    // MARK: - 三 Tab：资金明细 | 转入记录 | 转出记录（背景透明，选中不改背景）
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
            tabIndicator.widthAnchor.constraint(equalToConstant: 24),

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
        tableView.reloadData()
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
        tableView.register(FundDetailCell.self, forCellReuseIdentifier: "FundDetailCell")
        tableView.register(TransferRecordCell.self, forCellReuseIdentifier: "TransferCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Data
    private func loadData() {
        let detailDesc = "卖出股票,603352/C至信,占用本金:9039600.00,总手续费:903.96,递延费:0.00,印花税:4519.80,盈亏:7464600.00,总盈亏:7459176.24"
        fundDetails = [
            FundDetailRecord(type: "平仓收益", capitalChange: "9,039,600.00", dateTime: "2026-01-07 20:37:37", detailText: detailDesc),
            FundDetailRecord(type: "普通下单", capitalChange: "9,039,600.00", dateTime: "2026-01-07 20:37:37", detailText: detailDesc),
            FundDetailRecord(type: "平仓收益", capitalChange: "9,039,600.00", dateTime: "2026-01-07 20:37:37", detailText: detailDesc),
            FundDetailRecord(type: "普通下单", capitalChange: "9,039,600.00", dateTime: "2026-01-07 20:37:37", detailText: detailDesc)
        ]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        transferInRecords = [
            TransferRecord(type: .transferIn, status: .success, amount: 1000, timestamp: formatter.date(from: "2025-12-10 10:14:07") ?? Date()),
            TransferRecord(type: .transferIn, status: .failed, amount: 1000, timestamp: formatter.date(from: "2025-12-10 10:14:07") ?? Date())
        ]
        transferOutRecords = [
            TransferRecord(type: .transferOut, status: .success, amount: 500, timestamp: formatter.date(from: "2025-12-09 14:30:15") ?? Date()),
            TransferRecord(type: .transferOut, status: .failed, amount: 2000, timestamp: formatter.date(from: "2025-12-07 16:45:22") ?? Date())
        ]
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SecuritiesTransferRecordViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedTab {
        case .detail: return fundDetails.count
        case .transferIn: return transferInRecords.count
        case .transferOut: return transferOutRecords.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch selectedTab {
        case .detail:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FundDetailCell", for: indexPath) as! FundDetailCell
            cell.configure(with: fundDetails[indexPath.row])
            return cell
        case .transferIn:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransferCell", for: indexPath) as! TransferRecordCell
            cell.configure(with: transferInRecords[indexPath.row])
            return cell
        case .transferOut:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransferCell", for: indexPath) as! TransferRecordCell
            cell.configure(with: transferOutRecords[indexPath.row])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if selectedTab == .detail {
            let record = fundDetails[indexPath.row]
            let h = FundDetailCell.heightFor(record)
            return h
        }
        return 70
    }
}

// MARK: - 资金明细 Cell：类型(粗体) | 变动资金:(粗体) 金额；日期(灰)；多行详情(灰)
class FundDetailCell: UITableViewCell {

    private let typeLabel = UILabel()
    private let changeLabel = UILabel()
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

        typeLabel.font = UIFont.boldSystemFont(ofSize: 15)
        typeLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(typeLabel)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false

        changeLabel.text = "变动资金:"
        changeLabel.font = UIFont.systemFont(ofSize: 14)
        changeLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(changeLabel)
        changeLabel.translatesAutoresizingMaskIntoConstraints = false

        amountLabel.font = UIFont.boldSystemFont(ofSize: 15)
        amountLabel.textColor = Constants.Color.textPrimary
        amountLabel.textAlignment = .right
        contentView.addSubview(amountLabel)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = Constants.Color.textTertiary
        contentView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        detailLabel.font = UIFont.systemFont(ofSize: 12)
        detailLabel.textColor = Constants.Color.textTertiary
        detailLabel.numberOfLines = 0
        contentView.addSubview(detailLabel)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        separator.backgroundColor = Constants.Color.separator
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            typeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            typeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            changeLabel.centerYAnchor.constraint(equalTo: typeLabel.centerYAnchor),
            changeLabel.trailingAnchor.constraint(equalTo: amountLabel.leadingAnchor, constant: -4),
            amountLabel.centerYAnchor.constraint(equalTo: typeLabel.centerYAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: changeLabel.leadingAnchor),

            dateLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            detailLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }

    func configure(with record: FundDetailRecord) {
        typeLabel.text = record.type
        amountLabel.text = record.capitalChange
        dateLabel.text = record.dateTime
        detailLabel.text = record.detailText
    }

    static func heightFor(_ record: FundDetailRecord) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 12)
        let width = UIScreen.main.bounds.width - 32
        let rect = (record.detailText as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        let detailH = ceil(rect.height)
        return 16 + 20 + 8 + 18 + 8 + detailH + 16
    }
}

// MARK: - 转入/转出记录 Cell（保留原样式）
class TransferRecordCell: UITableViewCell {

    private let typeLabel = UILabel()
    private let statusLabel = UILabel()
    private let amountLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        typeLabel.font = UIFont.systemFont(ofSize: 15)
        typeLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(typeLabel)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.systemFont(ofSize: 13)
        statusLabel.textColor = Constants.Color.stockRise
        contentView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        amountLabel.textAlignment = .right
        contentView.addSubview(amountLabel)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = Constants.Color.textTertiary
        timeLabel.textAlignment = .right
        contentView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        let separator = UIView()
        separator.backgroundColor = Constants.Color.separator
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            typeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            typeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            amountLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: typeLabel.trailingAnchor, constant: 16),
            timeLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 6),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: statusLabel.trailingAnchor, constant: 16),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }

    func configure(with record: TransferRecord) {
        typeLabel.text = record.type.rawValue
        statusLabel.text = record.status.rawValue
        let sign = record.type == .transferIn ? "+" : "-"
        amountLabel.text = "\(sign)\(String(format: "%.2f", record.amount))"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        timeLabel.text = formatter.string(from: record.timestamp)
        if record.status == .failed {
            statusLabel.textColor = Constants.Color.stockRise
            amountLabel.textColor = Constants.Color.stockRise
        } else if record.status == .success {
            statusLabel.textColor = Constants.Color.stockFall
            amountLabel.textColor = Constants.Color.stockFall
        } else {
            statusLabel.textColor = Constants.Color.textSecondary
            amountLabel.textColor = Constants.Color.textPrimary
        }
    }
}
