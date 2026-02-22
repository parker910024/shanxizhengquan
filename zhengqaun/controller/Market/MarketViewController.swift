//
//  MarketViewController.swift
//  zhengqaun
//
//  行情页：指数卡片(DGCharts折线图) + 市场概括 + 行业板块 + 股票排行榜
//  分段：行情 | 新股申购 | 战略配售 | 天启护盘
//

import UIKit
import DGCharts

// MARK: - MarketViewController
class MarketViewController: ZQViewController {

    // MARK: - 颜色
    private let bgColor     = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
    private let themeRed    = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
    private let stockGreen  = UIColor(red: 0.13, green: 0.73, blue: 0.33, alpha: 1.0)
    private let textPrimary = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
    private let textSec     = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)
    private let cardBg      = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)

    // MARK: - 顶部分段
    private let segmentTitles = ["行情", "新股申购", "战略配售", "天启护盘"]
    private var selectedSegmentIndex = 0
    private var segmentWrap: UIView!
    private var segmentButtons: [UIButton] = []

    // MARK: - 行情 (segment 0)
    private let hangqingScrollView = UIScrollView()
    private let hangqingContent    = UIView()

    // MARK: - 新股申购 (segment 1‑3)
    private let subsTableView   = UITableView(frame: .zero, style: .plain)
    private var todayHeaderWrap: UIView!
    private var todayTitleLabel: UILabel!
    private var subscriptionList: [[String: Any]] = []  // API 数据

    // MARK: - 指数数据 (API)
    private var indexItems: [IndexCardModel] = []
    private var indexCardsScroll: UIScrollView!
    private var indexCardsContainer: UIView!

    // MARK: - 股票排行榜
    private let marketTabs = ["沪深", "创业", "北证", "科创"]
    private let marketAPIs = [
        "/api/Indexnew/getShenhuDetail",
        "/api/Indexnew/getCyDetail",
        "/api/Indexnew/getBjDetail",
        "/api/Indexnew/getKcDetail"
    ]
    private var selectedMarketTab = 0
    private var marketTabButtons: [UIButton] = []
    private var marketTabIndicator: UIView!
    private var rankingStocks: [StockRankItem] = []
    private var rankingTableView: UITableView!
    private var rankingTableHeightCons: NSLayoutConstraint?

    // MARK: - 市场概括 (模拟)
    private var barChartContainer: UIView!
    private var riseCountLabel: UILabel!
    private var fallCountLabel: UILabel!
    private var progressBar: UIView!
    private var riseProgressLayer: CALayer!
    private var marketOverviewContainer: UIView!
    private var sectorContainer: UIView!
    private var rankingContainer: UIView!
    private var barChartRendered = false

    // MARK: - Models
    struct IndexCardModel {
        let name: String
        let code: String
        let allcode: String
        let price: String
        let change: String
        let changePercent: String
        let volume: String
        let turnover: String
    }

    struct StockRankItem {
        let name: String
        let code: String
        let symbol: String
        let price: String
        let change: String
        let changePercent: String
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        gk_navigationBar.isHidden = true
        view.backgroundColor = bgColor
        setupSegmentBar()
        setupHangqingContent()
        setupSubscriptionContent()
        updateVisibleContent()
        loadAllData()
    }

    // MARK: - Segment Bar
    private func setupSegmentBar() {
        segmentWrap = UIView()
        segmentWrap.backgroundColor = .white
        view.addSubview(segmentWrap)
        segmentWrap.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        segmentWrap.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        for (i, t) in segmentTitles.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(t, for: .normal)
            btn.tag = i
            btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
            btn.setContentHuggingPriority(.required, for: .horizontal)
            btn.setContentCompressionResistancePriority(.required, for: .horizontal)
            btn.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(btn)
            segmentButtons.append(btn)
        }

        NSLayoutConstraint.activate([
            segmentWrap.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.safeAreaTop),
            segmentWrap.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentWrap.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentWrap.heightAnchor.constraint(equalToConstant: 44),
            stack.topAnchor.constraint(equalTo: segmentWrap.topAnchor),
            stack.leadingAnchor.constraint(equalTo: segmentWrap.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: segmentWrap.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: segmentWrap.bottomAnchor)
        ])
        refreshSegmentUI()
    }

    private func refreshSegmentUI() {
        for (i, btn) in segmentButtons.enumerated() {
            let sel = (i == selectedSegmentIndex)
            btn.setTitleColor(sel ? textPrimary : textSec, for: .normal)
            btn.titleLabel?.font = sel ? .boldSystemFont(ofSize: 26) : .systemFont(ofSize: 18)
        }
    }

    @objc private func segmentTapped(_ sender: UIButton) {
        guard sender.tag != selectedSegmentIndex else { return }
        selectedSegmentIndex = sender.tag
        refreshSegmentUI()
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
            todayTitleLabel.text = segTitleFor(selectedSegmentIndex)
            loadSubscriptionData()
        }
    }

    private func segTitleFor(_ idx: Int) -> String {
        switch idx {
        case 1:  return "今日申购"
        case 2:  return "今日战略配售"
        case 3:  return "今日天启护盘"
        default: return ""
        }
    }

    // ===================================================================
    // MARK: - 行情 ScrollView (segment 0)
    // ===================================================================
    private func setupHangqingContent() {
        view.addSubview(hangqingScrollView)
        hangqingScrollView.translatesAutoresizingMaskIntoConstraints = false
        hangqingScrollView.backgroundColor = bgColor
        hangqingScrollView.showsVerticalScrollIndicator = false

        hangqingScrollView.addSubview(hangqingContent)
        hangqingContent.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hangqingScrollView.topAnchor.constraint(equalTo: segmentWrap.bottomAnchor),
            hangqingScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hangqingScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hangqingScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hangqingContent.topAnchor.constraint(equalTo: hangqingScrollView.topAnchor),
            hangqingContent.leadingAnchor.constraint(equalTo: hangqingScrollView.leadingAnchor),
            hangqingContent.trailingAnchor.constraint(equalTo: hangqingScrollView.trailingAnchor),
            hangqingContent.widthAnchor.constraint(equalTo: hangqingScrollView.widthAnchor),
        ])

        buildSections()
    }

    private func buildSections() {
        // 1 — 指数卡片
        indexCardsContainer = UIView()
        indexCardsContainer.backgroundColor = .white
        indexCardsContainer.layer.cornerRadius = 8
        hangqingContent.addSubview(indexCardsContainer)
        indexCardsContainer.translatesAutoresizingMaskIntoConstraints = false

        indexCardsScroll = UIScrollView()
        indexCardsScroll.showsHorizontalScrollIndicator = false
        indexCardsContainer.addSubview(indexCardsScroll)
        indexCardsScroll.translatesAutoresizingMaskIntoConstraints = false

        // 2 — 市场概括
        marketOverviewContainer = UIView()
        marketOverviewContainer.backgroundColor = .white
        marketOverviewContainer.layer.cornerRadius = 8
        hangqingContent.addSubview(marketOverviewContainer)
        marketOverviewContainer.translatesAutoresizingMaskIntoConstraints = false

        // 3 — 行业板块
        sectorContainer = UIView()
        sectorContainer.backgroundColor = .white
        sectorContainer.layer.cornerRadius = 8
        hangqingContent.addSubview(sectorContainer)
        sectorContainer.translatesAutoresizingMaskIntoConstraints = false

        // 4 — 股票排行榜
        rankingContainer = UIView()
        rankingContainer.backgroundColor = .white
        rankingContainer.layer.cornerRadius = 8
        hangqingContent.addSubview(rankingContainer)
        rankingContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            indexCardsContainer.topAnchor.constraint(equalTo: hangqingContent.topAnchor, constant: 8),
            indexCardsContainer.leadingAnchor.constraint(equalTo: hangqingContent.leadingAnchor, constant: 12),
            indexCardsContainer.trailingAnchor.constraint(equalTo: hangqingContent.trailingAnchor, constant: -12),
            indexCardsContainer.heightAnchor.constraint(equalToConstant: 140),

            indexCardsScroll.topAnchor.constraint(equalTo: indexCardsContainer.topAnchor),
            indexCardsScroll.leadingAnchor.constraint(equalTo: indexCardsContainer.leadingAnchor),
            indexCardsScroll.trailingAnchor.constraint(equalTo: indexCardsContainer.trailingAnchor),
            indexCardsScroll.bottomAnchor.constraint(equalTo: indexCardsContainer.bottomAnchor),

            marketOverviewContainer.topAnchor.constraint(equalTo: indexCardsContainer.bottomAnchor, constant: 12),
            marketOverviewContainer.leadingAnchor.constraint(equalTo: hangqingContent.leadingAnchor, constant: 12),
            marketOverviewContainer.trailingAnchor.constraint(equalTo: hangqingContent.trailingAnchor, constant: -12),

            sectorContainer.topAnchor.constraint(equalTo: marketOverviewContainer.bottomAnchor, constant: 12),
            sectorContainer.leadingAnchor.constraint(equalTo: hangqingContent.leadingAnchor, constant: 12),
            sectorContainer.trailingAnchor.constraint(equalTo: hangqingContent.trailingAnchor, constant: -12),

            rankingContainer.topAnchor.constraint(equalTo: sectorContainer.bottomAnchor, constant: 12),
            rankingContainer.leadingAnchor.constraint(equalTo: hangqingContent.leadingAnchor, constant: 12),
            rankingContainer.trailingAnchor.constraint(equalTo: hangqingContent.trailingAnchor, constant: -12),
            rankingContainer.bottomAnchor.constraint(equalTo: hangqingContent.bottomAnchor, constant: -20),
        ])

        buildMarketOverview()
        buildSectorGrid()
        buildRankingSection()
    }

    // ===================================================================
    // MARK: - 1. 指数卡片 (DGCharts LineChartView)
    // ===================================================================
    private func populateIndexCards() {
        indexCardsScroll.subviews.forEach { $0.removeFromSuperview() }

        let cardW: CGFloat = 165
        let cardH: CGFloat = 128
        let spacing: CGFloat = 10
        let pad: CGFloat = 12

        for (i, item) in indexItems.enumerated() {
            let card = buildIndexCard(item: item, width: cardW, height: cardH)
            indexCardsScroll.addSubview(card)
            card.frame = CGRect(x: pad + CGFloat(i) * (cardW + spacing), y: 6, width: cardW, height: cardH)
        }
        indexCardsScroll.contentSize = CGSize(
            width: pad + CGFloat(indexItems.count) * (cardW + spacing) + pad,
            height: cardH + 12
        )
    }

    private func buildIndexCard(item: IndexCardModel, width: CGFloat, height: CGFloat) -> UIView {
        let changeVal = Double(item.change) ?? 0
        let isRise = changeVal >= 0
        let color = isRise ? themeRed : stockGreen

        let card = UIView()
        card.backgroundColor = cardBg
        card.layer.cornerRadius = 8

        // 名称
        let nameLabel = UILabel()
        nameLabel.text = item.name
        nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = textPrimary
        card.addSubview(nameLabel)

        // 价格
        let priceLabel = UILabel()
        priceLabel.text = item.price
        priceLabel.font = .boldSystemFont(ofSize: 22)
        priceLabel.textColor = color
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.minimumScaleFactor = 0.6
        card.addSubview(priceLabel)

        // 涨跌
        let sign = isRise ? "+" : ""
        let changeLabel = UILabel()
        changeLabel.text = "\(sign)\(item.change)  \(sign)\(item.changePercent)%"
        changeLabel.font = .systemFont(ofSize: 11)
        changeLabel.textColor = color
        card.addSubview(changeLabel)

        // DGCharts 折线图
        let chartView = LineChartView()
        chartView.isUserInteractionEnabled = false
        chartView.legend.enabled = false
        chartView.xAxis.enabled = false
        chartView.leftAxis.enabled = false
        chartView.rightAxis.enabled = false
        chartView.drawGridBackgroundEnabled = false
        chartView.drawBordersEnabled = false
        chartView.minOffset = 0
        chartView.setScaleEnabled(false)

        // 生成模拟走势数据（基于真实价格波动）
        let basePrice = Double(item.price) ?? 3000
        var entries: [ChartDataEntry] = []
        var lastP = basePrice * (1 - abs(changeVal) / basePrice * 0.6)
        let pointCount = 30
        for j in 0..<pointCount {
            let noiseFactor = Double.random(in: -0.002...0.002)
            let trendFactor = (changeVal / basePrice) * (Double(j) / Double(pointCount - 1))
            lastP = lastP * (1 + noiseFactor) + basePrice * trendFactor * 0.05
            entries.append(ChartDataEntry(x: Double(j), y: lastP))
        }
        // 最后一个点对齐真实价格
        entries[entries.count - 1] = ChartDataEntry(x: Double(pointCount - 1), y: basePrice)

        let dataSet = LineChartDataSet(entries: entries, label: "")
        dataSet.colors = [color]
        dataSet.lineWidth = 1.5
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.drawFilledEnabled = true
        dataSet.fillColor = color
        dataSet.fillAlpha = 0.12
        dataSet.mode = .cubicBezier

        chartView.data = LineChartData(dataSet: dataSet)
        card.addSubview(chartView)

        for v: UIView in [nameLabel, priceLabel, changeLabel, chartView] {
            v.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),

            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            priceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            priceLabel.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -12),

            changeLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 2),
            changeLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),

            chartView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            chartView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            chartView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -4),
            chartView.heightAnchor.constraint(equalToConstant: 36),
        ])

        return card
    }

    // ===================================================================
    // MARK: - 2. 市场概括
    // ===================================================================
    private struct BarItem {
        let label: String; let count: Int; let isRise: Bool
    }
    private let marketBars: [BarItem] = [
        .init(label: "涨停", count: 91, isRise: true),
        .init(label: ">7%",  count: 51, isRise: true),
        .init(label: "5‑7%", count: 86, isRise: true),
        .init(label: "3‑5%", count: 187, isRise: true),
        .init(label: "0‑3%", count: 1301, isRise: true),
        .init(label: "平",   count: 91, isRise: true),
        .init(label: "0‑3%", count: 2436, isRise: false),
        .init(label: "3‑5%", count: 658, isRise: false),
        .init(label: "5‑7%", count: 213, isRise: false),
        .init(label: ">7%",  count: 60, isRise: false),
        .init(label: "跌停", count: 38, isRise: false),
    ]
    private var riseCount = 1716
    private var fallCount = 3405

    private func buildMarketOverview() {
        let title = makeTitle("市场概括")
        marketOverviewContainer.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false

        let capTitleLbl = UILabel()
        capTitleLbl.text = "南向资金流入"
        capTitleLbl.font = .systemFont(ofSize: 13)
        capTitleLbl.textColor = textSec
        marketOverviewContainer.addSubview(capTitleLbl)
        capTitleLbl.translatesAutoresizingMaskIntoConstraints = false

        let capValLbl = UILabel()
        capValLbl.text = "4373.61亿"
        capValLbl.font = .boldSystemFont(ofSize: 15)
        capValLbl.textColor = themeRed
        marketOverviewContainer.addSubview(capValLbl)
        capValLbl.translatesAutoresizingMaskIntoConstraints = false

        barChartContainer = UIView()
        marketOverviewContainer.addSubview(barChartContainer)
        barChartContainer.translatesAutoresizingMaskIntoConstraints = false

        riseCountLabel = UILabel()
        riseCountLabel.text = "上涨\(riseCount)"
        riseCountLabel.font = .systemFont(ofSize: 12, weight: .medium)
        riseCountLabel.textColor = themeRed
        marketOverviewContainer.addSubview(riseCountLabel)
        riseCountLabel.translatesAutoresizingMaskIntoConstraints = false

        fallCountLabel = UILabel()
        fallCountLabel.text = "下跌\(fallCount)"
        fallCountLabel.font = .systemFont(ofSize: 12, weight: .medium)
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
            title.topAnchor.constraint(equalTo: marketOverviewContainer.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: marketOverviewContainer.leadingAnchor, constant: 16),
            capTitleLbl.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            capTitleLbl.trailingAnchor.constraint(equalTo: capValLbl.leadingAnchor, constant: -8),
            capValLbl.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            capValLbl.trailingAnchor.constraint(equalTo: marketOverviewContainer.trailingAnchor, constant: -16),

            barChartContainer.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
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
        DispatchQueue.main.async { self.layoutBarChart() }
    }

    private func layoutBarChart() {
        barChartContainer.subviews.forEach { $0.removeFromSuperview() }
        let cw = barChartContainer.bounds.width
        let ch = barChartContainer.bounds.height
        guard cw > 0, ch > 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in self?.layoutBarChart() }
            return
        }
        barChartRendered = true
        let maxC = CGFloat(marketBars.map { $0.count }.max() ?? 1)
        let n = CGFloat(marketBars.count)
        let sp: CGFloat = 4
        let bw = (cw - sp * (n - 1)) / n
        let labH: CGFloat = 18
        let numH: CGFloat = 16
        let maxH = ch - labH - numH - 8

        for (i, bar) in marketBars.enumerated() {
            let x = CGFloat(i) * (bw + sp)
            let h = max(4, CGFloat(bar.count) / maxC * maxH)
            let y = ch - labH - h
            let col = bar.isRise ? themeRed : stockGreen

            let bv = UIView(frame: CGRect(x: x, y: y, width: bw, height: h))
            bv.backgroundColor = col; bv.layer.cornerRadius = 2
            barChartContainer.addSubview(bv)

            let cl = UILabel(frame: CGRect(x: x - 4, y: y - numH, width: bw + 8, height: numH))
            cl.text = "\(bar.count)"; cl.font = .systemFont(ofSize: 9); cl.textColor = col; cl.textAlignment = .center
            barChartContainer.addSubview(cl)

            let ll = UILabel(frame: CGRect(x: x - 4, y: ch - labH, width: bw + 8, height: labH))
            ll.text = bar.label; ll.font = .systemFont(ofSize: 9); ll.textColor = col; ll.textAlignment = .center
            barChartContainer.addSubview(ll)
        }
        updateProgressBar()
    }

    private func updateProgressBar() {
        let total = CGFloat(riseCount + fallCount)
        let r = total > 0 ? CGFloat(riseCount) / total : 0.5
        if progressBar != nil, progressBar.bounds.width > 0 {
            riseProgressLayer.frame = CGRect(x: 0, y: 0, width: progressBar.bounds.width * r, height: 6)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if selectedSegmentIndex == 0 && !barChartRendered { layoutBarChart() }
        updateProgressBar()
    }

    // ===================================================================
    // MARK: - 3. 行业板块
    // ===================================================================
    private struct SectorItem { let name, pct, top, topPct: String }
    private let sectors: [SectorItem] = [
        .init(name: "贵金属",   pct: "+8.04%", top: "湖南黄金", topPct: "+10.01%"),
        .init(name: "采掘行业", pct: "+8.04%", top: "湖南黄金", topPct: "+10.01%"),
        .init(name: "酿酒行业", pct: "+8.04%", top: "湖南黄金", topPct: "+10.01%"),
        .init(name: "文化传媒", pct: "+8.04%", top: "湖南黄金", topPct: "+10.01%"),
        .init(name: "保险",    pct: "+8.04%", top: "湖南黄金", topPct: "+10.01%"),
        .init(name: "房地产",   pct: "+8.04%", top: "湖南黄金", topPct: "+10.01%"),
    ]

    private func buildSectorGrid() {
        let title = makeTitle("行业板块")
        sectorContainer.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false

        let grid = UIStackView()
        grid.axis = .vertical; grid.spacing = 0; grid.distribution = .fillEqually
        sectorContainer.addSubview(grid)
        grid.translatesAutoresizingMaskIntoConstraints = false

        for row in 0..<2 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal; rowStack.spacing = 0; rowStack.distribution = .fillEqually
            grid.addArrangedSubview(rowStack)
            for col in 0..<3 {
                let s = sectors[row * 3 + col]
                let cell = UIView()
                let nm = UILabel(); nm.text = s.name; nm.font = .boldSystemFont(ofSize: 15); nm.textColor = textPrimary; nm.textAlignment = .center
                let pc = UILabel(); pc.text = s.pct; pc.font = .boldSystemFont(ofSize: 17); pc.textColor = themeRed; pc.textAlignment = .center
                let sb = UILabel(); sb.text = "\(s.top) \(s.topPct)"; sb.font = .systemFont(ofSize: 11); sb.textColor = textSec; sb.textAlignment = .center
                for l: UIView in [nm, pc, sb] { cell.addSubview(l); l.translatesAutoresizingMaskIntoConstraints = false }
                NSLayoutConstraint.activate([
                    nm.topAnchor.constraint(equalTo: cell.topAnchor, constant: 10), nm.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                    pc.topAnchor.constraint(equalTo: nm.bottomAnchor, constant: 6), pc.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                    sb.topAnchor.constraint(equalTo: pc.bottomAnchor, constant: 4), sb.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                ])
                rowStack.addArrangedSubview(cell)
            }
        }
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: sectorContainer.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: sectorContainer.leadingAnchor, constant: 16),
            grid.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            grid.leadingAnchor.constraint(equalTo: sectorContainer.leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: sectorContainer.trailingAnchor),
            grid.bottomAnchor.constraint(equalTo: sectorContainer.bottomAnchor, constant: -12),
            grid.heightAnchor.constraint(equalToConstant: 180),
        ])
    }

    // ===================================================================
    // MARK: - 4. 股票排行榜 (沪深 / 创业 / 北证 / 科创)
    // ===================================================================
    private func buildRankingSection() {
        // 标题
        let title = makeTitle("股票排行榜")
        rankingContainer.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false

        // 市场 Tab
        let tabWrap = UIView()
        rankingContainer.addSubview(tabWrap)
        tabWrap.translatesAutoresizingMaskIntoConstraints = false

        let tabStack = UIStackView()
        tabStack.axis = .horizontal; tabStack.spacing = 0; tabStack.distribution = .fillEqually
        tabWrap.addSubview(tabStack)
        tabStack.translatesAutoresizingMaskIntoConstraints = false

        for (i, t) in marketTabs.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(t, for: .normal)
            btn.tag = i
            btn.titleLabel?.font = i == 0 ? .boldSystemFont(ofSize: 15) : .systemFont(ofSize: 15)
            btn.setTitleColor(i == 0 ? themeRed : textSec, for: .normal)
            btn.addTarget(self, action: #selector(marketTabTapped(_:)), for: .touchUpInside)
            tabStack.addArrangedSubview(btn)
            marketTabButtons.append(btn)
        }

        marketTabIndicator = UIView()
        marketTabIndicator.backgroundColor = themeRed
        marketTabIndicator.layer.cornerRadius = 1.5
        tabWrap.addSubview(marketTabIndicator)

        // 列标题
        let headerView = UIView()
        headerView.backgroundColor = bgColor
        rankingContainer.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let headers = [("名称", NSLayoutConstraint.Attribute.leading, 16),
                       ("现价", .centerX, -30),
                       ("涨跌", .centerX, 40)]
        for (text, attr, offset) in headers {
            let l = UILabel()
            l.text = text; l.font = .systemFont(ofSize: 13); l.textColor = textSec; l.textAlignment = .center
            headerView.addSubview(l); l.translatesAutoresizingMaskIntoConstraints = false
            l.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
            if attr == .leading {
                l.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: CGFloat(offset)).isActive = true
            } else {
                l.centerXAnchor.constraint(equalTo: headerView.centerXAnchor, constant: CGFloat(offset)).isActive = true
            }
        }
        let hPct = UILabel(); hPct.text = "涨跌幅"; hPct.font = .systemFont(ofSize: 13); hPct.textColor = textSec; hPct.textAlignment = .right
        headerView.addSubview(hPct); hPct.translatesAutoresizingMaskIntoConstraints = false
        hPct.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        hPct.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16).isActive = true

        // TableView
        rankingTableView = UITableView(frame: .zero, style: .plain)
        rankingTableView.separatorStyle = .none
        rankingTableView.backgroundColor = .white
        rankingTableView.isScrollEnabled = false
        rankingTableView.delegate = self
        rankingTableView.dataSource = self
        rankingTableView.register(RankingStockCell.self, forCellReuseIdentifier: "RankingCell")
        if #available(iOS 15.0, *) { rankingTableView.sectionHeaderTopPadding = 0 }
        rankingContainer.addSubview(rankingTableView)
        rankingTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: rankingContainer.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor, constant: 16),

            tabWrap.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            tabWrap.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor),
            tabWrap.trailingAnchor.constraint(equalTo: rankingContainer.trailingAnchor),
            tabWrap.heightAnchor.constraint(equalToConstant: 40),

            tabStack.topAnchor.constraint(equalTo: tabWrap.topAnchor),
            tabStack.leadingAnchor.constraint(equalTo: tabWrap.leadingAnchor),
            tabStack.trailingAnchor.constraint(equalTo: tabWrap.trailingAnchor),
            tabStack.heightAnchor.constraint(equalToConstant: 36),

            headerView.topAnchor.constraint(equalTo: tabWrap.bottomAnchor, constant: 4),
            headerView.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: rankingContainer.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 32),

            rankingTableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            rankingTableView.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor),
            rankingTableView.trailingAnchor.constraint(equalTo: rankingContainer.trailingAnchor),
            rankingTableView.bottomAnchor.constraint(equalTo: rankingContainer.bottomAnchor),
        ])

        DispatchQueue.main.async { self.moveTabIndicator(animated: false) }
    }

    @objc private func marketTabTapped(_ sender: UIButton) {
        let idx = sender.tag
        guard idx != selectedMarketTab else { return }
        selectedMarketTab = idx
        for (i, btn) in marketTabButtons.enumerated() {
            btn.setTitleColor(i == idx ? themeRed : textSec, for: .normal)
            btn.titleLabel?.font = i == idx ? .boldSystemFont(ofSize: 15) : .systemFont(ofSize: 15)
        }
        moveTabIndicator(animated: true)
        loadRankingData()
    }

    private func moveTabIndicator(animated: Bool) {
        guard selectedMarketTab < marketTabButtons.count else { return }
        let btn = marketTabButtons[selectedMarketTab]
        let f = btn.convert(btn.bounds, to: marketTabIndicator.superview)
        let w: CGFloat = 24
        let target = CGRect(x: f.midX - w / 2, y: f.maxY - 3, width: w, height: 3)
        if animated {
            UIView.animate(withDuration: 0.25) { self.marketTabIndicator.frame = target }
        } else {
            marketTabIndicator.frame = target
        }
    }

    private func updateRankingHeight() {
        let h = CGFloat(rankingStocks.count) * 60
        if let c = rankingTableHeightCons { c.constant = max(h, 120) }
        else {
            rankingTableHeightCons = rankingTableView.heightAnchor.constraint(equalToConstant: max(h, 120))
            rankingTableHeightCons?.isActive = true
        }
    }

    // ===================================================================
    // MARK: - 新股申购 Content (segment 1‑3)
    // ===================================================================
    private func setupSubscriptionContent() {
        todayHeaderWrap = UIView()
        todayHeaderWrap.backgroundColor = bgColor
        view.addSubview(todayHeaderWrap)
        todayHeaderWrap.translatesAutoresizingMaskIntoConstraints = false

        let redBar = UIView(); redBar.backgroundColor = themeRed; redBar.layer.cornerRadius = 2
        todayHeaderWrap.addSubview(redBar); redBar.translatesAutoresizingMaskIntoConstraints = false

        todayTitleLabel = UILabel()
        todayTitleLabel.font = .boldSystemFont(ofSize: 16); todayTitleLabel.textColor = textPrimary
        todayHeaderWrap.addSubview(todayTitleLabel); todayTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let dateLbl = UILabel()
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd EEEE"; fmt.locale = Locale(identifier: "zh_CN")
        dateLbl.text = fmt.string(from: Date()); dateLbl.font = .systemFont(ofSize: 14); dateLbl.textColor = textPrimary
        todayHeaderWrap.addSubview(dateLbl); dateLbl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(subsTableView)
        subsTableView.translatesAutoresizingMaskIntoConstraints = false
        subsTableView.backgroundColor = bgColor
        subsTableView.separatorStyle = .none
        subsTableView.delegate = self; subsTableView.dataSource = self
        subsTableView.register(SubscriptionTableHeaderView.self, forHeaderFooterViewReuseIdentifier: "SubsHeader")
        subsTableView.register(SubscriptionRowCell.self, forCellReuseIdentifier: "SubsRow")
        if #available(iOS 11.0, *) { subsTableView.contentInsetAdjustmentBehavior = .never }
        if #available(iOS 15.0, *) { subsTableView.sectionHeaderTopPadding = 0 }

        NSLayoutConstraint.activate([
            todayHeaderWrap.topAnchor.constraint(equalTo: segmentWrap.bottomAnchor),
            todayHeaderWrap.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            todayHeaderWrap.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            todayHeaderWrap.heightAnchor.constraint(equalToConstant: 28),
            redBar.leadingAnchor.constraint(equalTo: todayHeaderWrap.leadingAnchor, constant: 16),
            redBar.centerYAnchor.constraint(equalTo: todayHeaderWrap.centerYAnchor),
            redBar.widthAnchor.constraint(equalToConstant: 4), redBar.heightAnchor.constraint(equalToConstant: 16),
            todayTitleLabel.leadingAnchor.constraint(equalTo: redBar.trailingAnchor, constant: 8),
            todayTitleLabel.centerYAnchor.constraint(equalTo: todayHeaderWrap.centerYAnchor),
            dateLbl.leadingAnchor.constraint(equalTo: todayTitleLabel.trailingAnchor, constant: 12),
            dateLbl.centerYAnchor.constraint(equalTo: todayHeaderWrap.centerYAnchor),

            subsTableView.topAnchor.constraint(equalTo: todayHeaderWrap.bottomAnchor, constant: 10),
            subsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // ===================================================================
    // MARK: - Helpers
    // ===================================================================
    private func makeTitle(_ text: String) -> UILabel {
        let l = UILabel(); l.text = text; l.font = .boldSystemFont(ofSize: 18); l.textColor = textPrimary; return l
    }

    /// 外部调用切换分段
    func switchToTab(index: Int) {
        guard index >= 0, index < segmentTitles.count else { return }
        selectedSegmentIndex = index
        refreshSegmentUI()
        updateVisibleContent()
    }

    // ===================================================================
    // MARK: - ★ 网络请求
    // ===================================================================
    private func loadAllData() {
        loadIndexData()
        loadRankingData()
    }

    /// 指数行情 — /api/Indexnew/sandahangqing_new
    private func loadIndexData() {
        SecureNetworkManager.shared.request(
            api: "/api/Indexnew/sandahangqing_new",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard res.statusCode == 200,
                      let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    print("[行情] 指数行情: 解析失败, raw=\(res.raw.prefix(200))")
                    return
                }
                var items: [IndexCardModel] = []
                for obj in list {
                    guard let arr = obj["allcodes_arr"] as? [Any], arr.count >= 7 else { continue }
                    let str = arr.map { "\($0)" }   // 统一转字符串
                    items.append(IndexCardModel(
                        name:          str[1],
                        code:          str[2],
                        allcode:       obj["allcode"] as? String ?? "",
                        price:         str[3],
                        change:        str[4],
                        changePercent: str[5],
                        volume:        str[6],
                        turnover:      str.count > 7 ? str[7] : ""
                    ))
                }
                DispatchQueue.main.async {
                    self.indexItems = items
                    self.populateIndexCards()
                    print("[行情] 指数行情加载成功，共 \(items.count) 条")
                }
            case .failure(let err):
                print("[行情] 指数行情请求失败: \(err.localizedDescription)")
            }
        }
    }

    /// 股票排行榜 — 根据当前 tab 请求对应接口
    private func loadRankingData() {
        let api = marketAPIs[selectedMarketTab]
        SecureNetworkManager.shared.request(
            api: api,
            method: .get,
            params: ["page": "1", "size": "20"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard res.statusCode == 200,
                      let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    print("[行情] 排行榜(\(self.marketTabs[self.selectedMarketTab])): 解析失败, raw=\(res.raw.prefix(200))")
                    return
                }
                var stocks: [StockRankItem] = []
                for item in list {
                    let name    = item["name"] as? String ?? (item["title"] as? String ?? "")
                    let code    = item["code"] as? String ?? ""
                    let symbol  = item["symbol"] as? String ?? (item["allcode"] as? String ?? "")
                    let price   = "\(item["trade"] ?? item["cai_buy"] ?? "0")"
                    let change  = "\(item["pricechange"] ?? "0")"
                    let percent = "\(item["changepercent"] ?? "0")"
                    stocks.append(StockRankItem(name: name, code: code, symbol: symbol, price: price, change: change, changePercent: percent))
                }
                DispatchQueue.main.async {
                    self.rankingStocks = stocks
                    self.rankingTableView.reloadData()
                    self.updateRankingHeight()
                    print("[行情] 排行榜(\(self.marketTabs[self.selectedMarketTab]))加载成功，共 \(stocks.count) 条")
                }
            case .failure(let err):
                print("[行情] 排行榜请求失败: \(err.localizedDescription)")
            }
        }
    }

    /// 新股申购 — /api/subscribe/lst
    private func loadSubscriptionData() {
        let typeParam: String
        switch selectedSegmentIndex {
        case 1: typeParam = "0"   // 新股申购
        case 2: typeParam = "0"   // 战略配售 — 使用线下配售接口
        case 3: typeParam = "0"   // 天启护盘
        default: return
        }

        let api: String
        switch selectedSegmentIndex {
        case 1: api = "/api/subscribe/lst"
        case 2: api = "/api/subscribe/xxlst"
        case 3: api = "/api/dzjy/lst"
        default: return
        }

        SecureNetworkManager.shared.request(
            api: api,
            method: .get,
            params: ["page": "1", "type": typeParam]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard res.statusCode == 200,
                      let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any] else {
                    print("[行情] 申购列表解析失败")
                    return
                }
                // 新股和线下配售返回 list -> [flag, sub_info[...]]
                // 大宗交易返回 list -> [...]
                var rows: [[String: Any]] = []
                if let list = data["list"] as? [[String: Any]] {
                    for item in list {
                        if let subInfo = item["sub_info"] as? [[String: Any]] {
                            rows.append(contentsOf: subInfo)
                        } else {
                            rows.append(item)
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.subscriptionList = rows
                    self.subsTableView.reloadData()
                    print("[行情] 申购列表加载成功，共 \(rows.count) 条")
                }
            case .failure(let err):
                print("[行情] 申购列表请求失败: \(err.localizedDescription)")
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension MarketViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == rankingTableView { return rankingStocks.count }
        return subscriptionList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == rankingTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RankingCell", for: indexPath) as! RankingStockCell
            if indexPath.row < rankingStocks.count {
                let s = rankingStocks[indexPath.row]
                cell.configure(name: s.name, code: s.code, symbol: s.symbol, price: s.price, change: s.change, changePercent: s.changePercent)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "SubsRow", for: indexPath) as! SubscriptionRowCell
        if indexPath.row < subscriptionList.count {
            let item = subscriptionList[indexPath.row]
            let name   = item["name"] as? String ?? (item["title"] as? String ?? "")
            let code   = item["sgcode"] as? String ?? (item["code"] as? String ?? "")
            let price  = "\(item["fx_price"] ?? item["cai_buy"] ?? "0")"
            let sgType = item["sg_type"] as? String ?? ""
            let market: String = {
                switch sgType { case "1": return "沪"; case "2": return "深"; case "3": return "创"; case "4": return "北"; case "5": return "科"; default: return "" }
            }()
            let rate   = "\(item["fx_rate"] ?? "0")%"
            let sector = item["industry"] as? String ?? ""
            cell.configure(name: name, code: code, market: market, price: price, sector: sector.isEmpty ? marketLabel(sgType) : sector, pe: rate)
        }
        return cell
    }

    private func marketLabel(_ sgType: String) -> String {
        switch sgType { case "1": return "沪市"; case "2": return "深市"; case "3": return "创业板"; case "4": return "北交"; case "5": return "科创"; default: return "" }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == rankingTableView { return 60 }
        return 56
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == subsTableView {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "SubsHeader") as? SubscriptionTableHeaderView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == subsTableView { return 40 }
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == rankingTableView, indexPath.row < rankingStocks.count {
            let s = rankingStocks[indexPath.row]
            let vc = StockDetailViewController()
            vc.stockCode = s.code
            vc.stockName = s.name
            // 根据 symbol 判断交易所
            if s.symbol.hasPrefix("sh") { vc.exchange = "沪" }
            else if s.symbol.hasPrefix("sz") { vc.exchange = "深" }
            else if s.symbol.hasPrefix("bj") { vc.exchange = "北" }
            else { vc.exchange = "" }
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// =====================================================================
// MARK: - RankingStockCell
// =====================================================================
class RankingStockCell: UITableViewCell {

    private let nameLabel    = UILabel()
    private let codeLabel    = UILabel()
    private let marketBadge  = UILabel()
    private let priceLabel   = UILabel()
    private let changeLabel  = UILabel()
    private let percentLabel = UILabel()
    private let sep          = UIView()

    private let textP  = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1)
    private let textS  = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1)
    private let red    = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1)
    private let green  = UIColor(red: 0.13, green: 0.73, blue: 0.33, alpha: 1)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none; backgroundColor = .white
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        for v: UIView in [nameLabel, codeLabel, marketBadge, priceLabel, changeLabel, percentLabel, sep] {
            contentView.addSubview(v); v.translatesAutoresizingMaskIntoConstraints = false
        }
        nameLabel.font = .boldSystemFont(ofSize: 15); nameLabel.textColor = textP
        codeLabel.font = .systemFont(ofSize: 12); codeLabel.textColor = textS
        marketBadge.font = .boldSystemFont(ofSize: 10); marketBadge.textColor = .white
        marketBadge.textAlignment = .center; marketBadge.layer.cornerRadius = 2; marketBadge.clipsToBounds = true
        priceLabel.font = .systemFont(ofSize: 15, weight: .medium); priceLabel.textAlignment = .center
        changeLabel.font = .systemFont(ofSize: 15, weight: .medium); changeLabel.textAlignment = .center
        percentLabel.font = .systemFont(ofSize: 13, weight: .bold); percentLabel.textAlignment = .center
        percentLabel.layer.cornerRadius = 4; percentLabel.clipsToBounds = true
        sep.backgroundColor = UIColor(white: 0.93, alpha: 1)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            codeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            marketBadge.leadingAnchor.constraint(equalTo: codeLabel.trailingAnchor, constant: 5),
            marketBadge.centerYAnchor.constraint(equalTo: codeLabel.centerYAnchor),
            marketBadge.widthAnchor.constraint(equalToConstant: 16), marketBadge.heightAnchor.constraint(equalToConstant: 14),
            priceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -30),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            changeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 40),
            changeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            percentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            percentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            percentLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            percentLabel.heightAnchor.constraint(equalToConstant: 28),
            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sep.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
        ])
    }

    func configure(name: String, code: String, symbol: String, price: String, change: String, changePercent: String) {
        nameLabel.text = name
        codeLabel.text = code

        // 交易所标识
        let market: String = {
            if symbol.hasPrefix("sh") { return "沪" }
            if symbol.hasPrefix("sz") { return "深" }
            if symbol.hasPrefix("bj") { return "北" }
            return ""
        }()
        marketBadge.text = market
        let badgeColors: [String: UIColor] = [
            "沪": UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1),
            "深": UIColor(red: 0.26, green: 0.65, blue: 0.96, alpha: 1),
            "北": UIColor(red: 0.26, green: 0.40, blue: 0.90, alpha: 1),
        ]
        marketBadge.backgroundColor = badgeColors[market] ?? .gray

        let cv = Double(change) ?? 0
        let isRise = cv >= 0
        let color = isRise ? red : green

        priceLabel.text = price; priceLabel.textColor = color
        let s = isRise && cv > 0 ? "+" : ""
        changeLabel.text = "\(s)\(change)"; changeLabel.textColor = color

        let pv = Double(changePercent) ?? 0
        let ps = isRise && pv > 0 ? "+" : ""
        percentLabel.text = " \(ps)\(changePercent)% "
        percentLabel.textColor = .white
        percentLabel.backgroundColor = color
    }
}

