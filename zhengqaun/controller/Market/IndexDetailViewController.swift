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
    private var volumeBarView: UIView!

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

    /// 填充折线图（模拟数据，基于 indexPrice）
    private func populateChart() {
        let base = Double(indexPrice) ?? 1536
        let changeVal = Double(indexChange) ?? 0
        let isRise = changeVal >= 0
        let mainColor = isRise ? themeRed : stockGreen
        let avgColor = UIColor.orange

        let count = selectedChartTab == 0 ? 240 : (selectedChartTab == 1 ? 48 : 60)
        var priceEntries: [ChartDataEntry] = []
        var ma5Entries: [ChartDataEntry] = []
        var ma10Entries: [ChartDataEntry] = []

        var p = base - changeVal
        var prices: [Double] = []
        for i in 0..<count {
            let noise = Double.random(in: -0.003...0.003) * base
            let trend = changeVal * (Double(i) / Double(count - 1))
            p = base - changeVal + trend + noise
            prices.append(p)
            priceEntries.append(ChartDataEntry(x: Double(i), y: p))
        }
        // 最后一个点对齐实际价格
        priceEntries[count - 1] = ChartDataEntry(x: Double(count - 1), y: base)
        prices[count - 1] = base

        // MA5
        for i in 0..<count {
            let start = max(0, i - 4)
            let slice = prices[start...i]
            let avg = slice.reduce(0, +) / Double(slice.count)
            ma5Entries.append(ChartDataEntry(x: Double(i), y: avg))
        }
        // MA10
        for i in 0..<count {
            let start = max(0, i - 9)
            let slice = prices[start...i]
            let avg = slice.reduce(0, +) / Double(slice.count)
            ma10Entries.append(ChartDataEntry(x: Double(i), y: avg))
        }

        let priceDS = LineChartDataSet(entries: priceEntries, label: "")
        priceDS.colors = [mainColor]
        priceDS.lineWidth = 1.5
        priceDS.drawCirclesEnabled = false
        priceDS.drawValuesEnabled = false
        priceDS.drawFilledEnabled = true
        priceDS.fillColor = mainColor
        priceDS.fillAlpha = 0.08
        priceDS.mode = .cubicBezier

        let ma5DS = LineChartDataSet(entries: ma5Entries, label: "")
        ma5DS.colors = [avgColor]
        ma5DS.lineWidth = 1
        ma5DS.drawCirclesEnabled = false
        ma5DS.drawValuesEnabled = false
        ma5DS.drawFilledEnabled = false
        ma5DS.mode = .cubicBezier

        let ma10DS = LineChartDataSet(entries: ma10Entries, label: "")
        ma10DS.colors = [UIColor.systemBlue]
        ma10DS.lineWidth = 1
        ma10DS.drawCirclesEnabled = false
        ma10DS.drawValuesEnabled = false
        ma10DS.drawFilledEnabled = false
        ma10DS.mode = .cubicBezier

        // 昨收虚线
        let ycPrice = Double(yesterdayClose) ?? (base + changeVal)
        var ycEntries: [ChartDataEntry] = []
        for i in 0..<count {
            ycEntries.append(ChartDataEntry(x: Double(i), y: ycPrice))
        }
        let ycDS = LineChartDataSet(entries: ycEntries, label: "")
        ycDS.colors = [UIColor.gray]
        ycDS.lineWidth = 1
        ycDS.drawCirclesEnabled = false
        ycDS.drawValuesEnabled = false
        ycDS.lineDashLengths = [6, 3]

        lineChartView.data = LineChartData(dataSets: [priceDS, ma5DS, ma10DS, ycDS])

        drawVolumeBarChart(count: count)
    }

    /// 在 volumeBarView 上绘制成交量柱状图（模拟）
    private func drawVolumeBarChart(count: Int) {
        volumeBarView.subviews.forEach { $0.removeFromSuperview() }
        volumeBarView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let w = self.volumeBarView.bounds.width
            let h = self.volumeBarView.bounds.height
            guard w > 0, h > 0 else { return }

            let barW = max(1, (w - 2) / CGFloat(count))
            for i in 0..<count {
                let ratio = CGFloat.random(in: 0.1...1.0)
                let barH = ratio * (h - 4)
                let x = CGFloat(i) * barW
                let isUp = Bool.random()
                let color = isUp ? self.themeRed.cgColor : self.stockGreen.cgColor

                let bar = CALayer()
                bar.frame = CGRect(x: x, y: h - barH - 2, width: max(barW - 0.5, 0.5), height: barH)
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
            btn.titleLabel?.font = .systemFont(ofSize: 15)
            btn.addTarget(self, action: #selector(newsTabTapped(_:)), for: .touchUpInside)
            tabStack.addArrangedSubview(btn)
            newsTabButtons.append(btn)
        }

        newsTabIndicator = UIView()
        newsTabIndicator.backgroundColor = themeRed
        newsTabIndicator.layer.cornerRadius = 1.5
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
        for (i, btn) in newsTabButtons.enumerated() {
            let sel = (i == selectedNewsTab)
            btn.setTitleColor(sel ? textPrimary : textSec, for: .normal)
            btn.titleLabel?.font = sel ? .boldSystemFont(ofSize: 15) : .systemFont(ofSize: 15)
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
            self.newsTabIndicator.frame = CGRect(x: frame.midX - w / 2, y: frame.maxY - 4, width: w, height: 3)
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

    /// 加载指数行情详细数据
    private func loadIndexDetail() {
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
                      let list = data["list"] as? [[String: Any]] else { return }

                // 从列表中找到匹配当前指数的条目
                for obj in list {
                    guard let arr = obj["allcodes_arr"] as? [Any], arr.count >= 11 else { continue }
                    let str = arr.map { "\($0)" }
                    let code = str[2]
                    guard code == self.indexCode else { continue }

                    DispatchQueue.main.async {
                        // 更新价格
                        self.indexPrice = str[3]
                        self.indexChange = str[4]
                        self.indexChangePercent = str[5]

                        self.todayOpen = str[3]
                        self.yesterdayClose = str[3]
                        self.volume = str[6]
                        self.turnover = str.count > 7 ? str[7] : "--"
                        self.limitUp = "--"
                        self.turnover = self.turnover
                        self.limitDown = self.indexPrice
                        self.amplitude = "\(str[5])%"
                        self.highest = "--"
                        self.lowest = self.indexPrice

                        // allcodes_arr 可能含有额外数据：
                        // 0=市场, 1=名称, 2=代码, 3=最新价, 4=涨跌额, 5=涨跌幅,
                        // 6=成交量, 7=成交额, 8=预留, 9=总市值, 10=类型
                        if str.count > 9 {
                            // 用成交额做显示
                            self.turnover = str[7]
                        }

                        self.applyInitialData()
                        self.refreshMetrics()
                        self.populateChart()
                    }
                    break
                }
            case .failure(let err):
                print("[指数详情] 加载失败: \(err.localizedDescription)")
            }
        }
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
        // 跳转到交易页面（切换 TabBar 到交易 Tab）
        if let tabBarVC = self.tabBarController {
            navigationController?.popToRootViewController(animated: false)
            tabBarVC.selectedIndex = 2 // 交易 tab
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
