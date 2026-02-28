//
//  MyHoldingsViewController.swift
//  zhengqaun
//
//  我的持仓：红底导航+三 Tab（当前持仓/历史持仓/申购记录），表头 名称/代码、市值/数量、现价/买入、盈亏。
//

import UIKit

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadHoldingsData()
    }

    private func setupUI() {
        view.backgroundColor = .white
        setupNavigationBar()
        setupSegment()
        setupTableView()
        setupEmptyView()
        
        // 如果外部指定了初始 tab，使用它
        if initialTab > 0 && initialTab < 3 {
            selectedTabIndex = initialTab
        }
        updateTabSelection(selectedTabIndex)
    }

    private func setupNavigationBar() {
        let navRed = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
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

        let navH = Constants.Navigation.totalNavigationHeight
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
        let hasData: Bool
        switch idx {
        case 0: hasData = !holdings.isEmpty
        case 1: hasData = !historicalHoldings.isEmpty
        case 2: hasData = !subscriptionNewStocks.isEmpty
        default: hasData = false
        }
        emptyLabel.isHidden = hasData
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
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(MyHoldingsHoldingCell.self, forCellReuseIdentifier: "HoldingCell")
        tableView.register(MyHoldingsHistoryRowCell.self, forCellReuseIdentifier: "MyHoldingsHistoryRowCell")
        tableView.register(NewStockCell.self, forCellReuseIdentifier: "SubscriptionCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

//        let navH = Constants.Navigation.totalNavigationHeight
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
    }

    // 当前持仓数据模型（对齐安卓 toCurrentRecord）
    struct Holding {
        let name: String
        let code: String          // 交易所+代码
        let col2Top: String       // 第二列上：市值(citycc)
        let col2Bottom: String    // 第二列下：数量(number)
        let col3Top: String       // 第三列上：现价(cai_buy)
        let col3Bottom: String    // 第三列下：买入价(buyprice)
        let profitLoss: String    // 盈亏
        let profitLossPercent: String // 盈亏%
        let date: String          // 日期
    }

    /// 历史持仓单条（左侧竖条「普通交易」+ 名称/交易所/日期左对齐 + 三列数据 + 底部详情/行情/盈利）
    struct HistoricalHolding {
        let typeLabel: String   // "普通交易"
        let name: String       // "N 至信"
        let marketLine: String // "沪 8.75"
        let date: String       // "2026-01-15"
        let buyPrice: String
        let quantity: String
        let currentPrice: String
        let totalCost: String
        let profitLoss: String
        let profitLossPercent: String
    }
    
    private var holdings: [Holding] = []
    private var historicalHoldings: [HistoricalHolding] = []
    
    /// 新股持仓 / 申购记录 数据模型
    struct NewStockItem {
        let name: String
        let code: String
        let price: String      // 申购价/发行价
        let quantity: String   // 数量(中签数/申购数)
        let statusText: String // 状态描述
        let date: String       // 创建时间
        let statusColor: UIColor
    }
    private var newStockHoldings: [NewStockItem] = []
    private var subscriptionNewStocks: [NewStock] = []
    
    /// 缓存 API 原始返回数据，供跳转详情页时传入
    private var rawHoldingsData: [[String: Any]] = []
    private var rawHistoricalData: [[String: Any]] = []
    
    private func setupHoldingsHeader() {
        // 表头作为section header
        // 这里不需要单独设置，会在tableView的viewForHeaderInSection中处理
    }
    
    private func loadHoldingsData() {
        // 调用后端接口获取当前持仓
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
                    self.emptyLabel.isHidden = false
                    return
                }
                
                // 缓存原始数据
                self.rawHoldingsData = list
                
                self.holdings = list.compactMap { item in
                    let name = item["title"] as? String ?? "--"
                    let code = item["code"] as? String ?? "--"
                    let allcode = item["allcode"] as? String ?? ""
                    
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
                    
                    // 对齐安卓：所有字段兼容 Double/String/Int
                    let numberStr = "\(item["number"] ?? "0")"
                    let number = Double(numberStr) ?? 0
                    let buyPrice = Double("\(item["buyprice"] ?? 0)") ?? 0
                    let caiBuy = Double("\(item["cai_buy"] ?? 0)") ?? 0
                    let citycc = Double("\(item["citycc"] ?? 0)") ?? 0
                    let createTime = "\(item["createtime_name"] ?? "--")"
                    
                    // 盈亏：兼容 Double/String
                    let pl: String
                    if let plDouble = item["profitLose"] as? Double {
                        pl = String(format: "%.2f", plDouble)
                    } else {
                        pl = "\(item["profitLose"] ?? "0")"
                    }
                    let plRate = "\(item["profitLose_rate"] ?? "0")"
                    
                    // 对齐安卓 toCurrentRecord:
                    // value2 = "${citycc.toLong()}/$number" → 市值/数量
                    // value3 = "$cai_buy/$buyprice"        → 现价/买入
                    return Holding(
                        name: name,
                        code: "\(exchangeStr) \(code)",
                        col2Top: String(format: "%.0f", citycc),
                        col2Bottom: String(format: "%.0f", number),
                        col3Top: String(format: "%.2f", caiBuy),
                        col3Bottom: String(format: "%.2f", buyPrice),
                        profitLoss: pl,
                        profitLossPercent: plRate,
                        date: createTime
                    )
                }
                if self.selectedTabIndex == 0 {
                    self.tableView.reloadData()
                    self.emptyLabel.isHidden = !self.holdings.isEmpty
                }
                
            case .failure(_):
                self.emptyLabel.isHidden = false
            }
        }
        
        // 同时加载历史持仓
        loadHistoricalData()
        // 加载新股持仓
        loadNewStockHoldings()
        // 加载申购记录
        loadSubscriptionRecords()
    }

    private func loadHistoricalData() {
        // 默认查询近一年数据
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
                
                // 缓存原始数据
                self.rawHistoricalData = list
                
                self.historicalHoldings = list.compactMap { item in
                    let name = item["title"] as? String ?? "--"
                    let code = item["code"] as? String ?? "--"
                    let allcode = item["allcode"] as? String ?? ""
                    let buytype = "\(item["buytype"] ?? "1")"
                    
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
                    
                    // 对齐安卓：所有字段兼容 Double/String/Int
                    let buyPrice = Double("\(item["buyprice"] ?? 0)") ?? 0
                    let sellPrice = Double("\(item["cai_buy"] ?? 0)") ?? 0
                    let numberStr = "\(item["number"] ?? "0")"
                    let number = Double(numberStr) ?? 0
                    // 对齐安卓：金额用 money 字段，不是本地计算
                    let money = "\(item["money"] ?? "0")"
                    
                    // 盈亏：兼容 Double/String
                    let profitLose: String
                    if let plDouble = item["profitLose"] as? Double {
                        profitLose = String(format: "%.2f", plDouble)
                    } else {
                        profitLose = "\(item["profitLose"] ?? "0")"
                    }
                    let plRate = "\(item["profitLose_rate"] ?? "--")"
                    
                    let createTime = "\(item["createtime_name"] ?? "--")"
                    
                    // 对齐安卓：交易类型用 buytype 判断
                    let typeLabel = buytype == "7" ? "大宗交易" : "普通交易"
                    
                    return HistoricalHolding(
                        typeLabel: typeLabel,
                        name: name,
                        marketLine: "\(exchangeStr) \(code)",
                        date: createTime,
                        buyPrice: String(format: "%.2f", buyPrice),
                        quantity: String(format: "%.0f", number),
                        currentPrice: String(format: "%.2f", sellPrice),
                        totalCost: money,
                        profitLoss: profitLose,
                        profitLossPercent: plRate
                    )
                }
                
                if self.selectedTabIndex == 1 {
                    self.tableView.reloadData()
                    self.emptyLabel.isHidden = !self.historicalHoldings.isEmpty
                }
                
            case .failure(let err):
                Toast.showInfo(err.localizedDescription)
                break
            }
        }
    }
    
    // 新股持仓 tab 已隐藏（对齐安卓），不再加载
    private func loadNewStockHoldings() { }
    
    // MARK: - 申购记录（Tab 2）
    private func loadSubscriptionRecords() {
        SecureNetworkManager.shared.request(
            api: "/api/subscribe/getsgnewgu",
            method: .get,
            params: ["page": "1", "size": "50"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["dxlog_list"] as? [[String: Any]] else { return }
                
                self.subscriptionNewStocks = list.compactMap { item in
                    let name = item["name"] as? String ?? "--"
                    let code = item["code"] as? String ?? "--"
                    let statusStr = "\(item["status"] ?? "0")"
                    let statusText = item["status_txt"] as? String ?? ""
                    let dateStr = item["createtime_txt"] as? String ?? ""
                    
                    let issuePrice: Double
                    if let d = item["sg_fx_price"] as? Double { issuePrice = d }
                    else if let n = item["sg_fx_price"] as? NSNumber { issuePrice = n.doubleValue }
                    else if let s = item["sg_fx_price"] as? String, let d = Double(s) { issuePrice = d }
                    else { issuePrice = 0.0 }
                    
                    let zqNum = item["zq_num"] as? Int ?? (Int("\(item["zq_num"] ?? "0")") ?? 0)
                    let zqNums = item["zq_nums"] as? Int ?? (Int("\(item["zq_nums"] ?? "0")") ?? 0)
                    
                    let sgSsDate = item["sg_ss_date"] as? String ?? ""
                    let sgSsTag = item["sg_ss_tag"] as? Int ?? (Int("\(item["sg_ss_tag"] ?? "0")") ?? 0)
                    let listingDate = (sgSsTag == 1 && !sgSsDate.isEmpty && sgSsDate != "0000-00-00") ? sgSsDate : "未公布"
                    
                    let zqMoney: Double
                    if let d = item["zq_money"] as? Double { zqMoney = d }
                    else if let n = item["zq_money"] as? NSNumber { zqMoney = n.doubleValue }
                    else if let s = item["zq_money"] as? String, let d = Double(s) { zqMoney = d }
                    else { zqMoney = 0.0 }
                    
                    let syRenjiao: Double
                    if let d = item["sy_renjiao"] as? Double { syRenjiao = d }
                    else if let n = item["sy_renjiao"] as? NSNumber { syRenjiao = n.doubleValue }
                    else if let s = item["sy_renjiao"] as? String, let d = Double(s) { syRenjiao = d }
                    else { syRenjiao = 0.0 }
                    
                    return NewStock(
                        id: "\(item["id"] ?? "")",
                        name: name,
                        code: code,
                        status: NewStockStatus(rawValue: statusStr) ?? .successful,
                        statusText: statusText,
                        issuePrice: issuePrice,
                        quantity: zqNum,
                        lots: zqNums,
                        listingDate: listingDate,
                        hasListingDate: sgSsTag == 1,
                        paidAmount: zqMoney,
                        remainRenjiao: syRenjiao,
                        date: dateStr
                    )
                }
                
                if self.selectedTabIndex == 2 {
                    self.tableView.reloadData()
                    self.emptyLabel.isHidden = !self.subscriptionNewStocks.isEmpty
                }
                
            case .failure(_): break
            }
        }
    }
}