// =====================================================================
// MARK: - SubscriptionTableHeaderView
// =====================================================================
class SubscriptionTableHeaderView: UITableViewHeaderFooterView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1)
        let cols = ["申购代码", "发行价", "所属板块", "市盈率"]
        let xs: [CGFloat] = [16, 110, 200, -1]
        for (i, t) in cols.enumerated() {
            let l = UILabel(); l.text = t; l.font = .systemFont(ofSize: 13)
            l.textColor = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1)
            contentView.addSubview(l); l.translatesAutoresizingMaskIntoConstraints = false
            l.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
            if xs[i] < 0 { l.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true }
            else { l.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: xs[i]).isActive = true }
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

// =====================================================================
// MARK: - SubscriptionRowCell
// =====================================================================
class SubscriptionRowCell: UITableViewCell {
    private let nameLabel   = UILabel()
    private let codeLabel   = UILabel()
    private let marketBadge = UILabel()
    private let priceLabel  = UILabel()
    private let sectorLabel = UILabel()
    private let peLabel     = UILabel()
    private let sep         = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1)
        for v: UIView in [nameLabel, codeLabel, marketBadge, priceLabel, sectorLabel, peLabel, sep] {
            contentView.addSubview(v); v.translatesAutoresizingMaskIntoConstraints = false
        }
        let tp = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1)
        let ts = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1)
        nameLabel.font = .boldSystemFont(ofSize: 15); nameLabel.textColor = tp
        codeLabel.font = .systemFont(ofSize: 12); codeLabel.textColor = ts
        marketBadge.font = .boldSystemFont(ofSize: 11); marketBadge.textColor = .white
        marketBadge.textAlignment = .center; marketBadge.layer.cornerRadius = 2; marketBadge.clipsToBounds = true
        priceLabel.font = .systemFont(ofSize: 14); priceLabel.textColor = tp
        sectorLabel.font = .systemFont(ofSize: 13); sectorLabel.textColor = tp
        peLabel.font = .systemFont(ofSize: 13); peLabel.textColor = tp
        sep.backgroundColor = UIColor(white: 0.9, alpha: 1)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            codeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            marketBadge.leadingAnchor.constraint(equalTo: codeLabel.trailingAnchor, constant: 6),
            marketBadge.centerYAnchor.constraint(equalTo: codeLabel.centerYAnchor),
            marketBadge.widthAnchor.constraint(equalToConstant: 18), marketBadge.heightAnchor.constraint(equalToConstant: 16),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 110),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sectorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 200),
            sectorLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            peLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            peLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sep.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, code: String, market: String, price: String, sector: String, pe: String) {
        nameLabel.text = name; codeLabel.text = code; marketBadge.text = market
        let blue = UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)
        let r    = UIColor(red: 0.9, green: 0.3, blue: 0.35, alpha: 1)
        marketBadge.backgroundColor = (market == "北") ? blue : r
        priceLabel.text = price; sectorLabel.text = sector; peLabel.text = pe
    }
}
