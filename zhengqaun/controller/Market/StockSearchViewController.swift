//
//  StockSearchViewController.swift
//  zhengqaun
//
//  股票搜索页面
//

import UIKit

/// 股票搜索结果数据模型（对齐安卓 StockSearchResult）
struct StockSearchResult: Equatable {
    let name: String          // 股票名称
    let code: String          // 股票代码（纯数字）
    let displayCode: String   // 完整代码（如 sz000001）
    let latter: String        // 简拼
}

class StockSearchViewController: ZQViewController {
    
    /// 交易类型（从交易页传入，决定详情页点击交易后的行为）
    enum TradeType {
        case buy
        case sell
    }
    var tradeType: TradeType = .buy
    
    /// 对齐安卓 buyMode：是否为买入模式（仅从交易页点击买入时设为 true）
    var buyMode: Bool = false
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    // 搜索输入框
    private let searchBar = UIView()
    private let searchIconView = UIImageView()
    private let searchTextField = UITextField()
    private let searchButton = UIButton(type: .system)

    // 未输入时的「热门搜索」区域
    private let hotSearchContainer = UIView()
    private let hotSearchTitleLabel = UILabel()
    private var hotItemViews: [(badge: UIView, badgeLabel: UILabel, nameLabel: UILabel, codeLabel: UILabel)] = []

    // 输入后的股票列表表头
    private let listHeaderView = UIView()
    private let listTitleLabel = UILabel()
    private var headerRowView: UIView?

    // 空状态（无搜索结果时的占位）
    private let emptyStateView = UIView()
    private let emptyIcon = UIImageView()

    // 热门搜索数据（对齐安卓 buildHotStocks：code 含 sh/sz 前缀）
    private var hotStocks: [(name: String, code: String)] = [
        ("平安银行", "sz000001"),
        ("贵州茅台", "sh600519"),
        ("东方财富", "sz300059"),
        ("比亚迪", "sz002594"),
        ("宁德时代", "sz300750"),
        ("中芯国际", "sh688981")
    ]
    
    // 搜索结果数据源（动态更新）
    private var searchResults: [StockSearchResult] = []
    
