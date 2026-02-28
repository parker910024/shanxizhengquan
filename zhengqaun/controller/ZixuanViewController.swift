//
//  ZixuanViewController.swift
//  zhengqaun
//

import UIKit
import SafariServices

/// 自选股数据模型
struct ZixuanStockItem {
    let name: String
    let code: String
    let symbol: String      // 如 sh688108
    let trade: String       // 当前价
    let changePct: String   // 涨跌幅
    let changeAmt: String   // 涨跌额
    let isRise: Bool
}

/// 自选页：顶部指数卡片 + 表头(名称/最新/涨跌幅/涨跌额) + 空态「添加自选」或列表
class ZixuanViewController: ZQViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let indexStack = UIStackView()
    private let tableHeaderRow = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyWrap = UIView()
    private let addButton = UIButton(type: .custom)
    private let addLabel = UILabel()

    /// 自选行数据
    private var listData: [ZixuanStockItem] = []
    
    /// 指数卡片标签引用，用于更新数据
    private var indexCardLabels: [(nameL: UILabel, valueL: UILabel, changeL: UILabel)] = []
    
    /// 指数数据（name, code, allcode），用于点击跳转
    private var indexItems: [(name: String, code: String, allcode: String)] = []

    private let bgColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
    private let textPrimary = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
    private let textSecondary = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)
    private let riseColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    private let fallColor = UIColor(red: 0.2, green: 0.6, blue: 0.35, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadIndexData()
        loadZixuanList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 每次回到此页刷新自选列表
        loadZixuanList()
    }

    private func setupUI() {
        view.backgroundColor = .white
        setupNavigationBar()
        setupIndexSection()
        setupTableHeaderRow()
        setupEmptyState()
        setupTableView()
        updateListVisibility()
    }

    private func setupNavigationBar() {
        gk_navTitle = "自选"
        gk_navBackgroundColor = .white
        gk_navTintColor = .black
        gk_navTitleColor = textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 15)
        gk_statusBarStyle = .default
        gk_navLineHidden = true
        gk_navItemRightSpace = 12

        let serviceBtn = UIButton(type: .system)
        serviceBtn.setImage(UIImage(systemName: "headphones"), for: .normal)
        serviceBtn.tintColor = textPrimary
        serviceBtn.addTarget(self, action: #selector(serviceTapped), for: .touchUpInside)
        let searchBtn = UIButton(type: .system)
        searchBtn.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchBtn.tintColor = textPrimary
        searchBtn.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        let serviceItem = UIBarButtonItem(customView: serviceBtn)
        let searchItem = UIBarButtonItem(customView: searchBtn)
        serviceItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        searchItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        if let v = serviceItem.customView {
            NSLayoutConstraint.activate([v.widthAnchor.constraint(equalToConstant: 44), v.heightAnchor.constraint(equalToConstant: 44)])
        }
        if let v = searchItem.customView {
            NSLayoutConstraint.activate([v.widthAnchor.constraint(equalToConstant: 44), v.heightAnchor.constraint(equalToConstant: 44)])
        }
        gk_navRightBarButtonItems = [searchItem, serviceItem] // 左 客服，右 搜索
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
    @objc private func searchTapped() {
        let vc = StockSearchViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func setupIndexSection() {
        view.addSubview(contentView)
        contentView.backgroundColor = .white
        contentView.translatesAutoresizingMaskIntoConstraints = false

        indexStack.axis = .horizontal
        indexStack.distribution = .fillEqually
        indexStack.spacing = 10
        contentView.addSubview(indexStack)
        indexStack.translatesAutoresizingMaskIntoConstraints = false

        let defaultIndices = ["上证指数", "深证成指", "北证50"]
        for (i, name) in defaultIndices.enumerated() {
            let card = makeIndexCard(name: name, value: "--", change: "-- --", isRise: true)
            card.tag = i
            card.isUserInteractionEnabled = true
            card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(indexCardTapped(_:))))
            indexStack.addArrangedSubview(card)
        }

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            indexStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            indexStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            indexStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            indexStack.heightAnchor.constraint(equalToConstant: 76)
        ])
    }

    private func makeIndexCard(name: String, value: String, change: String, isRise: Bool) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 8
        let nameL = UILabel()
        nameL.text = name
        nameL.font = UIFont.systemFont(ofSize: 16)
        nameL.textColor = textSecondary
        let valueL = UILabel()
        valueL.text = value
        valueL.font = UIFont.boldSystemFont(ofSize: 20)
        valueL.textColor = isRise ? riseColor : fallColor
        let changeL = UILabel()
        changeL.text = change
        changeL.font = UIFont.systemFont(ofSize: 15)
        changeL.textColor = isRise ? riseColor : fallColor
        for v in [nameL, valueL, changeL] {
            card.addSubview(v)
            v.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            nameL.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            nameL.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            valueL.topAnchor.constraint(equalTo: nameL.bottomAnchor, constant: 6),
            valueL.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            changeL.topAnchor.constraint(equalTo: valueL.bottomAnchor, constant: 4),
            changeL.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10)
        ])
        // 保存标签引用
        indexCardLabels.append((nameL: nameL, valueL: valueL, changeL: changeL))
        return card
    }

    private func setupTableHeaderRow() {
        tableHeaderRow.backgroundColor = .white
        contentView.addSubview(tableHeaderRow)
        tableHeaderRow.translatesAutoresizingMaskIntoConstraints = false
        let sep = UIView()
        sep.backgroundColor = UIColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1.0)
        tableHeaderRow.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false
        let titles = ["名称", "最新", "涨跌幅", "涨跌额"]
        var labels: [UILabel] = []
        for t in titles {
            let l = UILabel()
            l.text = t
            l.font = UIFont.systemFont(ofSize: 13)
            l.textColor = textSecondary
            tableHeaderRow.addSubview(l)
            l.translatesAutoresizingMaskIntoConstraints = false
            labels.append(l)
        }
        NSLayoutConstraint.activate([
            tableHeaderRow.topAnchor.constraint(equalTo: indexStack.bottomAnchor, constant: 12),
            tableHeaderRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableHeaderRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableHeaderRow.heightAnchor.constraint(equalToConstant: 40),
            sep.topAnchor.constraint(equalTo: tableHeaderRow.topAnchor),
            sep.leadingAnchor.constraint(equalTo: tableHeaderRow.leadingAnchor, constant: 16),
            sep.trailingAnchor.constraint(equalTo: tableHeaderRow.trailingAnchor, constant: -16),
            sep.heightAnchor.constraint(equalToConstant: 1/UIScreen.main.scale)
        ])
        let w = UIScreen.main.bounds.width
        NSLayoutConstraint.activate([
            labels[0].leadingAnchor.constraint(equalTo: tableHeaderRow.leadingAnchor, constant: 16),
            labels[0].centerYAnchor.constraint(equalTo: tableHeaderRow.centerYAnchor),
            labels[1].leadingAnchor.constraint(equalTo: tableHeaderRow.leadingAnchor, constant: w * 0.32),
            labels[1].centerYAnchor.constraint(equalTo: tableHeaderRow.centerYAnchor),
            labels[2].leadingAnchor.constraint(equalTo: tableHeaderRow.leadingAnchor, constant: w * 0.52),
            labels[2].centerYAnchor.constraint(equalTo: tableHeaderRow.centerYAnchor),
            labels[3].trailingAnchor.constraint(equalTo: tableHeaderRow.trailingAnchor, constant: -16),
            labels[3].centerYAnchor.constraint(equalTo: tableHeaderRow.centerYAnchor)
        ])
    }

    private func setupEmptyState() {
        bodyContainer.backgroundColor = .clear
        contentView.addSubview(bodyContainer)
        bodyContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bodyContainer.topAnchor.constraint(equalTo: tableHeaderRow.bottomAnchor),
            bodyContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bodyContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bodyContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        emptyWrap.backgroundColor = .clear
        bodyContainer.addSubview(emptyWrap)
        emptyWrap.translatesAutoresizingMaskIntoConstraints = false
        addButton.setImage(UIImage(named: "optional-add"), for: .normal)
        addButton.imageView?.contentMode = .scaleAspectFit
        addButton.backgroundColor = .clear
        addButton.addTarget(self, action: #selector(addZixuanTapped), for: .touchUpInside)
        addLabel.text = "添加自选"
        addLabel.font = UIFont.systemFont(ofSize: 16)
        addLabel.textColor = textPrimary
        emptyWrap.addSubview(addButton)
        emptyWrap.addSubview(addLabel)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addButton.centerXAnchor.constraint(equalTo: emptyWrap.centerXAnchor),
            addButton.centerYAnchor.constraint(equalTo: emptyWrap.centerYAnchor, constant: -100),
            addButton.widthAnchor.constraint(equalToConstant: 34),
            addButton.heightAnchor.constraint(equalToConstant: 34),
            addLabel.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 8),
            addLabel.centerXAnchor.constraint(equalTo: emptyWrap.centerXAnchor),
            emptyWrap.topAnchor.constraint(equalTo: bodyContainer.topAnchor),
            emptyWrap.leadingAnchor.constraint(equalTo: bodyContainer.leadingAnchor),
            emptyWrap.trailingAnchor.constraint(equalTo: bodyContainer.trailingAnchor),
            emptyWrap.bottomAnchor.constraint(equalTo: bodyContainer.bottomAnchor)
        ])
    }

    private let bodyContainer = UIView()

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.isScrollEnabled = true
        tableView.register(ZixuanRowCell.self, forCellReuseIdentifier: "ZixuanRow")
        if #available(iOS 11.0, *) { tableView.contentInsetAdjustmentBehavior = .never }
        if #available(iOS 15.0, *) { tableView.sectionHeaderTopPadding = 0 }
        bodyContainer.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: bodyContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: bodyContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: bodyContainer.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bodyContainer.bottomAnchor)
        ])
    }

    private func updateListVisibility() {
        let isEmpty = listData.isEmpty
        emptyWrap.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        tableView.reloadData()
    }

    @objc private func addZixuanTapped() {
        // 跳转到搜索页添加自选
        let vc = StockSearchViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func indexCardTapped(_ g: UITapGestureRecognizer) {
        guard let card = g.view else { return }
        let idx = card.tag
        guard idx < indexItems.count else { return }
        let item = indexItems[idx]
        let vc = IndexDetailViewController()
        vc.indexName = item.name
        vc.indexCode = item.code
        vc.indexAllcode = item.allcode
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - 加载指数数据
    private func loadIndexData() {
        SecureNetworkManager.shared.request(
            api: "/api/Indexnew/sandahangqing_new",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else { return }
                
                self.indexItems.removeAll()
                for (i, obj) in list.prefix(3).enumerated() {
                    guard i < self.indexCardLabels.count,
                          let arr = obj["allcodes_arr"] as? [Any], arr.count >= 7 else { continue }
                    let str = arr.map { "\($0)" }
                    let name = str[1]
                    let code = str[2]
                    let allcode = obj["allcode"] as? String ?? ""
                    self.indexItems.append((name: name, code: code, allcode: allcode))
                    let price = str[3]
                    let change = str[4]
                    let changePct = str[5]
                    let changeVal = Double(change) ?? 0
                    let isRise = changeVal >= 0
                    let color = isRise ? self.riseColor : self.fallColor
                    let sign = isRise ? "+" : ""
                    
                    self.indexCardLabels[i].nameL.text = name
                    self.indexCardLabels[i].valueL.text = price
                    self.indexCardLabels[i].valueL.textColor = color
                    self.indexCardLabels[i].changeL.text = "\(sign)\(change) \(changePct)%"
                    self.indexCardLabels[i].changeL.textColor = color
                }
                
            case .failure(_): break
            }
        }
    }
    
    // MARK: - 加载自选列表
    private func loadZixuanList() {
        SecureNetworkManager.shared.request(
            api: "/api/elect/getZixuanNew",
            method: .get,
            params: ["page": "1", "size": "50"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        self.listData = []
                        self.updateListVisibility()
                    }
                    return
                }
                
                let parsed = list.compactMap { item -> ZixuanStockItem? in
                    let name = item["name"] as? String ?? "--"
                    let code = item["code"] as? String ?? ""
                    let symbol = item["symbol"] as? String ?? ""
                    let trade = item["trade"] as? String ?? "0.00"
                    let changePct = item["changepercent"] as? String ?? "0.00"
                    let priceChange = item["pricechange"] as? String ?? "0.00"
                    
                    let changeVal = Double(priceChange) ?? 0
                    let isRise = changeVal >= 0
                    let sign = isRise ? "+" : ""
                    
                    return ZixuanStockItem(
                        name: name,
                        code: code,
                        symbol: symbol,
                        trade: trade,
                        changePct: "\(sign)\(changePct)%",
                        changeAmt: "\(sign)\(priceChange)",
                        isRise: isRise
                    )
                }
                
                DispatchQueue.main.async {
                    self.listData = parsed
                    self.updateListVisibility()
                }
                
            case .failure(_): break
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ZixuanViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ZixuanRow", for: indexPath) as! ZixuanRowCell
        let row = listData[indexPath.row]
        cell.configure(name: row.name, latest: row.trade, changePct: row.changePct, changeAmt: row.changeAmt, isRise: row.isRise)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ZixuanViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = listData[indexPath.row]
        // 跳转到 IndexDetailViewController（个股详情页）
        let vc = IndexDetailViewController()
        vc.indexName = row.name
        vc.indexCode = row.code
        vc.indexAllcode = row.symbol
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - 自选行 Cell：名称 | 最新 | 涨跌幅 | 涨跌额
class ZixuanRowCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let latestLabel = UILabel()
    private let changePctLabel = UILabel()
    private let changeAmtLabel = UILabel()
    private let line = UIView()
    private let textPrimary = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
    private let riseColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    private let fallColor = UIColor(red: 0.2, green: 0.6, blue: 0.35, alpha: 1.0)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
        for v in [nameLabel, latestLabel, changePctLabel, changeAmtLabel, line] {
            contentView.addSubview(v)
            v.translatesAutoresizingMaskIntoConstraints = false
        }
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        latestLabel.font = UIFont.systemFont(ofSize: 14)
        changePctLabel.font = UIFont.systemFont(ofSize: 14)
        changeAmtLabel.font = UIFont.systemFont(ofSize: 14)
        line.backgroundColor = UIColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1.0)
        let w = UIScreen.main.bounds.width
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            latestLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: w * 0.32),
            latestLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            changePctLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: w * 0.52),
            changePctLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            changeAmtLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            changeAmtLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            line.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            line.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1/UIScreen.main.scale)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(name: String, latest: String, changePct: String, changeAmt: String, isRise: Bool) {
        nameLabel.text = name
        nameLabel.textColor = textPrimary
        latestLabel.text = latest
        latestLabel.textColor = isRise ? riseColor : fallColor
        changePctLabel.text = changePct
        changePctLabel.textColor = isRise ? riseColor : fallColor
        changeAmtLabel.text = changeAmt
        changeAmtLabel.textColor = isRise ? riseColor : fallColor
    }
}
