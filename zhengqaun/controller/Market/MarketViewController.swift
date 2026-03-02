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
    private var segmentTitles = ["行情", "新股申购", "战略配售", "天启护盘"]
    private var selectedSegmentIndex = 0
    /// 外部指定初始选中的 tab 索引（0=行情，1=新股申购，3=撮合交易）
    var initialSegmentIndex: Int = 0
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
    private var dzjyBalance: Double = 0  // 场外撮合可用余额
    private let subsEmptyLabel = UILabel()  // 暂无数据提示
    
    // 撮合交易专用表头
    private var dzjyHeaderWrap: UIView!

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
    // 多列横向滚动
    private var rankingScrollOffset: CGFloat = 0
    private var rankingColumnHeaderScroll: UIScrollView?
    private var rankingColumnIndicator: UIView?

    // 动态标题与日期
    private var rankingTitleLabel: UILabel?
    private var rankingDateLabel: UILabel?

    // MARK: - Layout Tracking
    private var barChartRendered = false
    
    // MARK: - 分页加载
    private var rankingCurrentPage: Int = 1
    private var rankingIsLoading: Bool = false
    private var rankingHasMore: Bool = true

    // MARK: - 市场概括
    private var barChartContainer: UIView!
    private var riseCountLabel: UILabel!
    private var fallCountLabel: UILabel!
    private var progressBar: UIView!
    private var riseProgressLayer: CALayer!
    private var marketOverviewContainer: UIView!
    private var sectorContainer: UIView!
    private var rankingContainer: UIView!
    private weak var capFundValueLabel: UILabel?
    // MARK: - 行业板块数据
    private var sectorDataItems: [SectorDataItem] = []
    private var sectorGridStack: UIStackView?
    // MARK: - 概念板块数据
    private var conceptSectorDataItems: [SectorDataItem] = []
    private var conceptSectorGridStack: UIStackView?
    private var conceptSectorContainer: UIView!
    // MARK: - A股主力净流入
    private weak var mainFundFlowLabel: UILabel?

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
        var sparklinePrices: [Float] = []
    }

    struct StockRankItem {
        let name: String
        let code: String
        let symbol: String
        let price: String
        let change: String
        let changePercent: String
        var volume: String    = "--"   // 成交额
        var turnover: String  = "--"   // 换手率
        var prevClose: String = "--"   // 昨收
        var open: String      = "--"   // 今开
        var high: String      = "--"   // 最高
    }

    struct SectorDataItem {
        let name: String
        let code: String
        let changePercent: Double
        let topStock: String
        let topStockChange: Double
        let isUp: Bool
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
        // 监听功能开关通知
        NotificationCenter.default.addObserver(self, selector: #selector(updateFeatureSegments), name: FeatureSwitchManager.didUpdateNotification, object: nil)
        updateFeatureSegments()
        
        // 对齐安卓：支持外部指定初始选中 tab
        if initialSegmentIndex > 0, initialSegmentIndex < segmentTitles.count {
            selectedSegmentIndex = initialSegmentIndex
            refreshSegmentUI()
            updateVisibleContent()
        }
    }

    /// 根据功能开关隐藏/显示分段 tab 并更新标题
    @objc private func updateFeatureSegments() {
        let mgr = FeatureSwitchManager.shared
        if !mgr.nameXgsg.isEmpty { segmentTitles[1] = mgr.nameXgsg }
        if !mgr.nameXxps.isEmpty { segmentTitles[2] = mgr.nameXxps }
        if !mgr.nameDzjy.isEmpty { segmentTitles[3] = mgr.nameDzjy }
        
        for btn in segmentButtons {
            switch btn.tag {
            case 1:
                btn.isHidden = !mgr.isXgsgEnabled  // 新股申购
                btn.setTitle(segmentTitles[1], for: .normal)
            case 2:
                btn.isHidden = !mgr.isXxpsEnabled   // 战略配售
                btn.setTitle(segmentTitles[2], for: .normal)
            case 3:
                btn.isHidden = !mgr.isDzjyEnabled   // 天启护盘(大宗交易)
                btn.setTitle(segmentTitles[3], for: .normal)
            default: break
            }
        }
        
        if selectedSegmentIndex > 0 {
            if todayTitleLabel != nil {
                todayTitleLabel.text = segTitleFor(selectedSegmentIndex)
            }
            loadSubscriptionData()
        }
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
        guard todayHeaderWrap != nil else { return }
        if selectedSegmentIndex == 0 {
            hangqingScrollView.isHidden = false
            subsTableView.isHidden = true
            todayHeaderWrap.isHidden = true
            dzjyHeaderWrap.isHidden = true
        } else {
            hangqingScrollView.isHidden = true
            subsTableView.isHidden = false
            
            if selectedSegmentIndex == 3 {
                // 撮合交易：显示专门的表头，隐藏日期表头
                todayHeaderWrap.isHidden = true
                dzjyHeaderWrap.isHidden = false
            } else {
                // 新股/配售：显示日期表头，隐藏专门的表头
                todayHeaderWrap.isHidden = false
                dzjyHeaderWrap.isHidden = true
                todayTitleLabel.text = segTitleFor(selectedSegmentIndex)
            }
            
            loadSubscriptionData()
        }
    }

    private func segTitleFor(_ idx: Int) -> String {
        guard idx > 0, idx < segmentTitles.count else { return "" }
        return "今日\(segmentTitles[idx])"
    }

    // ===================================================================
    // MARK: - 行情 ScrollView (segment 0)
    // ===================================================================
    private func setupHangqingContent() {
        view.addSubview(hangqingScrollView)
        hangqingScrollView.translatesAutoresizingMaskIntoConstraints = false
        hangqingScrollView.backgroundColor = bgColor
        hangqingScrollView.showsVerticalScrollIndicator = false
        hangqingScrollView.delegate = self

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
            hangqingContent.bottomAnchor.constraint(equalTo: hangqingScrollView.bottomAnchor),
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

        // 2 — 市场概括（已隐藏）
        marketOverviewContainer = UIView()
        marketOverviewContainer.isHidden = true
        hangqingContent.addSubview(marketOverviewContainer)
        marketOverviewContainer.translatesAutoresizingMaskIntoConstraints = false

        // 3 — 行业板块（已隐藏）
        sectorContainer = UIView()
        sectorContainer.isHidden = true
        hangqingContent.addSubview(sectorContainer)
        sectorContainer.translatesAutoresizingMaskIntoConstraints = false

        // 3.5 — 概念板块（已隐藏）
        conceptSectorContainer = UIView()
        conceptSectorContainer.isHidden = true
        hangqingContent.addSubview(conceptSectorContainer)
        conceptSectorContainer.translatesAutoresizingMaskIntoConstraints = false

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

            // 市场概括和行业板块高度设为 0
            marketOverviewContainer.topAnchor.constraint(equalTo: indexCardsContainer.bottomAnchor),
            marketOverviewContainer.heightAnchor.constraint(equalToConstant: 0),
            sectorContainer.topAnchor.constraint(equalTo: marketOverviewContainer.bottomAnchor),
            sectorContainer.heightAnchor.constraint(equalToConstant: 0),
            conceptSectorContainer.topAnchor.constraint(equalTo: sectorContainer.bottomAnchor),
            conceptSectorContainer.heightAnchor.constraint(equalToConstant: 0),

            // 排行榜直接接在指数卡片下方
            rankingContainer.topAnchor.constraint(equalTo: indexCardsContainer.bottomAnchor, constant: 12),
            rankingContainer.leadingAnchor.constraint(equalTo: hangqingContent.leadingAnchor, constant: 12),
            rankingContainer.trailingAnchor.constraint(equalTo: hangqingContent.trailingAnchor, constant: -12),
            rankingContainer.bottomAnchor.constraint(equalTo: hangqingContent.bottomAnchor, constant: -20),
        ])

        // 市场概括和行业板块已隐藏，但仍需初始化变量以避免 nil 崩溃
        barChartContainer = UIView()
        riseCountLabel = UILabel()
        fallCountLabel = UILabel()
        progressBar = UIView()
        riseProgressLayer = CALayer()