// MARK: - UITableViewDataSource
extension MyHoldingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        switch selectedTabIndex {
        case 0: return 1
        case 1: return historicalHoldings.count
        case 2: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedTabIndex {
        case 0: return holdings.count
        case 1: return 1
        case 2: return subscriptionNewStocks.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selectedTabIndex == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyHoldingsHistoryRowCell", for: indexPath) as! MyHoldingsHistoryRowCell
            cell.configure(with: historicalHoldings[indexPath.section])
            cell.onDetail = { [weak self] in
                guard let self = self else { return }
                let vc = HoldingDetailViewController()
                if indexPath.section < self.rawHistoricalData.count {
                    vc.holdingData = self.rawHistoricalData[indexPath.section]
                }
                vc.isHistorical = true
                vc.hiddingButton = false // 历史记录显示“返回”按钮，不应隐藏
                vc.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
            }
            cell.onMarket = { [weak self] in
                // 行情
            }
            cell.onProfit = { [weak self] in
                // 盈利
            }
            return cell
        }
        
        if selectedTabIndex == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriptionCell", for: indexPath) as! NewStockCell
            cell.configure(with: subscriptionNewStocks[indexPath.row])
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HoldingCell", for: indexPath) as! MyHoldingsHoldingCell
        cell.configure(with: holdings[indexPath.row])
        cell.onDetail = { [weak self] in
            guard let self = self else { return }
            let vc = HoldingDetailViewController()
            if indexPath.row < self.rawHoldingsData.count {
                vc.holdingData = self.rawHoldingsData[indexPath.row]
            }
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        cell.onMarket = { [weak self] in
            guard let self = self else { return }
            let item = self.holdings[indexPath.row]
            let vc = StockDetailViewController()
            vc.stockCode = item.code.components(separatedBy: " ").last ?? ""
            vc.stockName = item.name
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        cell.onSell = { [weak self] in
            guard let self = self else { return }
            let item = self.holdings[indexPath.row]
            let vc = AccountTradeViewController()
            vc.stockCode = item.code.components(separatedBy: " ").last ?? ""
            vc.stockName = item.name
            vc.selectedIndex = 1 // 1 是卖出
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        cell.onProfit = { [weak self] in
            // 盈利
        }
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Tab 2 (申购记录) 使用卡片式 NewStockCell，不需要表头
        if selectedTabIndex == 2 { return nil }
        if selectedTabIndex == 1 {
            if section == 0 {
                return makeColumnHeaderView()
            }
            let spacer = UIView()
            spacer.backgroundColor = .white
            return spacer
        }
        return makeColumnHeaderView()
    }

    private func makeColumnHeaderView() -> UIView {
        let header = UIView()
        header.backgroundColor = .white
        let gray = Constants.Color.textSecondary
        
        let nameHeader = UILabel()
        nameHeader.text = "名称/代码"
        nameHeader.font = UIFont.systemFont(ofSize: 14)
        nameHeader.textColor = gray
        nameHeader.textAlignment = .left
        header.addSubview(nameHeader)
        nameHeader.translatesAutoresizingMaskIntoConstraints = false
        
        let col2Header = UILabel()
        // 对齐安卓：当前持仓显示"市值/数量"，历史持仓显示"买入/数量"
        col2Header.text = selectedTabIndex == 1 ? "买入/数量" : "市值/数量"
        col2Header.font = UIFont.systemFont(ofSize: 14)
        col2Header.textColor = gray
        col2Header.textAlignment = .center
        header.addSubview(col2Header)
        col2Header.translatesAutoresizingMaskIntoConstraints = false
        
        let col3Header = UILabel()
        // 对齐安卓：当前持仓显示"现价/买入"，历史持仓显示"卖出/金额"
        col3Header.text = selectedTabIndex == 1 ? "卖出/金额" : "现价/买入"
        col3Header.font = UIFont.systemFont(ofSize: 14)
        col3Header.textColor = gray
        col3Header.textAlignment = .center
        header.addSubview(col3Header)
        col3Header.translatesAutoresizingMaskIntoConstraints = false
        
        let profitLossHeader = UILabel()
        // 对齐安卓：当前持仓显示"盈亏/盈亏比"，历史持仓只显示"盈亏"
        profitLossHeader.text = selectedTabIndex == 1 ? "盈亏" : "盈亏/盈亏比"
        profitLossHeader.font = UIFont.systemFont(ofSize: 14)
        profitLossHeader.textColor = gray
        profitLossHeader.textAlignment = .right
        header.addSubview(profitLossHeader)
        profitLossHeader.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameHeader.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 48),
            nameHeader.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            nameHeader.widthAnchor.constraint(equalToConstant: 80),
            
            col2Header.centerXAnchor.constraint(equalTo: header.centerXAnchor, constant: -40),
            col2Header.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            col2Header.widthAnchor.constraint(equalToConstant: 80),
            
            col3Header.centerXAnchor.constraint(equalTo: header.centerXAnchor, constant: 40),
            col3Header.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            col3Header.widthAnchor.constraint(equalToConstant: 80),
            
            profitLossHeader.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            profitLossHeader.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            profitLossHeader.widthAnchor.constraint(equalToConstant: 80)
        ])
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if selectedTabIndex == 2 { return 0 }
        if selectedTabIndex == 1 {
            return section == 0 ? 44 : 10
        }
        return 44
    }
}

