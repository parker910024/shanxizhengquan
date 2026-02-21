//
//  MarketViewController.swift
//  zhengqaun
//

import UIKit

/// 行情页：顶部 行情|新股申购|战略配售|天启护盘，主内容「今日申购」+ 表格（与 UI 图一致）
class MarketViewController: ZQViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let segmentTitles = ["行情", "新股申购", "战略配售", "天启护盘"]
    private var selectedSegmentIndex: Int = 1

    /// 今日申购行：(名称, 代码, 市场标签北/沪, 发行价, 所属板块, 市盈率)
    private let subscriptionRows: [(String, String, String, String, String, String)] = [
        ("爱舍伦", "920050", "北", "15.98", "北交", "14.99%"),
        ("爱舍伦", "920050", "北", "15.98", "北交", "14.99%"),
        ("爱舍伦", "920050", "沪", "15.98", "北交", "14.99%")
    ]

    private let bgColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0) // #F8F9FE
    private let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
    private let textPrimary = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
    private let textSecondary = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.gk_navigationBar.isHidden = true
        setupUI()
    }

    /// 外部调用：切换到指定分组（如首页“市场行情”可切到 行情/新股申购 等）
    func switchToTab(index: Int) {
        guard index >= 0, index < segmentTitles.count else { return }
        selectedSegmentIndex = index
        updateSegmentSelection()
        updateTableHeaderForCurrentSegment()
        tableView.reloadData()
    }

    /// 今日申购/今日详情 等标题行（在 tableView 外层）
    private var todayHeaderWrap: UIView!
    private var todayTitleLabel: UILabel!

    private func setupUI() {
        view.backgroundColor = bgColor
//        setupNavigationBar()
        setupSegmentBar()
        setupTodayHeaderRow()
        setupTableView()
    }

    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = .black
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .black
        gk_navTitle = ""
        gk_navLineHidden = true
        gk_navItemRightSpace = 15
        let searchBtn = UIButton(type: .system)
        searchBtn.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchBtn.tintColor = textPrimary
        searchBtn.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        gk_navRightBarButtonItem = UIBarButtonItem(customView: searchBtn)
    }

    private var segmentStack: UIStackView!
    private var segmentButtons: [UIButton] = []

    private var segmentWrap: UIView!

    private func setupSegmentBar() {
        segmentWrap = UIView()
        segmentWrap.backgroundColor = .white
        view.addSubview(segmentWrap)
        segmentWrap.translatesAutoresizingMaskIntoConstraints = false

        segmentStack = UIStackView()
        segmentStack.axis = .horizontal
        segmentStack.distribution = .fill
        segmentStack.spacing = 5
        segmentStack.alignment = .center
        segmentWrap.addSubview(segmentStack)
        segmentStack.translatesAutoresizingMaskIntoConstraints = false

        for (index, title) in segmentTitles.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.tag = index
            btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
            btn.setContentHuggingPriority(.required, for: .horizontal)
            btn.setContentCompressionResistancePriority(.required, for: .horizontal)
            btn.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
            segmentStack.addArrangedSubview(btn)
            segmentButtons.append(btn)
        }

        // 菜单位于导航栏正下方；菜单项按文字长度动态宽度，项间距 5
        NSLayoutConstraint.activate([
            segmentWrap.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.safeAreaTop),
            segmentWrap.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentWrap.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentWrap.heightAnchor.constraint(equalToConstant: 44),
            segmentStack.topAnchor.constraint(equalTo: segmentWrap.topAnchor),
            segmentStack.leadingAnchor.constraint(equalTo: segmentWrap.leadingAnchor, constant: 16),
            segmentStack.trailingAnchor.constraint(lessThanOrEqualTo: segmentWrap.trailingAnchor, constant: -16),
            segmentStack.bottomAnchor.constraint(equalTo: segmentWrap.bottomAnchor)
        ])
        updateSegmentSelection()
    }

    private func updateSegmentSelection() {
        for (index, btn) in segmentButtons.enumerated() {
            let selected = (index == selectedSegmentIndex)
            btn.setTitleColor(selected ? textPrimary : textSecondary, for: .normal)
            btn.titleLabel?.font = selected ? UIFont.boldSystemFont(ofSize: 26) : UIFont.systemFont(ofSize: 18)
        }
    }

    @objc private func segmentTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index != selectedSegmentIndex else { return }
        selectedSegmentIndex = index
        updateSegmentSelection()
        updateTableHeaderForCurrentSegment()
        tableView.reloadData()
    }

    private func updateTableHeaderForCurrentSegment() {
        todayTitleLabel.text = sectionTitleForCurrentSegment()
    }

    @objc private func searchTapped() {
        let vc = StockSearchViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    /// 今日申购/今日详情 行：放在 tableView 外层，紧贴 segment 下方，与 tableView 间距 10
    private func setupTodayHeaderRow() {
        todayHeaderWrap = UIView()
        todayHeaderWrap.backgroundColor = bgColor
        view.addSubview(todayHeaderWrap)
        todayHeaderWrap.translatesAutoresizingMaskIntoConstraints = false

        let redBar = UIView()
        redBar.backgroundColor = themeRed
        redBar.layer.cornerRadius = 2
        todayHeaderWrap.addSubview(redBar)
        redBar.translatesAutoresizingMaskIntoConstraints = false

        todayTitleLabel = UILabel()
        todayTitleLabel.text = sectionTitleForCurrentSegment()
        todayTitleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        todayTitleLabel.textColor = textPrimary
        todayHeaderWrap.addSubview(todayTitleLabel)
        todayTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let dateLabel = UILabel()
        dateLabel.text = "2026-01-30 周五"
        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textColor = textPrimary
        todayHeaderWrap.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            todayHeaderWrap.topAnchor.constraint(equalTo: segmentWrap.bottomAnchor),
            todayHeaderWrap.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            todayHeaderWrap.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            todayHeaderWrap.heightAnchor.constraint(equalToConstant: 28),
            redBar.leadingAnchor.constraint(equalTo: todayHeaderWrap.leadingAnchor, constant: 16),
            redBar.centerYAnchor.constraint(equalTo: todayHeaderWrap.centerYAnchor),
            redBar.widthAnchor.constraint(equalToConstant: 4),
            redBar.heightAnchor.constraint(equalToConstant: 16),
            todayTitleLabel.leadingAnchor.constraint(equalTo: redBar.trailingAnchor, constant: 8),
            todayTitleLabel.centerYAnchor.constraint(equalTo: todayHeaderWrap.centerYAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: todayTitleLabel.trailingAnchor, constant: 12),
            dateLabel.centerYAnchor.constraint(equalTo: todayHeaderWrap.centerYAnchor)
        ])
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = bgColor
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SubscriptionTableHeaderView.self, forHeaderFooterViewReuseIdentifier: "TableHeader")
        tableView.register(SubscriptionRowCell.self, forCellReuseIdentifier: "SubscriptionRow")
        // 禁止系统自动加顶部 contentInset，否则「今日申购」与表头之间会多出一块空白
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        tableView.contentInset = .zero
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        updateTableHeaderForCurrentSegment()

        // tableView 在「今日申购」行下方，间距 10
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: todayHeaderWrap.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// 各分段对应的标题：行情=今日详情，新股申购=今日申购，战略配售=今日战略配售，天启护盘=今日天启护盘
    private func sectionTitleForCurrentSegment() -> String {
        switch selectedSegmentIndex {
        case 0: return "今日详情"
        case 1: return "今日申购"
        case 2: return "今日战略配售"
        case 3: return "今日天启护盘"
        default: return "今日申购"
        }
    }
}

