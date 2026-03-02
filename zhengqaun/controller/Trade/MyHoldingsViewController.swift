//
//  MyHoldingsViewController.swift
//  zhengqaun
//
//  我的持仓：红底导航+三 Tab（当前持仓/历史持仓/申购记录），统一的卡片布局对齐安卓。
//

import UIKit

// MARK: - 数据模型 (对齐 Android PositionRecord)
struct PositionRecord {
    let tradeType: String  // 新股交易 / 普通交易 / 新股申购 等
    let stockName: String
    let market: String
    let code: String
    let allcode: String // 新增全码
    let date: String
    let value1: String
    let value2: String
    let value3: String
    let value4: String
    let profit: String
    let profitRatio: String
    let isUp: Bool
    let showSell: Bool
    let isHistory: Bool
    let rawData: [String: Any]?
}

class MyHoldingsViewController: ZQViewController {

    private let navRed = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var segmentContainer: UIView!
    private var tabButtons: [UIButton] = []
    private var underline: UIView!
    private var underlineLeading: NSLayoutConstraint?
    private var emptyLabel: UILabel!
    private var selectedTabIndex: Int = 0
    
    /// 外部可设置初始 tab（0=当前持仓, 1=历史持仓, 2=申购记录）
    var initialTab: Int = 0
    
    // 列表数据源
    private var currentRecords: [PositionRecord] = []
    private var historyRecords: [PositionRecord] = []
    private var subscriptionRecords: [PositionRecord] = []
    
    private let headerTitles = [
        ["名称/代码", "市值/数量", "现价/买入", "盈亏 / 涨幅"],
        ["名称/代码", "买入/数量", "卖出/金额", "盈亏"],
        ["名称/代码", "价格/数量", "状态", "中签/金额"]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData(for: selectedTabIndex)
    }

    private func setupUI() {
        view.backgroundColor = .white
        setupNavigationBar()
        setupSegment()
        setupTableView()
        setupEmptyView()
        
        if initialTab > 0 && initialTab < 3 {
            selectedTabIndex = initialTab
        }
        updateTabSelection(selectedTabIndex)
    }

    private func setupNavigationBar() {
        gk_navBackgroundColor = navRed
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "我的持仓"
        gk_navLineHidden = true
        gk_statusBarStyle = .lightContent
        gk_navItemRightSpace = 15
        gk_backStyle = .white
    }

