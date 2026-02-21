//
//  ZixuanViewController.swift
//  zhengqaun
//

import UIKit

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

    /// 自选行数据：名称, 最新价, 涨跌幅, 涨跌额, 是否上涨
    private var listData: [(String, String, String, String, Bool)] = []

    private let bgColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
    private let textPrimary = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
    private let textSecondary = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)
    private let riseColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    private let fallColor = UIColor(red: 0.2, green: 0.6, blue: 0.35, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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

    @objc private func serviceTapped() { }
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

        let indices: [(String, String, String, Bool)] = [
            ("上证指数", "3968.84", "+3.72 0.09%", true),
            ("深证成指", "3968.84", "+3.72 0.09%", true),
            ("北证50", "10015.86", "-15.97 0.16%", false)
        ]
        for item in indices {
            indexStack.addArrangedSubview(makeIndexCard(name: item.0, value: item.1, change: item.2, isRise: item.3))
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
        listData = [
            ("舒泰神", "27.32", "-0.98%", "-0.26", false),
            ("中钢天源", "8.65", "-0.92%", "-0.08", false),
            ("芭薇股份", "6.28", "-0.63%", "-0.04", false),
            ("兴图新科", "18.52", "+1.61%", "+0.29", true)
        ]
        updateListVisibility()
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
        cell.configure(name: row.0, latest: row.1, changePct: row.2, changeAmt: row.3, isRise: row.4)
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
        let vc = StockDetailViewController()
        vc.stockName = row.0
        vc.stockCode = ""
        vc.exchange = ""
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