//        buildMarketOverview()
//        buildSectorGrid()
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
            // 点击卡片进入指数详情
            card.tag = i
            card.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(indexCardTapped(_:)))
            card.addGestureRecognizer(tap)
        }
        indexCardsScroll.contentSize = CGSize(
            width: pad + CGFloat(indexItems.count) * (cardW + spacing) + pad,
            height: cardH + 12
        )
    }

    @objc private func indexCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view, card.tag < indexItems.count else { return }
        let item = indexItems[card.tag]
        let vc = IndexDetailViewController()
        vc.indexName = item.name
        vc.indexCode = item.code
        vc.indexAllcode = item.allcode
        vc.indexPrice = item.price
        vc.indexChange = item.change
        vc.indexChangePercent = item.changePercent
        vc.isIndex = true   // 指数卡片 → 不可交易
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
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

        // 优先使用真实走势数据，否则生成模拟走势
        let basePrice = Double(item.price) ?? 3000
        var entries: [ChartDataEntry] = []
        if !item.sparklinePrices.isEmpty {
            for (j, p) in item.sparklinePrices.enumerated() {
                entries.append(ChartDataEntry(x: Double(j), y: Double(p)))
            }
        } else {
            var lastP = basePrice * (1 - abs(changeVal) / basePrice * 0.6)
            let pointCount = 30
            for j in 0..<pointCount {
                let noiseFactor = Double.random(in: -0.002...0.002)
                let trendFactor = (changeVal / basePrice) * (Double(j) / Double(pointCount - 1))
                lastP = lastP * (1 + noiseFactor) + basePrice * trendFactor * 0.05
                entries.append(ChartDataEntry(x: Double(j), y: lastP))
            }
            entries[entries.count - 1] = ChartDataEntry(x: Double(pointCount - 1), y: basePrice)
        }

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
        capTitleLbl.text = "北向资金净流入"
        capTitleLbl.font = .systemFont(ofSize: 13)
        capTitleLbl.textColor = textSec
        marketOverviewContainer.addSubview(capTitleLbl)
        capTitleLbl.translatesAutoresizingMaskIntoConstraints = false

        let capValLbl = UILabel()
        capValLbl.text = "--"
        capValLbl.font = .boldSystemFont(ofSize: 15)
        capValLbl.textColor = themeRed
        marketOverviewContainer.addSubview(capValLbl)
        capValLbl.translatesAutoresizingMaskIntoConstraints = false
        capFundValueLabel = capValLbl

        // A 股主力净流入
        let mainFundTitleLbl = UILabel()
        mainFundTitleLbl.text = "A股主力净流入"
        mainFundTitleLbl.font = .systemFont(ofSize: 13)
        mainFundTitleLbl.textColor = textSec
        marketOverviewContainer.addSubview(mainFundTitleLbl)
        mainFundTitleLbl.translatesAutoresizingMaskIntoConstraints = false

        let mainFundValLbl = UILabel()
        mainFundValLbl.text = "--"
        mainFundValLbl.font = .boldSystemFont(ofSize: 15)
        mainFundValLbl.textColor = themeRed
        marketOverviewContainer.addSubview(mainFundValLbl)
        mainFundValLbl.translatesAutoresizingMaskIntoConstraints = false
        mainFundFlowLabel = mainFundValLbl

        NSLayoutConstraint.activate([
            mainFundTitleLbl.topAnchor.constraint(equalTo: capTitleLbl.topAnchor),
            mainFundTitleLbl.leadingAnchor.constraint(equalTo: marketOverviewContainer.centerXAnchor, constant: 8),
            mainFundValLbl.topAnchor.constraint(equalTo: capValLbl.topAnchor),
            mainFundValLbl.leadingAnchor.constraint(equalTo: mainFundTitleLbl.leadingAnchor),
        ])

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
            var col = bar.isRise ? themeRed : stockGreen
            if bar.label == "平" {
                col = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
            }

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
        if progressBar.bounds.width > 0 {
            riseProgressLayer.frame = CGRect(x: 0, y: 0, width: progressBar.bounds.width * r, height: 6)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 市场概括已隐藏，跳过 barChart 布局
        if selectedSegmentIndex == 0 && !barChartRendered && barChartContainer.superview != nil { layoutBarChart() }
        if progressBar.superview != nil { updateProgressBar() }
    }

    // ===================================================================
    // MARK: - 3. 行业板块
    // ===================================================================
    private func buildSectorGrid() {
        let title = makeTitle("行业板块")
        sectorContainer.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false

        let grid = UIStackView()
        grid.axis = .vertical; grid.spacing = 0; grid.distribution = .fill
        sectorContainer.addSubview(grid)
        grid.translatesAutoresizingMaskIntoConstraints = false
        sectorGridStack = grid

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: sectorContainer.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: sectorContainer.leadingAnchor, constant: 16),
            grid.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            grid.leadingAnchor.constraint(equalTo: sectorContainer.leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: sectorContainer.trailingAnchor),
            grid.bottomAnchor.constraint(equalTo: sectorContainer.bottomAnchor, constant: -12),
        ])
    }

    /// 用 API 数据填充行业板块网格（加载完成后调用）
    private func populateSectorGrid() {
        guard let grid = sectorGridStack else { return }
        grid.arrangedSubviews.forEach { grid.removeArrangedSubview($0); $0.removeFromSuperview() }
        let items = Array(sectorDataItems.prefix(20)) // 展示最多 20 个板块数据
        guard !items.isEmpty else { return }
        let rowCount = Int(ceil(Double(items.count) / 3.0))
        for row in 0..<rowCount {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal; rowStack.spacing = 0; rowStack.distribution = .fillEqually
            rowStack.heightAnchor.constraint(equalToConstant: 90).isActive = true
            grid.addArrangedSubview(rowStack)
            for col in 0..<3 {
                let idx = row * 3 + col
                let cell = UIView()
                let nm = UILabel()
                let pc = UILabel()
                let sb = UILabel()
                if idx < items.count {
                    let s = items[idx]
                    let sign = s.isUp ? "+" : ""
                    let color = s.isUp ? themeRed : stockGreen
                    let topSign = s.topStockChange >= 0 ? "+" : ""
                    nm.text = s.name
                    pc.text = "\(sign)\(String(format: "%.2f", s.changePercent))%"
                    pc.textColor = color
                    sb.text = "\(s.topStock) \(topSign)\(String(format: "%.2f", s.topStockChange))%"
                } else {
                    nm.text = ""; pc.text = ""; sb.text = ""
                    pc.textColor = themeRed
                }
                nm.font = .boldSystemFont(ofSize: 15); nm.textColor = textPrimary; nm.textAlignment = .center
                pc.font = .boldSystemFont(ofSize: 17); pc.textAlignment = .center
                sb.font = .systemFont(ofSize: 11); sb.textColor = textSec; sb.textAlignment = .center
                for l: UIView in [nm, pc, sb] { cell.addSubview(l); l.translatesAutoresizingMaskIntoConstraints = false }
                NSLayoutConstraint.activate([
                    nm.topAnchor.constraint(equalTo: cell.topAnchor, constant: 10),
                    nm.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                    pc.topAnchor.constraint(equalTo: nm.bottomAnchor, constant: 6),
                    pc.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                    sb.topAnchor.constraint(equalTo: pc.bottomAnchor, constant: 4),
                    sb.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                ])
                rowStack.addArrangedSubview(cell)
                
                // 点击跳转详情
                if idx < items.count {
                    cell.tag = idx
                    cell.isUserInteractionEnabled = true
                    cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sectorItemTapped(_:))))
                }
            }
        }
    }

    /// 用 API 数据填充概念板块网格
    private func populateConceptSectorGrid() {
        // 如果还没构建过概念板块 grid，先构建
        if conceptSectorGridStack == nil {
            let title = makeTitle("概念板块")
            conceptSectorContainer.addSubview(title)
            title.translatesAutoresizingMaskIntoConstraints = false
            let grid = UIStackView()
            grid.axis = .vertical; grid.spacing = 0; grid.distribution = .fill
            conceptSectorContainer.addSubview(grid)
            grid.translatesAutoresizingMaskIntoConstraints = false
            conceptSectorGridStack = grid
            NSLayoutConstraint.activate([
                title.topAnchor.constraint(equalTo: conceptSectorContainer.topAnchor, constant: 16),
                title.leadingAnchor.constraint(equalTo: conceptSectorContainer.leadingAnchor, constant: 16),
                grid.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
                grid.leadingAnchor.constraint(equalTo: conceptSectorContainer.leadingAnchor),
                grid.trailingAnchor.constraint(equalTo: conceptSectorContainer.trailingAnchor),
                grid.bottomAnchor.constraint(equalTo: conceptSectorContainer.bottomAnchor, constant: -12),
            ])
        }
        guard let grid = conceptSectorGridStack else { return }
        grid.arrangedSubviews.forEach { grid.removeArrangedSubview($0); $0.removeFromSuperview() }
        let items = Array(conceptSectorDataItems.prefix(20))
        guard !items.isEmpty else { return }
        let rowCount = Int(ceil(Double(items.count) / 3.0))
        for row in 0..<rowCount {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal; rowStack.spacing = 0; rowStack.distribution = .fillEqually
            rowStack.heightAnchor.constraint(equalToConstant: 90).isActive = true
            grid.addArrangedSubview(rowStack)
            for col in 0..<3 {
                let idx = row * 3 + col
                let cell = UIView()
                let nm = UILabel(); let pc = UILabel(); let sb = UILabel()
                if idx < items.count {
                    let s = items[idx]
                    let sign = s.isUp ? "+" : ""
                    let color = s.isUp ? themeRed : stockGreen
                    let topSign = s.topStockChange >= 0 ? "+" : ""
                    nm.text = s.name
                    pc.text = "\(sign)\(String(format: "%.2f", s.changePercent))%"
                    pc.textColor = color
                    sb.text = "\(s.topStock) \(topSign)\(String(format: "%.2f", s.topStockChange))%"
                } else { nm.text = ""; pc.text = ""; sb.text = ""; pc.textColor = themeRed }
                nm.font = .boldSystemFont(ofSize: 15); nm.textColor = textPrimary; nm.textAlignment = .center
                pc.font = .boldSystemFont(ofSize: 17); pc.textAlignment = .center
                sb.font = .systemFont(ofSize: 11); sb.textColor = textSec; sb.textAlignment = .center
                for l: UIView in [nm, pc, sb] { cell.addSubview(l); l.translatesAutoresizingMaskIntoConstraints = false }
                NSLayoutConstraint.activate([
                    nm.topAnchor.constraint(equalTo: cell.topAnchor, constant: 10),
                    nm.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                    pc.topAnchor.constraint(equalTo: nm.bottomAnchor, constant: 6),
                    pc.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                    sb.topAnchor.constraint(equalTo: pc.bottomAnchor, constant: 4),
                    sb.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                ])
                rowStack.addArrangedSubview(cell)
            }
        }
    }
    
    @objc private func sectorItemTapped(_ g: UITapGestureRecognizer) {
        guard let cell = g.view else { return }
        let idx = cell.tag
        guard idx < sectorDataItems.count else { return }
        let item = sectorDataItems[idx]
        let vc = IndexDetailViewController()
        vc.indexName = item.name
        vc.indexCode = item.code
        vc.indexAllcode = "90.\(item.code)"
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // ===================================================================
    // MARK: - 4. 股票排行榜 (沪深 / 创业 / 北证 / 科创)
    // ===================================================================
    private func buildRankingSection() {
        // 1. 标题
        let title = makeTitle("股票排行榜")
        rankingTitleLabel = title
        rankingContainer.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        
        // 随 Tab 变化的日期
        let dateLbl = UILabel()
        dateLbl.font = .systemFont(ofSize: 12)
        dateLbl.textColor = textSec
        dateLbl.isHidden = true
        rankingDateLabel = dateLbl
        rankingContainer.addSubview(dateLbl)
        dateLbl.translatesAutoresizingMaskIntoConstraints = false

        // 2. 市场 Tab（沪深/创业/北证/科创）— 对齐安卓：隐藏
        let tabWrap = UIView()
        tabWrap.isHidden = true
        tabWrap.clipsToBounds = true
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

        // 3. 列标题行：固定「名称」列 + 可横滑的数据列 tab（对齐 Android layout_ranking_tabs）
        let colHeaderWrap = UIView()
        colHeaderWrap.backgroundColor = .white
        
        rankingContainer.addSubview(colHeaderWrap)
        colHeaderWrap.translatesAutoresizingMaskIntoConstraints = false
        // 左侧固定「名称」
        let nameLbl = UILabel()
        nameLbl.text = "名称"
        nameLbl.font = .boldSystemFont(ofSize: 13)
        nameLbl.textColor = textPrimary
        colHeaderWrap.addSubview(nameLbl)
        nameLbl.translatesAutoresizingMaskIntoConstraints = false
        // 右侧横向滚动区
        let colScroll = UIScrollView()
        colScroll.showsHorizontalScrollIndicator = false
        colScroll.bounces = false
        colScroll.delegate = self
        colHeaderWrap.addSubview(colScroll)
        colScroll.translatesAutoresizingMaskIntoConstraints = false
        rankingColumnHeaderScroll = colScroll
        let colContent = UIView()
        colScroll.addSubview(colContent)
        colContent.translatesAutoresizingMaskIntoConstraints = false
        let totalColW = RankingStockCell.columnWidths.reduce(0, +)
        NSLayoutConstraint.activate([
            colContent.topAnchor.constraint(equalTo: colScroll.topAnchor),
            colContent.leadingAnchor.constraint(equalTo: colScroll.leadingAnchor),
            colContent.trailingAnchor.constraint(equalTo: colScroll.trailingAnchor),
            colContent.bottomAnchor.constraint(equalTo: colScroll.bottomAnchor),
            colContent.heightAnchor.constraint(equalTo: colScroll.heightAnchor),
            colContent.widthAnchor.constraint(equalToConstant: totalColW),
        ])

        // 添加列标题按钮（对齐 Android rankingTabs：现价/涨跌幅/成交额/换手率/昨收/今开/最高）
        var colLeading: CGFloat = 0
        for (i, colTitle) in RankingStockCell.columnTitles.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(colTitle, for: .normal)
            btn.tag = i
            btn.titleLabel?.font = i == 0 ? .boldSystemFont(ofSize: 13) : .systemFont(ofSize: 13)
            btn.setTitleColor(i == 0 ? textPrimary : textSec, for: .normal)
            btn.addTarget(self, action: #selector(rankingColumnTapped(_:)), for: .touchUpInside)
            colContent.addSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: colContent.topAnchor),
                btn.bottomAnchor.constraint(equalTo: colContent.bottomAnchor),
                btn.leadingAnchor.constraint(equalTo: colContent.leadingAnchor, constant: colLeading),
                btn.widthAnchor.constraint(equalToConstant: RankingStockCell.columnWidths[i]),
            ])
            colLeading += RankingStockCell.columnWidths[i]
        }

        // 列 Tab 指示器（对齐 Android view_ranking_indicator）
        let colIndicator = UIView()
        colIndicator.backgroundColor = themeRed
        colIndicator.layer.cornerRadius = 1.5
        let firstColW = RankingStockCell.columnWidths[0]
        colIndicator.frame = CGRect(x: (firstColW - 24) / 2, y: 0, width: 24, height: 3)
        colContent.addSubview(colIndicator)
        rankingColumnIndicator = colIndicator
        
        // 约束 colHeaderWrap 内部布局
        NSLayoutConstraint.activate([
            nameLbl.leadingAnchor.constraint(equalTo: colHeaderWrap.leadingAnchor, constant: 12),
            nameLbl.centerYAnchor.constraint(equalTo: colHeaderWrap.centerYAnchor),
            colScroll.leadingAnchor.constraint(equalTo: colHeaderWrap.leadingAnchor, constant: RankingStockCell.leftWidth),
            colScroll.topAnchor.constraint(equalTo: colHeaderWrap.topAnchor),
            colScroll.trailingAnchor.constraint(equalTo: colHeaderWrap.trailingAnchor),
            colScroll.bottomAnchor.constraint(equalTo: colHeaderWrap.bottomAnchor),
        ])

        // 4. TableView
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
            
            dateLbl.leadingAnchor.constraint(equalTo: title.trailingAnchor, constant: 8),
            dateLbl.centerYAnchor.constraint(equalTo: title.centerYAnchor),

            // 对齐安卓：隐藏市场分类 tab（沪深/创业/北证/科创），列标题直接显示在标题下方
            tabWrap.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 0),
            tabWrap.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor),
            tabWrap.trailingAnchor.constraint(equalTo: rankingContainer.trailingAnchor),
            tabWrap.heightAnchor.constraint(equalToConstant: 0),

            colHeaderWrap.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            colHeaderWrap.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor),
            colHeaderWrap.trailingAnchor.constraint(equalTo: rankingContainer.trailingAnchor),
            colHeaderWrap.heightAnchor.constraint(equalToConstant: 40),

            rankingTableView.topAnchor.constraint(equalTo: colHeaderWrap.bottomAnchor),
            rankingTableView.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor),
            rankingTableView.trailingAnchor.constraint(equalTo: rankingContainer.trailingAnchor),
            rankingTableView.bottomAnchor.constraint(equalTo: rankingContainer.bottomAnchor),
        ])

        // 分割线（对齐 Android）
        let divider = UIView()
        divider.backgroundColor = UIColor(white: 0.93, alpha: 1)
        rankingContainer.addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: colHeaderWrap.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: rankingContainer.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: rankingContainer.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
        ])

        // 布局完成后更新指示器位置到底部
        DispatchQueue.main.async {
            self.moveTabIndicator(animated: false)
            // 指示器放在底部
            if let indicator = self.rankingColumnIndicator {
                let y = (indicator.superview?.bounds.height ?? 40) - 5
                indicator.frame = CGRect(x: indicator.frame.origin.x, y: y, width: 24, height: 3)
            }
            self.moveRankingColumnIndicator(to: 0, animated: false)
        }
        updateRankingTitle()
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
        updateRankingTitle()
        
        // 切换 Tab 时重置分页
        rankingCurrentPage = 1
        rankingHasMore = true
        loadRankingData()
    }
    
    private func updateRankingTitle() {
        guard selectedMarketTab < marketTabs.count else { return }
        // 标题固定为"股票排行榜"，不跟随 Tab 变化
        
        if selectedMarketTab == 2 || selectedMarketTab == 3 {
            rankingDateLabel?.isHidden = false
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            rankingDateLabel?.text = fmt.string(from: Date())
        } else {
            rankingDateLabel?.isHidden = true
        }
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

    // MARK: - 加载更多 footer（对应 Android layoutLoadMore）
    private lazy var loadMoreFooter: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.tag = 100
        spinner.hidesWhenStopped = true
        v.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        let noMoreLbl = UILabel()
        noMoreLbl.tag = 200
        noMoreLbl.text = "没有更多数据了"
        noMoreLbl.font = .systemFont(ofSize: 13)
        noMoreLbl.textColor = UIColor(white: 0.6, alpha: 1)
        noMoreLbl.textAlignment = .center
        noMoreLbl.isHidden = true
        v.addSubview(noMoreLbl)
        noMoreLbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            noMoreLbl.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            noMoreLbl.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])
        return v
    }()

    /// 更新加载更多 footer 状态（对应 Android stockLoadState: 0/1/2）
    private func updateLoadMoreFooter() {
        // 确保 footer 已挂载
        if rankingTableView.tableFooterView !== loadMoreFooter {
            rankingTableView.tableFooterView = loadMoreFooter
        }
        let spinner = loadMoreFooter.viewWithTag(100) as? UIActivityIndicatorView
        let noMoreLbl = loadMoreFooter.viewWithTag(200) as? UILabel
        if rankingIsLoading {
            // 状态 1：加载中
            loadMoreFooter.isHidden = false
            spinner?.startAnimating()
            noMoreLbl?.isHidden = true
        } else if !rankingHasMore && !rankingStocks.isEmpty {
            // 状态 2：没有更多
            loadMoreFooter.isHidden = false
            spinner?.stopAnimating()
            noMoreLbl?.isHidden = false
        } else {
            // 状态 0：空闲
            loadMoreFooter.isHidden = true
            spinner?.stopAnimating()
            noMoreLbl?.isHidden = true
        }
    }

    /// 同步所有可见行和列标题到同一横向偏移（对应 Android setupScrollSync）
    private func syncAllRankingRows(to offset: CGFloat) {
        rankingScrollOffset = offset
        if let scv = rankingColumnHeaderScroll, abs(scv.contentOffset.x - offset) > 0.5 {
            scv.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        }
        for cell in (rankingTableView?.visibleCells ?? []).compactMap({ $0 as? RankingStockCell }) {
            cell.syncOffset(offset)
        }
    }

    /// 移动列指示器到指定列（对应 Android rankingTabIndicatorHelper.selectTab）
    private func moveRankingColumnIndicator(to index: Int, animated: Bool) {
        guard index < RankingStockCell.columnWidths.count,
              let indicator = rankingColumnIndicator else { return }
        var x: CGFloat = 0
        for i in 0..<index { x += RankingStockCell.columnWidths[i] }
        let colW = RankingStockCell.columnWidths[index]
        let iW: CGFloat = 20
        let target = CGRect(x: x + (colW - iW) / 2,
                            y: indicator.frame.minY,
                            width: iW, height: indicator.frame.height)
        if animated { UIView.animate(withDuration: 0.2) { indicator.frame = target } }
        else { indicator.frame = target }
    }

    /// 点击列 tab：滚动数据到该列并更新指示器
    @objc private func rankingColumnTapped(_ sender: UIButton) {
        let idx = sender.tag
        var x: CGFloat = 0
        for i in 0..<idx { x += RankingStockCell.columnWidths[i] }
        let colW = RankingStockCell.columnWidths[idx]
        let visibleW = (rankingContainer?.bounds.width ?? UIScreen.main.bounds.width) - RankingStockCell.leftWidth
        let targetX = max(0, x - (visibleW - colW) / 2)
        syncAllRankingRows(to: targetX)
        moveRankingColumnIndicator(to: idx, animated: true)
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

        // --- 撮合交易表头 ---
        dzjyHeaderWrap = UIView()
        dzjyHeaderWrap.backgroundColor = .white
        dzjyHeaderWrap.isHidden = true
        view.addSubview(dzjyHeaderWrap)
        dzjyHeaderWrap.translatesAutoresizingMaskIntoConstraints = false
        
        let dzjyHeaders = ["股票名称", "现价", "交易价", "折扣率(%)", "操作"]
        let dzjyStack = UIStackView()
        dzjyStack.axis = .horizontal
        dzjyStack.distribution = .fillEqually
        dzjyStack.alignment = .center
        dzjyHeaderWrap.addSubview(dzjyStack)
        dzjyStack.translatesAutoresizingMaskIntoConstraints = false
        
        for (i, title) in dzjyHeaders.enumerated() {
            let lbl = UILabel()
            lbl.text = title
            lbl.font = .systemFont(ofSize: 13)
            lbl.textColor = textSec
            lbl.textAlignment = i == 0 ? .left : (i == dzjyHeaders.count - 1 ? .right : .center)
            dzjyStack.addArrangedSubview(lbl)
        }
        
        let dzjyLine = UIView()
        dzjyLine.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        dzjyHeaderWrap.addSubview(dzjyLine)
        dzjyLine.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(subsTableView)
        subsTableView.translatesAutoresizingMaskIntoConstraints = false
        subsTableView.backgroundColor = bgColor
        subsTableView.separatorStyle = .none
        subsTableView.delegate = self; subsTableView.dataSource = self
        subsTableView.register(IpoPlacementCell.self, forCellReuseIdentifier: "IpoPlacementCell")
        subsTableView.register(BlockTradeCell.self, forCellReuseIdentifier: "BlockTradeCell")
        if #available(iOS 11.0, *) { subsTableView.contentInsetAdjustmentBehavior = .never }
        if #available(iOS 15.0, *) { subsTableView.sectionHeaderTopPadding = 0 }

        // 空状态标签
        subsEmptyLabel.text = "暂无数据"
        subsEmptyLabel.font = UIFont.systemFont(ofSize: 14)
        subsEmptyLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        subsEmptyLabel.textAlignment = .center
        subsEmptyLabel.isHidden = true
        view.addSubview(subsEmptyLabel)
        subsEmptyLabel.translatesAutoresizingMaskIntoConstraints = false

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

            dzjyHeaderWrap.topAnchor.constraint(equalTo: segmentWrap.bottomAnchor),
            dzjyHeaderWrap.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dzjyHeaderWrap.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dzjyHeaderWrap.heightAnchor.constraint(equalToConstant: 34),
            
            dzjyStack.leadingAnchor.constraint(equalTo: dzjyHeaderWrap.leadingAnchor, constant: 16),
            dzjyStack.trailingAnchor.constraint(equalTo: dzjyHeaderWrap.trailingAnchor, constant: -16),
            dzjyStack.topAnchor.constraint(equalTo: dzjyHeaderWrap.topAnchor),
            dzjyStack.bottomAnchor.constraint(equalTo: dzjyHeaderWrap.bottomAnchor, constant: -1),
            
            dzjyLine.leadingAnchor.constraint(equalTo: dzjyHeaderWrap.leadingAnchor),
            dzjyLine.trailingAnchor.constraint(equalTo: dzjyHeaderWrap.trailingAnchor),
            dzjyLine.bottomAnchor.constraint(equalTo: dzjyHeaderWrap.bottomAnchor),
            dzjyLine.heightAnchor.constraint(equalToConstant: 1),

            subsTableView.topAnchor.constraint(equalTo: segmentWrap.bottomAnchor, constant: 38),
            subsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            subsEmptyLabel.centerXAnchor.constraint(equalTo: subsTableView.centerXAnchor),
            subsEmptyLabel.centerYAnchor.constraint(equalTo: subsTableView.centerYAnchor),
        ])
    }

    // ===================================================================
    // MARK: - Helpers
    // ===================================================================
    private func makeTitle(_ text: String) -> UILabel {
        let l = UILabel(); l.text = text; l.font = .boldSystemFont(ofSize: 18); l.textColor = textPrimary; return l
    }

    /// 成交量格式化（对应 Android HqViewModel.formatVolume）
    private func formatVolume(_ raw: String) -> String {
        guard let v = Int64(raw.trimmingCharacters(in: .whitespaces)) else { return raw.isEmpty ? "--" : raw }
        if v >= 100_000_000 { return String(format: "%.2f亿", Double(v) / 100_000_000.0) }
        if v >= 10_000       { return String(format: "%.2f万", Double(v) / 10_000.0) }
        return v == 0 ? "--" : "\(v)"
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
        loadMarketRiseCount()
        loadMarketFundFlow()
        loadSectorData()
        loadConceptSectorData()
        loadMainFundFlow()
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
                    self.loadIndexSparklines()  // 加载真实走势图
                    print("[行情] 指数行情加载成功，共 \(items.count) 条")
                }
            case .failure(let err):
                print("[行情] 指数行情请求失败: \(err.localizedDescription)")
            }
        }
    }

    /// 股票排行榜 — 根据当前 tab 请求对应接口
    private func loadRankingData(isLoadMore: Bool = false) {
        guard !rankingIsLoading && rankingHasMore else { return }
        rankingIsLoading = true
        if isLoadMore { updateLoadMoreFooter() }  // 显示加载中转圈
        
        let api = marketAPIs[selectedMarketTab]
        let page = isLoadMore ? rankingCurrentPage + 1 : 1
        
        SecureNetworkManager.shared.request(
            api: api,
            method: .get,
            params: ["page": "\(page)", "size": "50"]
        ) { [weak self] result in
            guard let self = self else { return }
            self.rankingIsLoading = false
            switch result {
            case .success(let res):
                guard res.statusCode == 200,
                      let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    print("[行情] 排行榜(\(self.marketTabs[self.selectedMarketTab])): 解析失败, raw=\(res.raw.prefix(200))")
                    if isLoadMore { self.rankingHasMore = false }
                    return
                }
                var stocks: [StockRankItem] = []
                for item in list {
                    let name    = item["name"] as? String ?? (item["title"] as? String ?? "")
                    let code    = item["code"] as? String ?? ""
                    let symbol  = item["symbol"] as? String ?? (item["allcode"] as? String ?? "")
                    let price   = "\(item["trade"] ?? item["cai_buy"] ?? "0")"
                    let change   = "\(item["pricechange"]   ?? "0")"
                    let percent  = "\(item["changepercent"] ?? "0")"
                    let volume   = formatVolume("\(item["buy"]        ?? "")")
                    let prevClose = "\(item["settlement"]   ?? "--")"
                    let openVal   = "\(item["open"]         ?? "--")"
                    stocks.append(StockRankItem(name: name, code: code, symbol: symbol,
                                               price: price, change: change, changePercent: percent,
                                               volume: volume, turnover: "--",
                                               prevClose: prevClose, open: openVal, high: "--"))
                }
                DispatchQueue.main.async {
                    if isLoadMore {
                        // 去重逻辑（按 symbol 去重，与 Android 一致）
                        let existedKeys = Set(self.rankingStocks.map { $0.symbol })
                        let newStocks = stocks.filter { !existedKeys.contains($0.symbol) }
                        self.rankingStocks.append(contentsOf: newStocks)
                        self.rankingCurrentPage += 1
                        if stocks.isEmpty || newStocks.isEmpty {
                            self.rankingHasMore = false
                        }
                    } else {
                        // distinct by symbol
                        var seen = Set<String>()
                        self.rankingStocks = stocks.filter { seen.insert($0.symbol).inserted }
                        self.rankingCurrentPage = 1
                        self.rankingHasMore = !stocks.isEmpty
                    }
                    self.rankingTableView.reloadData()
                    self.updateRankingHeight()
                    self.updateLoadMoreFooter()
                    print("[行情] 排行榜(\(self.marketTabs[self.selectedMarketTab]))加载成功，共 \(self.rankingStocks.count) 条, 当前页: \(self.rankingCurrentPage)")
                }
            case .failure(let err):
                self.rankingIsLoading = false
                if isLoadMore {
                    // 加载失败回退页码（与 Android 一致）
                    self.rankingCurrentPage = max(1, self.rankingCurrentPage)
                }
                print("[行情] 排行榜请求失败: \(err.localizedDescription)")
            }
        }
    }

    // ===================================================================
    // MARK: - ★ East Money 公开行情接口（对齐 Android HqViewModel）
    // ===================================================================

    /// 指数走势折线 — 东方财富 trends2 API
    /// 对应 Android: EastMoneyMarketRepository.fetchIndexSparkline
    private func loadIndexSparklines() {
        let items = indexItems
        guard !items.isEmpty else { return }
        let group  = DispatchGroup()
        var sparklineMap: [String: [Float]] = [:]
        let lock = NSLock()
        for item in items {
            let allcode = item.allcode.lowercased()
            let secId: String
            if allcode.hasPrefix("sh") {
                secId = "1.\(allcode.dropFirst(2))"
            } else if allcode.hasPrefix("sz") {
                secId = "0.\(allcode.dropFirst(2))"
            } else { continue }
            let urlStr = "https://push2his.eastmoney.com/api/qt/stock/trends2/get"
                + "?secid=\(secId)&fields1=f1,f2,f3,f4,f5,f6,f7,f8"
                + "&fields2=f51,f52,f53,f54,f55,f56,f57,f58&ndays=1&iscr=0"
            group.enter()
            fetchEastMoneyJSON(url: urlStr) { root in
                defer { group.leave() }
                guard let data = root?["data"] as? [String: Any],
                      let trends = data["trends"] as? [String] else { return }
                let prices = trends.compactMap { t -> Float? in
                    let parts = t.split(separator: ",")
                    guard parts.count > 1 else { return nil }
                    return Float(parts[1])
                }
                lock.lock(); sparklineMap[item.code] = prices; lock.unlock()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.indexItems = self.indexItems.map { item in
                var updated = item
                if let prices = sparklineMap[item.code], !prices.isEmpty {
                    updated.sparklinePrices = prices
                }
                return updated
            }
            self.populateIndexCards()
            print("[行情] 指数走势图更新完成")
        }
    }

    /// 全市场涨跌家数 — 东方财富 ulist API
    /// 对应 Android: EastMoneyMarketRepository.fetchRiseCount
    private func loadMarketRiseCount() {
        let url = "https://push2delay.eastmoney.com/api/qt/ulist/get"
            + "?fltt=2&invt=2&pn=1&np=1&pz=5"
            + "&secids=1.000001,0.399001&fields=f104,f105,f106"
        fetchEastMoneyJSON(url: url) { [weak self] root in
            guard let self = self,
                  let data = root?["data"] as? [String: Any] else { return }
            // diff 兼容数组和字典格式
            var diffArr: [[String: Any]] = []
            if let arr = data["diff"] as? [[String: Any]] { diffArr = arr }
            else if let dict = data["diff"] as? [String: Any] {
                diffArr = dict.values.compactMap { $0 as? [String: Any] }
            }
            guard let first = diffArr.first,
                  let rise  = first["f104"] as? Int,
                  let fall  = first["f105"] as? Int else { return }
            DispatchQueue.main.async {
                self.riseCount = rise
                self.fallCount = fall
                self.riseCountLabel?.text = "上涨\(rise)"
                self.fallCountLabel?.text = "下跌\(fall)"
                self.updateProgressBar()
                print("[行情] 涨跌家数: 涨\(rise) 跌\(fall)")
            }
        }
    }

    /// 北向资金净流入 — 东方财富 kamt API
    /// 对应 Android: EastMoneyMarketRepository.fetchFundFlow
    private func loadMarketFundFlow() {
        let url = "https://push2delay.eastmoney.com/api/qt/kamt/get"
            + "?fields1=f1,f2,f3,f4&fields2=f51,f52,f53,f54,f56,f62,f63,f65,f66"
        fetchEastMoneyJSON(url: url) { [weak self] root in
            guard let self = self, let root = root else { return }
            // 北向资金：沪股通(sh2hk) + 深股通(sz2hk)
            var amount: Double?
            if let sh = (root["sh2hk"] as? [String: Any])?["netBuyAmt"] as? Double,
               let sz = (root["sz2hk"] as? [String: Any])?["netBuyAmt"] as? Double {
                amount = sh + sz
            }
            // fallback: 南向
            if amount == nil,
               let hkSh = (root["hk2sh"] as? [String: Any])?["netBuyAmt"] as? Double,
               let hkSz = (root["hk2sz"] as? [String: Any])?["netBuyAmt"] as? Double {
                amount = hkSh + hkSz
            }
            guard let amt = amount else { return }
            let isPos = amt >= 0
            let absAmt = Swift.abs(amt)
            let sign   = isPos ? "" : "-"
            let display: String
            if absAmt >= 1_0000_0000 {
                display = "\(sign)\(String(format: "%.2f", absAmt / 1_0000_0000))亿"
            } else if absAmt >= 10000 {
                display = "\(sign)\(String(format: "%.2f", absAmt / 10000))万"
            } else {
                display = "\(sign)\(String(format: "%.2f", absAmt))"
            }
            DispatchQueue.main.async {
                self.capFundValueLabel?.text = display
                self.capFundValueLabel?.textColor = isPos ? self.themeRed : self.stockGreen
                print("[行情] 北向资金净流入: \(display)")
            }
        }
    }

    /// 行业板块 TOP6 — 东方财富 clist API (sectorType=2)
    /// 对应 Android: EastMoneyMarketRepository.fetchSectorList(2)
    private func loadSectorData(retryCount: Int = 0) {
        let url = "https://push2delay.eastmoney.com/api/qt/clist/get"
            + "?pn=1&pz=20&po=1&np=1&fltt=2&invt=2&fid=f3"
            + "&fs=m:90+t:2&fields=f3,f12,f14,f128,f136"
        fetchEastMoneyJSON(url: url) { [weak self] root in
            guard let self = self else { return }
            
            // 解析数据
            guard let root = root,
                  let data = root["data"] as? [String: Any] else {
                print("[行情] 行业板块: 解析失败 root=\(root ?? [:])")
                // 重试（最多 3 次）
                if retryCount < 3 {
                    print("[行情] 行业板块: 第 \(retryCount + 1) 次重试...")
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                        self.loadSectorData(retryCount: retryCount + 1)
                    }
                }
                return
            }
            
            // diff 可能是数组或字典（按 key 索引）
            var diffArr: [[String: Any]] = []
            if let arr = data["diff"] as? [[String: Any]] {
                diffArr = arr
            } else if let dict = data["diff"] as? [String: Any] {
                // 有时返回 {"0": {...}, "1": {...}} 格式
                diffArr = dict.keys.sorted().compactMap { dict[$0] as? [String: Any] }
            }
            
            guard !diffArr.isEmpty else {
                print("[行情] 行业板块: diff 为空, data keys=\(data.keys)")
                if retryCount < 3 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                        self.loadSectorData(retryCount: retryCount + 1)
                    }
                }
                return
            }
            
            let items = diffArr.compactMap { obj -> SectorDataItem? in
                guard let name = obj["f14"] as? String, !name.isEmpty else { return nil }
                let code        = (obj["f12"]  as? String) ?? ""
                let changePct   = (obj["f3"]   as? Double) ?? 0.0
                let topStock    = (obj["f128"]  as? String) ?? ""
                let topChange   = (obj["f136"]  as? Double) ?? 0.0
                return SectorDataItem(name: name, code: code, changePercent: changePct,
                                      topStock: topStock, topStockChange: topChange,
                                      isUp: changePct >= 0)
            }
            DispatchQueue.main.async {
                self.sectorDataItems = items
                self.populateSectorGrid()
                print("[行情] 行业板块加载成功，共 \(items.count) 条")
            }
        }
    }

    /// 概念板块 TOP20 — 东方财富 clist API (sectorType=3)
    /// 对应 Android: EastMoneyMarketRepository.fetchSectorList(3)
    private func loadConceptSectorData(retryCount: Int = 0) {
        let url = "https://push2delay.eastmoney.com/api/qt/clist/get"
            + "?pn=1&pz=20&po=1&np=1&fltt=2&invt=2&fid=f3"
            + "&fs=m:90+t:3&fields=f3,f12,f14,f128,f136"
        fetchEastMoneyJSON(url: url) { [weak self] root in
            guard let self = self else { return }
            guard let root = root,
                  let data = root["data"] as? [String: Any] else {
                if retryCount < 3 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                        self.loadConceptSectorData(retryCount: retryCount + 1)
                    }
                }
                return
            }
            var diffArr: [[String: Any]] = []
            if let arr = data["diff"] as? [[String: Any]] { diffArr = arr }
            else if let dict = data["diff"] as? [String: Any] {
                diffArr = dict.keys.sorted().compactMap { dict[$0] as? [String: Any] }
            }
            guard !diffArr.isEmpty else {
                if retryCount < 3 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                        self.loadConceptSectorData(retryCount: retryCount + 1)
                    }
                }
                return
            }
            let items = diffArr.compactMap { obj -> SectorDataItem? in
                guard let name = obj["f14"] as? String, !name.isEmpty else { return nil }
                let code      = (obj["f12"] as? String) ?? ""
                let changePct = (obj["f3"]  as? Double) ?? 0.0
                let topStock  = (obj["f128"] as? String) ?? ""
                let topChange = (obj["f136"] as? Double) ?? 0.0
                return SectorDataItem(name: name, code: code, changePercent: changePct,
                                      topStock: topStock, topStockChange: topChange,
                                      isUp: changePct >= 0)
            }
            DispatchQueue.main.async {
                self.conceptSectorDataItems = items
                self.populateConceptSectorGrid()
                print("[行情] 概念板块加载成功，共 \(items.count) 条")
            }
        }
    }

    /// A股主力净流入 — 东方财富 ulist f62
    private func loadMainFundFlow() {
        let url = "https://push2delay.eastmoney.com/api/qt/ulist/get"
            + "?fltt=2&invt=2&secids=1.000001,0.399001&fields=f62,f184"
        fetchEastMoneyJSON(url: url) { [weak self] root in
            guard let self = self,
                  let data = root?["data"] as? [String: Any] else { return }
            var diffArr: [[String: Any]] = []
            if let arr = data["diff"] as? [[String: Any]] { diffArr = arr }
            else if let dict = data["diff"] as? [String: Any] {
                diffArr = dict.values.compactMap { $0 as? [String: Any] }
            }
            var totalYuan = 0.0
            for item in diffArr {
                totalYuan += (item["f62"] as? Double) ?? 0
            }
            let yi = totalYuan / 100_000_000.0
            let isPos = totalYuan >= 0
            let sign = isPos ? "" : "-"
            let display = "\(sign)\(String(format: "%.2f", abs(yi)))亿"
            DispatchQueue.main.async {
                self.mainFundFlowLabel?.text = display
                self.mainFundFlowLabel?.textColor = isPos ? self.themeRed : self.stockGreen
                print("[行情] A股主力净流入: \(display)")
            }
        }
    }

    /// 通用 JSON GET（东方财富公开 API，支持 JSONP 格式）
    private func fetchEastMoneyJSON(url: String, completion: @escaping ([String: Any]?) -> Void) {
        guard let reqUrl = URL(string: url) else { completion(nil); return }
        var request = URLRequest(url: reqUrl, timeoutInterval: 15)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent")
        request.setValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[行情] EastMoney 请求失败: \(error.localizedDescription), url=\(url.prefix(80))")
                completion(nil); return
            }
            guard let data = data,
                  var jsonStr = String(data: data, encoding: .utf8) else {
                print("[行情] EastMoney 响应为空")
                completion(nil); return
            }
            // 去掉 JSONP 包装（如 jQuery12345(...)）
            if let lp = jsonStr.firstIndex(of: "("),
               let rp = jsonStr.lastIndex(of: ")") {
                jsonStr = String(jsonStr[jsonStr.index(after: lp)..<rp])
            }
            guard let d = jsonStr.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else {
                completion(nil); return
            }
            completion(obj)
        }.resume()
    }

    /// 从独立接口或 FeatureSwitchManager 加载申购、配售、大宗交易数据
    private func loadSubscriptionData() {
        let mgr = FeatureSwitchManager.shared

        switch selectedSegmentIndex {
        case 1:
            // 新股申购使用独立接口 /api/subscribe/lst
            loadXgsgData()
            return
        case 2:
            // 线下配售使用独立接口 /api/subscribe/xxlst
            loadXxpsData()
            return
        case 3:
            // 场外撮合交易使用独立接口 /api/dzjy/lst
            loadDzjyData()
            return
        default: return
        }
    }

    /// 新股可申购列表 — /api/subscribe/lst
    private func loadXgsgData() {
        SecureNetworkManager.shared.request(
            api: "/api/subscribe/lst",
            method: .get,
            params: ["page": "1", "type": "0"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    print("[行情] 新股申购: 解析失败, raw=\(res.raw.prefix(200))")
                    DispatchQueue.main.async {
                        self.subscriptionList = []
                        self.subsTableView.reloadData()
                        self.subsEmptyLabel.isHidden = true
                    }
                    return
                }
                // 解析 sub_info 结构
                var rows: [[String: Any]] = []
                for item in list {
                    if let subInfo = item["sub_info"] as? [[String: Any]] {
                        rows.append(contentsOf: subInfo)
                    } else {
                        rows.append(item)
                    }
                }
                DispatchQueue.main.async {
                    self.subscriptionList = rows
                    self.subsTableView.reloadData()
                    self.subsEmptyLabel.isHidden = !rows.isEmpty
                    print("[行情] 新股申购加载成功，共 \(rows.count) 条")
                }
            case .failure(let err):
                print("[行情] 新股申购请求失败: \(err.localizedDescription)")
            }
        }
    }

    /// 场外撮合交易列表 — /api/dzjy/lst
    private func loadDzjyData() {
        SecureNetworkManager.shared.request(
            api: "/api/dzjy/lst",
            method: .get,
            params: ["page": "1", "size": "50"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    print("[行情] 场外撮合: 解析失败, raw=\(res.raw.prefix(200))")
                    DispatchQueue.main.async {
                        self.subscriptionList = []
                        self.subsTableView.reloadData()
                        self.subsEmptyLabel.isHidden = false
                    }
                    return
                }
                // 保存可用余额
                if let bal = data["balance"] as? Double {
                    self.dzjyBalance = bal
                } else if let balStr = data["balance"] as? String, let bal = Double(balStr) {
                    self.dzjyBalance = bal
                }
                DispatchQueue.main.async {
                    self.subscriptionList = list
                    self.subsTableView.reloadData()
                    self.subsEmptyLabel.isHidden = !list.isEmpty
                    print("[行情] 场外撮合加载成功，共 \(list.count) 条，余额: \(self.dzjyBalance)")
                }
            case .failure(let err):
                print("[行情] 场外撮合请求失败: \(err.localizedDescription)")
            }
        }
    }

    /// 线下配售可申购列表 — /api/subscribe/xxlst
    private func loadXxpsData() {
        SecureNetworkManager.shared.request(
            api: "/api/subscribe/xxlst",
            method: .get,
            params: ["page": "1", "type": "0"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    print("[行情] 线下配售: 解析失败, raw=\(res.raw.prefix(200))")
                    DispatchQueue.main.async {
                        self.subscriptionList = []
                        self.subsTableView.reloadData()
                        self.subsEmptyLabel.isHidden = true
                    }
                    return
                }
                // 返回格式解析，兼容包含 sub_info 的字典数组和纯字典数组
                var rows: [[String: Any]] = []
                for item in list {
                    if let subInfo = item["sub_info"] as? [[String: Any]] {
                        rows.append(contentsOf: subInfo)
                    } else if let id = item["id"], "\(id)" != "" {
                        rows.append(item)
                    } else {
                        rows.append(item)
                    }
                }
                DispatchQueue.main.async {
                    self.subscriptionList = rows
                    self.subsTableView.reloadData()
                    self.subsEmptyLabel.isHidden = !rows.isEmpty
                    print("[行情] 线下配售加载成功，共 \(rows.count) 条")
                }
            case .failure(let err):
                print("[行情] 线下配售请求失败: \(err.localizedDescription)")
            }
        }
    }

    // ===================================================================
    // MARK: - 场外撮合交易购买弹窗
    // ===================================================================
    private func showDzjyBuySheet(item: [String: Any]) {
        let name    = item["title"] as? String ?? (item["name"] as? String ?? "--")
        let code    = item["code"] as? String ?? "--"
        let allcode = item["allcode"] as? String ?? ""
        let priceStr = "\(item["cai_buy"] ?? "0")"
        let price   = Double(priceStr) ?? 0
        let maxNum  = (item["max_num"] as? Int) ?? Int("\(item["max_num"] ?? "0")") ?? 0

        // 半透明遮罩
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlay.tag = 9999
        view.addSubview(overlay)

        // 弹窗容器
        let sheet = UIView()
        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 12
        sheet.clipsToBounds = true
        sheet.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(sheet)

        // 当前购买手数
        var buyNums = 0

        // ── 名称 + 价格 ──
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .boldSystemFont(ofSize: 17)
        nameLabel.textColor = textPrimary
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(nameLabel)

        let priceLabel = UILabel()
        priceLabel.text = String(format: "%.2f", price)
        priceLabel.font = .boldSystemFont(ofSize: 17)
        priceLabel.textColor = themeRed
        priceLabel.textAlignment = .right
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(priceLabel)

        let codeLabel = UILabel()
        codeLabel.text = code
        codeLabel.font = .systemFont(ofSize: 13)
        codeLabel.textColor = textSec
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(codeLabel)

        // ── 可用余额 + 最大可买 ──
        let balLabel = UILabel()
        balLabel.text = "可用余额"
        balLabel.font = .systemFont(ofSize: 14)
        balLabel.textColor = textPrimary
        balLabel.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(balLabel)

        let balValue = UILabel()
        balValue.text = String(format: "%.2f", dzjyBalance)
        balValue.font = .systemFont(ofSize: 14)
        balValue.textColor = textPrimary
        balValue.textAlignment = .right
        balValue.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(balValue)

        let maxLabel = UILabel()
        maxLabel.text = "最大可买(手)"
        maxLabel.font = .systemFont(ofSize: 14)
        maxLabel.textColor = textPrimary
        maxLabel.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(maxLabel)

        let maxValue = UILabel()
        maxValue.text = "\(maxNum)"
        maxValue.font = .systemFont(ofSize: 14)
        maxValue.textColor = textPrimary
        maxValue.textAlignment = .right
        maxValue.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(maxValue)

        // ── 步进器 ──
        let minusBtn = UIButton(type: .system)
        minusBtn.setTitle("−", for: .normal)
        minusBtn.setTitleColor(textPrimary, for: .normal)
        minusBtn.titleLabel?.font = .systemFont(ofSize: 22, weight: .medium)
        minusBtn.layer.borderWidth = 1
        minusBtn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        minusBtn.layer.cornerRadius = 4
        minusBtn.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(minusBtn)

        let numsLbl = UILabel()
        numsLbl.text = "\(buyNums)"
        numsLbl.textAlignment = .center
        numsLbl.font = .systemFont(ofSize: 16, weight: .medium)
        numsLbl.textColor = textPrimary
        numsLbl.layer.borderWidth = 1
        numsLbl.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        numsLbl.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(numsLbl)

        let plusBtn = UIButton(type: .system)
        plusBtn.setTitle("+", for: .normal)
        plusBtn.setTitleColor(textPrimary, for: .normal)
        plusBtn.titleLabel?.font = .systemFont(ofSize: 22, weight: .medium)
        plusBtn.layer.borderWidth = 1
        plusBtn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        plusBtn.layer.cornerRadius = 4
        plusBtn.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(plusBtn)

        // ── 支付金额 ──
        let payTitle = UILabel()
        payTitle.text = "支付金额"
        payTitle.font = .systemFont(ofSize: 14)
        payTitle.textColor = textPrimary
        payTitle.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(payTitle)

        let payValue = UILabel()
        payValue.text = "0.00"
        payValue.font = .boldSystemFont(ofSize: 14)
        payValue.textColor = themeRed
        payValue.textAlignment = .right
        payValue.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(payValue)

        // ── 底部按钮 ──
        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(textPrimary, for: .normal)
        cancelBtn.titleLabel?.font = .systemFont(ofSize: 16)
        cancelBtn.layer.borderWidth = 1
        cancelBtn.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        cancelBtn.layer.cornerRadius = 6
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(cancelBtn)

        let confirmBtn = UIButton(type: .system)
        confirmBtn.setTitle("确定", for: .normal)
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.titleLabel?.font = .boldSystemFont(ofSize: 16)
        confirmBtn.backgroundColor = themeRed
        confirmBtn.layer.cornerRadius = 6
        confirmBtn.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(confirmBtn)

        // 分隔线
        let sep1 = UIView(); sep1.backgroundColor = UIColor(white: 0.93, alpha: 1)
        sep1.translatesAutoresizingMaskIntoConstraints = false; sheet.addSubview(sep1)

        // ── 约束 ──
        NSLayoutConstraint.activate([
            sheet.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            sheet.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 20),
            sheet.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -20),

            nameLabel.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 20),
            priceLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -20),

            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            codeLabel.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 20),

            balLabel.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 16),
            balLabel.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 20),
            balValue.centerYAnchor.constraint(equalTo: balLabel.centerYAnchor),
            balValue.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -20),

            maxLabel.topAnchor.constraint(equalTo: balLabel.bottomAnchor, constant: 8),
            maxLabel.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 20),
            maxValue.centerYAnchor.constraint(equalTo: maxLabel.centerYAnchor),
            maxValue.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -20),

            // 步进器
            minusBtn.topAnchor.constraint(equalTo: maxLabel.bottomAnchor, constant: 16),
            minusBtn.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 20),
            minusBtn.widthAnchor.constraint(equalToConstant: 44),
            minusBtn.heightAnchor.constraint(equalToConstant: 40),
            numsLbl.topAnchor.constraint(equalTo: minusBtn.topAnchor),
            numsLbl.leadingAnchor.constraint(equalTo: minusBtn.trailingAnchor),
            numsLbl.trailingAnchor.constraint(equalTo: plusBtn.leadingAnchor),
            numsLbl.heightAnchor.constraint(equalToConstant: 40),
            plusBtn.topAnchor.constraint(equalTo: minusBtn.topAnchor),
            plusBtn.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -20),
            plusBtn.widthAnchor.constraint(equalToConstant: 44),
            plusBtn.heightAnchor.constraint(equalToConstant: 40),

            // 支付金额
            payTitle.topAnchor.constraint(equalTo: minusBtn.bottomAnchor, constant: 12),
            payTitle.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 20),
            payValue.centerYAnchor.constraint(equalTo: payTitle.centerYAnchor),
            payValue.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -20),

            // 分隔线
            sep1.topAnchor.constraint(equalTo: payTitle.bottomAnchor, constant: 12),
            sep1.leadingAnchor.constraint(equalTo: sheet.leadingAnchor),
            sep1.trailingAnchor.constraint(equalTo: sheet.trailingAnchor),
            sep1.heightAnchor.constraint(equalToConstant: 0.5),

            // 底部按钮
            cancelBtn.topAnchor.constraint(equalTo: sep1.bottomAnchor, constant: 12),
            cancelBtn.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 20),
            cancelBtn.widthAnchor.constraint(equalTo: sheet.widthAnchor, multiplier: 0.38),
            cancelBtn.heightAnchor.constraint(equalToConstant: 44),
            cancelBtn.bottomAnchor.constraint(equalTo: sheet.bottomAnchor, constant: -16),

            confirmBtn.topAnchor.constraint(equalTo: sep1.bottomAnchor, constant: 12),
            confirmBtn.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -20),
            confirmBtn.widthAnchor.constraint(equalTo: sheet.widthAnchor, multiplier: 0.38),
            confirmBtn.heightAnchor.constraint(equalToConstant: 44),
        ])

        // ── 事件 ──
        let updateAmount = {
            let total = price * Double(buyNums) * 100
            payValue.text = String(format: "%.2f", total)
        }

        minusBtn.addAction(UIAction { _ in
            guard buyNums > 0 else { return }
            buyNums -= 1
            numsLbl.text = "\(buyNums)"
            updateAmount()
        }, for: .touchUpInside)

        plusBtn.addAction(UIAction { _ in
            guard buyNums < maxNum else { return }
            buyNums += 1
            numsLbl.text = "\(buyNums)"
            updateAmount()
        }, for: .touchUpInside)

        cancelBtn.addAction(UIAction { _ in
            overlay.removeFromSuperview()
        }, for: .touchUpInside)

        // 点遮罩关闭
        let tapDismiss = UITapGestureRecognizer(target: self, action: nil)
        tapDismiss.cancelsTouchesInView = false
        overlay.addGestureRecognizer(tapDismiss)

        confirmBtn.addAction(UIAction { [weak self] _ in
            guard buyNums > 0 else {
                Toast.show("请选择购买手数")
                return
            }
            overlay.removeFromSuperview()
            self?.performDzjyBuy(allcode: allcode, canBuy: buyNums)
        }, for: .touchUpInside)
    }

    /// 调用大宗交易买入接口
    private func performDzjyBuy(allcode: String, canBuy: Int) {
        SecureNetworkManager.shared.request(
            api: "/api/dzjy/addStrategy_zfa",
            method: .post,
            params: [
                "allcode": allcode,
                "canBuy": canBuy,
                "miyao": ""
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let res):
                    let dict = res.decrypted
                    let code = dict?["code"] as? Int ?? 0
                    let msg  = dict?["msg"] as? String ?? "购买成功"
                    Toast.show(msg)
                    if code == 1 {
                        // 刷新列表
                        self?.loadDzjyData()
                    }
                case .failure(let err):
                    Toast.show("购买失败: \(err.localizedDescription)")
                }
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

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let rankCell = cell as? RankingStockCell {
            rankCell.syncOffset(rankingScrollOffset)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == rankingTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RankingCell", for: indexPath) as! RankingStockCell
            if indexPath.row < rankingStocks.count {
                cell.configure(stock: rankingStocks[indexPath.row])
                cell.onScroll = { [weak self] offset in self?.syncAllRankingRows(to: offset) }
                cell.onTap = { [weak self] in
                    guard let self = self else { return }
                    let s = self.rankingStocks[indexPath.row]
                    let vc = IndexDetailViewController()
                    vc.indexName          = s.name
                    vc.indexCode          = s.code
                    vc.indexAllcode       = s.symbol
                    vc.indexPrice         = s.price
                    vc.indexChange        = s.change
                    vc.indexChangePercent = s.changePercent
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            return cell
        }

        if selectedSegmentIndex == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BlockTradeCell", for: indexPath) as! BlockTradeCell
            if indexPath.row < subscriptionList.count {
                let item = subscriptionList[indexPath.row]
                let name = item["title"] as? String ?? "--"
                let code = item["code"] as? String ?? "--"
                
                let typeVal: String
                if let t = item["type"] as? Int { typeVal = "\(t)" }
                else { typeVal = "\(item["type"] ?? "")" }
                let mkt: String = {
                    switch typeVal { case "1": return "沪"; case "2": return "深"; case "3": return "创"; case "4": return "北"; case "5": return "科"; case "6": return "基"; default: return "沪" }
                }()
                
                let currentPrice = "\(item["current_price"] ?? item["cai_price"] ?? "--")"
                let price = "\(item["cai_buy"] ?? "--")"
                let rate = "\(item["rate"] ?? "--")"
                
                cell.configure(name: name, code: code, market: mkt, currentPrice: currentPrice, price: price, rate: rate)
                cell.onActionTap = { [weak self] in
                    guard let self = self else { return }
                    self.showDzjyBuySheet(item: item)
                }
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "IpoPlacementCell", for: indexPath) as! IpoPlacementCell
        if indexPath.row < subscriptionList.count {
            let item = subscriptionList[indexPath.row]
            
            var name = "--"
            for key in ["name", "title", "stock_name"] {
                if let val = item[key] as? String, !val.isEmpty {
                    name = val
                    break
                }
            }
            
            var code = "--"
            for key in ["sgcode", "code", "symbol", "stock_code", "allcode"] {
                if let valAny = item[key], !("\(valAny)".isEmpty) {
                    code = "\(valAny)"
                    break
                }
            }
            
            let sgTypeStr: String
            if let typeInt = item["sg_type"] as? Int {
                sgTypeStr = "\(typeInt)"
            } else if let typeStr = item["sg_type"] as? String {
                sgTypeStr = typeStr
            } else if let typeAny = item["type"], let str = typeAny as? String {
                sgTypeStr = str
            } else {
                sgTypeStr = ""
            }
            let market: String = {
                switch sgTypeStr { case "1": return "沪"; case "2": return "深"; case "3": return "创"; case "4": return "北"; case "5": return "科"; default: return "沪" }
            }()

            if selectedSegmentIndex == 1 {
                // 新股申购
                var priceDouble: Double = 0.0
                if let fxPriceStr = item["fx_price"] as? String, let p = Double(fxPriceStr) { priceDouble = p }
                else if let fxPriceNum = item["fx_price"] as? Double { priceDouble = fxPriceNum }
                else if let issuePriceStr = item["issue_price"] as? String, let p = Double(issuePriceStr) { priceDouble = p }
                else if let issuePriceNum = item["issue_price"] as? Double { priceDouble = issuePriceNum }
                
                let price = String(format: "%.2f", priceDouble)
                let zqRate = "\(item["zq_rate"] ?? "0.00")"
                
                let fxNumRaw = "\(item["fx_num"] ?? "--")"
                let fxNum: String
                if let v = Double(fxNumRaw) {
                    if v >= 100000000 { fxNum = String(format: "%.1f亿股", v / 100000000.0) }
                    else if v >= 10000 { fxNum = String(format: "%.1f万股", v / 10000.0) }
                    else { fxNum = "\(v)股" }
                } else {
                    fxNum = fxNumRaw
                }
                
                cell.configure(name: name, code: code, market: market, price: price, zqRate: zqRate, fxNum: fxNum)
                cell.onDetailTap = { [weak self] in
                    guard let self = self else { return }
                    let vc = NewStockDetailViewController()
                    vc.stockData = self.createNewStockSubscription(from: item)
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                
            } else if selectedSegmentIndex == 2 {
                // 战略配售
                var priceDouble: Double = 0.0
                if let fxPriceStr = item["fx_price"] as? String, let p = Double(fxPriceStr) { priceDouble = p }
                else if let fxPriceNum = item["fx_price"] as? Double { priceDouble = fxPriceNum }
                else if let issuePriceStr = item["issue_price"] as? String, let p = Double(issuePriceStr) { priceDouble = p }
                else if let issuePriceNum = item["issue_price"] as? Double { priceDouble = issuePriceNum }
                
                let price = String(format: "%.2f", priceDouble)
                let zqRateRaw = "\(item["zq_rate"] ?? "0")"
                let zqRate = String(format: "%.2f%%", Double(zqRateRaw) ?? 0)
                
                let fxNumStr = "\(item["fx_num"] ?? "0")"
                let fxNumFormatted: String
                if let fxNum = Double(fxNumStr), fxNum > 0 {
                    fxNumFormatted = String(format: "%.2f万股", fxNum / 10000.0)
                } else {
                    fxNumFormatted = "--"
                }
                
                cell.configure(name: name, code: code, market: market, price: price, zqRate: zqRate, fxNum: fxNumFormatted)
                cell.onDetailTap = { [weak self] in
                    guard let self = self else { return }
                    let vc = XxpsDetailViewController()
                    vc.stockId = "\(item["id"] ?? "")"
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        return cell
    }

    private func marketLabel(_ sgType: String) -> String {
        switch sgType { case "1": return "沪市"; case "2": return "深市"; case "3": return "创业板"; case "4": return "北交"; case "5": return "科创"; default: return "" }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == subsTableView { return UITableView.automaticDimension }
        if tableView == rankingTableView { return 60 }
        return 56
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == subsTableView {
            return nil
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == subsTableView { return 0.01 }
        return 0
    }

    /// 列标题横向滚 → 同步所有行；整体 ScrollView 滚 → 下拉加载更多
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === rankingColumnHeaderScroll {
            syncAllRankingRows(to: scrollView.contentOffset.x)
        } else if scrollView === hangqingScrollView {
            // 监听行情整个 ScrollView 是否滚到底部，触发加载更多排行榜
            let offsetY = scrollView.contentOffset.y
            let contentHeight = scrollView.contentSize.height
            let boundsHeight = scrollView.bounds.size.height
            if offsetY > 0 && offsetY + boundsHeight >= contentHeight - 300 {
                // 距离底部 300px 时加载更多（与 Android 一致）
                if !rankingIsLoading && rankingHasMore && selectedSegmentIndex == 0 {
                    loadRankingData(isLoadMore: true)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 排行榜跳转由 RankingStockCell.onTap 手势处理，此处不重复
        if tableView == subsTableView, indexPath.row < subscriptionList.count {
            let item = subscriptionList[indexPath.row]
            // 线下配售跳 XxpsDetailViewController，其他跳 NewStockDetailViewController
            if selectedSegmentIndex == 2 {
                let vc = XxpsDetailViewController()
                vc.stockId = "\(item["id"] ?? "")"
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            } else {
                let vc = NewStockDetailViewController()
                vc.stockData = createNewStockSubscription(from: item)
                vc.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    // MARK: - 辅助：将 dict 转换为 NewStockSubscription 进行详情传递
    private func createNewStockSubscription(from item: [String: Any]) -> NewStockSubscription {
        let idStr = "\(item["id"] ?? "")"
        var name = "--"
        for key in ["name", "title", "stock_name"] {
            if let val = item[key] as? String, !val.isEmpty { name = val; break }
        }
        var sgCode = "--"
        for key in ["sgcode", "code", "symbol", "stock_code", "allcode"] {
            if let valAny = item[key], !("\(valAny)".isEmpty) { sgCode = "\(valAny)"; break }
        }
        
        let stockCode = item["code"] as? String ?? ""
        
        var priceDouble: Double = 0.0
        if let fxPriceStr = item["fx_price"] as? String, let p = Double(fxPriceStr) { priceDouble = p }
        else if let fxPriceNum = item["fx_price"] as? Double { priceDouble = fxPriceNum }
        else if let issuePriceStr = item["issue_price"] as? String, let p = Double(issuePriceStr) { priceDouble = p }
        else if let issuePriceNum = item["issue_price"] as? Double { priceDouble = issuePriceNum }
        let priceVal = String(format: "%.2f", priceDouble)
        
        let zqRateVal: Double
        if let d = item["zq_rate"] as? Double { zqRateVal = d }
        else if let s = item["zq_rate"] as? String, let d = Double(s) { zqRateVal = d }
        else { zqRateVal = 0 }
        let rateVal = String(format: "%.2f%%", zqRateVal)
        
        let fxNum = item["fx_num"]
        var fxNumStr = "0.00万股"
        if let fxNumInt = fxNum as? Int {
            fxNumStr = String(format: "%.2f万股", Double(fxNumInt) / 10000.0)
        } else if let fxNumStrVal = fxNum as? String, let doubleVal = Double(fxNumStrVal) {
            fxNumStr = String(format: "%.2f万股", doubleVal / 10000.0)
        } else if fxNum != nil {
            fxNumStr = "\(fxNum!)万股"
        }
        
        let wsFxNum = item["wsfx_num"]
        var wsFxNumStr = "0.00万股"
        if let wsFxNumInt = wsFxNum as? Int {
            wsFxNumStr = String(format: "%.2f万股", Double(wsFxNumInt) / 10000.0)
        } else if let wsFxNumStrVal = wsFxNum as? String, let doubleVal = Double(wsFxNumStrVal) {
            wsFxNumStr = String(format: "%.2f万股", doubleVal / 10000.0)
        } else if wsFxNum != nil {
            wsFxNumStr = "\(wsFxNum!)万股"
        }
        
        let peRatioVal: Double
        if let d = item["fx_rate"] as? Double { peRatioVal = d }
        else if let s = item["fx_rate"] as? String, let d = Double(s) { peRatioVal = d }
        else { peRatioVal = 0 }
        let peRatio = peRatioVal > 0 ? String(format: "%.2f%%", peRatioVal) : "--"
        
        let sgTypeStr: String
        if let typeInt = item["sg_type"] as? Int { sgTypeStr = "\(typeInt)" }
        else if let typeStr = item["sg_type"] as? String { sgTypeStr = typeStr }
        else if let typeStr = item["type"] as? String { sgTypeStr = typeStr }
        else { sgTypeStr = "" }
        
        let market: String = {
            switch sgTypeStr { case "1": return "沪"; case "2": return "深"; case "3": return "创"; case "4": return "北"; case "5": return "科"; default: return "沪" }
        }()
        
        let industryStr = item["industry"] as? String ?? ""
        let boardStr = item["board"] as? String ?? ""
        
        return NewStockSubscription(
            id: idStr,
            stockName: name,
            stockCode: stockCode,
            sgCode: sgCode,
            exchange: market,
            issuePrice: priceVal,
            winningRate: rateVal,
            totalIssued: fxNumStr,
            peRatio: peRatio,
            wsfxNum: wsFxNumStr,
            type: sgTypeStr,
            industry: industryStr,
            board: boardStr
        )
    }
}

// =====================================================================
// MARK: - RankingStockCell  （多列横向滚动，对应 Android StockAdapter）
// =====================================================================
class RankingStockCell: UITableViewCell {

    // MARK: - 列宽定义（对齐 Android columnWidths dp≈pt）
    static let leftWidth: CGFloat    = 120
    static let columnWidths: [CGFloat] = [80, 70, 100, 70, 80, 80, 80]
    static let columnTitles            = ["现价", "涨跌幅", "成交额", "换手率", "昨收", "今开", "最高"]

    // MARK: - 左侧固定视图
    private let nameLabel   = UILabel()
    private let codeLabel   = UILabel()
    private let marketBadge = UILabel()

    // MARK: - 右侧横向可滚动视图
    let dataScrollView = UIScrollView()
    private var dataLabels: [UILabel] = []
    private let sep = UIView()

    // MARK: - 滚动同步
    var onScroll: ((CGFloat) -> Void)?
    private var isSyncing = false

    // MARK: - 颜色
    private let textP  = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1)
    private let textS  = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1)
    private let red    = UIColor(red: 230/255, green: 0,     blue: 18/255,  alpha: 1)
    private let green  = UIColor(red: 0.13,   green: 0.73,   blue: 0.33,   alpha: 1)

    // MARK: - 点击回调
    var onTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        setupViews()
        
        // 整行点击手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        tap.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tap)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    @objc private func cellTapped() {
        onTap?()
    }

    private func setupViews() {
        // ── 左侧固定面板 ──
        let leftPanel = UIView()
        contentView.addSubview(leftPanel)
        leftPanel.translatesAutoresizingMaskIntoConstraints = false
        for v: UIView in [nameLabel, codeLabel, marketBadge] {
            leftPanel.addSubview(v); v.translatesAutoresizingMaskIntoConstraints = false
        }
        nameLabel.font = .boldSystemFont(ofSize: 15); nameLabel.textColor = textP
        nameLabel.numberOfLines = 1; nameLabel.lineBreakMode = .byTruncatingMiddle
        codeLabel.font = .systemFont(ofSize: 12); codeLabel.textColor = textS
        marketBadge.font = .boldSystemFont(ofSize: 10); marketBadge.textColor = .white
        marketBadge.textAlignment = .center; marketBadge.layer.cornerRadius = 2; marketBadge.clipsToBounds = true
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leftPanel.leadingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: leftPanel.topAnchor, constant: 11),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: leftPanel.trailingAnchor, constant: -4),
            codeLabel.leadingAnchor.constraint(equalTo: leftPanel.leadingAnchor, constant: 12),
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            marketBadge.leadingAnchor.constraint(equalTo: codeLabel.trailingAnchor, constant: 4),
            marketBadge.centerYAnchor.constraint(equalTo: codeLabel.centerYAnchor),
            marketBadge.widthAnchor.constraint(equalToConstant: 16),
            marketBadge.heightAnchor.constraint(equalToConstant: 14),
        ])

        // ── 右侧横向滚动面板 ──
        dataScrollView.showsHorizontalScrollIndicator = false
        dataScrollView.showsVerticalScrollIndicator   = false
        dataScrollView.bounces = false
        dataScrollView.delegate = self
        contentView.addSubview(dataScrollView)
        dataScrollView.translatesAutoresizingMaskIntoConstraints = false

        let scrollContent = UIView()
        dataScrollView.addSubview(scrollContent)
        scrollContent.translatesAutoresizingMaskIntoConstraints = false
        let totalW = RankingStockCell.columnWidths.reduce(0, +)
        NSLayoutConstraint.activate([
            scrollContent.topAnchor.constraint(equalTo: dataScrollView.topAnchor),
            scrollContent.leadingAnchor.constraint(equalTo: dataScrollView.leadingAnchor),
            scrollContent.trailingAnchor.constraint(equalTo: dataScrollView.trailingAnchor),
            scrollContent.bottomAnchor.constraint(equalTo: dataScrollView.bottomAnchor),
            scrollContent.heightAnchor.constraint(equalTo: dataScrollView.heightAnchor),
            scrollContent.widthAnchor.constraint(equalToConstant: totalW),
        ])

        // 8 个数据列 label（用 leading + width 约束定位，简洁高效）
        var leading: CGFloat = 0
        for w in RankingStockCell.columnWidths {
            let lbl = UILabel()
            lbl.font = .systemFont(ofSize: 14, weight: .medium)
            lbl.textAlignment = .center
            lbl.adjustsFontSizeToFitWidth = true
            lbl.minimumScaleFactor = 0.8
            scrollContent.addSubview(lbl)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                lbl.topAnchor.constraint(equalTo: scrollContent.topAnchor),
                lbl.bottomAnchor.constraint(equalTo: scrollContent.bottomAnchor),
                lbl.leadingAnchor.constraint(equalTo: scrollContent.leadingAnchor, constant: leading),
                lbl.widthAnchor.constraint(equalToConstant: w),
            ])
            dataLabels.append(lbl)
            leading += w
        }

        // 分隔线
        sep.backgroundColor = UIColor(white: 0.93, alpha: 1)
        contentView.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false

        // ── 外部约束 ──
        NSLayoutConstraint.activate([
            leftPanel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            leftPanel.topAnchor.constraint(equalTo: contentView.topAnchor),
            leftPanel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftPanel.widthAnchor.constraint(equalToConstant: RankingStockCell.leftWidth),

            dataScrollView.leadingAnchor.constraint(equalTo: leftPanel.trailingAnchor),
            dataScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            dataScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dataScrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
        ])
    }

    // MARK: - 公开 API

    /// 由 VC 调用，同步横向偏移（不触发回调，避免循环）
    func syncOffset(_ x: CGFloat) {
        guard abs(dataScrollView.contentOffset.x - x) > 0.5 else { return }
        isSyncing = true
        dataScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
        isSyncing = false
    }

    func configure(stock: MarketViewController.StockRankItem) {
        nameLabel.text = stock.name
        codeLabel.text = stock.code

        let market: String = {
            let s = stock.symbol.lowercased()
            if s.hasPrefix("sh") { return "沪" }
            if s.hasPrefix("sz") { return "深" }
            if s.hasPrefix("bj") { return "北" }
            return ""
        }()
        marketBadge.text = market
        let badgeColors: [String: UIColor] = [
            "沪": UIColor(red: 1.0, green: 0.6,  blue: 0.0,  alpha: 1),
            "深": UIColor(red: 0.26, green: 0.65, blue: 0.96, alpha: 1),
            "北": UIColor(red: 0.26, green: 0.40, blue: 0.90, alpha: 1),
        ]
        marketBadge.backgroundColor = badgeColors[market] ?? .lightGray

        let cv    = Double(stock.change) ?? 0
        let isRise = cv >= 0
        let color  = isRise ? red : green
        let sign   = (isRise && cv > 0) ? "+" : ""
        let pv     = Double(stock.changePercent) ?? 0
        let psign  = (isRise && pv > 0) ? "+" : ""

        // 现价, 涨跌幅, 成交额, 换手率, 昨收, 今开, 最高
        let fPrice = String(format: "%.2f", Double(stock.price) ?? 0.0)
        let fChangePercent = String(format: "%.2f", pv)

        let vals: [String] = [
            fPrice,
            "\(psign)\(fChangePercent)%",
            stock.volume,
            stock.turnover,
            stock.prevClose,
            stock.open,
            stock.high,
        ]
        for (i, lbl) in dataLabels.enumerated() {
            lbl.text = vals[i]
            lbl.textColor = i < 2 ? color : textP
            lbl.font = i == 2
                ? .boldSystemFont(ofSize: 13)
                : .systemFont(ofSize: 14, weight: .medium)
        }
    }
}

extension RankingStockCell: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isSyncing else { return }
        onScroll?(scrollView.contentOffset.x)
    }
}