    // 分页相关（对齐安卓）
    private var activeKeyword: String = ""
    private var currentPage = 0
    private var hasMore = true
    private var isSearching = false
    private let pageSize = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupTableView()
        setupHeaderView()
        setupEmptyState()
        updateUI()
        loadHotStocks()
    }
    
    private func loadHotStocks() {
        // 对齐安卓：热门搜索使用写死数据，不调用接口
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "股票搜索"
        gk_navLineHidden = false
        gk_statusBarStyle = .default
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
        gk_backStyle = .black
    }
    
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    private func setupTableView() {
        let navH = Constants.Navigation.totalNavigationHeight
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // 浅灰色背景
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StockSearchCell.self, forCellReuseIdentifier: "StockSearchCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private var headerContainerView: UIView!
    private let searchRowContainer = UIView()
    private var searchBarTrailingToContainer: NSLayoutConstraint?
    private var searchButtonLeadingToBar: NSLayoutConstraint?
    /// 非空态时折叠热门区域，避免与列表表头约束冲突导致搜索行被挤上去
    private var hotSearchContainerHeightZero: NSLayoutConstraint?
    private var hotSearchContainerBottom: NSLayoutConstraint?

    private func setupHeaderView() {
        let headerView = UIView()
        headerView.backgroundColor = .white
        headerContainerView = headerView

        // 搜索行：搜索框 + 右侧「搜索」按钮
        searchRowContainer.backgroundColor = .white
        headerView.addSubview(searchRowContainer)
        searchRowContainer.translatesAutoresizingMaskIntoConstraints = false

        searchBar.layer.cornerRadius = 8
        searchRowContainer.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        searchIconView.image = UIImage(systemName: "magnifyingglass")
        searchIconView.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        searchIconView.contentMode = .scaleAspectFit
        searchBar.addSubview(searchIconView)
        searchIconView.translatesAutoresizingMaskIntoConstraints = false

        searchTextField.setZqPlaceholder("请输入股票代码/名称")
        searchTextField.font = UIFont.systemFont(ofSize: 14)
        searchTextField.textColor = Constants.Color.textPrimary
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextFieldDidChange), for: .editingChanged)
        searchBar.addSubview(searchTextField)
        searchTextField.translatesAutoresizingMaskIntoConstraints = false

        searchButton.setTitle("搜索", for: .normal)
        searchButton.setTitleColor(Constants.Color.textSecondary, for: .normal)
        searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        searchRowContainer.addSubview(searchButton)
        searchButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchRowContainer.topAnchor.constraint(equalTo: headerView.topAnchor),
            searchRowContainer.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            searchRowContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            searchRowContainer.heightAnchor.constraint(equalToConstant: 56),

            searchBar.leadingAnchor.constraint(equalTo: searchRowContainer.leadingAnchor, constant: 16),
            searchBar.centerYAnchor.constraint(equalTo: searchRowContainer.centerYAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 40),

            searchButton.trailingAnchor.constraint(equalTo: searchRowContainer.trailingAnchor, constant: -16),
            searchButton.centerYAnchor.constraint(equalTo: searchRowContainer.centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 44),

            searchIconView.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: 12),
            searchIconView.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            searchIconView.widthAnchor.constraint(equalToConstant: 18),
            searchIconView.heightAnchor.constraint(equalToConstant: 18),

            searchTextField.leadingAnchor.constraint(equalTo: searchIconView.trailingAnchor, constant: 8),
            searchTextField.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: -12),
            searchTextField.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor)
        ])
        let btnLeading = searchButton.leadingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: 8)
        searchButtonLeadingToBar = btnLeading
        btnLeading.isActive = true
        let barTrailing = searchBar.trailingAnchor.constraint(equalTo: searchRowContainer.trailingAnchor, constant: -16)
        searchBarTrailingToContainer = barTrailing
        barTrailing.isActive = false

        // 热门搜索区域（未输入时显示）
        hotSearchContainer.backgroundColor = .white
        headerView.addSubview(hotSearchContainer)
        hotSearchContainer.translatesAutoresizingMaskIntoConstraints = false

        hotSearchTitleLabel.text = "热门搜索"
        hotSearchTitleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        hotSearchTitleLabel.textColor = Constants.Color.textPrimary
        hotSearchContainer.addSubview(hotSearchTitleLabel)
        hotSearchTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let badgeColors: [UIColor] = [
            UIColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0),   // 1 橙黄
            UIColor(red: 0.95, green: 0.3, blue: 0.25, alpha: 1.0),   // 2 红
            UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),    // 3 黄
            UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0),   // 4-6 灰
            UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0),
            UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        ]
        let colCount = 3
        let itemH: CGFloat = 56
        let spacing: CGFloat = 12
        let cellWidth = (UIScreen.main.bounds.width - 32 - spacing * CGFloat(colCount - 1)) / CGFloat(colCount)
        var firstRowCells: [UIView] = []
        var lastCell: UIView?
        for (idx, stock) in hotStocks.enumerated() {
            let cell = UIView()
            cell.backgroundColor = .clear
            hotSearchContainer.addSubview(cell)
            cell.translatesAutoresizingMaskIntoConstraints = false

            let badge = UIView()
            badge.layer.cornerRadius = 4
            badge.backgroundColor = idx < 3 ? badgeColors[idx] : badgeColors[3]
            cell.addSubview(badge)
            badge.translatesAutoresizingMaskIntoConstraints = false

            let badgeLabel = UILabel()
            badgeLabel.text = "\(idx + 1)"
            badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            badgeLabel.textColor = .white
            badge.addSubview(badgeLabel)
            badgeLabel.translatesAutoresizingMaskIntoConstraints = false

            let nameLabel = UILabel()
            nameLabel.text = stock.name
            nameLabel.font = UIFont.systemFont(ofSize: 15)
            nameLabel.textColor = Constants.Color.textPrimary
            cell.addSubview(nameLabel)
            nameLabel.translatesAutoresizingMaskIntoConstraints = false

            let codeLabel = UILabel()
            codeLabel.text = stock.code
            codeLabel.font = UIFont.systemFont(ofSize: 12)
            codeLabel.textColor = Constants.Color.textTertiary
            cell.addSubview(codeLabel)
            codeLabel.translatesAutoresizingMaskIntoConstraints = false

            hotItemViews.append((badge, badgeLabel, nameLabel, codeLabel))

            let row = idx / colCount
            let col = idx % colCount
            let leadingConstant = 16 + CGFloat(col) * (cellWidth + spacing)

            NSLayoutConstraint.activate([
                badge.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
                badge.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                badge.widthAnchor.constraint(equalToConstant: 22),
                badge.heightAnchor.constraint(equalToConstant: 22),
                badgeLabel.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
                badgeLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
                nameLabel.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 8),
                nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor),
                nameLabel.topAnchor.constraint(equalTo: cell.topAnchor, constant: 10),
                codeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
                codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4)
            ])

            if row == 0 {
                let topC = cell.topAnchor.constraint(equalTo: hotSearchTitleLabel.bottomAnchor, constant: 12)
                topC.priority = .defaultHigh
                topC.isActive = true
                firstRowCells.append(cell)
            } else {
                let topC = cell.topAnchor.constraint(equalTo: firstRowCells[col].bottomAnchor, constant: 8)
                topC.priority = .defaultHigh
                topC.isActive = true
            }
            cell.leadingAnchor.constraint(equalTo: hotSearchContainer.leadingAnchor, constant: leadingConstant).isActive = true
            cell.widthAnchor.constraint(equalToConstant: cellWidth).isActive = true
            let hC = cell.heightAnchor.constraint(equalToConstant: itemH)
            hC.priority = .defaultHigh
            hC.isActive = true
            lastCell = cell
            cell.tag = idx
            cell.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(hotItemTapped(_:)))
            cell.addGestureRecognizer(tap)
        }

        hotSearchContainer.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
        hotSearchContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
        hotSearchContainer.topAnchor.constraint(equalTo: searchRowContainer.bottomAnchor).isActive = true
        if let last = lastCell {
            let bottomC = hotSearchContainer.bottomAnchor.constraint(equalTo: last.bottomAnchor, constant: 24)
            bottomC.priority = .defaultHigh
            hotSearchContainerBottom = bottomC
            bottomC.isActive = true
        }
        hotSearchContainerHeightZero = hotSearchContainer.heightAnchor.constraint(equalToConstant: 0)
        hotSearchContainerHeightZero?.isActive = false

        // 股票列表表头（输入后显示，保持旧页样式）
        listHeaderView.backgroundColor = .white
        headerView.addSubview(listHeaderView)
        listHeaderView.translatesAutoresizingMaskIntoConstraints = false

        listTitleLabel.text = "股票列表"
        listTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        listTitleLabel.textColor = Constants.Color.textPrimary
        listTitleLabel.textAlignment = .center
        listHeaderView.addSubview(listTitleLabel)
        listTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let headerRow = UIView()
        headerRow.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        headerView.addSubview(headerRow)
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerRowView = headerRow

        let nameLabel = UILabel()
        nameLabel.text = "名称"
        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.textColor = Constants.Color.textPrimary
        nameLabel.textAlignment = .left
        headerRow.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let codeLabel = UILabel()
        codeLabel.text = "代码"
        codeLabel.font = UIFont.systemFont(ofSize: 12)
        codeLabel.textColor = Constants.Color.textPrimary
        codeLabel.textAlignment = .center
        headerRow.addSubview(codeLabel)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        let abbreviationLabel = UILabel()
        abbreviationLabel.text = "简拼"
        abbreviationLabel.font = UIFont.systemFont(ofSize: 12)
        abbreviationLabel.textColor = Constants.Color.textPrimary
        abbreviationLabel.textAlignment = .right
        headerRow.addSubview(abbreviationLabel)
        abbreviationLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hotSearchTitleLabel.topAnchor.constraint(equalTo: hotSearchContainer.topAnchor, constant: 4),
            hotSearchTitleLabel.leadingAnchor.constraint(equalTo: hotSearchContainer.leadingAnchor, constant: 16),
            listHeaderView.topAnchor.constraint(equalTo: searchRowContainer.bottomAnchor, constant: 0),
            listHeaderView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            listHeaderView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            listHeaderView.heightAnchor.constraint(equalToConstant: 44),
            listTitleLabel.centerXAnchor.constraint(equalTo: listHeaderView.centerXAnchor),
            listTitleLabel.centerYAnchor.constraint(equalTo: listHeaderView.centerYAnchor),
            headerRow.topAnchor.constraint(equalTo: listHeaderView.bottomAnchor, constant: 10),
            headerRow.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerRow.heightAnchor.constraint(equalToConstant: 40),
            headerRow.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: headerRow.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            codeLabel.centerXAnchor.constraint(equalTo: headerRow.centerXAnchor),
            codeLabel.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor),
            abbreviationLabel.trailingAnchor.constraint(equalTo: headerRow.trailingAnchor, constant: -16),
            abbreviationLabel.centerYAnchor.constraint(equalTo: headerRow.centerYAnchor)
        ])

        updateHeaderMode()
        let h = headerHeightForCurrentMode()
        headerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: h)
        headerView.layoutIfNeeded()
        tableView.tableHeaderView = headerView
    }

    private func headerHeightForCurrentMode() -> CGFloat {
        let isEmpty = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        if isEmpty {
            let rowH: CGFloat = 56
            let titleH: CGFloat = 24
            return 56 + 12 + titleH + 12 + rowH * 2 + 24
        }
        return 56 + 0 + 44 + 10 + 40
    }

    private func updateHeaderMode() {
        let isEmpty = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        // 搜索框和搜索按钮始终使用新样式、位置一致（灰底 + 右侧「搜索」按钮）
        searchBar.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        searchButton.isHidden = false
        searchButtonLeadingToBar?.isActive = true
        searchBarTrailingToContainer?.isActive = false
        hotSearchContainer.isHidden = !isEmpty
        // 搜索态时折叠热门区域：高度为 0 并断开 bottom，避免与列表表头约束冲突导致搜索行被挤上去
        hotSearchContainerHeightZero?.isActive = !isEmpty
        hotSearchContainerBottom?.isActive = isEmpty
        listHeaderView.isHidden = isEmpty
        headerRowView?.isHidden = isEmpty
        let h = headerHeightForCurrentMode()
        headerContainerView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: h)
        headerContainerView?.layoutIfNeeded()
        tableView.tableHeaderView = headerContainerView
    }

    @objc private func searchButtonTapped() {
        searchTextField.becomeFirstResponder()
        performSearch()
    }

    @objc private func hotItemTapped(_ g: UITapGestureRecognizer) {
        guard let cell = g.view, cell.tag < hotStocks.count else { return }
        let item = hotStocks[cell.tag]
        
        // 去掉前缀得到纯数字代码
        let pureCode = item.code
            .replacingOccurrences(of: "sh", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "sz", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "bj", with: "", options: .caseInsensitive)
        
        // 对齐安卓 buyMode：交易模式直接跳转买入页
        if buyMode {
            let vc = StockTradeViewController()
            vc.stockName = item.name
            vc.stockCode = pureCode
            vc.stockAllcode = item.code
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        // 普通模式：跳转详情页
        let vc = IndexDetailViewController()
        vc.indexName = item.name
        vc.indexCode = pureCode
        vc.indexAllcode = item.code
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupEmptyState() {
        emptyStateView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // 浅灰色背景
        emptyStateView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 400)
        
        // 空状态图标（使用系统图标模拟空盒子）
        emptyIcon.image = UIImage(systemName: "tray")
        emptyIcon.tintColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        emptyIcon.contentMode = .scaleAspectFit
        emptyStateView.addSubview(emptyIcon)
        emptyIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emptyIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyIcon.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 80),
            emptyIcon.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        tableView.backgroundView = emptyStateView
    }
    
    private func updateUI() {
        updateHeaderMode()
        tableView.reloadData()
        if searchResults.isEmpty {
            tableView.backgroundView = emptyStateView
        } else {
            tableView.backgroundView = nil
        }
    }
    
    @objc private func searchTextFieldDidChange() {
        // 动态搜索
        performSearch()
    }
    
    private func performSearch() {
        guard let keyword = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !keyword.isEmpty else {
            // 输入框为空时清空（对齐安卓 clearSearchState）
            clearSearchState()
            updateUI()
            return
        }
        startSearch(keyword: keyword, reset: true)
    }

    /// 分页加载更多（对齐安卓 loadMore）
    private func loadMore() {
        guard !activeKeyword.isEmpty, hasMore, !isSearching else { return }
        startSearch(keyword: activeKeyword, reset: false)
    }

    /// 对齐安卓 startSearch：支持分页和去重
    private func startSearch(keyword: String, reset: Bool) {
        if isSearching && !reset { return }

        if reset {
            activeKeyword = keyword
            currentPage = 0
            hasMore = true
            searchResults.removeAll()
        }

        let requestPage = reset ? 1 : currentPage + 1
        isSearching = true

        SecureNetworkManager.shared.request(
            api: "/api/user/searchstrategy",
            method: .get,
            params: ["key": keyword, "page": "\(requestPage)", "size": "\(pageSize)"]
        ) { [weak self] result in
            guard let self = self else { return }
            self.isSearching = false

            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    if reset {
                        self.searchResults = []
                        self.updateUI()
                    }
                    return
                }

                if reset && list.isEmpty {
                    self.searchResults = []
                    self.updateUI()
                    Toast.showInfo("未找到匹配的股票")
                    return
                }

                self.hasMore = list.count >= self.pageSize
                self.currentPage = requestPage

                let pageResults: [StockSearchResult] = list.map { item in
                    let name = item["name"] as? String ?? (item["title"] as? String ?? "")
                    let code = item["code"] as? String ?? ""
                    let allcode = item["allcode"] as? String ?? ""
                    let latter = item["latter"] as? String ?? ""
                    return StockSearchResult(name: name, code: code, displayCode: allcode, latter: latter)
                }

                if reset {
                    self.searchResults = pageResults
                } else {
                    // 去重追加（对齐安卓 appendUniqueResults）
                    let existing = Set(self.searchResults.map { $0.displayCode.lowercased() })
                    let unique = pageResults.filter { !existing.contains($0.displayCode.lowercased()) }
                    self.searchResults.append(contentsOf: unique)
                }
                self.updateUI()

            case .failure(let err):
                Toast.show("搜索失败: \(err.localizedDescription)")
                if reset {
                    self.searchResults = []
                    self.updateUI()
                }
            }
        }
    }

    /// 清空搜索状态（对齐安卓 clearSearchState）
    private func clearSearchState() {
        activeKeyword = ""
        currentPage = 0
        hasMore = true
        isSearching = false
        searchResults.removeAll()
    }
}