// MARK: - UITableViewDataSource
extension MarketViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedSegmentIndex == 1 { return subscriptionRows.count }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriptionRow", for: indexPath) as! SubscriptionRowCell
        let row = subscriptionRows[indexPath.row]
        cell.configure(name: row.0, code: row.1, market: row.2, price: row.3, sector: row.4, pe: row.5)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MarketViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard selectedSegmentIndex == 1 else { return nil }
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TableHeader") as? SubscriptionTableHeaderView
        header?.configure()
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard selectedSegmentIndex == 1 else { return 0 }
        return 40
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - 表头：申购代码 | 发行价 | 所属板块 | 市盈率
class SubscriptionTableHeaderView: UITableViewHeaderFooterView {
    private let sep = UIView()
    private let codeLabel = UILabel()
    private let priceLabel = UILabel()
    private let sectorLabel = UILabel()
    private let peLabel = UILabel()
    private let textSecondary = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
        sep.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        contentView.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false
        for (l, t) in [(codeLabel, "申购代码"), (priceLabel, "发行价"), (sectorLabel, "所属板块"), (peLabel, "市盈率")] {
            l.text = t
            l.font = UIFont.systemFont(ofSize: 13)
            l.textColor = textSecondary
            contentView.addSubview(l)
            l.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: contentView.topAnchor),
            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sep.heightAnchor.constraint(equalToConstant: 1/UIScreen.main.scale),
            codeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            codeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 110),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sectorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 160),
            sectorLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            peLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            peLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure() {}
}