// =====================================================================
// MARK: - Market Cell Layouts (Ipo / Dzjy)
// =====================================================================

class IpoPlacementCell: UITableViewCell {
    let containerView = UIView()
    let marketBadge = UILabel()
    let nameLabel = UILabel()
    let detailLabel = UILabel()
    let codeLabel = UILabel()
    let priceValLabel = UILabel()
    let priceSubLabel = UILabel()
    let zqValLabel = UILabel()
    let zqSubLabel = UILabel()
    let fxValLabel = UILabel()
    let fxSubLabel = UILabel()
    
    var onDetailTap: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
        
        containerView.backgroundColor = .white
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.alignment = .center
        row1.spacing = 8
        row1.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(row1)
        
        marketBadge.font = .systemFont(ofSize: 11)
        marketBadge.textColor = .white
        marketBadge.textAlignment = .center
        marketBadge.layer.cornerRadius = 2
        marketBadge.clipsToBounds = true
        marketBadge.widthAnchor.constraint(equalToConstant: 16).isActive = true
        marketBadge.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        nameLabel.font = .boldSystemFont(ofSize: 16)
        nameLabel.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1)
        
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = UIColor(red: 0.9, green: 0.3, blue: 0.35, alpha: 1)
        detailLabel.text = "详情+"
        detailLabel.isUserInteractionEnabled = true
        detailLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(detailTapped)))
        
        row1.addArrangedSubview(marketBadge)
        row1.addArrangedSubview(nameLabel)
        let spacerRow1 = UIView()
        row1.addArrangedSubview(spacerRow1)
        row1.addArrangedSubview(detailLabel)
        
        codeLabel.font = .systemFont(ofSize: 12)
        codeLabel.textColor = .gray
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(codeLabel)
        
        let row3 = UIStackView()
        row3.axis = .horizontal
        row3.distribution = .fillEqually
        row3.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(row3)
        
        func createBlock(_ valLbl: UILabel, _ subLbl: UILabel, text: String) -> UIStackView {
            valLbl.font = .boldSystemFont(ofSize: 15)
            valLbl.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1)
            subLbl.font = .systemFont(ofSize: 11)
            subLbl.textColor = .gray
            subLbl.text = text
            let sv = UIStackView(arrangedSubviews: [valLbl, subLbl])
            sv.axis = .vertical
            sv.alignment = .center
            sv.spacing = 4
            return sv
        }
        
        let block1 = createBlock(priceValLabel, priceSubLabel, text: "发行价格")
        let block2 = createBlock(zqValLabel, zqSubLabel, text: "中签率")
        let block3 = createBlock(fxValLabel, fxSubLabel, text: "发行总数")
        
        row3.addArrangedSubview(block1)
        row3.addArrangedSubview(block2)
        row3.addArrangedSubview(block3)
        
        NSLayoutConstraint.activate([
            row1.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            row1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            row1.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            codeLabel.topAnchor.constraint(equalTo: row1.bottomAnchor, constant: 4),
            codeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            
            row3.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 12),
            row3.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            row3.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            row3.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    
    @objc func detailTapped() { onDetailTap?() }
    
    func configure(name: String, code: String, market: String, price: String, zqRate: String, fxNum: String) {
        nameLabel.text = name
        codeLabel.text = code
        marketBadge.text = market.isEmpty ? "—" : String(market.prefix(1))
        
        let blue = UIColor(red: 0x3b/255.0, green: 0x82/255.0, blue: 0xf6/255.0, alpha: 1)
        let redColor = UIColor(red: 0xef/255.0, green: 0x44/255.0, blue: 0x44/255.0, alpha: 1)
        let greenColor = UIColor(red: 0x10/255.0, green: 0xb9/255.0, blue: 0x81/255.0, alpha: 1)
        let orangeColor = UIColor(red: 0xf9/255.0, green: 0x73/255.0, blue: 0x16/255.0, alpha: 1)
        let grayColor = UIColor(red: 0x6b/255.0, green: 0x72/255.0, blue: 0x80/255.0, alpha: 1)
        
        var badgeColor = grayColor
        let m = market
        if m == "京" || m == "北交" || m == "深" { badgeColor = blue }
        else if m == "科" || m == "科创" { badgeColor = orangeColor }
        else if m == "沪" { badgeColor = redColor }
        else if m == "创" { badgeColor = greenColor }
        
        marketBadge.isHidden = market.isEmpty
        marketBadge.backgroundColor = badgeColor
        priceValLabel.text = price.contains("¥") ? price : "¥\(price)"
        zqValLabel.text = zqRate.hasSuffix("%") ? zqRate : "\(zqRate)%"
        fxValLabel.text = fxNum
    }
}