// MARK: - UITableViewDelegate
extension MyHoldingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return selectedTabIndex == 1 ? 88 : 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if selectedTabIndex == 1 { return }
        if selectedTabIndex == 0 {
            let vc = HoldingDetailViewController()
            if indexPath.row < rawHoldingsData.count {
                vc.holdingData = rawHoldingsData[indexPath.row]
            }
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - MyHoldingsHoldingCell
class MyHoldingsHoldingCell: UITableViewCell {
    
    private let typeTagView = UIView()
    private let typeTagLabel = UILabel()
    private let contentBlock = UIView()
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let buyPriceLabel = UILabel()
    private let quantityLabel = UILabel()
    private let currentPriceLabel = UILabel()
    private let totalCostLabel = UILabel()
    private let profitLossLabel = UILabel()
    private let profitLossPercentLabel = UILabel()
    private let detailButton = UIButton(type: .system)
    private let marketButton = UIButton(type: .system)
    private let sellButton = UIButton(type: .system)
    private let profitButton = UIButton(type: .system)

    var onDetail: (() -> Void)?
    var onMarket: (() -> Void)?
    var onSell: (() -> Void)?
    var onProfit: (() -> Void)?

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
        
        typeTagView.backgroundColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        typeTagView.layer.cornerRadius = 2
        contentView.addSubview(typeTagView)
        typeTagView.translatesAutoresizingMaskIntoConstraints = false

        typeTagLabel.text = "普通交易"
        typeTagLabel.font = UIFont.systemFont(ofSize: 12)
        typeTagLabel.textColor = .white
        typeTagLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        typeTagView.addSubview(typeTagLabel)
        typeTagLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentBlock)
        contentBlock.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.textColor = Constants.Color.textPrimary
        contentBlock.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        codeLabel.font = UIFont.systemFont(ofSize: 12)
        codeLabel.textColor = Constants.Color.textSecondary
        contentBlock.addSubview(codeLabel)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        buyPriceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        buyPriceLabel.textColor = Constants.Color.textPrimary
        buyPriceLabel.textAlignment = .center
        contentBlock.addSubview(buyPriceLabel)
        buyPriceLabel.translatesAutoresizingMaskIntoConstraints = false

        quantityLabel.font = UIFont.systemFont(ofSize: 12)
        quantityLabel.textColor = Constants.Color.textSecondary
        quantityLabel.textAlignment = .center
        contentBlock.addSubview(quantityLabel)
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false

        currentPriceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        currentPriceLabel.textColor = Constants.Color.textPrimary
        currentPriceLabel.textAlignment = .center
        contentBlock.addSubview(currentPriceLabel)
        currentPriceLabel.translatesAutoresizingMaskIntoConstraints = false

        totalCostLabel.font = UIFont.systemFont(ofSize: 12)
        totalCostLabel.textColor = Constants.Color.textSecondary
        totalCostLabel.textAlignment = .center
        contentBlock.addSubview(totalCostLabel)
        totalCostLabel.translatesAutoresizingMaskIntoConstraints = false

        profitLossLabel.font = UIFont.boldSystemFont(ofSize: 14)
        profitLossLabel.textColor = Constants.Color.stockRise
        profitLossLabel.textAlignment = .right
        contentBlock.addSubview(profitLossLabel)
        profitLossLabel.translatesAutoresizingMaskIntoConstraints = false

        // 盈亏比（百分比）
        profitLossPercentLabel.font = UIFont.systemFont(ofSize: 12)
        profitLossPercentLabel.textColor = Constants.Color.textSecondary
        profitLossPercentLabel.textAlignment = .right
        contentBlock.addSubview(profitLossPercentLabel)
        profitLossPercentLabel.translatesAutoresizingMaskIntoConstraints = false

        detailButton.setTitle("详情", for: .normal)
        detailButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        detailButton.setTitleColor(UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0), for: .normal)
        detailButton.layer.cornerRadius = 4
        detailButton.layer.borderWidth = 1
        detailButton.layer.borderColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0).cgColor
        detailButton.addTarget(self, action: #selector(detailTapped), for: .touchUpInside)
        contentBlock.addSubview(detailButton)
        detailButton.translatesAutoresizingMaskIntoConstraints = false

        marketButton.setTitle("行情", for: .normal)
        marketButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        marketButton.setTitleColor(UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0), for: .normal)
        marketButton.layer.cornerRadius = 4
        marketButton.layer.borderWidth = 1
        marketButton.layer.borderColor = UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0).cgColor
        marketButton.addTarget(self, action: #selector(marketTapped), for: .touchUpInside)
        contentBlock.addSubview(marketButton)
        marketButton.translatesAutoresizingMaskIntoConstraints = false

        sellButton.setTitle("卖出", for: .normal)
        sellButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        // 对齐安卓：红色填充圆角按钮
        sellButton.setTitleColor(.white, for: .normal)
        sellButton.backgroundColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        sellButton.layer.cornerRadius = 11
        sellButton.clipsToBounds = true
        sellButton.addTarget(self, action: #selector(sellTapped), for: .touchUpInside)
        contentBlock.addSubview(sellButton)
        sellButton.translatesAutoresizingMaskIntoConstraints = false

        profitButton.setTitle("盈利", for: .normal)
        profitButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        profitButton.setTitleColor(UIColor(red: 0.7, green: 0.35, blue: 0.2, alpha: 1.0), for: .normal)
        profitButton.layer.cornerRadius = 4
        profitButton.layer.borderWidth = 1
        profitButton.layer.borderColor = UIColor(red: 0.7, green: 0.35, blue: 0.2, alpha: 1.0).cgColor
        profitButton.addTarget(self, action: #selector(profitTapped), for: .touchUpInside)
        contentBlock.addSubview(profitButton)
        profitButton.translatesAutoresizingMaskIntoConstraints = false

        let rowGap: CGFloat = 8
        let colWidth: CGFloat = 80
        let vPadding: CGFloat = 12

        NSLayoutConstraint.activate([
            typeTagView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            typeTagView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            typeTagView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            typeTagView.widthAnchor.constraint(equalToConstant: 26),

            typeTagLabel.centerXAnchor.constraint(equalTo: typeTagView.centerXAnchor),
            typeTagLabel.centerYAnchor.constraint(equalTo: typeTagView.centerYAnchor),
            typeTagLabel.widthAnchor.constraint(equalToConstant: 52),
            typeTagLabel.heightAnchor.constraint(equalToConstant: 20),

            contentBlock.leadingAnchor.constraint(equalTo: typeTagView.trailingAnchor, constant: 10),
            contentBlock.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentBlock.topAnchor.constraint(equalTo: contentView.topAnchor, constant: vPadding),
            contentBlock.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -vPadding),

            // Row 1
            nameLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 80),

            buyPriceLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            buyPriceLabel.centerXAnchor.constraint(equalTo: contentBlock.centerXAnchor, constant: -40),
            buyPriceLabel.widthAnchor.constraint(equalToConstant: colWidth),

            currentPriceLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            currentPriceLabel.centerXAnchor.constraint(equalTo: contentBlock.centerXAnchor, constant: 40),
            currentPriceLabel.widthAnchor.constraint(equalToConstant: colWidth),

            profitLossLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            profitLossLabel.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            profitLossLabel.widthAnchor.constraint(equalToConstant: colWidth),

            // 盈亏比显示在盈亏金额下方
            profitLossPercentLabel.topAnchor.constraint(equalTo: profitLossLabel.bottomAnchor, constant: rowGap),
            profitLossPercentLabel.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            profitLossPercentLabel.widthAnchor.constraint(equalToConstant: colWidth),

            // Row 2
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: rowGap),
            codeLabel.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor),
            codeLabel.widthAnchor.constraint(equalToConstant: 80),

            quantityLabel.topAnchor.constraint(equalTo: buyPriceLabel.bottomAnchor, constant: rowGap),
            quantityLabel.centerXAnchor.constraint(equalTo: buyPriceLabel.centerXAnchor),
            quantityLabel.widthAnchor.constraint(equalToConstant: colWidth),

            totalCostLabel.topAnchor.constraint(equalTo: currentPriceLabel.bottomAnchor, constant: rowGap),
            totalCostLabel.centerXAnchor.constraint(equalTo: currentPriceLabel.centerXAnchor),
            totalCostLabel.widthAnchor.constraint(equalToConstant: colWidth),

            // Row 3 (按钮顺序对齐安卓：详情→行情→盈利→卖出)
            detailButton.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: rowGap),
            detailButton.trailingAnchor.constraint(equalTo: marketButton.leadingAnchor, constant: -8),
            detailButton.widthAnchor.constraint(equalToConstant: 46),
            detailButton.heightAnchor.constraint(equalToConstant: 22),

            marketButton.topAnchor.constraint(equalTo: detailButton.topAnchor),
            marketButton.trailingAnchor.constraint(equalTo: profitButton.leadingAnchor, constant: -8),
            marketButton.widthAnchor.constraint(equalToConstant: 46),
            marketButton.heightAnchor.constraint(equalToConstant: 22),

            profitButton.topAnchor.constraint(equalTo: detailButton.topAnchor),
            profitButton.trailingAnchor.constraint(equalTo: sellButton.leadingAnchor, constant: -8),
            profitButton.widthAnchor.constraint(equalToConstant: 46),
            profitButton.heightAnchor.constraint(equalToConstant: 22),

            sellButton.topAnchor.constraint(equalTo: detailButton.topAnchor),
            sellButton.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            sellButton.widthAnchor.constraint(equalToConstant: 46),
            sellButton.heightAnchor.constraint(equalToConstant: 22),
            sellButton.bottomAnchor.constraint(equalTo: contentBlock.bottomAnchor)
        ])
    }
    
    @objc private func detailTapped() { onDetail?() }
    @objc private func marketTapped() { onMarket?() }
    @objc private func sellTapped() { onSell?() }
    @objc private func profitTapped() { onProfit?() }
    
    func configure(with holding: MyHoldingsViewController.Holding) {
        nameLabel.text = holding.name
        codeLabel.text = holding.code
        // 对齐安卓 toCurrentRecord:
        // col2: 市值/数量
        buyPriceLabel.text = holding.col2Top
        quantityLabel.text = holding.col2Bottom
        // col3: 现价/买入
        currentPriceLabel.text = holding.col3Top
        totalCostLabel.text = holding.col3Bottom
        // col4: 盈亏
        profitLossLabel.text = holding.profitLoss
        // 盈亏比（百分比）
        let pct = holding.profitLossPercent
        profitLossPercentLabel.text = pct.hasSuffix("%") ? pct : pct + "%"
        
        let isRise = holding.profitLoss.hasPrefix("+") || (!holding.profitLoss.hasPrefix("-") && Double(holding.profitLoss.replacingOccurrences(of: ",", with: "")) ?? 0 >= 0)
        let plColor = isRise ? Constants.Color.stockRise : Constants.Color.stockFall
        profitLossLabel.textColor = plColor
        profitLossPercentLabel.textColor = plColor
        if holding.profitLoss == "0" || holding.profitLoss == "0.00" {
            profitLossLabel.textColor = .gray
            profitLossPercentLabel.textColor = .gray
        }
    }
}

