//
//  IndexDetailViewController.swift
//  zhengqaun
//
//  指数详情页：价格概览 + 指标网格 + 分时/K线图 + 新闻列表 + 底部操作栏
//

import UIKit
import DGCharts

class IndexDetailViewController: ZQViewController {

    // MARK: - 外部传入
    var indexName: String = ""       // 北证50
    var indexCode: String = ""       // 899050
    var indexAllcode: String = ""    // bj899050
    var indexPrice: String = ""      // 1536.00
    var indexChange: String = ""     // -26.45
    var indexChangePercent: String = "" // -1.69
    /// 是否为指数（指数置灰交易按钮，不可交易）。由调用方赋值：指数卡片传 true，股票排行榜传 false（默认）
    var isIndex: Bool = false

    // MARK: - 颜色
    private let bgColor     = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1)
    private let themeRed    = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1)
    private let stockGreen  = UIColor(red: 0.13, green: 0.73, blue: 0.33, alpha: 1)
    private let textPrimary = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1)
    private let textSec     = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1)
    private let textGray    = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)

    // MARK: - 指标数据
    private var todayOpen: String = "--"
    private var lowest: String = "--"
    private var yesterdayClose: String = "--"
    private var volume: String = "--"
    private var limitUp: String = "--"
    private var turnover: String = "--"
    private var limitDown: String = "--"
    private var amplitude: String = "--"
    private var highest: String = "--"

    // MARK: - 自选状态
    private var isFavorite: Bool = false

    // MARK: - 新闻
    private let newsTabs = ["动态", "7X24", "盘面", "投顾", "要闻", "更多"]
    private var selectedNewsTab = 0
    private var newsTabButtons: [UIButton] = []
    private var newsTabIndicator: UIView!
    private var newsList: [[String: Any]] = []

    // MARK: - 图表
    private let chartTabs = ["分时", "五分", "日K", "周K月K"]
    private var selectedChartTab = 0
    private var chartTabButtons: [UIButton] = []

    // MARK: - 指标 label 引用（刷新用）
    private var metricValueLabels: [UILabel] = []

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let customNavBar = UIView()
    private let bottomBar = UIView()
    private let favoriteBtn = UIButton(type: .system)
    private let tradeBtn = UIButton(type: .system)

    // 价格区
    private let priceLabel = UILabel()
    private let changeAmtLabel = UILabel()
    private let changePctLabel = UILabel()

    // 图表
    private var chartContainer: UIView!
    private var lineChartView: LineChartView!
    private var candleChartView: CombinedChartView!
    private var volumeBarView: UIView!
    /// 图表数据缓存（key 与 Android 一致："time" / "k_5" / "k_101" / "k_102"）
    private var chartDataCache: [String: Any] = [:]

    // 新闻 tableView
    private let newsTableView = UITableView(frame: .zero, style: .plain)
    private var newsTableHeightCons: NSLayoutConstraint?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        gk_navigationBar.isHidden = true
        view.backgroundColor = .white
        setupNavBar()
        setupBottomBar()
        applyTradeButtonState()
        setupScrollContent()
        applyInitialData()
        loadIndexDetail()
        loadFavoriteStatus()
        loadNews()
    }

    // ===================================================================
    // MARK: - 导航栏
    // ===================================================================
    private func setupNavBar() {
        view.addSubview(customNavBar)
        customNavBar.backgroundColor = .white
        customNavBar.translatesAutoresizingMaskIntoConstraints = false

        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backBtn.tintColor = .black
        backBtn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        customNavBar.addSubview(backBtn)
        backBtn.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = indexName
        titleLbl.font = .boldSystemFont(ofSize: 17)
        titleLbl.textColor = .black
        customNavBar.addSubview(titleLbl)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let searchBtn = UIButton(type: .system)
        searchBtn.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchBtn.tintColor = .black
        searchBtn.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        customNavBar.addSubview(searchBtn)
        searchBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            customNavBar.topAnchor.constraint(equalTo: view.topAnchor),
            customNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavBar.heightAnchor.constraint(equalToConstant: Constants.Navigation.totalNavigationHeight),

            backBtn.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor, constant: 16),
            backBtn.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor, constant: Constants.Navigation.statusBarHeight / 2),
            backBtn.widthAnchor.constraint(equalToConstant: 44),
            backBtn.heightAnchor.constraint(equalToConstant: 44),

            titleLbl.centerXAnchor.constraint(equalTo: customNavBar.centerXAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor, constant: Constants.Navigation.statusBarHeight / 2),

            searchBtn.trailingAnchor.constraint(equalTo: customNavBar.trailingAnchor, constant: -16),
            searchBtn.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor, constant: Constants.Navigation.statusBarHeight / 2),
            searchBtn.widthAnchor.constraint(equalToConstant: 44),
            searchBtn.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    // ===================================================================
    // MARK: - 底部操作栏
    // ===================================================================
    private func setupBottomBar() {
        view.addSubview(bottomBar)
        bottomBar.backgroundColor = .white
        bottomBar.layer.shadowColor = UIColor.black.cgColor
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomBar.layer.shadowRadius = 4
        bottomBar.layer.shadowOpacity = 0.08
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        // 加入自选
        favoriteBtn.setTitle("  加入自选", for: .normal)
        favoriteBtn.setImage(UIImage(systemName: "plus.rectangle"), for: .normal)
        favoriteBtn.tintColor = .white
        favoriteBtn.setTitleColor(.white, for: .normal)
        favoriteBtn.titleLabel?.font = .boldSystemFont(ofSize: 15)
        favoriteBtn.backgroundColor = stockGreen
        favoriteBtn.layer.cornerRadius = 8
        favoriteBtn.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        bottomBar.addSubview(favoriteBtn)
        favoriteBtn.translatesAutoresizingMaskIntoConstraints = false

        // 交易
        tradeBtn.setTitle("  交易", for: .normal)
        tradeBtn.setImage(UIImage(systemName: "arrow.up.forward.square"), for: .normal)
        tradeBtn.tintColor = .white
        tradeBtn.setTitleColor(.white, for: .normal)
        tradeBtn.titleLabel?.font = .boldSystemFont(ofSize: 15)
        tradeBtn.backgroundColor = themeRed
        tradeBtn.layer.cornerRadius = 8
        tradeBtn.addTarget(self, action: #selector(tradeTapped), for: .touchUpInside)
        bottomBar.addSubview(tradeBtn)
        tradeBtn.translatesAutoresizingMaskIntoConstraints = false

        let btnH: CGFloat = 44
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: btnH + 16 + Constants.Navigation.safeAreaBottom),

            favoriteBtn.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            favoriteBtn.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            favoriteBtn.heightAnchor.constraint(equalToConstant: btnH),
            favoriteBtn.trailingAnchor.constraint(equalTo: bottomBar.centerXAnchor, constant: -6),

            tradeBtn.leadingAnchor.constraint(equalTo: bottomBar.centerXAnchor, constant: 6),
            tradeBtn.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            tradeBtn.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            tradeBtn.heightAnchor.constraint(equalToConstant: btnH),
        ])
    }

    // ===================================================================
    // MARK: - ScrollView 内容
    // ===================================================================
    private func setupScrollContent() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: customNavBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        buildPriceSection()
        buildMetricsGrid()
        buildChartSection()
        buildNewsSection()
    }

    // ===================================================================
    // MARK: - 1. 价格区
    // ===================================================================
    private var priceContainer: UIView!
    private func buildPriceSection() {
        priceContainer = UIView()
        priceContainer.backgroundColor = .white
        contentView.addSubview(priceContainer)
        priceContainer.translatesAutoresizingMaskIntoConstraints = false

        priceLabel.font = .boldSystemFont(ofSize: 38)
        priceLabel.textColor = stockGreen
        priceContainer.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        changeAmtLabel.font = .systemFont(ofSize: 16)
        changeAmtLabel.textColor = stockGreen
        priceContainer.addSubview(changeAmtLabel)
        changeAmtLabel.translatesAutoresizingMaskIntoConstraints = false

        changePctLabel.font = .systemFont(ofSize: 16)
        changePctLabel.textColor = stockGreen
        priceContainer.addSubview(changePctLabel)
        changePctLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            priceContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            priceContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            priceContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            priceLabel.topAnchor.constraint(equalTo: priceContainer.topAnchor, constant: 12),
            priceLabel.leadingAnchor.constraint(equalTo: priceContainer.leadingAnchor, constant: 16),

            changeAmtLabel.leadingAnchor.constraint(equalTo: priceLabel.leadingAnchor),
            changeAmtLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 2),

            changePctLabel.leadingAnchor.constraint(equalTo: changeAmtLabel.trailingAnchor, constant: 12),
            changePctLabel.centerYAnchor.constraint(equalTo: changeAmtLabel.centerYAnchor),
        ])
    }

    // ===================================================================
    // MARK: - 2. 指标网格（3 列 × 3 行）
    // ===================================================================
    private var metricsContainer: UIView!
    private func buildMetricsGrid() {
        metricsContainer = UIView()
        metricsContainer.backgroundColor = .white
        contentView.addSubview(metricsContainer)
        metricsContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            metricsContainer.topAnchor.constraint(equalTo: changeAmtLabel.bottomAnchor, constant: 14),
            metricsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            metricsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])

        // 3 × 3 grid
        let titles = ["今开", "最低", "昨收",
                       "成交量", "涨停价", "成交额",
                       "跌停价", "振幅", "最高"]
        let cols = 3
        let rows = 3
        let rowH: CGFloat = 36

        metricValueLabels = []
        var lastRow: UIView?

        for r in 0..<rows {
            let rowView = UIView()
            metricsContainer.addSubview(rowView)
            rowView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                rowView.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),
                rowView.trailingAnchor.constraint(equalTo: metricsContainer.trailingAnchor),
                rowView.heightAnchor.constraint(equalToConstant: rowH),
            ])
            if let prev = lastRow {
                rowView.topAnchor.constraint(equalTo: prev.bottomAnchor).isActive = true
            } else {
                rowView.topAnchor.constraint(equalTo: metricsContainer.topAnchor).isActive = true
            }
            if r == rows - 1 {
                rowView.bottomAnchor.constraint(equalTo: metricsContainer.bottomAnchor).isActive = true
            }
            lastRow = rowView

            for c in 0..<cols {
                let idx = r * cols + c
                let pair = buildMetricPair(title: titles[idx], value: "--")
                rowView.addSubview(pair.view)
                pair.view.translatesAutoresizingMaskIntoConstraints = false
                let frac = CGFloat(c) / CGFloat(cols)
                NSLayoutConstraint.activate([
                    pair.view.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: frac * (Constants.Screen.width - 32)),
                    pair.view.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                ])
                metricValueLabels.append(pair.valueLabel)
            }
        }

        // 底部分隔线
        let sep = UIView()
        sep.backgroundColor = bgColor
        contentView.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: metricsContainer.bottomAnchor, constant: 8),
            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 4),
        ])
    }

    private func buildMetricPair(title: String, value: String) -> (view: UIView, valueLabel: UILabel) {
        let wrap = UIView()
        let tl = UILabel()
        tl.text = title
        tl.font = .systemFont(ofSize: 12)
        tl.textColor = textSec
        wrap.addSubview(tl)
        tl.translatesAutoresizingMaskIntoConstraints = false

        let vl = UILabel()
        vl.text = value
        vl.font = .systemFont(ofSize: 13, weight: .medium)
        vl.textColor = textPrimary
        wrap.addSubview(vl)
        vl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tl.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            tl.topAnchor.constraint(equalTo: wrap.topAnchor),
            vl.leadingAnchor.constraint(equalTo: tl.trailingAnchor, constant: 6),
            vl.firstBaselineAnchor.constraint(equalTo: tl.firstBaselineAnchor),
        ])
        return (wrap, vl)
    }

    // ===================================================================
    // MARK: - 3. 图表区
    // ===================================================================
    private func buildChartSection() {
        chartContainer = UIView()
        chartContainer.backgroundColor = .white
        contentView.addSubview(chartContainer)
        chartContainer.translatesAutoresizingMaskIntoConstraints = false

        // Tab 按钮
        let tabStack = UIStackView()
        tabStack.axis = .horizontal
        tabStack.distribution = .fillEqually
        tabStack.spacing = 0
        chartContainer.addSubview(tabStack)
        tabStack.translatesAutoresizingMaskIntoConstraints = false

        for (i, t) in chartTabs.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(t, for: .normal)
            btn.tag = i
            btn.titleLabel?.font = .systemFont(ofSize: 14)
            btn.addTarget(self, action: #selector(chartTabTapped(_:)), for: .touchUpInside)
            tabStack.addArrangedSubview(btn)
            chartTabButtons.append(btn)
        }
        refreshChartTabs()

        // 折线图
        lineChartView = LineChartView()
        lineChartView.isUserInteractionEnabled = true
        lineChartView.legend.enabled = false
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.drawGridLinesEnabled = true
        lineChartView.xAxis.gridColor = UIColor(white: 0.9, alpha: 1)
        lineChartView.xAxis.labelTextColor = textSec
        lineChartView.xAxis.labelFont = .systemFont(ofSize: 9)
        lineChartView.leftAxis.drawGridLinesEnabled = true
        lineChartView.leftAxis.gridColor = UIColor(white: 0.9, alpha: 1)
        lineChartView.leftAxis.labelTextColor = textSec
        lineChartView.leftAxis.labelFont = .systemFont(ofSize: 9)
        lineChartView.rightAxis.enabled = false
        lineChartView.drawGridBackgroundEnabled = false
        lineChartView.drawBordersEnabled = true
        lineChartView.borderColor = UIColor(white: 0.9, alpha: 1)
        lineChartView.minOffset = 6
        lineChartView.setScaleEnabled(false)
        lineChartView.highlightPerTapEnabled = true
        chartContainer.addSubview(lineChartView)
        lineChartView.translatesAutoresizingMaskIntoConstraints = false

        // K 线合并图（烛台 + MA）与 lineChartView 同位置，互斥显示）
        candleChartView = CombinedChartView()
        candleChartView.isHidden = true
        candleChartView.legend.enabled = false
        candleChartView.xAxis.labelPosition = .bottom
        candleChartView.xAxis.drawGridLinesEnabled = true
        candleChartView.xAxis.gridColor = UIColor(white: 0.9, alpha: 1)
        candleChartView.xAxis.labelTextColor = textSec
        candleChartView.xAxis.labelFont = .systemFont(ofSize: 9)
        candleChartView.leftAxis.drawGridLinesEnabled = true
        candleChartView.leftAxis.gridColor = UIColor(white: 0.9, alpha: 1)
        candleChartView.leftAxis.labelTextColor = textSec
        candleChartView.leftAxis.labelFont = .systemFont(ofSize: 9)
        candleChartView.rightAxis.enabled = false
        candleChartView.drawGridBackgroundEnabled = false
        candleChartView.drawBordersEnabled = true
        candleChartView.borderColor = UIColor(white: 0.9, alpha: 1)
        candleChartView.minOffset = 6
        candleChartView.setScaleEnabled(false)
        chartContainer.addSubview(candleChartView)
        candleChartView.translatesAutoresizingMaskIntoConstraints = false

        // 成交量柱状图区域
        volumeBarView = UIView()
        volumeBarView.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
        chartContainer.addSubview(volumeBarView)
        volumeBarView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            chartContainer.topAnchor.constraint(equalTo: metricsContainer.bottomAnchor, constant: 12),
            chartContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            chartContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            tabStack.topAnchor.constraint(equalTo: chartContainer.topAnchor, constant: 4),
            tabStack.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor, constant: 16),
            tabStack.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor, constant: -16),
            tabStack.heightAnchor.constraint(equalToConstant: 36),

            lineChartView.topAnchor.constraint(equalTo: tabStack.bottomAnchor, constant: 4),
            lineChartView.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor, constant: 4),
            lineChartView.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor, constant: -4),
            lineChartView.heightAnchor.constraint(equalToConstant: 220),

            candleChartView.topAnchor.constraint(equalTo: lineChartView.topAnchor),
            candleChartView.leadingAnchor.constraint(equalTo: lineChartView.leadingAnchor),
            candleChartView.trailingAnchor.constraint(equalTo: lineChartView.trailingAnchor),
            candleChartView.heightAnchor.constraint(equalTo: lineChartView.heightAnchor),

            volumeBarView.topAnchor.constraint(equalTo: lineChartView.bottomAnchor),
            volumeBarView.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor, constant: 4),
            volumeBarView.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor, constant: -4),
            volumeBarView.heightAnchor.constraint(equalToConstant: 80),
            volumeBarView.bottomAnchor.constraint(equalTo: chartContainer.bottomAnchor, constant: -4),
        ])

        populateChart()
    }

    private func refreshChartTabs() {
        for (i, btn) in chartTabButtons.enumerated() {
            let sel = (i == selectedChartTab)
            btn.setTitleColor(sel ? textPrimary : textSec, for: .normal)
            btn.titleLabel?.font = sel ? .boldSystemFont(ofSize: 15) : .systemFont(ofSize: 14)
        }
    }

    @objc private func chartTabTapped(_ sender: UIButton) {
        guard sender.tag != selectedChartTab else { return }
        selectedChartTab = sender.tag
        refreshChartTabs()
        populateChart()
    }

    // ===================================================================
    // MARK: - 图表数据结构
    // ===================================================================
    private struct TimeSharePoint {
        let price: Double
        let avgPrice: Double
        let volume: Double
        let isUp: Bool  // 相对昨收是否上涨
    }

    private struct KLinePoint {
        let open: Double
        let close: Double
        let high: Double
        let low: Double
        let volume: Double
    }

    // ===================================================================
    // MARK: - 图表入口（与 Android StockDetailViewModel.loadChart 一致）
    // ===================================================================

    /// 切换 Tab 或刷新时调用。检查缓存，命中则直接渲染，否则拉取 EastMoney 数据。
    private func populateChart() {
        let cacheKey: String
        switch selectedChartTab {
        case 0: cacheKey = "time"
        case 1: cacheKey = "k_5"
        case 2: cacheKey = "k_101"
        default: cacheKey = "k_102"
        }

        if let cached = chartDataCache[cacheKey] {
            if let pts = cached as? [TimeSharePoint] {
                renderTimeShare(pts)
            } else if let pts = cached as? [KLinePoint] {
                renderKLine(pts)
            }
            return
        }

        if selectedChartTab == 0 {
            fetchTimeShare { [weak self] points in
                guard let self else { return }
                self.chartDataCache[cacheKey] = points
                DispatchQueue.main.async { self.renderTimeShare(points) }
            }
        } else {
            let klt: Int
            switch selectedChartTab {
            case 1: klt = 5
            case 2: klt = 101
            default: klt = 102
            }
            fetchKLine(klt: klt) { [weak self] points in
                guard let self else { return }
                self.chartDataCache[cacheKey] = points
                DispatchQueue.main.async { self.renderKLine(points) }
            }
        }
    }

    // ===================================================================
    // MARK: - EastMoney 数据拉取（与 Android EastMoneyDetailRepository 一致）
    // ===================================================================

    /// 分时图数据 —— Android fetchTimeShare
    /// URL: push2his.eastmoney.com/api/qt/stock/trends2/get
    private func fetchTimeShare(completion: @escaping ([TimeSharePoint]) -> Void) {
        let secId = resolveSecId()
        let urlStr = "https://push2his.eastmoney.com/api/qt/stock/trends2/get"
            + "?secid=\(secId)"
            + "&fields1=f1,f2,f3,f4,f5,f6,f7,f8"
            + "&fields2=f51,f52,f53,f54,f55,f56,f57,f58"
            + "&ndays=1&iscr=0"
        guard let url = URL(string: urlStr) else { completion([]); return }

        var req = URLRequest(url: url)
        req.setValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
                     forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let json  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let root  = json["data"] as? [String: Any],
                  let trends = root["trends"] as? [String] else { completion([]); return }

            // 昨收取自 preClose 字段，或退而使用已知 yesterdayClose
            let preCloseRef = Double(self.yesterdayClose) ?? 0

            let points: [TimeSharePoint] = trends.compactMap { entry in
                let v = entry.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
                guard v.count >= 6,
                      let price = Double(v[1]),
                      let avg   = Double(v[2]) else { return nil }
                let vol  = Double(v[5]) ?? 0
                return TimeSharePoint(
                    price: price,
                    avgPrice: avg,
                    volume: vol,
                    isUp: price >= preCloseRef
                )
            }
            completion(points)
        }.resume()
    }

    /// K 线数据 —— Android fetchKLine
    /// URL: push2his.eastmoney.com/api/qt/stock/kline/get
    private func fetchKLine(klt: Int, completion: @escaping ([KLinePoint]) -> Void) {
        let secId = resolveSecId()
        let ut = "fa5fd1943c7b386f172d6893dbfba10b"
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        let urlStr = "https://push2his.eastmoney.com/api/qt/stock/kline/get"
            + "?secid=\(secId)&ut=\(ut)"
            + "&fields1=f1,f2,f3,f4,f5,f6"
            + "&fields2=f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61"
            + "&klt=\(klt)&fqt=1&beg=0&end=20500101&lmt=120&_=\(ts)"
        guard let url = URL(string: urlStr) else { completion([]); return }

        var req = URLRequest(url: url)
        req.setValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
                     forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data,
                  let json   = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let root   = json["data"] as? [String: Any],
                  let klines = root["klines"] as? [String] else { completion([]); return }

            let points: [KLinePoint] = klines.compactMap { entry in
                let v = entry.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
                // values: date,open,close,high,low,volume,amount,...
                guard v.count >= 6,
                      let open  = Double(v[1]),
                      let close = Double(v[2]),
                      let high  = Double(v[3]),
                      let low   = Double(v[4]) else { return nil }
                let vol = Double(v[5]) ?? 0
                return KLinePoint(open: open, close: close, high: high, low: low, volume: vol)
            }
            completion(points)
        }.resume()
    }

    // ===================================================================
    // MARK: - 渲染
    // ===================================================================

    /// 分时图：LineChartView 显示（价格线 + 均价线 + 昨收基线）
    private func renderTimeShare(_ points: [TimeSharePoint]) {
        lineChartView.isHidden   = false
        candleChartView.isHidden = true
        guard !points.isEmpty else {
            lineChartView.data = nil
            drawVolumeBarChart(volumes: [], isUpArray: [])
            return
        }

        let changeVal = Double(indexChange) ?? 0
        let isRise    = changeVal >= 0
        let mainColor = isRise ? themeRed : stockGreen

        var priceEntries:  [ChartDataEntry] = []
        var avgEntries:    [ChartDataEntry] = []
        var ycEntries:     [ChartDataEntry] = []
        let ycPrice = Double(yesterdayClose) ?? 0

        for (i, pt) in points.enumerated() {
            let x = Double(i)
            priceEntries.append(ChartDataEntry(x: x, y: pt.price))
            avgEntries.append(ChartDataEntry(x: x, y: pt.avgPrice))
            ycEntries.append(ChartDataEntry(x: x, y: ycPrice))
        }

        let priceDS = LineChartDataSet(entries: priceEntries, label: "")
        priceDS.colors = [mainColor]
        priceDS.lineWidth = 1.5
        priceDS.drawCirclesEnabled = false
        priceDS.drawValuesEnabled  = false
        priceDS.drawFilledEnabled  = true
        priceDS.fillColor  = mainColor
        priceDS.fillAlpha  = 0.08
        priceDS.mode = .linear

        let avgDS = LineChartDataSet(entries: avgEntries, label: "")
        avgDS.colors = [UIColor.orange]
        avgDS.lineWidth = 1
        avgDS.drawCirclesEnabled = false
        avgDS.drawValuesEnabled  = false
        avgDS.mode = .linear

        let ycDS = LineChartDataSet(entries: ycEntries, label: "")
        ycDS.colors = [UIColor.gray]
        ycDS.lineWidth = 1
        ycDS.drawCirclesEnabled = false
        ycDS.drawValuesEnabled  = false
        ycDS.lineDashLengths = [6, 3]

        lineChartView.data = LineChartData(dataSets: [priceDS, avgDS, ycDS])

        let vols   = points.map { $0.volume }
        let isUps  = points.map { $0.isUp }
        drawVolumeBarChart(volumes: vols, isUpArray: isUps)
    }

    /// K 线图：CandleChartView 显示，并计算 MA5/MA10 覆盖在 candleChartView 上
    private func renderKLine(_ points: [KLinePoint]) {
        lineChartView.isHidden   = true
        candleChartView.isHidden = false
        guard !points.isEmpty else {
            candleChartView.data = nil
            drawVolumeBarChart(volumes: [], isUpArray: [])
            return
        }

        var candleEntries: [CandleChartDataEntry] = []
        var closes: [Double] = []

        for (i, pt) in points.enumerated() {
            let entry = CandleChartDataEntry(
                x: Double(i),
                shadowH: pt.high,
                shadowL: pt.low,
                open:    pt.open,
                close:   pt.close
            )
            candleEntries.append(entry)
            closes.append(pt.close)
        }

        let candleDS = CandleChartDataSet(entries: candleEntries, label: "")
        candleDS.increasingColor      = themeRed
        candleDS.decreasingColor      = stockGreen
        candleDS.increasingFilled     = true
        candleDS.decreasingFilled     = true
        candleDS.neutralColor         = textSec
        candleDS.shadowColor          = .darkGray
        candleDS.shadowWidth          = 0.7
        candleDS.drawValuesEnabled    = false
        candleDS.highlightColor       = UIColor(white: 0.5, alpha: 0.5)

        // MA5 / MA10 覆盖线
        func maEntries(period: Int) -> [ChartDataEntry] {
            (0..<closes.count).compactMap { i in
                let start = max(0, i - period + 1)
                let slice = closes[start...i]
                let avg = slice.reduce(0, +) / Double(slice.count)
                return ChartDataEntry(x: Double(i), y: avg)
            }
        }
        let ma5DS  = LineChartDataSet(entries: maEntries(period: 5),  label: "")
        ma5DS.colors = [UIColor.orange]
        ma5DS.lineWidth = 1
        ma5DS.drawCirclesEnabled = false
        ma5DS.drawValuesEnabled  = false

        let ma10DS = LineChartDataSet(entries: maEntries(period: 10), label: "")
        ma10DS.colors = [UIColor.systemBlue]
        ma10DS.lineWidth = 1
        ma10DS.drawCirclesEnabled = false
        ma10DS.drawValuesEnabled  = false

        let combined = CombinedChartData()
        combined.candleData = CandleChartData(dataSet: candleDS)
        combined.lineData   = LineChartData(dataSets: [ma5DS, ma10DS])
        candleChartView.data = combined

        let vols  = points.map { $0.volume }
        let isUps = points.map { $0.close >= $0.open }
        drawVolumeBarChart(volumes: vols, isUpArray: isUps)
    }

    /// 在 volumeBarView 上绘制真实成交量柱状图（与 Android 色彩规则一致：涨红跌绿）
    private func drawVolumeBarChart(volumes: [Double], isUpArray: [Bool]) {
        volumeBarView.subviews.forEach { $0.removeFromSuperview() }
        volumeBarView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        guard !volumes.isEmpty else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let w = self.volumeBarView.bounds.width
            let h = self.volumeBarView.bounds.height
            guard w > 0, h > 0 else { return }

            let maxVol = volumes.max() ?? 1
            let count  = volumes.count
            let barW   = max(1, (w - 2) / CGFloat(count))

            for (i, vol) in volumes.enumerated() {
                let ratio = maxVol > 0 ? CGFloat(vol / maxVol) : 0
                let barH  = max(1, ratio * (h - 4))
                let x     = CGFloat(i) * barW
                let isUp  = i < isUpArray.count ? isUpArray[i] : (vol >= 0)
                let color = isUp ? self.themeRed.cgColor : self.stockGreen.cgColor

                let bar = CALayer()
                bar.frame = CGRect(x: x, y: h - barH - 2,
                                   width: max(barW - 0.5, 0.5), height: barH)
                bar.backgroundColor = color
                self.volumeBarView.layer.addSublayer(bar)
            }
        }
    }

    // ===================================================================
    // MARK: - 4. 新闻区
    // ===================================================================
    private var newsContainer: UIView!
    private func buildNewsSection() {
        newsContainer = UIView()
        newsContainer.backgroundColor = .white
        contentView.addSubview(newsContainer)
        newsContainer.translatesAutoresizingMaskIntoConstraints = false

        // 分隔
        let sep = UIView()
        sep.backgroundColor = bgColor
        contentView.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false

        // Tab 按钮
        let tabScroll = UIScrollView()
        tabScroll.showsHorizontalScrollIndicator = false
        newsContainer.addSubview(tabScroll)
        tabScroll.translatesAutoresizingMaskIntoConstraints = false

        let tabStack = UIStackView()
        tabStack.axis = .horizontal
        tabStack.spacing = 20
        tabScroll.addSubview(tabStack)
        tabStack.translatesAutoresizingMaskIntoConstraints = false

        for (i, t) in newsTabs.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(t, for: .normal)
            btn.tag = i
            btn.titleLabel?.font = .systemFont(ofSize: 16)
            btn.addTarget(self, action: #selector(newsTabTapped(_:)), for: .touchUpInside)
            tabStack.addArrangedSubview(btn)
            newsTabButtons.append(btn)
        }

        newsTabIndicator = UIView()
        newsTabIndicator.backgroundColor = themeRed
        newsTabIndicator.layer.cornerRadius = 2
        tabScroll.addSubview(newsTabIndicator)

        // TableView
        newsTableView.dataSource = self
        newsTableView.delegate = self
        newsTableView.register(IndexNewsCell.self, forCellReuseIdentifier: "NewsCell")
        newsTableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        newsTableView.isScrollEnabled = false
        newsTableView.rowHeight = UITableView.automaticDimension
        newsTableView.estimatedRowHeight = 90
        newsContainer.addSubview(newsTableView)
        newsTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: chartContainer.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 8),

            newsContainer.topAnchor.constraint(equalTo: sep.bottomAnchor),
            newsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            newsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            newsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            tabScroll.topAnchor.constraint(equalTo: newsContainer.topAnchor),
            tabScroll.leadingAnchor.constraint(equalTo: newsContainer.leadingAnchor),
            tabScroll.trailingAnchor.constraint(equalTo: newsContainer.trailingAnchor),
            tabScroll.heightAnchor.constraint(equalToConstant: 40),

            tabStack.topAnchor.constraint(equalTo: tabScroll.topAnchor),
            tabStack.leadingAnchor.constraint(equalTo: tabScroll.leadingAnchor, constant: 16),
            tabStack.trailingAnchor.constraint(equalTo: tabScroll.trailingAnchor, constant: -16),
            tabStack.bottomAnchor.constraint(equalTo: tabScroll.bottomAnchor),
            tabStack.heightAnchor.constraint(equalTo: tabScroll.heightAnchor),

            newsTableView.topAnchor.constraint(equalTo: tabScroll.bottomAnchor),
            newsTableView.leadingAnchor.constraint(equalTo: newsContainer.leadingAnchor),
            newsTableView.trailingAnchor.constraint(equalTo: newsContainer.trailingAnchor),
            newsTableView.bottomAnchor.constraint(equalTo: newsContainer.bottomAnchor),
        ])

        newsTableHeightCons = newsTableView.heightAnchor.constraint(equalToConstant: 200)
        newsTableHeightCons?.isActive = true

        refreshNewsTabs()
    }

    private func refreshNewsTabs() {
        let selColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1) // 深黑
        let norColor = UIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1)       // 浅灰
        for (i, btn) in newsTabButtons.enumerated() {
            let sel = (i == selectedNewsTab)
            btn.setTitleColor(sel ? selColor : norColor, for: .normal)
            btn.titleLabel?.font = sel ? .boldSystemFont(ofSize: 17) : .systemFont(ofSize: 16)
        }
        DispatchQueue.main.async { [weak self] in
            self?.moveNewsIndicator()
        }
    }

    private func moveNewsIndicator() {
        guard selectedNewsTab < newsTabButtons.count else { return }
        let btn = newsTabButtons[selectedNewsTab]
        guard let sv = newsTabIndicator.superview else { return }
        let frame = btn.convert(btn.bounds, to: sv)
        let w: CGFloat = 20
        UIView.animate(withDuration: 0.25) {
            self.newsTabIndicator.frame = CGRect(x: frame.midX - w / 2, y: frame.maxY - 4, width: w, height: 4)
        }
    }

    @objc private func newsTabTapped(_ sender: UIButton) {
        guard sender.tag != selectedNewsTab else { return }
        selectedNewsTab = sender.tag
        refreshNewsTabs()
        loadNews()
    }

    // ===================================================================
    // MARK: - 填充初始数据
    // ===================================================================
    private func applyInitialData() {
        let cv = Double(indexChange) ?? 0
        let pv = Double(indexChangePercent) ?? 0
        let isRise = cv >= 0
        let color = isRise ? themeRed : stockGreen

        priceLabel.text = indexPrice
        priceLabel.textColor = color

        let sign = isRise ? "+" : ""
        changeAmtLabel.text = "\(sign)\(indexChange)"
        changeAmtLabel.textColor = color

        changePctLabel.text = "\(sign)\(indexChangePercent)%"
        changePctLabel.textColor = color
    }

    private func refreshMetrics() {
        let values = [todayOpen, lowest, yesterdayClose,
                      volume, limitUp, turnover,
                      limitDown, amplitude, highest]
        for (i, lbl) in metricValueLabels.enumerated() where i < values.count {
            lbl.text = values[i]
        }
    }

    private func updateFavoriteButton() {
        if isFavorite {
            favoriteBtn.setTitle("  已自选", for: .normal)
            favoriteBtn.setImage(UIImage(systemName: "checkmark.rectangle"), for: .normal)
            favoriteBtn.backgroundColor = textSec
        } else {
            favoriteBtn.setTitle("  加入自选", for: .normal)
            favoriteBtn.setImage(UIImage(systemName: "plus.rectangle"), for: .normal)
            favoriteBtn.backgroundColor = stockGreen
        }
    }

    // ===================================================================
    // MARK: - 网络请求
    // ===================================================================

    /// 将 indexCode / indexAllcode 转换为东方财富 secId（市场前缀.代码）
    /// 逻辑与 Android SecIdResolver 一致
    private func resolveSecId() -> String {
        let code = indexCode
        let allcode = indexAllcode.lowercased()

        // 北交所
        if allcode.hasPrefix("bj") { return "0.\(code)" }

        // 上交所 sh prefix
        if allcode.hasPrefix("sh") { return "1.\(code)" }

        // 指数：特定代码归属上交所
        let shIndexCodes = Set(["000001","000016","000300","000905","000852","000688"])
        if shIndexCodes.contains(code) { return "1.\(code)" }
        if code.hasPrefix("399") || code.hasPrefix("899") { return "0.\(code)" }
        if code.hasPrefix("000") { return "1.\(code)" }

        // 普通股票
        if code.hasPrefix("6") || code.hasPrefix("5") || code.hasPrefix("9") { return "1.\(code)" }

        // 深交所默认
        return "0.\(code)"
    }

    /// 加载指数行情详细数据 —— 直接调用东方财富 push2 API，与 Android EastMoneyDetailRepository 一致
    private func loadIndexDetail() {
        let secId = resolveSecId()
        let ut = "fa5fd1943c7b386f172d6893dbfba10b"
        let fields = "f43,f44,f45,f46,f47,f48,f51,f52,f57,f58,f60,f116,f117,f168,f169,f170"
        let urlStr = "https://push2.eastmoney.com/api/qt/stock/get"
            + "?secid=\(secId)&fltt=2&invt=2&ut=\(ut)&fields=\(fields)"
        guard let url = URL(string: urlStr) else { return }

        var req = URLRequest(url: url)
        req.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
            + "AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
            forHTTPHeaderField: "User-Agent"
        )
        req.setValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")

        URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            guard let self else { return }
            if let error = error {
                print("[指数详情] EastMoney 请求失败: \(error.localizedDescription)")
                return
            }
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any] else {
                print("[指数详情] EastMoney 响应解析失败")
                return
            }

            // 将 JSON 值解析为 Double（兼容 Int / Double / String 三种类型）
            func dbl(_ key: String) -> Double? {
                guard let v = d[key] else { return nil }
                if let n = v as? Double { return n }
                if let n = v as? Int    { return Double(n) }
                if let s = v as? String { return Double(s) }
                return nil
            }

            let price    = dbl("f43")   // 最新价
            let high     = dbl("f44")   // 最高
            let low      = dbl("f45")   // 最低
            let open     = dbl("f46")   // 今开
            let vol      = dbl("f47")   // 成交量（手）
            let amt      = dbl("f48")   // 成交额（元）
            let lu       = dbl("f51")   // 涨停价
            let ld       = dbl("f52")   // 跌停价
            let preClose = dbl("f60")   // 昨收
            let change   = dbl("f169")  // 涨跌额
            let changePct = dbl("f170") // 涨跌幅（%）

            // 格式化为两位小数字符串
            func fmt2(_ v: Double?) -> String {
                guard let v else { return "--" }
                return String(format: "%.2f", v)
            }

            // 成交量格式化（与 Android formatVolume 一致）
            func fmtVolume(_ v: Double?) -> String {
                guard let v else { return "--" }
                let a = abs(v)
                if a >= 1e8 { return String(format: "%.2f亿", v / 1e8) }
                if a >= 1e4 { return String(format: "%.2f万", v / 1e4) }
                return String(format: "%.0f", v)
            }

            // 成交额格式化（与 Android formatAmount 一致）
            func fmtAmount(_ v: Double?) -> String {
                guard let v else { return "--" }
                let a = abs(v)
                if a >= 1e12 { return String(format: "%.2f万亿", v / 1e12) }
                if a >= 1e8  { return String(format: "%.2f亿", v / 1e8) }
                if a >= 1e4  { return String(format: "%.2f万", v / 1e4) }
                return String(format: "%.2f", v)
            }

            // 振幅 = (最高 - 最低) / 昨收 × 100%（与 Android SnapshotData.amplitudePct 一致）
            func amplitudePct() -> String {
                guard let h = high, let l = low, let p = preClose, p != 0 else { return "--" }
                return String(format: "%.2f%%", (h - l) / p * 100.0)
            }

            DispatchQueue.main.async {
                // 刷新价格区
                if let price, let change {
                    let isRise = change >= 0
                    let color = isRise ? self.themeRed : self.stockGreen
                    let sign  = isRise ? "+" : ""
                    self.indexPrice         = fmt2(price)
                    self.indexChange        = fmt2(change)
                    self.indexChangePercent = fmt2(changePct)

                    self.priceLabel.text    = self.indexPrice
                    self.priceLabel.textColor = color
                    self.changeAmtLabel.text  = "\(sign)\(self.indexChange)"
                    self.changeAmtLabel.textColor = color
                    self.changePctLabel.text  = "\(sign)\(self.indexChangePercent)%"
                    self.changePctLabel.textColor = color
                }

                // 刷新指标网格
                self.todayOpen      = fmt2(open)
                self.lowest         = fmt2(low)
                self.yesterdayClose = fmt2(preClose)
                self.volume         = fmtVolume(vol)
                self.limitUp        = fmt2(lu)
                self.turnover       = fmtAmount(amt)
                self.limitDown      = fmt2(ld)
                self.amplitude      = amplitudePct()
                self.highest        = fmt2(high)

                self.refreshMetrics()
                self.populateChart()
            }
        }.resume()
    }

    /// 检查是否已加入自选
    private func loadFavoriteStatus() {
        guard !indexAllcode.isEmpty else { return }
        SecureNetworkManager.shared.request(
            api: "/api/Indexnew/getHqinfo_1",
            method: .get,
            params: ["q": indexAllcode]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any] else { return }
                let isZx = "\(data["is_zx"] ?? "0")"
                DispatchQueue.main.async {
                    self.isFavorite = (isZx == "1")
                    self.updateFavoriteButton()
                }
            case .failure: break
            }
        }
    }

    /// 加载新闻列表
    private func loadNews() {
        // type: 1国内经济 2国际经济 3证券要闻 4公司咨询
        // 映射 newsTabs: 动态→3, 7X24→1, 盘面→2, 投顾→3, 要闻→3, 更多→4
        let typeMap = [3, 1, 2, 3, 3, 4]
        let newsType = selectedNewsTab < typeMap.count ? typeMap[selectedNewsTab] : 3

        SecureNetworkManager.shared.request(
            api: "/api/Indexnew/getGuoneinews",
            method: .get,
            params: ["page": "1", "size": "20", "type": "\(newsType)"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        self.newsList = []
                        self.newsTableView.reloadData()
                        self.updateNewsTableHeight()
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.newsList = list
                    self.newsTableView.reloadData()
                    self.updateNewsTableHeight()
                }
            case .failure(let err):
                print("[指数详情] 新闻加载失败: \(err.localizedDescription)")
            }
        }
    }

    private func updateNewsTableHeight() {
        let h = max(200, CGFloat(newsList.count) * 90)
        newsTableHeightCons?.constant = h
        view.layoutIfNeeded()
    }

    /// 添加 / 取消自选
    private func toggleFavorite() {
        let api = isFavorite ? "/api/ask/delzx" : "/api/ask/addzx"
        SecureNetworkManager.shared.request(
            api: api,
            method: .post,
            params: ["allcode": indexAllcode, "code": indexCode]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let code = dict["code"] as? Int, code == 1 else {
                    DispatchQueue.main.async { Toast.show("操作失败") }
                    return
                }
                DispatchQueue.main.async {
                    self.isFavorite.toggle()
                    self.updateFavoriteButton()
                    Toast.show(self.isFavorite ? "已加入自选" : "已取消自选")
                }
            case .failure(let err):
                DispatchQueue.main.async { Toast.show("操作失败: \(err.localizedDescription)") }
            }
        }
    }

    // ===================================================================
    // MARK: - Actions
    // ===================================================================
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func searchTapped() {
        let vc = StockSearchViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func favoriteTapped() {
        toggleFavorite()
    }

    @objc private func tradeTapped() {
        guard !isIndex else { return }   // 指数不可交易，按钮已置灰，双重保险
        let vc = StockTradeViewController()
        vc.stockName     = indexName
        vc.stockCode     = indexCode
        vc.stockAllcode  = indexAllcode
        vc.currentPrice  = Double(indexPrice) ?? 0
        vc.changeAmount  = Double(indexChange) ?? 0
        vc.changePercent = Double(indexChangePercent) ?? 0
        // 根据 allcode 前缀推断交易所标识
        let prefix = indexAllcode.lowercased()
        if prefix.hasPrefix("sh") || prefix.hasPrefix("zssh") { vc.exchange = "沪" }
        else if prefix.hasPrefix("sz") || prefix.hasPrefix("zssz") { vc.exchange = "深" }
        else if prefix.hasPrefix("bj") { vc.exchange = "北" }
        else { vc.exchange = "" }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    /// 根据 isIndex 配置交易按钮的样式（对应 Android renderTradeState）
    private func applyTradeButtonState() {
        if isIndex {
            tradeBtn.setTitle("  指数不可交易", for: .normal)
            tradeBtn.setImage(nil, for: .normal)
            tradeBtn.backgroundColor = UIColor(white: 0.88, alpha: 1)
            tradeBtn.setTitleColor(textSec, for: .normal)
            tradeBtn.tintColor = textSec
            tradeBtn.isEnabled = false
        } else {
            tradeBtn.setTitle("  交易", for: .normal)
            tradeBtn.setImage(UIImage(systemName: "arrow.up.forward.square"), for: .normal)
            tradeBtn.backgroundColor = themeRed
            tradeBtn.setTitleColor(.white, for: .normal)
            tradeBtn.tintColor = .white
            tradeBtn.isEnabled = true
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension IndexDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath) as! IndexNewsCell
        if indexPath.row < newsList.count {
            let item = newsList[indexPath.row]
            let title = item["news_title"] as? String ?? ""
            let time  = item["news_time_text"] as? String ?? (item["news_time"] as? String ?? "")
            cell.configure(title: title, time: time)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < newsList.count else { return }
        let item = newsList[indexPath.row]

        // 优先使用已有的 news_content
        if let content = item["news_content"] as? String, !content.isEmpty {
            let vc = NewsDetailViewController()
            vc.htmlContent = content
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
            return
        }

        // 否则通过 news_id 请求新闻详情
        let newsId = "\(item["news_id"] ?? "")"
        guard !newsId.isEmpty else { return }
        SecureNetworkManager.shared.request(
            api: "/api/Indexnew/getNewsssDetail",
            method: .get,
            params: ["news_id": newsId]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let content = data["news_content"] as? String else { return }
                DispatchQueue.main.async {
                    let vc = NewsDetailViewController()
                    vc.htmlContent = content
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            case .failure(let err):
                DispatchQueue.main.async { Toast.show("加载失败") }
                print("[指数详情] 新闻详情请求失败: \(err.localizedDescription)")
            }
        }
    }
}

// MARK: - IndexNewsCell
class IndexNewsCell: UITableViewCell {

    private let titleLabel = UILabel()
    private let timeLabel  = UILabel()
    private let sep        = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white

        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1)
        titleLabel.numberOfLines = 2
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        contentView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        sep.backgroundColor = UIColor(white: 0.93, alpha: 1)
        contentView.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sep.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, time: String) {
        titleLabel.text = title
        // 格式化时间显示，只取日期和时间
        if let range = time.range(of: #"\d{2}-\d{2} \d{2}:\d{2}"#, options: .regularExpression) {
            timeLabel.text = "发布时间：\(time[range])"
        } else {
            timeLabel.text = "发布时间：\(time)"
        }
    }
}