class BlockTradeCell: UITableViewCell {
    let containerView = UIView()
    let marketBadge = UILabel()
    let nameLabel = UILabel()
    let codeLabel = UILabel()
    let currentPriceLabel = UILabel()
    let priceLabel = UILabel()
    let rateLabel = UILabel()
    let actionBtn = UIButton()
    
    var onActionTap: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
        
        containerView.backgroundColor = .white
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stack)
        
        let nameCol = UIStackView()
        nameCol.axis = .vertical
        nameCol.spacing = 2
        
        let nameRow = UIStackView()
        nameRow.axis = .horizontal
        nameRow.spacing = 4
        nameRow.alignment = .center
        
        marketBadge.font = .systemFont(ofSize: 10)
        marketBadge.textColor = .white
        marketBadge.textAlignment = .center
        marketBadge.layer.cornerRadius = 2
        marketBadge.clipsToBounds = true
        marketBadge.widthAnchor.constraint(equalToConstant: 14).isActive = true
        marketBadge.heightAnchor.constraint(equalToConstant: 14).isActive = true
        
        nameLabel.font = .boldSystemFont(ofSize: 14)
        nameLabel.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        nameRow.addArrangedSubview(marketBadge)
        nameRow.addArrangedSubview(nameLabel)
        
        codeLabel.font = .systemFont(ofSize: 12)
        codeLabel.textColor = .gray
        
        nameCol.addArrangedSubview(nameRow)
        nameCol.addArrangedSubview(codeLabel)
        
        currentPriceLabel.font = .systemFont(ofSize: 13)
        currentPriceLabel.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1)
        currentPriceLabel.textAlignment = .center
        
        priceLabel.font = .boldSystemFont(ofSize: 14)
        priceLabel.textColor = UIColor(red: 0.9, green: 0.3, blue: 0.35, alpha: 1)
        priceLabel.textAlignment = .center
        
        rateLabel.font = .systemFont(ofSize: 13)
        rateLabel.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1)
        rateLabel.textAlignment = .center
        
        actionBtn.setTitle("买入", for: .normal)
        actionBtn.titleLabel?.font = .systemFont(ofSize: 12)
        actionBtn.backgroundColor = UIColor(red: 0.9, green: 0.3, blue: 0.35, alpha: 1)
        actionBtn.layer.cornerRadius = 4
        actionBtn.clipsToBounds = true
        actionBtn.heightAnchor.constraint(equalToConstant: 24).isActive = true
        actionBtn.addTarget(self, action: #selector(btnTapped), for: .touchUpInside)
        
        stack.addArrangedSubview(nameCol)
        stack.addArrangedSubview(currentPriceLabel)
        stack.addArrangedSubview(priceLabel)
        stack.addArrangedSubview(rateLabel)
        stack.addArrangedSubview(actionBtn)
        
        nameCol.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 1.2 / 5.0).isActive = true
        currentPriceLabel.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 1.0 / 5.0).isActive = true
        priceLabel.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 1.0 / 5.0).isActive = true
        rateLabel.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 1.0 / 5.0).isActive = true
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    
    @objc func btnTapped() { onActionTap?() }
    
    func configure(name: String, code: String, market: String, currentPrice: String, price: String, rate: String) {
        nameLabel.text = name
        codeLabel.text = code
        marketBadge.text = market.isEmpty ? "—" : String(market.prefix(1))
        
        let blue = UIColor(red: 0x3b/255.0, green: 0x82/255.0, blue: 0xf6/255.0, alpha: 1)
        let redColor = UIColor(red: 0xef/255.0, green: 0x44/255.0, blue: 0x44/255.0, alpha: 1)
        let greenColor = UIColor(red: 0x10/255.0, green: 0xb9/255.0, blue: 0x81/255.0, alpha: 1)
        let orangeColor = UIColor(red: 0xf9/255.0, green: 0x73/255.0, blue: 0x16/255.0, alpha: 1)
        let grayColor = UIColor(red: 0x6b/255.0, green: 0x72/255.0, blue: 0x80/255.0, alpha: 1)
        
        var badgeColor = grayColor
        let m = market
        if m == "京" || m == "北交" || m == "深" { badgeColor = blue }
        else if m == "科" || m == "科创" { badgeColor = orangeColor }
        else if m == "沪" { badgeColor = redColor }
        else if m == "创" { badgeColor = greenColor }
        
        marketBadge.isHidden = market.isEmpty
        marketBadge.backgroundColor = badgeColor
        
        currentPriceLabel.text = currentPrice
        priceLabel.text = price
        let rateDouble = Double(rate) ?? 0.0
        let isInt = floor(rateDouble) == rateDouble
        rateLabel.text = isInt ? "\(Int(rateDouble))" : String(format: "%.2f", rateDouble)
    }
}