// MARK: - UITextFieldDelegate
extension StockSearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        performSearch()
        return true
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension StockSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < searchResults.count else {
            return UITableViewCell()
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StockSearchCell", for: indexPath) as? StockSearchCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: searchResults[indexPath.row])
        cell.selectionStyle = .none

        // 分页加载更多（对齐安卓 LOAD_MORE_THRESHOLD=5）
        if indexPath.row >= searchResults.count - 5 && hasMore && !isSearching {
            loadMore()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < searchResults.count else { return }
        let result = searchResults[indexPath.row]
        let allcode = result.displayCode.isEmpty
            ? buildAllcode(from: result.code) : result.displayCode
        
        // 对齐安卓 buyMode：交易模式直接跳转买入页
        if buyMode {
            let vc = StockTradeViewController()
            vc.stockName = result.name
            vc.stockCode = result.code
            vc.stockAllcode = allcode
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        // 普通模式：跳转详情页
        let vc = IndexDetailViewController()
        vc.indexName = result.name
        vc.indexCode = result.code
        vc.indexAllcode = allcode
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    /// 对齐安卓 inferMarketHint：根据 allcode 前缀判断市场
    private func inferMarketHint(displayCode: String, code: String) -> String {
        let lower = displayCode.lowercased().replacingOccurrences(of: " ", with: "")
        if lower.hasPrefix("sh") { return "沪" }
        if lower.hasPrefix("sz") { return "深" }
        if lower.hasPrefix("bj") { return "京" }
        // 对齐安卓 isBeiJingCode
        if isBeiJingCode(code) { return "京" }
        if code.hasPrefix("6") || code.hasPrefix("5") || code.hasPrefix("9") { return "沪" }
        return "深"
    }

    /// 对齐安卓 isBeiJingCode
    private func isBeiJingCode(_ code: String) -> Bool {
        let digits = code.filter { $0.isNumber }
        return digits.hasPrefix("4")
            || digits.hasPrefix("8")
            || digits.hasPrefix("92")
            || digits.hasPrefix("83")
            || digits.hasPrefix("87")
            || digits.hasPrefix("43")
    }

    /// 根据纯数字代码构建 allcode（当 API 返回的 allcode 为空时用）
    private func buildAllcode(from code: String) -> String {
        if isBeiJingCode(code) { return "bj\(code)" }
        if code.hasPrefix("6") || code.hasPrefix("5") || code.hasPrefix("9") { return "sh\(code)" }
        return "sz\(code)"
    }
}

// MARK: - StockSearchCell（对齐安卓 item_stock_search_result.xml：3 列布局）
class StockSearchCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let latterLabel = UILabel()
    private let separatorLine = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        
        // 股票名称（左对齐，对齐安卓 tv_stock_name）
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        nameLabel.textAlignment = .left
        nameLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票代码（居中，对齐安卓 tv_stock_code）
        codeLabel.font = UIFont.systemFont(ofSize: 14)
        codeLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        codeLabel.textAlignment = .center
        contentView.addSubview(codeLabel)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 简拼（右对齐灰色，对齐安卓 tv_stock_latter #8B8B8B）
        latterLabel.font = UIFont.systemFont(ofSize: 14)
        latterLabel.textColor = UIColor(red: 0.545, green: 0.545, blue: 0.545, alpha: 1.0)
        latterLabel.textAlignment = .right
        contentView.addSubview(latterLabel)
        latterLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 分隔线（对齐安卓 #F0F0F0）
        separatorLine.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0)
        contentView.addSubview(separatorLine)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 3 列等宽布局（对齐安卓 layout_weight=1）
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0/3.0, constant: -16),
            
            codeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            codeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            codeLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0/3.0),
            
            latterLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            latterLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            latterLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 1.0/3.0, constant: -16),
            
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func configure(with result: StockSearchResult) {
        nameLabel.text = result.name
        codeLabel.text = result.code
        latterLabel.text = result.latter
    }
}