    @objc private func searchTapped() {
        let vc = StockSearchViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func setupSegment() {
        let wrap = UIView()
        wrap.backgroundColor = navRed
        view.addSubview(wrap)
        wrap.translatesAutoresizingMaskIntoConstraints = false
        segmentContainer = wrap

        let titles = ["当前持仓", "历史持仓", "申购记录"]
        for (i, t) in titles.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(t, for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            btn.tag = i
            btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            wrap.addSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
            tabButtons.append(btn)
        }
        underline = UIView()
        underline.backgroundColor = .white
        wrap.addSubview(underline)
        underline.translatesAutoresizingMaskIntoConstraints = false

        let w = Constants.Screen.width / CGFloat(titles.count)
        NSLayoutConstraint.activate([
            wrap.topAnchor.constraint(equalTo: gk_navigationBar.bottomAnchor),
            wrap.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wrap.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wrap.heightAnchor.constraint(equalToConstant: 44),
            underline.heightAnchor.constraint(equalToConstant: 3),
            underline.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            underline.widthAnchor.constraint(equalToConstant: 24)
        ])
        for (i, btn) in tabButtons.enumerated() {
            NSLayoutConstraint.activate([
                btn.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: w * CGFloat(i)),
                btn.topAnchor.constraint(equalTo: wrap.topAnchor),
                btn.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
                btn.widthAnchor.constraint(equalToConstant: w)
            ])
        }
        underlineLeading = underline.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: (w - 24) / 2)
        underlineLeading?.isActive = true
    }

    @objc private func tabTapped(_ sender: UIButton) {
        let idx = sender.tag
        if idx == selectedTabIndex { return }
        selectedTabIndex = idx
        updateTabSelection(idx)
        let w = segmentContainer.bounds.width / CGFloat(tabButtons.count)
        UIView.animate(withDuration: 0.25) {
            self.underlineLeading?.constant = (w - 24) / 2 + w * CGFloat(idx)
            self.segmentContainer.layoutIfNeeded()
        }
        tableView.reloadData()
        loadData(for: idx)
    }

    private func updateTabSelection(_ idx: Int) {
        for (i, btn) in tabButtons.enumerated() {
            btn.titleLabel?.font = i == idx ? UIFont.boldSystemFont(ofSize: 14) : UIFont.systemFont(ofSize: 14)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = segmentContainer.bounds.width / CGFloat(tabButtons.count)
        if w > 0 { underlineLeading?.constant = (w - 24) / 2 + w * CGFloat(selectedTabIndex) }
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.backgroundView = nil
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(MyHoldingsRecordCell.self, forCellReuseIdentifier: "MyHoldingsRecordCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupEmptyView() {
        emptyLabel = UILabel()
        emptyLabel.text = "暂无数据"
        emptyLabel.font = UIFont.systemFont(ofSize: 15)
        emptyLabel.textColor = Constants.Color.textTertiary
        emptyLabel.textAlignment = .center
        tableView.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 120)
        ])
        emptyLabel.isHidden = true
    }

    private func updateEmptyState() {
        let hasData: Bool
        switch selectedTabIndex {
        case 0: hasData = !currentRecords.isEmpty
        case 1: hasData = !historyRecords.isEmpty
        case 2: hasData = !subscriptionRecords.isEmpty
        default: hasData = false
        }
        emptyLabel.isHidden = hasData
        if !hasData {
            emptyLabel.text = "暂无数据"
        }
    }

    private func showLoading() {
        emptyLabel.isHidden = false
        emptyLabel.text = "加载中..."
    }

    // MARK: - Data Loading
    private func loadData(for tabIndex: Int) {
        showLoading()
        switch tabIndex {
        case 0: loadCurrentHolding()
        case 1: loadHistoryHolding()
        case 2: loadSubscriptionRecords()
        default: break
        }
    }

    private func getMarketLabel(type: Int, allcode: String, code: String = "") -> String {
        switch type {
        case 1: return "沪"
        case 2: return "深"
        case 3: return "创"
        case 4: return "京"
        case 5: return "科"
        case 6: return "基"
        default:
            let c = code.isEmpty ? (allcode.count > 2 ? String(allcode.dropFirst(2)) : allcode) : code
            if allcode.lowercased().hasPrefix("sh") {
                if allcode.hasPrefix("sh688") { return "科" } else { return "沪" }
            } else if allcode.lowercased().hasPrefix("bj") {
                return "京"
            } else if allcode.lowercased().hasPrefix("sz") {
                if allcode.hasPrefix("sz30") { return "创" } else { return "深" }
            } else {
                if c.hasPrefix("688") { return "科" }
                else if c.hasPrefix("30") { return "创" }
                else if c.hasPrefix("8") || c.hasPrefix("4") { return "京" }
                else if c.hasPrefix("6") { return "沪" }
                else { return "深" }
            }
        }
    }

    private func fmt(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }
    
    private func fmtStr(_ value: String) -> String {
        if let d = Double(value) {
            return String(format: "%.2f", d)
        }
        return value
    }

    private func loadCurrentHolding() {
        SecureNetworkManager.shared.request(
            api: "/api/deal/getNowWarehouse",
            method: .get,
            params: ["buytype": "1", "page": "1", "size": "50", "status": "1"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    self.currentRecords = []
                    self.tableView.reloadData()
                    self.updateEmptyState()
                    return
                }
                
                self.currentRecords = list.compactMap { item in
                    let name = (item["title"] as? String ?? "").isEmpty ? "-" : (item["title"] as? String ?? "-")
                    let code = item["code"] as? String ?? ""
                    let allcode = item["allcode"] as? String ?? ""
                    let market = self.getMarketLabel(type: item["type"] as? Int ?? 0, allcode: allcode, code: code)
                    
                    let buypriceStr = "\(item["buyprice"] ?? 0)"
                    let caibuyStr = "\(item["cai_buy"] ?? 0)"
                    let cityccStr = "\(item["citycc"] ?? 0)"
                    let profitStr = "\(item["profitLose"] ?? 0)"
                    let numberStr = "\(item["number"] ?? "0")"
                    
                    let number = Double(numberStr) ?? 0
                    let buyPrice = Double(buypriceStr) ?? 0
                    let caiBuy = Double(caibuyStr) ?? 0
                    let citycc = Double(cityccStr) ?? 0
                    let profitLose = Double(profitStr) ?? 0
                    let profitLoseRate = "\(item["profitLose_rate"] ?? "")"
                    let createTime = "\(item["createtime_name"] ?? "--")"
                    let buyType = "\(item["buytype"] ?? "1")"
                    let tradeType = buyType == "7" ? "大宗交易" : "普通交易"
                    
                    return PositionRecord(
                        tradeType: tradeType,
                        stockName: name,
                        market: market,
                        code: code,
                        allcode: allcode,
                        date: createTime,
                        value1: self.fmt(citycc),
                        value2: String(format: "%.0f", number),
                        value3: self.fmt(caiBuy),
                        value4: self.fmt(buyPrice),
                        profit: self.fmt(profitLose),
                        profitRatio: profitLoseRate,
                        isUp: profitLose >= 0,
                        showSell: true,
                        isHistory: false,
                        rawData: item
                    )
                }
                
                if self.selectedTabIndex == 0 {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
            case .failure(_):
                self.currentRecords = []
                if self.selectedTabIndex == 0 {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
            }
        }
    }

    private func loadHistoryHolding() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let endDate = formatter.string(from: Date())
        let startDate = formatter.string(from: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date())
        
        SecureNetworkManager.shared.request(
            api: "/api/deal/getNowWarehouse_lishi",
            method: .get,
            params: ["buytype": "1", "page": "1", "size": "50", "status": "2", "type": "2", "s_time": startDate, "e_time": endDate]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    self.historyRecords = []
                    self.tableView.reloadData()
                    self.updateEmptyState()
                    return
                }
                
                
                self.historyRecords = list.compactMap { item in
                    let name = (item["title"] as? String ?? "").isEmpty ? "-" : (item["title"] as? String ?? "-")
                    let code = item["code"] as? String ?? ""
                    let allcode = item["allcode"] as? String ?? ""
                    let market = self.getMarketLabel(type: item["type"] as? Int ?? 0, allcode: allcode, code: code)
                    
                    let buypriceStr = "\(item["buyprice"] ?? 0)"
                    let caibuyStr = "\(item["cai_buy"] ?? 0)"
                    let profitLoseStr = "\(item["profitLose"] ?? 0)"
                    let numberStr = "\(item["number"] ?? "0")"
                    
                    let buyPrice = Double(buypriceStr) ?? 0
                    let sellPrice = Double(caibuyStr) ?? 0
                    let number = Double(numberStr) ?? 0
                    let money = "\(item["money"] ?? "0")"
                    let profitLose = Double(profitLoseStr) ?? 0
                    let profitLoseRate = "\(item["profitLose_rate"] ?? "")"
                    let createTime = "\(item["createtime_name"] ?? "--")"
                    let buyType = "\(item["buytype"] ?? "1")"
                    let tradeType = buyType == "7" ? "大宗交易" : "普通交易"
                    
                    return PositionRecord(
                        tradeType: tradeType,
                        stockName: name,
                        market: market,
                        code: code,
                        allcode: allcode,
                        date: createTime,
                        value1: self.fmt(buyPrice),
                        value2: String(format: "%.0f", number),
                        value3: self.fmt(sellPrice),
                        value4: self.fmtStr(money),
                        profit: self.fmt(profitLose),
                        profitRatio: profitLoseRate,
                        isUp: profitLose >= 0,
                        showSell: false,
                        isHistory: true,
                        rawData: item
                    )
                }
                
                if self.selectedTabIndex == 1 {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
            case .failure(_):
                self.historyRecords = []
                if self.selectedTabIndex == 1 {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
            }
        }
    }

    private func loadSubscriptionRecords() {
        SecureNetworkManager.shared.request(
            api: "/api/subscribe/getsgnewgu0",
            method: .get,
            params: ["page": "1", "size": "20"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["dxlog_list"] as? [[String: Any]] else {
                    self.subscriptionRecords = []
                    self.tableView.reloadData()
                    self.updateEmptyState()
                    return
                }
                
                self.subscriptionRecords = list.compactMap { item in
                    let name = (item["name"] as? String ?? "").isEmpty ? "-" : (item["name"] as? String ?? "-")
                    let code = item["code"] as? String ?? ""
                    let statusStr = "\(item["status"] ?? "0")"
                    let fallbackStatusTxt = item["status_txt"] as? String ?? "未知"
                    let statusText: String
                    switch statusStr {
                    case "0": statusText = "申购中"
                    case "1": statusText = "中签"
                    case "2": statusText = "未中签"
                    case "3": statusText = "弃购"
                    default: statusText = fallbackStatusTxt.isEmpty ? "未知" : fallbackStatusTxt
                    }
                    
                    let sgFxPriceStr = "\(item["sg_fx_price"] ?? 0)"
                    let sgFxPrice = Double(sgFxPriceStr) ?? 0
                    let zqNums = "\(item["zq_nums"] ?? 0)"
                    
                    let zqMoneyStr = "\(item["zq_money"] ?? 0)"
                    let zqMoney = Double(zqMoneyStr) ?? 0
                    let createtimeTxt = item["createtime_txt"] as? String ?? ""
                    
                    // 由于新股申购后端未下发 allcode，为了行情能跳过去需要手动推断
                    let inferredAllcode: String
                    if code.hasPrefix("6") || code.hasPrefix("5") { inferredAllcode = "sh\(code)" }
                    else if code.hasPrefix("8") || code.hasPrefix("4") || code.hasPrefix("9") { inferredAllcode = "bj\(code)" }
                    else if !code.isEmpty { inferredAllcode = "sz\(code)" }
                    else { inferredAllcode = "" }
                    
                    return PositionRecord(
                        tradeType: "新股申购",
                        stockName: name,
                        market: "",
                        code: code,
                        allcode: inferredAllcode, // 这里用推断好的全码
                        date: createtimeTxt,
                        value1: String(format: "%.2f", sgFxPrice),
                        value2: zqNums,
                        value3: statusText,
                        value4: "",
                        profit: zqNums,
                        profitRatio: String(format: "%.2f", zqMoney),
                        isUp: zqMoney > 0,
                        showSell: false,
                        isHistory: false,
                        rawData: item
                    )
                }
                
                if self.selectedTabIndex == 2 {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
            case .failure(_):
                self.subscriptionRecords = []
                if self.selectedTabIndex == 2 {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension MyHoldingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    // 返回当前的 records 列表
    private func currentList() -> [PositionRecord] {
        switch selectedTabIndex {
        case 0: return currentRecords
        case 1: return historyRecords
        case 2: return subscriptionRecords
        default: return []
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentList().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyHoldingsRecordCell", for: indexPath) as! MyHoldingsRecordCell
        let record = currentList()[indexPath.row]
        cell.configure(with: record)
        
        // 点击整个Cell区域：股票行情
        cell.onStockClick = { [weak self] in
            guard let self = self, !record.code.isEmpty else { return }
            let vc = IndexDetailViewController()
            vc.indexCode = record.code
            vc.indexName = record.stockName
            vc.indexAllcode = record.allcode
            vc.isIndex = false
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        // 详情按钮：只对有原始数据的（非申购记录）有效
        cell.onDetailClick = { [weak self] in
            guard let self = self, let raw = record.rawData else { return }
            let vc = HoldingDetailViewController()
            vc.holdingData = raw
            vc.isHistorical = record.isHistory
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        // 卖出按钮
        cell.onSellClick = { [weak self] in
            guard let self = self else { return }
            let vc = AccountTradeViewController()
            vc.stockCode = record.code
            vc.stockName = record.stockName
            vc.selectedIndex = 1 // 1 是卖出
            vc.holdingId = "\(record.rawData?["id"] ?? "")"
            
            // 解析交易所信息避免生成的 allcode 出错
            let allcode = record.allcode.lowercased()
            if allcode.hasPrefix("sh") { vc.exchange = "沪" }
            else if allcode.hasPrefix("sz") { vc.exchange = "深" }
            else if allcode.hasPrefix("bj") { vc.exchange = "京" }
            
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        // 盈利按钮
        cell.onProfitClick = { [weak self] in
            if record.tradeType == "新股申购" { return }
            // Android 端对 item_position_record.xml 中的 btn_profit 未设置响应，iOS 端目前亦无对应跳转页面
            Toast.show("敬请期待")
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // 如果当前列表有数据，统一展示四列标题头，和安卓保持一致
        if currentList().isEmpty { return nil }
        return makeColumnHeaderView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if currentList().isEmpty { return 0 }
        return 44
    }
    
    private func makeColumnHeaderView() -> UIView {
        let header = UIView()
        header.backgroundColor = .white
        
        let titles = headerTitles[selectedTabIndex]
        
        // 左边偏移量约 48 (对应标签+边距)
        let nameHeader = UILabel()
        nameHeader.text = titles[0]
        nameHeader.font = UIFont.systemFont(ofSize: 13)
        nameHeader.textColor = UIColor(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0) // 666666
        let col2Header = UILabel()
        col2Header.text = titles[1]
        col2Header.font = UIFont.systemFont(ofSize: 13)
        col2Header.textColor = UIColor(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0)
        col2Header.textAlignment = .center
        
        let col3Header = UILabel()
        col3Header.text = titles[2]
        col3Header.font = UIFont.systemFont(ofSize: 13)
        col3Header.textColor = UIColor(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0)
        col3Header.textAlignment = .center
        
        let col4Header = UILabel()
        col4Header.text = titles[3]
        col4Header.font = UIFont.systemFont(ofSize: 13)
        col4Header.textColor = UIColor(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0)
        col4Header.textAlignment = .right
        
        let stackView = UIStackView(arrangedSubviews: [nameHeader, col2Header, col3Header, col4Header])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        header.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 48),
            stackView.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: header.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: header.bottomAnchor)
        ])
        
        return header
    }
}

// MARK: - 统一持仓记录 Cell (对齐 item_position_record.xml)
class MyHoldingsRecordCell: UITableViewCell {

    private let typeTagLabel = UILabel()
    private let contentBlock = UIView()
    
    // Row 1
    private let nameLabel = UILabel()
    private let val1Label = UILabel()
    private let val3Label = UILabel()
    private let profitLabel = UILabel()
    
    // Row 2
    private let marketLabel = UILabel()
    private let codeLabel = UILabel()
    private let val2Label = UILabel()
    private let val4Label = UILabel()
    private let profitRatioLabel = UILabel()
    
    // Row 3
    private let dateLabel = UILabel()
    private let detailBtn = UIButton(type: .system)
    private let marketBtn = UIButton(type: .system)
    private let profitBtn = UIButton(type: .system)
    private let sellBtn = UIButton(type: .system)
    
    private let divider = UIView()

    var onStockClick: (() -> Void)?
    var onDetailClick: (() -> Void)?
    var onSellClick: (() -> Void)?
    var onProfitClick: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .white
        
        // 红色竖排标签
        typeTagLabel.backgroundColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        typeTagLabel.layer.cornerRadius = 2
        typeTagLabel.clipsToBounds = true
        typeTagLabel.textColor = .white
        typeTagLabel.font = UIFont.systemFont(ofSize: 11)
        typeTagLabel.numberOfLines = 0
        typeTagLabel.textAlignment = .center
        typeTagLabel.isUserInteractionEnabled = true
        typeTagLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleStockClick)))
        contentView.addSubview(typeTagLabel)
        typeTagLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(contentBlock)
        contentBlock.translatesAutoresizingMaskIntoConstraints = false
        // 点击右侧数据区上部触发 stockClick
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleStockClick))
        contentBlock.addGestureRecognizer(tap)
        
        // --- Row 1 ---
        nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        nameLabel.textColor = UIColor(red: 48/255.0, green: 48/255.0, blue: 48/255.0, alpha: 1.0)
        
        val1Label.font = UIFont.systemFont(ofSize: 14)
        val1Label.textColor = UIColor(red: 48/255.0, green: 48/255.0, blue: 48/255.0, alpha: 1.0)
        val1Label.textAlignment = .center
        
        val3Label.font = UIFont.systemFont(ofSize: 14)
        val3Label.textColor = UIColor(red: 48/255.0, green: 48/255.0, blue: 48/255.0, alpha: 1.0)
        val3Label.textAlignment = .center
        
        profitLabel.font = UIFont.systemFont(ofSize: 14)
        profitLabel.textAlignment = .right
        
        let row1Stack = UIStackView(arrangedSubviews: [nameLabel, val1Label, val3Label, profitLabel])
        row1Stack.axis = .horizontal
        row1Stack.distribution = .fillEqually
        contentBlock.addSubview(row1Stack)
        row1Stack.translatesAutoresizingMaskIntoConstraints = false
        
        // --- Row 2 ---
        marketLabel.font = UIFont.systemFont(ofSize: 10)
        marketLabel.textColor = .white
        marketLabel.textAlignment = .center
        marketLabel.layer.cornerRadius = 2
        marketLabel.clipsToBounds = true
        
        codeLabel.font = UIFont.systemFont(ofSize: 12)
        codeLabel.textColor = UIColor(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0) // 666666
        
        let marketCodeStack = UIStackView(arrangedSubviews: [marketLabel, codeLabel])
        marketCodeStack.axis = .horizontal
        marketCodeStack.spacing = 4
        marketCodeStack.alignment = .center
        
        val2Label.font = UIFont.systemFont(ofSize: 12)
        val2Label.textColor = UIColor(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0)
        val2Label.textAlignment = .center
        
        val4Label.font = UIFont.systemFont(ofSize: 12)
        val4Label.textColor = UIColor(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0)
        val4Label.textAlignment = .center
        
        profitRatioLabel.font = UIFont.systemFont(ofSize: 12)
        profitRatioLabel.textAlignment = .right
        
        let wrapper = UIView()
        wrapper.addSubview(marketCodeStack)
        marketCodeStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            marketCodeStack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            marketCodeStack.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor)
        ])
        
        let row2Stack = UIStackView(arrangedSubviews: [wrapper, val2Label, val4Label, profitRatioLabel])
        row2Stack.axis = .horizontal
        row2Stack.distribution = .fillEqually
        contentBlock.addSubview(row2Stack)
        row2Stack.translatesAutoresizingMaskIntoConstraints = false
        
        // --- Row 3 (Date + Buttons) ---
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = UIColor(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1.0) // 999999
        
        detailBtn.setTitle("详情", for: .normal)
        detailBtn.setTitleColor(UIColor(red: 17/255.0, green: 155/255.0, blue: 221/255.0, alpha: 1.0), for: .normal) // 119BDD
        configureBtn(detailBtn)
        detailBtn.addTarget(self, action: #selector(handleDetailClick), for: .touchUpInside)
        
        marketBtn.setTitle("行情", for: .normal)
        marketBtn.setTitleColor(UIColor(red: 81/255.0, green: 72/255.0, blue: 162/255.0, alpha: 1.0), for: .normal) // 5148A2
        configureBtn(marketBtn)
        marketBtn.addTarget(self, action: #selector(handleStockClick), for: .touchUpInside)
        
        profitBtn.setTitle("盈利", for: .normal)
        profitBtn.setTitleColor(UIColor(red: 188/255.0, green: 70/255.0, blue: 48/255.0, alpha: 1.0), for: .normal) // BC4630
        configureBtn(profitBtn)
        profitBtn.addTarget(self, action: #selector(handleProfitClick), for: .touchUpInside)
        
        sellBtn.setTitle("卖出", for: .normal)
        sellBtn.setTitleColor(.white, for: .normal)
        sellBtn.backgroundColor = UIColor(red: 232/255.0, green: 76/255.0, blue: 61/255.0, alpha: 1.0) // E84C3D
        sellBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        sellBtn.layer.cornerRadius = 2
        sellBtn.addTarget(self, action: #selector(handleSellClick), for: .touchUpInside)
        
        let btnStack = UIStackView(arrangedSubviews: [detailBtn, marketBtn, profitBtn, sellBtn])
        btnStack.axis = .horizontal
        btnStack.spacing = 12
        
        let row3Stack = UIStackView(arrangedSubviews: [dateLabel, btnStack])
        row3Stack.axis = .horizontal
        row3Stack.alignment = .center
        contentBlock.addSubview(row3Stack)
        row3Stack.translatesAutoresizingMaskIntoConstraints = false
        
        // 分割线
        divider.backgroundColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0) // F0F0F0
        contentView.addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Left tag
            typeTagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            typeTagLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            typeTagLabel.bottomAnchor.constraint(equalTo: contentBlock.bottomAnchor),
            typeTagLabel.widthAnchor.constraint(equalToConstant: 24),
            
            // Content Block
            contentBlock.leadingAnchor.constraint(equalTo: typeTagLabel.trailingAnchor, constant: 8),
            contentBlock.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentBlock.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            contentBlock.bottomAnchor.constraint(equalTo: divider.topAnchor, constant: -12),
            
            // Rows inside Content Block
            row1Stack.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            row1Stack.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor),
            row1Stack.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            
            row2Stack.topAnchor.constraint(equalTo: row1Stack.bottomAnchor, constant: 4),
            row2Stack.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor),
            row2Stack.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            
            row3Stack.topAnchor.constraint(equalTo: row2Stack.bottomAnchor, constant: 12),
            row3Stack.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor),
            row3Stack.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            row3Stack.bottomAnchor.constraint(equalTo: contentBlock.bottomAnchor),
            
            // Button sizes
            detailBtn.widthAnchor.constraint(equalToConstant: 46),
            detailBtn.heightAnchor.constraint(equalToConstant: 24),
            marketBtn.widthAnchor.constraint(equalToConstant: 46),
            marketBtn.heightAnchor.constraint(equalToConstant: 24),
            profitBtn.widthAnchor.constraint(equalToConstant: 46),
            profitBtn.heightAnchor.constraint(equalToConstant: 24),
            sellBtn.widthAnchor.constraint(equalToConstant: 46),
            sellBtn.heightAnchor.constraint(equalToConstant: 24),
            
            // Market label
            marketLabel.widthAnchor.constraint(equalToConstant: 16),
            marketLabel.heightAnchor.constraint(equalToConstant: 16),
            
            // Divider
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func configureBtn(_ btn: UIButton) {
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        btn.backgroundColor = .clear
        btn.layer.cornerRadius = 2
        btn.layer.borderWidth = 1
        btn.layer.borderColor = btn.titleColor(for: .normal)?.cgColor
    }
    
    // 把文字拆成换行
    private func toVerticalText(_ text: String) -> String {
        return text.map { String($0) }.joined(separator: "\n")
    }

    func configure(with record: PositionRecord) {
        typeTagLabel.text = toVerticalText(record.tradeType)
        nameLabel.text = record.stockName
        marketLabel.text = record.market
        marketLabel.isHidden = record.market.isEmpty
        codeLabel.text = record.code
        
        val1Label.text = record.value1
        val2Label.text = record.value2
        val3Label.text = record.value3
        val4Label.text = record.value4
        
        profitLabel.text = record.profit
        profitRatioLabel.text = record.profitRatio
        // 不能用 isHidden = true，否则 UIStackView 会重新分配宽度，导致第二行的列数变化进而和表头错位
        profitRatioLabel.isHidden = false
        
        dateLabel.text = record.date
        
        // Color
        let pColor = record.isUp ? UIColor(red: 232/255.0, green: 76/255.0, blue: 61/255.0, alpha: 1.0) : UIColor(red: 0/255.0, green: 153/255.0, blue: 68/255.0, alpha: 1.0)
        profitLabel.textColor = pColor
        profitRatioLabel.textColor = pColor
        
        var mColor = UIColor.clear
        switch record.market {
        case "沪": mColor = UIColor(red: 232/255.0, green: 76/255.0, blue: 61/255.0, alpha: 1.0)
        case "深": mColor = UIColor(red: 17/255.0, green: 155/255.0, blue: 221/255.0, alpha: 1.0)
        default: mColor = UIColor(red: 232/255.0, green: 76/255.0, blue: 61/255.0, alpha: 1.0)
        }
        marketLabel.backgroundColor = mColor
        
        // Buttons visibility 
        // 1. 行情按钮：始终显示，点击跳转 K 线
        marketBtn.isHidden = false
        // 2. 详情按钮：仅当存在持仓原始数据（非申购）时显示
        detailBtn.isHidden = (record.rawData == nil) || (record.tradeType == "新股申购")
        // 3. 卖出按钮：允许卖出 (showSell)且不属于申购时显示
        sellBtn.isHidden = !(record.showSell && record.rawData != nil) || (record.tradeType == "新股申购")
        // 4. 盈利按钮：当前持仓、历史持仓、新股申购 全部展示盈利按钮
        profitBtn.isHidden = false
    }
    
    @objc private func handleStockClick() { onStockClick?() }
    @objc private func handleDetailClick() { onDetailClick?() }
    @objc private func handleSellClick() { onSellClick?() }
    @objc private func handleProfitClick() { onProfitClick?() }
}