// MARK: - 表格行：名称+代码+北/沪 | 发行价 | 所属板块 | 市盈率
class SubscriptionRowCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let marketBadge = UILabel()
    private let priceLabel = UILabel()
    private let sectorLabel = UILabel()
    private let peLabel = UILabel()
    private let line = UIView()
    private let textPrimary = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
    private let textSecondary = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)
    private let blueBadge = UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)
    private let redBadge = UIColor(red: 0.9, green: 0.3, blue: 0.35, alpha: 1.0)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
        contentView.addSubview(nameLabel)
        contentView.addSubview(codeLabel)
        contentView.addSubview(marketBadge)
        contentView.addSubview(priceLabel)
        contentView.addSubview(sectorLabel)
        contentView.addSubview(peLabel)
        contentView.addSubview(line)
        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.textColor = textPrimary
        codeLabel.font = UIFont.systemFont(ofSize: 12)
        codeLabel.textColor = textSecondary
        marketBadge.font = UIFont.boldSystemFont(ofSize: 11)
        marketBadge.textColor = .white
        marketBadge.textAlignment = .center
        marketBadge.layer.cornerRadius = 2
        marketBadge.clipsToBounds = true
        priceLabel.font = UIFont.systemFont(ofSize: 14)
        priceLabel.textColor = textPrimary
        sectorLabel.font = UIFont.systemFont(ofSize: 13)
        sectorLabel.textColor = textPrimary
        peLabel.font = UIFont.systemFont(ofSize: 13)
        peLabel.textColor = textPrimary
        line.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        for v in [nameLabel, codeLabel, marketBadge, priceLabel, sectorLabel, peLabel, line] {
            v.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            codeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            marketBadge.leadingAnchor.constraint(equalTo: codeLabel.trailingAnchor, constant: 6),
            marketBadge.centerYAnchor.constraint(equalTo: codeLabel.centerYAnchor),
            marketBadge.widthAnchor.constraint(equalToConstant: 18),
            marketBadge.heightAnchor.constraint(equalToConstant: 16),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 110),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sectorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 160),
            sectorLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            peLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            peLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            line.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            line.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1/UIScreen.main.scale)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(name: String, code: String, market: String, price: String, sector: String, pe: String) {
        nameLabel.text = name
        codeLabel.text = code
        marketBadge.text = market
        marketBadge.backgroundColor = (market == "北") ? blueBadge : redBadge
        priceLabel.text = price
        sectorLabel.text = sector
        peLabel.text = pe
    }
}
