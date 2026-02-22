//
//  MarketViewController.swift
//  zhengqaun
//

import UIKit

/// 行情页：顶部 行情|新股申购|战略配售|天启护盘
/// 行情 Tab 包含：指数卡片、市场概括、行业板块、股票排行榜
class MarketViewController: ZQViewController {

    // MARK: - 颜色 & 常量
    private let bgColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
    private let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
    private let stockGreen = UIColor(red: 0.13, green: 0.73, blue: 0.33, alpha: 1.0)
    private let textPrimary = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
    private let textSecondary = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)

    // MARK: - Segment
    private let segmentTitles = ["行情", "新股申购", "战略配售", "天启护盘"]
    private var selectedSegmentIndex: Int = 0
    private var segmentWrap: UIView!
    private var segmentStack: UIStackView!
    private var segmentButtons: [UIButton] = []

    // MARK: - 行情 Content (segment 0)
    private let hangqingScrollView = UIScrollView()
    private let hangqingContentView = UIView()

    // MARK: - 新股申购 Content (segment 1-3)
    private let subsTableView = UITableView(frame: .zero, style: .plain)
    private var todayHeaderWrap: UIView!
    private var todayTitleLabel: UILabel!
    private let subscriptionRows: [(String, String, String, String, String, String)] = [
        ("爱舍伦", "920050", "北", "15.98", "北交", "14.99%"),
        ("爱舍伦", "920050", "北", "15.98", "北交", "14.99%"),
        ("爱舍伦", "920050", "沪", "15.98", "北交", "14.99%")
    ]

    // MARK: - 指数数据
    private var indexDataList: [[String]] = []

    // MARK: - 市场概括模拟数据
    private struct MarketBarData {
        let label: String
        let count: Int
        let isRise: Bool
    }
    private var marketBars: [MarketBarData] = [
        MarketBarData(label: "涨停", count: 91, isRise: true),
        MarketBarData(label: ">7%", count: 51, isRise: true),
        MarketBarData(label: "5-7%", count: 86, isRise: true),
        MarketBarData(label: "3-5%", count: 187, isRise: true),
        MarketBarData(label: "0-3%", count: 1301, isRise: true),
        MarketBarData(label: "平", count: 91, isRise: true),
        MarketBarData(label: "0-3%", count: 2436, isRise: false),
        MarketBarData(label: "3-5%", count: 658, isRise: false),
        MarketBarData(label: "5-7%", count: 213, isRise: false),
        MarketBarData(label: ">7%", count: 60, isRise: false),
        MarketBarData(label: "跌停", count: 38, isRise: false)
    ]
    private var riseCount: Int = 1716
    private var fallCount: Int = 3405
    private var northboundCapital: String = "4373.61亿"

    // MARK: - 行业板块数据
    private struct SectorData {
        let name: String
        let changePercent: String
        let topStock: String
        let topStockChange: String
    }
    private var sectors: [SectorData] = [
        SectorData(name: "贵金属", changePercent: "+8.04%", topStock: "湖南黄金", topStockChange: "+10.01%"),
        SectorData(name: "采掘行业", changePercent: "+8.04%", topStock: "湖南黄金", topStockChange: "+10.01%"),
        SectorData(name: "酿酒行业", changePercent: "+8.04%", topStock: "湖南黄金", topStockChange: "+10.01%"),
        SectorData(name: "文化传媒", changePercent: "+8.04%", topStock: "湖南黄金", topStockChange: "+10.01%"),
        SectorData(name: "保险", changePercent: "+8.04%", topStock: "湖南黄金", topStockChange: "+10.01%"),
        SectorData(name: "房地产", changePercent: "+8.04%", topStock: "湖南黄金", topStockChange: "+10.01%")
    ]

    // MARK: - 股票排行榜
    private let rankingTabs = ["现价", "涨跌", "涨跌幅", "成交额", "换手率", "昨收"]
    private var selectedRankingTabIndex: Int = 0
    private var rankingTabButtons: [UIButton] = []
    private var rankingTabIndicator: UIView!
    private var stockRankingData: [(name: String, code: String, market: String, price: String, change: String, changePercent: String)] = []
    private var rankingTableView: UITableView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.gk_navigationBar.isHidden = true
        setupUI()
        loadHangqingData()
    }

    /// 外部切换分段
    func switchToTab(index: Int) {
        guard index >= 0, index < segmentTitles.count else { return }
        selectedSegmentIndex = index
        updateSegmentSelection()
        updateVisibleContent()
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = bgColor
        setupSegmentBar()
        setupHangqingScrollView()
        setupSubscriptionContent()
        updateVisibleContent()
    }

    // MARK: - Segment Bar
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
        updateVisibleContent()
    }

    private func updateVisibleContent() {
        if selectedSegmentIndex == 0 {
            hangqingScrollView.isHidden = false
            subsTableView.isHidden = true
            todayHeaderWrap.isHidden = true
        } else {
            hangqingScrollView.isHidden = true
            subsTableView.isHidden = false
            todayHeaderWrap.isHidden = false
            todayTitleLabel.text = sectionTitleForCurrentSegment()
            subsTableView.reloadData()
        }
    }

    private func sectionTitleForCurrentSegment() -> String {
        switch selectedSegmentIndex {
        case 0: return "今日详情"
        case 1: return "今日申购"
        case 2: return "今日战略配售"
        case 3: return "今日天启护盘"
        default: return "今日申购"
        }
    }

    // MARK: - 行情 ScrollView (segment 0)
    private func setupHangqingScrollView() {
        view.addSubview(hangqingScrollView)
        hangqingScrollView.translatesAutoresizingMaskIntoConstraints = false
        hangqingScrollView.backgroundColor = bgColor
        hangqingScrollView.showsVerticalScrollIndicator = false

        hangqingScrollView.addSubview(hangqingContentView)
        hangqingContentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hangqingScrollView.topAnchor.constraint(equalTo: segmentWrap.bottomAnchor),
            hangqingScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hangqingScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hangqingScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hangqingContentView.topAnchor.constraint(equalTo: hangqingScrollView.topAnchor),
            hangqingContentView.leadingAnchor.constraint(equalTo: hangqingScrollView.leadingAnchor),
            hangqingContentView.trailingAnchor.constraint(equalTo: hangqingScrollView.trailingAnchor),
            hangqingContentView.widthAnchor.constraint(equalTo: hangqingScrollView.widthAnchor),
        ])

        buildHangqingSections()
    }

    private var indexCardsContainer: UIView!
    private var indexCardsScrollView: UIScrollView!
    private var marketOverviewContainer: UIView!
    private var sectorContainer: UIView!
    private var rankingContainer: UIView!

    private func buildHangqingSections() {
        // 1. Index Cards
        indexCardsContainer = UIView()
        indexCardsContainer.backgroundColor = .white
        indexCardsContainer.layer.cornerRadius = 8
        hangqingContentView.addSubview(indexCardsContainer)
        indexCardsContainer.translatesAutoresizingMaskIntoConstraints = false

        indexCardsScrollView = UIScrollView()
        indexCardsScrollView.showsHorizontalScrollIndicator = false
        indexCardsScrollView.isPagingEnabled = false
        indexCardsContainer.addSubview(indexCardsScrollView)
        indexCardsScrollView.translatesAutoresizingMaskIntoConstraints = false

        // 2. Market Overview
        marketOverviewContainer = UIView()
        marketOverviewContainer.backgroundColor = .white
        marketOverviewContainer.layer.cornerRadius = 8
        hangqingContentView.addSubview(marketOverviewContainer)
        marketOverviewContainer.translatesAutoresizingMaskIntoConstraints = false

        // 3. Industry Sectors
        sectorContainer = UIView()
        sectorContainer.backgroundColor = .white
        sectorContainer.layer.cornerRadius = 8
        hangqingContentView.addSubview(sectorContainer)
        sectorContainer.translatesAutoresizingMaskIntoConstraints = false

        // 4. Stock Ranking
        rankingContainer = UIView()
        rankingContainer.backgroundColor = .white
        rankingContainer.layer.cornerRadius = 8
        hangqingContentView.addSubview(rankingContainer)
        rankingContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            indexCardsContainer.topAnchor.constraint(equalTo: hangqingContentView.topAnchor, constant: 8),
            indexCardsContainer.leadingAnchor.constraint(equalTo: hangqingContentView.leadingAnchor, constant: 12),
            indexCardsContainer.trailingAnchor.constraint(equalTo: hangqingContentView.trailingAnchor, constant: -12),
            indexCardsContainer.heightAnchor.constraint(equalToConstant: 130),

            indexCardsScrollView.topAnchor.constraint(equalTo: indexCardsContainer.topAnchor),
            indexCardsScrollView.leadingAnchor.constraint(equalTo: indexCardsContainer.leadingAnchor),
            indexCardsScrollView.trailingAnchor.constraint(equalTo: indexCardsContainer.trailingAnchor),
            indexCardsScrollView.bottomAnchor.constraint(equalTo: indexCardsContainer.bottomAnchor),

            marketOverviewContainer.topAnchor.constraint(equalTo: indexCardsContainer.bottomAnchor, constant: 12),
            marketOverviewContainer.leadingAnchor.constraint(equalTo: hangqingContentView.leadingAnchor, constant: 12),
            marketOverviewContainer.trailingAnchor.constraint(equalTo: hangqingContentView.trailingAnchor, constant: -12),

            sectorContainer.topAnchor.constraint(equalTo: marketOverviewContainer.bottomAnchor, constant: 12),
            sectorContainer.leadingAnchor.constraint(equalTo: hangqingContentView.leadingAnchor, constant: 12),
            sectorContainer.trailingAnchor.constraint(equalTo: hangqingContentView.trailingAnchor, constant: -12),

            rankingContainer.topAnchor.constraint(equalTo: sectorContainer.bottomAnchor, constant: 12),
            rankingContainer.leadingAnchor.constraint(equalTo: hangqingContentView.leadingAnchor, constant: 12),
            rankingContainer.trailingAnchor.constraint(equalTo: hangqingContentView.trailingAnchor, constant: -12),
            rankingContainer.bottomAnchor.constraint(equalTo: hangqingContentView.bottomAnchor, constant: -20),
        ])

        buildMarketOverviewSection()
        buildSectorSection()
        buildRankingSection()
    }

    // MARK: - 1. Index Cards
    private func populateIndexCards() {
        indexCardsScrollView.subviews.forEach { $0.removeFromSuperview() }
        let cardWidth: CGFloat = 160
        let cardHeight: CGFloat = 120
        let cardSpacing: CGFloat = 10
        let leftPad: CGFloat = 12

        for (index, data) in indexDataList.enumerated() {
            guard data.count >= 7 else { continue }
            let card = createIndexCard(data: data)
            indexCardsScrollView.addSubview(card)
            card.frame = CGRect(
                x: leftPad + CGFloat(index) * (cardWidth + cardSpacing),
                y: 5,
                width: cardWidth,
                height: cardHeight
            )
        }
        let totalWidth = leftPad + CGFloat(indexDataList.count) * (cardWidth + cardSpacing) + leftPad
        indexCardsScrollView.contentSize = CGSize(width: totalWidth, height: cardHeight + 10)
    }

    private func createIndexCard(data: [String]) -> UIView {
        let name = data.count > 1 ? data[1] : ""
        let price = data.count > 3 ? data[3] : "0"
        let changeAmount = data.count > 4 ? data[4] : "0"
        let changePercent = data.count > 5 ? data[5] : "0"

        let changeVal = Double(changeAmount) ?? 0
        let isRise = changeVal >= 0
        let color = isRise ? themeRed : stockGreen

        let card = UIView()
        card.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
        card.layer.cornerRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = name
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = textPrimary
        card.addSubview(titleLabel)

        let priceLabel = UILabel()
        priceLabel.text = price
        priceLabel.font = UIFont.boldSystemFont(ofSize: 24)
        priceLabel.textColor = color
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.minimumScaleFactor = 0.6
        card.addSubview(priceLabel)

        let changeLabel = UILabel()
        let sign = isRise ? "+" : ""
        changeLabel.text = "\(sign)\(changeAmount)  \(sign)\(changePercent)%"
        changeLabel.font = UIFont.systemFont(ofSize: 11)
        changeLabel.textColor = color
        card.addSubview(changeLabel)

        let chartView = MiniChartView(isRise: isRise, color: color)
        card.addSubview(chartView)

        for v: UIView in [titleLabel, priceLabel, changeLabel, chartView] {
            v.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            priceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            priceLabel.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -12),
            changeLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 4),
            changeLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            chartView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            chartView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            chartView.widthAnchor.constraint(equalToConstant: 60),
            chartView.heightAnchor.constraint(equalToConstant: 30),
        ])

        return card
    }

    // MARK: - 2. Market Overview Section
    private var barChartContainer: UIView!
    private var riseCountLabel: UILabel!
    private var fallCountLabel: UILabel!
    private var progressBar: UIView!
    private var riseProgressLayer: CALayer!

    private func buildMarketOverviewSection() {
        let titleLabel = UILabel()
        titleLabel.text = "市场概括"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = textPrimary
        marketOverviewContainer.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let capitalLabel = UILabel()
        capitalLabel.text = "南向资金流入"
        capitalLabel.font = UIFont.systemFont(ofSize: 13)
        capitalLabel.textColor = textSecondary
        marketOverviewContainer.addSubview(capitalLabel)
        capitalLabel.translatesAutoresizingMaskIntoConstraints = false

        let capitalValueLabel = UILabel()
        capitalValueLabel.text = northboundCapital
        capitalValueLabel.font = UIFont.boldSystemFont(ofSize: 15)
        capitalValueLabel.textColor = themeRed
        marketOverviewContainer.addSubview(capitalValueLabel)
        capitalValueLabel.translatesAutoresizingMaskIntoConstraints = false

        barChartContainer = UIView()
        marketOverviewContainer.addSubview(barChartContainer)
        barChartContainer.translatesAutoresizingMaskIntoConstraints = false

        riseCountLabel = UILabel()
        riseCountLabel.text = "上涨\(riseCount)"
        riseCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        riseCountLabel.textColor = themeRed
        marketOverviewContainer.addSubview(riseCountLabel)
        riseCountLabel.translatesAutoresizingMaskIntoConstraints = false

        fallCountLabel = UILabel()
        fallCountLabel.text = "下跌\(fallCount)"
        fallCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        fallCountLabel.textColor = stockGreen
        fallCountLabel.textAlignment = .right
        marketOverviewContainer.addSubview(fallCountLabel)
        fallCountLabel.translatesAutoresizingMaskIntoConstraints = false

        progressBar = UIView()
        progressBar.backgroundColor = stockGreen
        progressBar.layer.cornerRadius = 3
        progressBar.clipsToBounds = true
        marketOverviewContainer.addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false

        riseProgressLayer = CALayer()
        riseProgressLayer.backgroundColor = themeRed.cgColor
        riseProgressLayer.cornerRadius = 3
        progressBar.layer.addSublayer(riseProgressLayer)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: marketOverviewContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: marketOverviewContainer.leadingAnchor, constant: 16),

            capitalLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            capitalLabel.trailingAnchor.constraint(equalTo: capitalValueLabel.leadingAnchor, constant: -8),

            capitalValueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            capitalValueLabel.trailingAnchor.constraint(equalTo: marketOverviewContainer.trailingAnchor, constant: -16),

            barChartContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            barChartContainer.leadingAnchor.constraint(equalTo: marketOverviewContainer.leadingAnchor, constant: 8),
            barChartContainer.trailingAnchor.constraint(equalTo: marketOverviewContainer.trailingAnchor, constant: -8),
            barChartContainer.heightAnchor.constraint(equalToConstant: 150),

            riseCountLabel.topAnchor.constraint(equalTo: barChartContainer.bottomAnchor, constant: 8),
            riseCountLabel.leadingAnchor.constraint(equalTo: marketOverviewContainer.leadingAnchor, constant: 16),

            fallCountLabel.topAnchor.constraint(equalTo: barChartContainer.bottomAnchor, constant: 8),
            fallCountLabel.trailingAnchor.constraint(equalTo: marketOverviewContainer.trailingAnchor, constant: -16),

            progressBar.topAnchor.constraint(equalTo: riseCountLabel.bottomAnchor, constant: 6),
            progressBar.leadingAnchor.constraint(equalTo: marketOverviewContainer.leadingAnchor, constant: 16),
            progressBar.trailingAnchor.constraint(equalTo: marketOverviewContainer.trailingAnchor, constant: -16),
            progressBar.heightAnchor.constraint(equalToConstant: 6),
            progressBar.bottomAnchor.constraint(equalTo: marketOverviewContainer.bottomAnchor, constant: -16),
        ])

        DispatchQueue.main.async { [weak self] in
            self?.layoutBarChart()
        }
    }

    private var barChartRendered = false

    private func layoutBarChart() {
        barChartContainer.subviews.forEach { $0.removeFromSuperview() }

        let containerWidth = barChartContainer.bounds.width
        let containerHeight = barChartContainer.bounds.height
        guard containerWidth > 0, containerHeight > 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.layoutBarChart()
            }
            return
        }
        barChartRendered = true

        let maxCount = marketBars.map { $0.count }.max() ?? 1
        let barCount = CGFloat(marketBars.count)
        let barSpacing: CGFloat = 4
        let barWidth = (containerWidth - barSpacing * (barCount - 1)) / barCount
        let labelHeight: CGFloat = 18
        let numberHeight: CGFloat = 16
        let maxBarHeight = containerHeight - labelHeight - numberHeight - 8

        for (i, bar) in marketBars.enumerated() {
            let x = CGFloat(i) * (barWidth + barSpacing)
            let barHeight = max(4, CGFloat(bar.count) / CGFloat(maxCount) * maxBarHeight)
            let barY = containerHeight - labelHeight - barHeight

            let barView = UIView()
            barView.backgroundColor = bar.isRise ? themeRed : stockGreen
            barView.layer.cornerRadius = 2
            barView.frame = CGRect(x: x, y: barY, width: barWidth, height: barHeight)
            barChartContainer.addSubview(barView)

            let countLabel = UILabel()
            countLabel.text = "\(bar.count)"
            countLabel.font = UIFont.systemFont(ofSize: 9)
            countLabel.textColor = bar.isRise ? themeRed : stockGreen
            countLabel.textAlignment = .center
            countLabel.frame = CGRect(x: x - 4, y: barY - numberHeight, width: barWidth + 8, height: numberHeight)
            barChartContainer.addSubview(countLabel)

            let label = UILabel()
            label.text = bar.label
            label.font = UIFont.systemFont(ofSize: 9)
            label.textColor = bar.isRise ? themeRed : stockGreen
            label.textAlignment = .center
            label.frame = CGRect(x: x - 4, y: containerHeight - labelHeight, width: barWidth + 8, height: labelHeight)
            barChartContainer.addSubview(label)
        }

        updateProgressBar()
    }

    private func updateProgressBar() {
        let total = CGFloat(riseCount + fallCount)
        let riseRatio = total > 0 ? CGFloat(riseCount) / total : 0.5
        if progressBar != nil && progressBar.bounds.width > 0 {
            riseProgressLayer.frame = CGRect(x: 0, y: 0, width: progressBar.bounds.width * riseRatio, height: 6)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if selectedSegmentIndex == 0 && !barChartRendered {
            layoutBarChart()
        }
        updateProgressBar()
    }

    // MARK: - 3. Industry Sector Section
    private func buildSectorSection() {
        let titleLabel = UILabel()
        titleLabel.text = "行业板块"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = textPrimary
        sectorContainer.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 0
        gridStack.distribution = .fillEqually
        sectorContainer.addSubview(gridStack)
        gridStack.translatesAutoresizingMaskIntoConstraints = false

        for rowIdx in 0..<2 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 0
            rowStack.distribution = .fillEqually
            gridStack.addArrangedSubview(rowStack)

            for colIdx in 0..<3 {
                let idx = rowIdx * 3 + colIdx
                if idx < sectors.count {
                    let cell = createSectorCell(sector: sectors[idx])
                    rowStack.addArrangedSubview(cell)
                }
            }
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: sectorContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: sectorContainer.leadingAnchor, constant: 16),

            gridStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            gridStack.leadingAnchor.constraint(equalTo: sectorContainer.leadingAnchor),
            gridStack.trailingAnchor.constraint(equalTo: sectorContainer.trailingAnchor),
            gridStack.bottomAnchor.constraint(equalTo: sectorContainer.bottomAnchor, constant: -12),
            gridStack.heightAnchor.constraint(equalToConstant: 180),
        ])
    }

    private func createSectorCell(sector: SectorData) -> UIView {
        let cell = UIView()

        let nameLabel = UILabel()
        nameLabel.text = sector.name
        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.textColor = textPrimary
        nameLabel.textAlignment = .center
        cell.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let percentLabel = UILabel()
        percentLabel.text = sector.changePercent
        percentLabel.font = UIFont.boldSystemFont(ofSize: 17)
        percentLabel.textColor = themeRed
        percentLabel.textAlignment = .center
        cell.addSubview(percentLabel)
        percentLabel.translatesAutoresizingMaskIntoConstraints = false

        let subLabel = UILabel()
        subLabel.text = "\(sector.topStock)  \(sector.topStockChange)"
        subLabel.font = UIFont.systemFont(ofSize: 11)
        subLabel.textColor = textSecondary
        subLabel.textAlignment = .center
        cell.addSubview(subLabel)
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: cell.topAnchor, constant: 10),
            nameLabel.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            percentLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            percentLabel.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
            subLabel.topAnchor.constraint(equalTo: percentLabel.bottomAnchor, constant: 4),
            subLabel.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
        ])

        return cell
    }

    // MARK: - 4. Stock Ranking Section
    private func buildRankingSection() {
        let titleLabel = UILabel()
        titleLabel.text = "股票排行榜"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = textPrimary
        rankingContainer.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let tabScrollView = UIScrollView()
        tabScrollView.showsHorizontalScrollIndicator = false
        rankingContainer.addSubview(tabScrollView)
        tabScrollView.translatesAutoresizingMaskIntoConstraints = false

        let tabStack = UIStackView()
        tabStack.axis = .horizontal
        tabStack.spacing = 0
        tabStack.distribution = .fillEqually
        tabScrollView.addSubview(tabStack)
        tabStack.translatesAutoresizingMaskIntoConstraints = false

        for (i, tab) in rankingTabs.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(tab, for: .normal)
            btn.tag = i
            btn.titleLabel?.font = i == 0 ? UIFont.boldSystemFont(ofSize: 14) : UIFont.systemFont(ofSize: 14)
            btn.setTitleColor(i == 0 ? themeRed : textSecondary, for: .normal)
            btn.addTarget(self, action: #selector(rankingTabTapped(_:)), for: .touchUpInside)
            tabStack.addArrangedSubview(btn)
            rankingTabButtons.append(btn)
        }

        rankingTabIndicator = UIView()
        rankingTabIndicator.backgroundColor = themeRed
        rankingTabIndicator.layer.cornerRadius = 1.5
        tabScrollView.addSubview(rankingTabIndicator)

        let headerView = UIView()
        headerView.backgroundColor = bgColor
        rankingContainer.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let hName = UILabel()
        hName.text = "名称"
        hName.font = UIFont.systemFont(ofSize: 13)
        hName.textColor = textSecondary
        headerView.addSubview(hName)
        hName.translatesAutoresizingMaskIntoConstraints = false

        let hPrice = UILabel()
        hPrice.text = "现价"
        hPrice.font = UIFont.systemFont(ofSize: 13)
        hPrice.textColor = textSecondary
        hPrice.textAlignment = .center
        headerView.addSubview(hPrice)
        hPrice.translatesAutoresizingMaskIntoConstraints = false

        let hChange = UILabel()
        hChange.text = "涨跌"
        hChange.font = UIFont.systemFont(ofSize: 13)
        hChange.textColor = textSecondary
        hChange.textAlignment = .center
        headerView.addSubview(hChange)
        hChange.translatesAutoresizingMaskIntoConstraints = false

        let hPercent = UILabel()
        hPercent.text = "涨跌幅"
        hPercent.font = UIFont.systemFont(ofSize: 13)
        hPercent.textColor = textSecondary
        hPercent.textAlignment = .right
        headerView.addSubview(hPercent)
        hPercent.translatesAutoresizingMaskIntoConstraints = false

        rankingTableView = UITableView(frame: .zero, style: .plain)
        rankingTableView.separatorStyle = .none
        rankingTableView.backgroundColor = .white
        rankingTableView.isScrollEnabled = false
        rankingTableView.delegate = self
        rankingTableView.dataSource = self
        rankingTableView.register(RankingStockCell.self, forCellReuseIdentifier: "RankingStockCell")
        if #available(iOS 15.0, *) {
            rankingTableView.sectionHeaderTopPadding = 0
        }
        rankingContainer.addSubview(rankingTableView)
        rankingTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: rankingContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor, constant: 16),

            tabScrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tabScrollView.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor),
            tabScrollView.trailingAnchor.constraint(equalTo: rankingContainer.trailingAnchor),
            tabScrollView.heightAnchor.constraint(equalToConstant: 36),

            tabStack.topAnchor.constraint(equalTo: tabScrollView.topAnchor),
            tabStack.leadingAnchor.constraint(equalTo: tabScrollView.leadingAnchor),
            tabStack.trailingAnchor.constraint(equalTo: tabScrollView.trailingAnchor),
            tabStack.bottomAnchor.constraint(equalTo: tabScrollView.bottomAnchor),
            tabStack.widthAnchor.constraint(equalTo: tabScrollView.widthAnchor),

            headerView.topAnchor.constraint(equalTo: tabScrollView.bottomAnchor, constant: 4),
            headerView.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: rankingContainer.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 32),

            hName.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            hName.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            hPrice.centerXAnchor.constraint(equalTo: headerView.centerXAnchor, constant: -30),
            hPrice.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            hChange.centerXAnchor.constraint(equalTo: headerView.centerXAnchor, constant: 40),
            hChange.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            hPercent.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            hPercent.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            rankingTableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            rankingTableView.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor),
            rankingTableView.trailingAnchor.constraint(equalTo: rankingContainer.trailingAnchor),
            rankingTableView.bottomAnchor.constraint(equalTo: rankingContainer.bottomAnchor),
        ])

        DispatchQueue.main.async { [weak self] in
            self?.updateRankingTabIndicator(animated: false)
        }
    }

    private var rankingTableHeightConstraint: NSLayoutConstraint?

    private func updateRankingTableHeight() {
        let rowHeight: CGFloat = 60
        let height = CGFloat(stockRankingData.count) * rowHeight
        if let c = rankingTableHeightConstraint {
            c.constant = max(height, 120)
        } else {
            rankingTableHeightConstraint = rankingTableView.heightAnchor.constraint(equalToConstant: max(height, 120))
            rankingTableHeightConstraint?.isActive = true
        }
    }

    @objc private func rankingTabTapped(_ sender: UIButton) {
        let idx = sender.tag
        guard idx != selectedRankingTabIndex else { return }
        selectedRankingTabIndex = idx
        for (i, btn) in rankingTabButtons.enumerated() {
            btn.setTitleColor(i == idx ? themeRed : textSecondary, for: .normal)
            btn.titleLabel?.font = i == idx ? UIFont.boldSystemFont(ofSize: 14) : UIFont.systemFont(ofSize: 14)
        }
        updateRankingTabIndicator(animated: true)
        rankingTableView.reloadData()
    }

    private func updateRankingTabIndicator(animated: Bool) {
        guard selectedRankingTabIndex < rankingTabButtons.count else { return }
        let btn = rankingTabButtons[selectedRankingTabIndex]
        let frame = btn.convert(btn.bounds, to: rankingTabIndicator.superview)
        let indicatorWidth: CGFloat = 24
        let newFrame = CGRect(
            x: frame.midX - indicatorWidth / 2,
            y: frame.maxY - 3,
            width: indicatorWidth,
            height: 3
        )
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.rankingTabIndicator.frame = newFrame
            }
        } else {
            rankingTabIndicator.frame = newFrame
        }
    }

    // MARK: - Subscription Content (segments 1-3)
    private func setupSubscriptionContent() {
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        dateLabel.text = formatter.string(from: Date())
        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textColor = textPrimary
        todayHeaderWrap.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(subsTableView)
        subsTableView.translatesAutoresizingMaskIntoConstraints = false
        subsTableView.backgroundColor = bgColor
        subsTableView.separatorStyle = .none
        subsTableView.delegate = self
        subsTableView.dataSource = self
        subsTableView.register(SubscriptionTableHeaderView.self, forHeaderFooterViewReuseIdentifier: "TableHeader")
        subsTableView.register(SubscriptionRowCell.self, forCellReuseIdentifier: "SubscriptionRow")
        if #available(iOS 11.0, *) {
            subsTableView.contentInsetAdjustmentBehavior = .never
        }
        subsTableView.contentInset = .zero
        if #available(iOS 15.0, *) {
            subsTableView.sectionHeaderTopPadding = 0
        }

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
            dateLabel.centerYAnchor.constraint(equalTo: todayHeaderWrap.centerYAnchor),

            subsTableView.topAnchor.constraint(equalTo: todayHeaderWrap.bottomAnchor, constant: 10),
            subsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Search
    @objc private func searchTapped() {
        let vc = StockSearchViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Data Loading
    private func loadHangqingData() {
        loadIndexData()
        loadStockRankingData()
    }

    /// 加载指数行情
    private func loadIndexData() {
        SecureNetworkManager.shared.request(
            api: "/api/Indexnew/sandahangqing_new",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                if let dict = res.decrypted,
                   let data = dict["data"] as? [String: Any],
                   let list = data["list"] as? [[String: Any]] {
                    var allCodes: [[String]] = []
                    for item in list {
                        if let arr = item["allcodes_arr"] as? [String] {
                            allCodes.append(arr)
                        }
                    }
                    DispatchQueue.main.async {
                        self.indexDataList = allCodes
                        self.populateIndexCards()
                    }
                }
            case .failure(let err):
                print("指数行情加载失败: \(err)")
            }
        }
    }

    /// 加载股票排行榜数据（沪深列表）
    private func loadStockRankingData() {
        SecureNetworkManager.shared.request(
            api: "/api/Indexnew/getShenhuDetail",
            method: .get,
            params: ["page": "1", "size": "20"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                if let dict = res.decrypted,
                   let data = dict["data"] as? [String: Any],
                   let list = data["list"] as? [[String: Any]] {
                    var stocks: [(name: String, code: String, market: String, price: String, change: String, changePercent: String)] = []
                    for item in list {
                        let name = item["name"] as? String ?? ""
                        let code = item["code"] as? String ?? ""
                        let symbol = item["symbol"] as? String ?? ""
                        let price = item["trade"] as? String ?? "0"
                        let change = item["pricechange"] as? String ?? "0"
                        let percent = item["changepercent"] as? String ?? "0"

                        var market = ""
                        if symbol.hasPrefix("sh") { market = "沪" }
                        else if symbol.hasPrefix("sz") { market = "深" }
                        else if symbol.hasPrefix("bj") { market = "北" }

                        stocks.append((name, code, market, price, change, percent))
                    }
                    DispatchQueue.main.async {
                        self.stockRankingData = stocks
                        self.rankingTableView.reloadData()
                        self.updateRankingTableHeight()
                    }
                }
            case .failure(let err):
                print("股票排行榜加载失败: \(err)")
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension MarketViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == rankingTableView {
            return stockRankingData.count
        }
        if selectedSegmentIndex == 1 { return subscriptionRows.count }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == rankingTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RankingStockCell", for: indexPath) as! RankingStockCell
            if indexPath.row < stockRankingData.count {
                let stock = stockRankingData[indexPath.row]
                cell.configure(
                    name: stock.name,
                    code: stock.code,
                    market: stock.market,
                    price: stock.price,
                    change: stock.change,
                    changePercent: stock.changePercent
                )
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriptionRow", for: indexPath) as! SubscriptionRowCell
        let row = subscriptionRows[indexPath.row]
        cell.configure(name: row.0, code: row.1, market: row.2, price: row.3, sector: row.4, pe: row.5)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == rankingTableView { return 60 }
        return 56
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == subsTableView && selectedSegmentIndex == 1 {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TableHeader") as? SubscriptionTableHeaderView
            header?.configure()
            return header
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == subsTableView && selectedSegmentIndex == 1 { return 40 }
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == rankingTableView, indexPath.row < stockRankingData.count {
            let stock = stockRankingData[indexPath.row]
            let vc = StockDetailViewController()
            vc.stockCode = stock.code
            vc.stockName = stock.name
            vc.exchange = stock.market
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - Mini Chart View
class MiniChartView: UIView {
    private var isRise: Bool
    private var chartColor: UIColor
    private var chartPoints: [CGFloat] = []

    init(isRise: Bool, color: UIColor) {
        self.isRise = isRise
        self.chartColor = color
        super.init(frame: .zero)
        backgroundColor = .clear
        let count = 12
        var lastY: CGFloat = 0.5
        for i in 0..<count {
            let variance = CGFloat.random(in: -0.12...0.12)
            let trend: CGFloat = isRise ? -CGFloat(i) * 0.015 : CGFloat(i) * 0.015
            lastY = max(0.05, min(0.95, lastY + variance + trend))
            chartPoints.append(lastY)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), !chartPoints.isEmpty else { return }
        let w = rect.width
        let h = rect.height
        let stepX = w / CGFloat(chartPoints.count - 1)

        ctx.setLineWidth(1.5)
        ctx.setStrokeColor(chartColor.cgColor)

        let path = CGMutablePath()
        for (i, pt) in chartPoints.enumerated() {
            let x = stepX * CGFloat(i)
            let y = pt * h
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        ctx.addPath(path)
        ctx.strokePath()
    }
}

// MARK: - Ranking Stock Cell
class RankingStockCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let marketBadge = UILabel()
    private let priceLabel = UILabel()
    private let changeLabel = UILabel()
    private let percentLabel = UILabel()
    private let line = UIView()

    private let textPrimary = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
    private let textSecondary = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)
    private let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
    private let stockGreen = UIColor(red: 0.13, green: 0.73, blue: 0.33, alpha: 1.0)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        for v in [nameLabel, codeLabel, marketBadge, priceLabel, changeLabel, percentLabel, line] as [UIView] {
            contentView.addSubview(v)
            v.translatesAutoresizingMaskIntoConstraints = false
        }

        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.textColor = textPrimary

        codeLabel.font = UIFont.systemFont(ofSize: 12)
        codeLabel.textColor = textSecondary

        marketBadge.font = UIFont.boldSystemFont(ofSize: 10)
        marketBadge.textColor = .white
        marketBadge.textAlignment = .center
        marketBadge.layer.cornerRadius = 2
        marketBadge.clipsToBounds = true

        priceLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        priceLabel.textAlignment = .center

        changeLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        changeLabel.textAlignment = .center

        percentLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        percentLabel.textAlignment = .right

        line.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            codeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),

            marketBadge.leadingAnchor.constraint(equalTo: codeLabel.trailingAnchor, constant: 5),
            marketBadge.centerYAnchor.constraint(equalTo: codeLabel.centerYAnchor),
            marketBadge.widthAnchor.constraint(equalToConstant: 16),
            marketBadge.heightAnchor.constraint(equalToConstant: 14),

            priceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -30),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            changeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 40),
            changeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            percentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            percentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            line.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            line.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
        ])
    }

    func configure(name: String, code: String, market: String, price: String, change: String, changePercent: String) {
        nameLabel.text = name
        codeLabel.text = code
        marketBadge.text = market

        let badgeColors: [String: UIColor] = [
            "沪": UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0),
            "深": UIColor(red: 0.26, green: 0.65, blue: 0.96, alpha: 1.0),
            "北": UIColor(red: 0.26, green: 0.40, blue: 0.90, alpha: 1.0),
            "创": UIColor(red: 0.4, green: 0.73, blue: 0.42, alpha: 1.0),
            "科": UIColor(red: 0.93, green: 0.25, blue: 0.48, alpha: 1.0)
        ]
        marketBadge.backgroundColor = badgeColors[market] ?? .gray

        let changeVal = Double(change) ?? 0
        let isRise = changeVal >= 0
        let color = isRise ? themeRed : stockGreen

        priceLabel.text = price
        priceLabel.textColor = color

        let sign = isRise && changeVal > 0 ? "+" : ""
        changeLabel.text = "\(sign)\(change)"
        changeLabel.textColor = color

        let percentVal = Double(changePercent) ?? 0
        let pSign = isRise && percentVal > 0 ? "+" : ""
        percentLabel.text = "\(pSign)\(changePercent)%"
        percentLabel.textColor = color
    }
}

// MARK: - Subscription Table Header View
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
    required init?(coder: NSCoder) { fatalError() }
    func configure() {}
}

// MARK: - Subscription Row Cell
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
        for v in [nameLabel, codeLabel, marketBadge, priceLabel, sectorLabel, peLabel, line] as [UIView] {
            contentView.addSubview(v)
            v.translatesAutoresizingMaskIntoConstraints = false
        }
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
    required init?(coder: NSCoder) { fatalError() }

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