// MARK: - 历史持仓行 Cell：左侧竖条与 cell 同高、文字从上往下；右侧三行上中下排列且整体垂直居中
class MyHoldingsHistoryRowCell: UITableViewCell {

    private let typeTagView = UIView()
    private let typeTagLabel = UILabel()
    private let contentBlock = UIView()
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let dateLabel = UILabel()
    private let buyPriceLabel = UILabel()
    private let quantityLabel = UILabel()
    private let currentPriceLabel = UILabel()
    private let totalCostLabel = UILabel()
    private let profitLossLabel = UILabel()
    private let detailButton = UIButton(type: .system)
    private let marketButton = UIButton(type: .system)
    private let profitButton = UIButton(type: .system)

    var onDetail: (() -> Void)?
    var onMarket: (() -> Void)?
    var onProfit: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white

        typeTagView.backgroundColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        typeTagView.layer.cornerRadius = 2
        contentView.addSubview(typeTagView)
        typeTagView.translatesAutoresizingMaskIntoConstraints = false

        typeTagLabel.text = "普通交易"
        typeTagLabel.font = UIFont.systemFont(ofSize: 12)
        typeTagLabel.textColor = .white
        typeTagLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        typeTagView.addSubview(typeTagLabel)
        typeTagLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentBlock)
        contentBlock.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.textColor = Constants.Color.textPrimary
        contentBlock.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        codeLabel.font = UIFont.systemFont(ofSize: 12)
        codeLabel.textColor = Constants.Color.textSecondary
        contentBlock.addSubview(codeLabel)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = Constants.Color.textTertiary
        contentBlock.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        buyPriceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        buyPriceLabel.textColor = Constants.Color.textPrimary
        buyPriceLabel.textAlignment = .center
        contentBlock.addSubview(buyPriceLabel)
        buyPriceLabel.translatesAutoresizingMaskIntoConstraints = false

        quantityLabel.font = UIFont.systemFont(ofSize: 12)
        quantityLabel.textColor = Constants.Color.textSecondary
        quantityLabel.textAlignment = .center
        contentBlock.addSubview(quantityLabel)
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false

        currentPriceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        currentPriceLabel.textColor = Constants.Color.textPrimary
        currentPriceLabel.textAlignment = .center
        contentBlock.addSubview(currentPriceLabel)
        currentPriceLabel.translatesAutoresizingMaskIntoConstraints = false

        totalCostLabel.font = UIFont.systemFont(ofSize: 12)
        totalCostLabel.textColor = Constants.Color.textSecondary
        totalCostLabel.textAlignment = .center
        contentBlock.addSubview(totalCostLabel)
        totalCostLabel.translatesAutoresizingMaskIntoConstraints = false

        profitLossLabel.font = UIFont.boldSystemFont(ofSize: 14)
        profitLossLabel.textColor = Constants.Color.stockRise
        profitLossLabel.textAlignment = .right
        contentBlock.addSubview(profitLossLabel)
        profitLossLabel.translatesAutoresizingMaskIntoConstraints = false

        detailButton.setTitle("详情", for: .normal)
        detailButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        detailButton.setTitleColor(UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0), for: .normal)
        detailButton.layer.cornerRadius = 4
        detailButton.layer.borderWidth = 1
        detailButton.layer.borderColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0).cgColor
        detailButton.addTarget(self, action: #selector(detailTapped), for: .touchUpInside)
        contentBlock.addSubview(detailButton)
        detailButton.translatesAutoresizingMaskIntoConstraints = false

        marketButton.setTitle("行情", for: .normal)
        marketButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        marketButton.setTitleColor(UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0), for: .normal)
        marketButton.layer.cornerRadius = 4
        marketButton.layer.borderWidth = 1
        marketButton.layer.borderColor = UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1.0).cgColor
        marketButton.addTarget(self, action: #selector(marketTapped), for: .touchUpInside)
        contentBlock.addSubview(marketButton)
        marketButton.translatesAutoresizingMaskIntoConstraints = false

        profitButton.setTitle("盈利", for: .normal)
        profitButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        profitButton.setTitleColor(UIColor(red: 0.7, green: 0.35, blue: 0.2, alpha: 1.0), for: .normal)
        profitButton.layer.cornerRadius = 4
        profitButton.layer.borderWidth = 1
        profitButton.layer.borderColor = UIColor(red: 0.7, green: 0.35, blue: 0.2, alpha: 1.0).cgColor
        profitButton.addTarget(self, action: #selector(profitTapped), for: .touchUpInside)
        contentBlock.addSubview(profitButton)
        profitButton.translatesAutoresizingMaskIntoConstraints = false

        let rowGap: CGFloat = 8
        let colWidth: CGFloat = 80
        let vPadding: CGFloat = 12

        NSLayoutConstraint.activate([
            typeTagView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            typeTagView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            typeTagView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            typeTagView.widthAnchor.constraint(equalToConstant: 26),

            typeTagLabel.centerXAnchor.constraint(equalTo: typeTagView.centerXAnchor),
            typeTagLabel.centerYAnchor.constraint(equalTo: typeTagView.centerYAnchor),
            typeTagLabel.widthAnchor.constraint(equalToConstant: 52),
            typeTagLabel.heightAnchor.constraint(equalToConstant: 20),

            contentBlock.leadingAnchor.constraint(equalTo: typeTagView.trailingAnchor, constant: 10),
            contentBlock.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentBlock.topAnchor.constraint(equalTo: contentView.topAnchor, constant: vPadding),
            contentBlock.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -vPadding),

            // Row 1
            nameLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 80),

            buyPriceLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            buyPriceLabel.centerXAnchor.constraint(equalTo: contentBlock.centerXAnchor, constant: -40),
            buyPriceLabel.widthAnchor.constraint(equalToConstant: colWidth),

            currentPriceLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            currentPriceLabel.centerXAnchor.constraint(equalTo: contentBlock.centerXAnchor, constant: 40),
            currentPriceLabel.widthAnchor.constraint(equalToConstant: colWidth),

            profitLossLabel.topAnchor.constraint(equalTo: contentBlock.topAnchor),
            profitLossLabel.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            profitLossLabel.widthAnchor.constraint(equalToConstant: colWidth),

            // Row 2
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: rowGap),
            codeLabel.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor),
            codeLabel.widthAnchor.constraint(equalToConstant: 80),

            quantityLabel.topAnchor.constraint(equalTo: buyPriceLabel.bottomAnchor, constant: rowGap),
            quantityLabel.centerXAnchor.constraint(equalTo: buyPriceLabel.centerXAnchor),
            quantityLabel.widthAnchor.constraint(equalToConstant: colWidth),

            totalCostLabel.topAnchor.constraint(equalTo: currentPriceLabel.bottomAnchor, constant: rowGap),
            totalCostLabel.centerXAnchor.constraint(equalTo: currentPriceLabel.centerXAnchor),
            totalCostLabel.widthAnchor.constraint(equalToConstant: colWidth),

            // Row 3 (Date + Buttons)
            dateLabel.leadingAnchor.constraint(equalTo: contentBlock.leadingAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: detailButton.centerYAnchor),

            detailButton.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: rowGap),
            detailButton.trailingAnchor.constraint(equalTo: marketButton.leadingAnchor, constant: -10),
            detailButton.widthAnchor.constraint(equalToConstant: 52),
            detailButton.heightAnchor.constraint(equalToConstant: 22),

            marketButton.topAnchor.constraint(equalTo: detailButton.topAnchor),
            marketButton.trailingAnchor.constraint(equalTo: profitButton.leadingAnchor, constant: -10),
            marketButton.widthAnchor.constraint(equalToConstant: 52),
            marketButton.heightAnchor.constraint(equalToConstant: 22),

            profitButton.topAnchor.constraint(equalTo: detailButton.topAnchor),
            profitButton.trailingAnchor.constraint(equalTo: contentBlock.trailingAnchor),
            profitButton.widthAnchor.constraint(equalToConstant: 52),
            profitButton.heightAnchor.constraint(equalToConstant: 22),
            profitButton.bottomAnchor.constraint(equalTo: contentBlock.bottomAnchor)
        ])
    }

    @objc private func detailTapped() { onDetail?() }
    @objc private func marketTapped() { onMarket?() }
    @objc private func profitTapped() { onProfit?() }

    func configure(with item: MyHoldingsViewController.HistoricalHolding) {
        typeTagLabel.text = item.typeLabel
        nameLabel.text = item.name
        // 对齐安卓：codeLabel 显示交易所+代码，如 "沪 920166"
        codeLabel.text = item.marketLine
        dateLabel.text = item.date
        buyPriceLabel.text = item.buyPrice
        quantityLabel.text = item.quantity
        currentPriceLabel.text = item.currentPrice
        totalCostLabel.text = item.totalCost
        profitLossLabel.text = item.profitLoss
        
        let isRise = item.profitLoss.hasPrefix("+") || (!item.profitLoss.hasPrefix("-") && Double(item.profitLoss.replacingOccurrences(of: ",", with: "")) ?? 0 >= 0)
        let plColor = isRise ? Constants.Color.stockRise : Constants.Color.stockFall
        profitLossLabel.textColor = plColor
        if item.profitLoss == "0" || item.profitLoss == "0.00" {
            profitLossLabel.textColor = .gray
        }
    }
}

