//
//  StockDetailViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit
import SafariServices

class StockDetailViewController: ZQViewController {
    
    // MARK: - Properties
    var stockName: String = "天润科技"
    var stockCode: String = "920564"
    var exchange: String = "京" // 交易所标识
    
    // 股票数据
    private var currentPrice: Double = 21.88
    private var change: Double = 5.17
    private var changePercent: Double = 22.29
    private var isRising: Bool = true
    
    // 关键指标
    private var turnoverRate: Double = 33.2
    private var peRatio: Double = -196.44
    private var todayOpen: Double = 23.2
    private var yesterdayClose: Double = 23.19
    private var amplitude: Double = 29.75
    private var totalMarketCap: String = "25.27亿"
    private var circulatingMarketCap: String = "23.19"
    private var lowest: Double = 23.2
    private var highest: Double = 23.19
    private var volume: String = "13.44万手"
    private var turnover: String = "3.66亿"
    private var pbRatio: Double = 8.19
    
    // 图表类型
    private var selectedChartType: ChartType = .minute {
        didSet {
            updateChartType()
        }
    }
    
    enum ChartType: Int {
        case minute = 0  // 分时
        case daily = 1   // 日K
        case weekly = 2   // 周K
        case monthly = 3 // 月K
        case yearly = 4  // 年
    }
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 顶部导航栏（自定义）
    private let customNavBar = UIView()
    private let timeLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let stockNameLabel = UILabel()
    private let stockCodeLabel = UILabel()
    private let searchButton = UIButton(type: .system)
    
    // 股票概览区域
    private let overviewContainer = UIView()
    private let priceLabel = UILabel()
    private let changeLabel = UILabel()
    private let changePercentLabel = UILabel()
    private let metricsContainer = UIView()
    
    // 图表区域
    private let chartContainer = UIView()
    private let chartTypeSegmentedControl = UISegmentedControl(items: ["分时", "日K", "周K", "月K", "年"])
    private let priceChartView = UIView()
    private let volumeChartView = UIView()
    private let orderBookView = UIView()
    
    // 今日资金区域
    private let fundsContainer = UIView()
    
    // 底部操作栏
    private let bottomBar = UIView()
    private let buyButton = UIButton(type: .system)
    private let sellButton = UIButton(type: .system)
    private let favoriteButton = UIButton(type: .system)
    
    // 全屏K线
    private var fullScreenChartVC: FullScreenChartViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTime()
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        setupCustomNavigationBar()
        setupBottomBar() // 先创建底部栏，因为scrollView需要引用它
        setupScrollView()
        setupOverviewSection()
        setupChartSection()
        setupFundsSection()
    }
    
    private func setupCustomNavigationBar() {
        view.addSubview(customNavBar)
        customNavBar.backgroundColor = .white
        customNavBar.translatesAutoresizingMaskIntoConstraints = false
        
        // 时间标签
        timeLabel.text = "09:41"
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = Constants.Color.textSecondary
        customNavBar.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 返回按钮
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        customNavBar.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票名称
        stockNameLabel.text = stockName
        stockNameLabel.font = UIFont.boldSystemFont(ofSize: 17)
        stockNameLabel.textColor = .black
        customNavBar.addSubview(stockNameLabel)
        stockNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票代码
        stockCodeLabel.text = "[\(stockCode)]"
        stockCodeLabel.font = UIFont.systemFont(ofSize: 12)
        stockCodeLabel.textColor = Constants.Color.textSecondary
        customNavBar.addSubview(stockCodeLabel)
        stockCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 搜索按钮
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.tintColor = .black
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        customNavBar.addSubview(searchButton)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 客服按钮
        let serviceButton = UIButton(type: .system)
        serviceButton.setImage(UIImage(systemName: "headphones"), for: .normal)
        serviceButton.tintColor = .black
        serviceButton.addTarget(self, action: #selector(serviceTapped), for: .touchUpInside)
        customNavBar.addSubview(serviceButton)
        serviceButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            customNavBar.topAnchor.constraint(equalTo: view.topAnchor),
            customNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavBar.heightAnchor.constraint(equalToConstant: Constants.Navigation.totalNavigationHeight),
            
            timeLabel.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor, constant: 16),
            timeLabel.topAnchor.constraint(equalTo: customNavBar.topAnchor, constant: Constants.Navigation.statusBarHeight + 4),
            
            backButton.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor, constant: Constants.Navigation.statusBarHeight / 2),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            stockNameLabel.centerXAnchor.constraint(equalTo: customNavBar.centerXAnchor),
            stockNameLabel.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor, constant: Constants.Navigation.statusBarHeight / 2),
            
            stockCodeLabel.centerXAnchor.constraint(equalTo: customNavBar.centerXAnchor),
            stockCodeLabel.topAnchor.constraint(equalTo: stockNameLabel.bottomAnchor, constant: 2),
            
            searchButton.trailingAnchor.constraint(equalTo: customNavBar.trailingAnchor, constant: -16),
            searchButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor, constant: Constants.Navigation.statusBarHeight / 2),
            searchButton.widthAnchor.constraint(equalToConstant: 44),
            searchButton.heightAnchor.constraint(equalToConstant: 44),
            
            serviceButton.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -4),
            serviceButton.centerYAnchor.constraint(equalTo: searchButton.centerYAnchor),
            serviceButton.widthAnchor.constraint(equalToConstant: 44),
            serviceButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: customNavBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupOverviewSection() {
        contentView.addSubview(overviewContainer)
        overviewContainer.backgroundColor = .white
        overviewContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 价格
        priceLabel.text = String(format: "%.2f", currentPrice)
        priceLabel.font = UIFont.boldSystemFont(ofSize: 36)
        priceLabel.textColor = Constants.Color.stockRise
        overviewContainer.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 涨跌额
        changeLabel.text = String(format: "+%.2f", change)
        changeLabel.font = UIFont.systemFont(ofSize: 16)
        changeLabel.textColor = Constants.Color.stockRise
        overviewContainer.addSubview(changeLabel)
        changeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 涨跌幅
        changePercentLabel.text = String(format: "+%.2f%%", changePercent)
        changePercentLabel.font = UIFont.systemFont(ofSize: 16)
        changePercentLabel.textColor = Constants.Color.stockRise
        overviewContainer.addSubview(changePercentLabel)
        changePercentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 关键指标
        setupMetrics()
        
        NSLayoutConstraint.activate([
            overviewContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            overviewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overviewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            priceLabel.leadingAnchor.constraint(equalTo: overviewContainer.leadingAnchor, constant: 16),
            priceLabel.topAnchor.constraint(equalTo: overviewContainer.topAnchor, constant: 16),
            
            changeLabel.leadingAnchor.constraint(equalTo: priceLabel.trailingAnchor, constant: 12),
            changeLabel.bottomAnchor.constraint(equalTo: priceLabel.centerYAnchor, constant: -2),
            
            changePercentLabel.leadingAnchor.constraint(equalTo: changeLabel.trailingAnchor, constant: 8),
            changePercentLabel.centerYAnchor.constraint(equalTo: changeLabel.centerYAnchor),
            
            metricsContainer.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 16),
            metricsContainer.leadingAnchor.constraint(equalTo: overviewContainer.leadingAnchor, constant: 16),
            metricsContainer.trailingAnchor.constraint(equalTo: overviewContainer.trailingAnchor, constant: -16),
            metricsContainer.bottomAnchor.constraint(equalTo: overviewContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupMetrics() {
        overviewContainer.addSubview(metricsContainer)
        metricsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let metrics: [(String, String)] = [
            ("换手率", String(format: "%.2f%%", turnoverRate)),
            ("市盈率", String(format: "%.2f%%", peRatio)),
            ("今开", String(format: "%.2f", todayOpen)),
            ("昨收", String(format: "%.2f", yesterdayClose)),
            ("振幅", String(format: "%.2f%%", amplitude)),
            ("总市值", totalMarketCap),
            ("流动市值", circulatingMarketCap),
            ("最低", String(format: "%.2f", lowest)),
            ("最高", String(format: "%.2f", highest)),
            ("成交量", volume),
            ("成交额", turnover),
            ("市净率", String(format: "%.2f", pbRatio))
        ]
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        metricsContainer.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建3列布局
        var rowStackViews: [UIStackView] = []
        for i in 0..<4 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 16
            rowStackViews.append(rowStack)
            stackView.addArrangedSubview(rowStack)
        }
        
        for (index, metric) in metrics.enumerated() {
            let metricView = createMetricView(title: metric.0, value: metric.1)
            let column = index % 3
            let row = index / 3
            if row < rowStackViews.count {
                rowStackViews[row].addArrangedSubview(metricView)
            }
        }
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: metricsContainer.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: metricsContainer.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: metricsContainer.bottomAnchor)
        ])
    }
    
    private func createMetricView(title: String, value: String) -> UIView {
        let container = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = Constants.Color.textSecondary
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 12)
        valueLabel.textColor = Constants.Color.textPrimary
        container.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func setupChartSection() {
        contentView.addSubview(chartContainer)
        chartContainer.backgroundColor = .white
        chartContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 图表类型切换
        chartTypeSegmentedControl.selectedSegmentIndex = 0
        chartTypeSegmentedControl.addTarget(self, action: #selector(chartTypeChanged), for: .valueChanged)
        chartContainer.addSubview(chartTypeSegmentedControl)
        chartTypeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // 价格图表
        priceChartView.backgroundColor = .white
        chartContainer.addSubview(priceChartView)
        priceChartView.translatesAutoresizingMaskIntoConstraints = false
        
        // 成交量图表
        volumeChartView.backgroundColor = .white
        chartContainer.addSubview(volumeChartView)
        volumeChartView.translatesAutoresizingMaskIntoConstraints = false
        
        // 买卖五档
        setupOrderBook()
        
        NSLayoutConstraint.activate([
            chartContainer.topAnchor.constraint(equalTo: overviewContainer.bottomAnchor, constant: 16),
            chartContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            chartContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            chartContainer.heightAnchor.constraint(equalToConstant: 400),
            
            chartTypeSegmentedControl.topAnchor.constraint(equalTo: chartContainer.topAnchor, constant: 16),
            chartTypeSegmentedControl.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor, constant: 16),
            chartTypeSegmentedControl.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor, constant: -16),
            chartTypeSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            priceChartView.topAnchor.constraint(equalTo: chartTypeSegmentedControl.bottomAnchor, constant: 16),
            priceChartView.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor),
            priceChartView.trailingAnchor.constraint(equalTo: orderBookView.leadingAnchor, constant: -8),
            priceChartView.heightAnchor.constraint(equalToConstant: 200),
            
            volumeChartView.topAnchor.constraint(equalTo: priceChartView.bottomAnchor, constant: 8),
            volumeChartView.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor),
            volumeChartView.trailingAnchor.constraint(equalTo: orderBookView.leadingAnchor, constant: -8),
            volumeChartView.heightAnchor.constraint(equalToConstant: 100),
            
            orderBookView.topAnchor.constraint(equalTo: priceChartView.topAnchor),
            orderBookView.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor, constant: -16),
            orderBookView.widthAnchor.constraint(equalToConstant: 100),
            orderBookView.heightAnchor.constraint(equalToConstant: 308)
        ])
        
        // 添加图表绘制
        setupPriceChart()
        setupVolumeChart()
    }
    
    private func setupOrderBook() {
        chartContainer.addSubview(orderBookView)
        orderBookView.backgroundColor = .white
        orderBookView.translatesAutoresizingMaskIntoConstraints = false
        
        // 买卖五档数据
        let sellOrders: [(Double, Int)] = [
            (28.42, 245),
            (28.39, 69),
            (28.38, 68),
            (28.37, 146),
            (28.36, 96)
        ]
        
        let buyOrders: [(Double, Int)] = [
            (28.42, 245),
            (28.39, 69),
            (28.38, 68),
            (28.37, 146),
            (28.36, 96)
        ]
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.distribution = .fillEqually
        orderBookView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 卖盘
        for (index, order) in sellOrders.enumerated() {
            let orderView = createOrderView(price: order.0, quantity: order.1, isSell: true, level: index + 1)
            stackView.addArrangedSubview(orderView)
        }
        
        // 买盘
        for (index, order) in buyOrders.enumerated() {
            let orderView = createOrderView(price: order.0, quantity: order.1, isSell: false, level: index + 1)
            stackView.addArrangedSubview(orderView)
        }
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: orderBookView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: orderBookView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: orderBookView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: orderBookView.bottomAnchor)
        ])
    }
    
    private func createOrderView(price: Double, quantity: Int, isSell: Bool, level: Int) -> UIView {
        let container = UIView()
        
        let levelLabel = UILabel()
        levelLabel.text = isSell ? "卖\(level)" : "买\(level)"
        levelLabel.font = UIFont.systemFont(ofSize: 10)
        levelLabel.textColor = Constants.Color.textSecondary
        container.addSubview(levelLabel)
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let priceLabel = UILabel()
        priceLabel.text = String(format: "%.2f", price)
        priceLabel.font = UIFont.systemFont(ofSize: 10)
        priceLabel.textColor = isSell ? Constants.Color.stockRise : Constants.Color.stockFall
        container.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let quantityLabel = UILabel()
        quantityLabel.text = "\(quantity)"
        quantityLabel.font = UIFont.systemFont(ofSize: 10)
        quantityLabel.textColor = Constants.Color.textPrimary
        container.addSubview(quantityLabel)
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            levelLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            levelLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            levelLabel.widthAnchor.constraint(equalToConstant: 24),
            
            priceLabel.leadingAnchor.constraint(equalTo: levelLabel.trailingAnchor, constant: 4),
            priceLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            quantityLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            quantityLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            // 移除固定高度约束，让UIStackView的fillEqually自动分配
            // container.heightAnchor.constraint(equalToConstant: 20)
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])
        
        return container
    }
    
    private func setupPriceChart() {
        // 添加全屏按钮
        let fullScreenButton = UIButton(type: .system)
        fullScreenButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        fullScreenButton.tintColor = Constants.Color.textSecondary
        fullScreenButton.addTarget(self, action: #selector(showFullScreenChart), for: .touchUpInside)
        priceChartView.addSubview(fullScreenButton)
        fullScreenButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            fullScreenButton.trailingAnchor.constraint(equalTo: priceChartView.trailingAnchor, constant: -8),
            fullScreenButton.topAnchor.constraint(equalTo: priceChartView.topAnchor, constant: 8),
            fullScreenButton.widthAnchor.constraint(equalToConstant: 30),
            fullScreenButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // 绘制分时图
        drawPriceChart()
        
        // 添加价格和百分比刻度
        addChartLabels(to: priceChartView, isPriceChart: true)
    }
    
    private func setupVolumeChart() {
        // 绘制成交量柱状图
        drawVolumeChart()
        
        // 添加成交量刻度
        addChartLabels(to: volumeChartView, isPriceChart: false)
    }
    
    private func drawPriceChart() {
        // 清除旧的图层
        priceChartView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // 设置背景色（浅蓝色）
        priceChartView.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
        
        // 模拟分时数据点（从09:30到15:00，每5分钟一个点，共66个点）
        // 价格范围：16.85 - 29.53，基准价：23.19
        let basePrice: CGFloat = 23.19
        let minPrice: CGFloat = 16.85
        let maxPrice: CGFloat = 29.53
        let priceRange = maxPrice - minPrice
        
        // 生成更多数据点，模拟价格波动
        var dataPoints: [CGPoint] = []
        var maPoints: [CGPoint] = [] // 移动平均线数据点
        let pointCount = 66 // 从09:30到15:00，每5分钟一个点
        
        for i in 0..<pointCount {
            let x = CGFloat(i) / CGFloat(pointCount - 1)
            // 模拟价格波动：开始上涨，然后波动
            let normalizedY: CGFloat
            if i < 10 {
                // 开盘上涨
                normalizedY = 0.5 + CGFloat(i) * 0.02
            } else if i < 30 {
                // 大幅上涨
                normalizedY = 0.7 + sin(CGFloat(i) * 0.1) * 0.1
            } else if i < 50 {
                // 波动
                normalizedY = 0.6 + sin(CGFloat(i) * 0.15) * 0.15
            } else {
                // 回落
                normalizedY = 0.5 - CGFloat(i - 50) * 0.01
            }
            dataPoints.append(CGPoint(x: x, y: normalizedY))
            
            // 计算移动平均（平滑处理）
            if i == 0 {
                maPoints.append(CGPoint(x: x, y: normalizedY - 0.05))
            } else {
                let prevMA = maPoints[i - 1].y
                let newMA = prevMA * 0.9 + normalizedY * 0.1
                maPoints.append(CGPoint(x: x, y: newMA))
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let width = self.priceChartView.bounds.width
            let height = self.priceChartView.bounds.height
            
            // 绘制网格线
            self.drawGridLines(in: self.priceChartView, isPriceChart: true)
            
            // 绘制0%基准线（灰色虚线）
            let baseLineY = height * 0.5 // 中间位置
            let baseLine = CAShapeLayer()
            let baseLinePath = UIBezierPath()
            baseLinePath.move(to: CGPoint(x: 0, y: baseLineY))
            baseLinePath.addLine(to: CGPoint(x: width, y: baseLineY))
            baseLine.path = baseLinePath.cgPath
            baseLine.strokeColor = UIColor.gray.cgColor
            baseLine.lineWidth = 1.0
            baseLine.lineDashPattern = [4, 2]
            self.priceChartView.layer.addSublayer(baseLine)
            
            // 绘制移动平均线（橙色平滑线）
            let maPath = UIBezierPath()
            for (index, point) in maPoints.enumerated() {
                let x = point.x * width
                let y = (1 - point.y) * height
                
                if index == 0 {
                    maPath.move(to: CGPoint(x: x, y: y))
                } else {
                    maPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            let maLayer = CAShapeLayer()
            maLayer.path = maPath.cgPath
            maLayer.strokeColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0).cgColor // 橙色
            maLayer.fillColor = UIColor.clear.cgColor
            maLayer.lineWidth = 1.5
            maLayer.lineCap = .round
            maLayer.lineJoin = .round
            self.priceChartView.layer.addSublayer(maLayer)
            
            // 绘制分时线（浅蓝色）
            let path = UIBezierPath()
            for (index, point) in dataPoints.enumerated() {
                let x = point.x * width
                let y = (1 - point.y) * height
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.strokeColor = UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0).cgColor // 浅蓝色
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.lineWidth = 1.5
            shapeLayer.lineCap = .round
            shapeLayer.lineJoin = .round
            
            // 添加动画
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 1.5
            shapeLayer.add(animation, forKey: "drawLine")
            
            self.priceChartView.layer.addSublayer(shapeLayer)
        }
    }
    
    private func drawGridLines(in view: UIView, isPriceChart: Bool) {
        let width = view.bounds.width
        let height = view.bounds.height
        
        // 绘制水平网格线
        let horizontalLines = isPriceChart ? 5 : 3
        for i in 0..<horizontalLines {
            let y = CGFloat(i) * (height / CGFloat(horizontalLines - 1))
            let gridLine = CAShapeLayer()
            let gridPath = UIBezierPath()
            gridPath.move(to: CGPoint(x: 0, y: y))
            gridPath.addLine(to: CGPoint(x: width, y: y))
            gridLine.path = gridPath.cgPath
            gridLine.strokeColor = UIColor(white: 0.8, alpha: 0.5).cgColor
            gridLine.lineWidth = 0.5
            view.layer.addSublayer(gridLine)
        }
        
        // 绘制垂直网格线
        let verticalLines = 6
        for i in 0..<verticalLines {
            let x = CGFloat(i) * (width / CGFloat(verticalLines - 1))
            let gridLine = CAShapeLayer()
            let gridPath = UIBezierPath()
            gridPath.move(to: CGPoint(x: x, y: 0))
            gridPath.addLine(to: CGPoint(x: x, y: height))
            gridLine.path = gridPath.cgPath
            gridLine.strokeColor = UIColor(white: 0.8, alpha: 0.5).cgColor
            gridLine.lineWidth = 0.5
            view.layer.addSublayer(gridLine)
        }
    }
    
    private func drawVolumeChart() {
        // 清除旧的图层
        volumeChartView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // 设置背景色（浅蓝色）
        volumeChartView.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
        
        // 模拟成交量数据（66个点，对应分时图的每个时间点）
        var volumes: [(CGFloat, Bool)] = []
        let pointCount = 66
        
        // 生成更真实的成交量数据：开始高，然后波动
        for i in 0..<pointCount {
            let volume: CGFloat
            let isBuy: Bool
            
            if i < 20 {
                // 开盘时成交量高
                volume = CGFloat.random(in: 0.6...1.0)
                isBuy = true // 开盘多为买入
            } else if i < 40 {
                // 中期波动
                volume = CGFloat.random(in: 0.3...0.8)
                isBuy = Bool.random()
            } else {
                // 后期成交量较低
                volume = CGFloat.random(in: 0.2...0.6)
                isBuy = Bool.random()
            }
            volumes.append((volume, isBuy))
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let width = self.volumeChartView.bounds.width
            let height = self.volumeChartView.bounds.height
            
            // 绘制网格线
            self.drawGridLines(in: self.volumeChartView, isPriceChart: false)
            
            let barWidth = width / CGFloat(volumes.count) - 1
            
            // 绘制柱状图
            for (index, volume) in volumes.enumerated() {
                let barHeight = volume.0 * height
                let x = CGFloat(index) * (width / CGFloat(volumes.count)) + 0.5
                let y = height - barHeight
                
                let barPath = UIBezierPath(rect: CGRect(x: x, y: y, width: barWidth, height: barHeight))
                
                let shapeLayer = CAShapeLayer()
                shapeLayer.path = barPath.cgPath
                shapeLayer.fillColor = volume.1 ? Constants.Color.stockRise.cgColor : Constants.Color.stockFall.cgColor
                
                // 添加动画
                let animation = CABasicAnimation(keyPath: "path")
                animation.fromValue = UIBezierPath(rect: CGRect(x: x, y: height, width: barWidth, height: 0)).cgPath
                animation.toValue = barPath.cgPath
                animation.duration = 0.3
                animation.beginTime = CACurrentMediaTime() + Double(index) * 0.02
                shapeLayer.add(animation, forKey: "drawBar")
                
                self.volumeChartView.layer.addSublayer(shapeLayer)
            }
            
            // 计算并绘制成交量移动平均线（两条）
            var ma1Points: [CGPoint] = [] // 第一条移动平均线（深蓝色）
            var ma2Points: [CGPoint] = [] // 第二条移动平均线（浅蓝色/青色）
            
            for (index, volume) in volumes.enumerated() {
                let x = CGFloat(index) / CGFloat(volumes.count - 1) * width
                
                // 第一条MA（较短周期，更敏感）
                if index == 0 {
                    ma1Points.append(CGPoint(x: x, y: height - volume.0 * height))
                } else {
                    let prevMA1 = ma1Points[index - 1].y
                    let newMA1 = prevMA1 * 0.85 + (height - volume.0 * height) * 0.15
                    ma1Points.append(CGPoint(x: x, y: newMA1))
                }
                
                // 第二条MA（较长周期，更平滑）
                if index == 0 {
                    ma2Points.append(CGPoint(x: x, y: height - volume.0 * height))
                } else {
                    let prevMA2 = ma2Points[index - 1].y
                    let newMA2 = prevMA2 * 0.95 + (height - volume.0 * height) * 0.05
                    ma2Points.append(CGPoint(x: x, y: newMA2))
                }
            }
            
            // 绘制第一条移动平均线（深蓝色）
            let ma1Path = UIBezierPath()
            for (index, point) in ma1Points.enumerated() {
                if index == 0 {
                    ma1Path.move(to: point)
                } else {
                    ma1Path.addLine(to: point)
                }
            }
            
            let ma1Layer = CAShapeLayer()
            ma1Layer.path = ma1Path.cgPath
            ma1Layer.strokeColor = UIColor(red: 0.0, green: 0.3, blue: 0.8, alpha: 1.0).cgColor // 深蓝色
            ma1Layer.fillColor = UIColor.clear.cgColor
            ma1Layer.lineWidth = 1.0
            ma1Layer.lineCap = .round
            ma1Layer.lineJoin = .round
            self.volumeChartView.layer.addSublayer(ma1Layer)
            
            // 绘制第二条移动平均线（浅蓝色/青色）
            let ma2Path = UIBezierPath()
            for (index, point) in ma2Points.enumerated() {
                if index == 0 {
                    ma2Path.move(to: point)
                } else {
                    ma2Path.addLine(to: point)
                }
            }
            
            let ma2Layer = CAShapeLayer()
            ma2Layer.path = ma2Path.cgPath
            ma2Layer.strokeColor = UIColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0).cgColor // 浅蓝色/青色
            ma2Layer.fillColor = UIColor.clear.cgColor
            ma2Layer.lineWidth = 1.0
            ma2Layer.lineCap = .round
            ma2Layer.lineJoin = .round
            self.volumeChartView.layer.addSublayer(ma2Layer)
        }
    }
    
    private func addChartLabels(to view: UIView, isPriceChart: Bool) {
        // 清除旧的标签
        view.subviews.forEach { if $0 is UILabel { $0.removeFromSuperview() } }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if isPriceChart {
                // 左侧价格刻度（红色、灰色、绿色）
                let leftLabels: [(String, UIColor)] = [
                    ("29.53", Constants.Color.stockRise),  // 红色
                    ("23.19", UIColor.gray),                // 灰色（基准线）
                    ("16.85", Constants.Color.stockFall)     // 绿色
                ]
                for (index, labelData) in leftLabels.enumerated() {
                    let label = UILabel()
                    label.text = labelData.0
                    label.font = UIFont.systemFont(ofSize: 10)
                    label.textColor = labelData.1
                    label.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.8) // 半透明背景，避免遮挡
                    view.addSubview(label)
                    label.translatesAutoresizingMaskIntoConstraints = false
                    
                    let yPosition = CGFloat(index) * (view.bounds.height / CGFloat(max(leftLabels.count - 1, 1)))
                    NSLayoutConstraint.activate([
                        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
                        label.topAnchor.constraint(equalTo: view.topAnchor, constant: yPosition - 8)
                    ])
                }
                
                // 右侧百分比刻度（红色、灰色、绿色）
                let rightLabels: [(String, UIColor)] = [
                    ("27.34%", Constants.Color.stockRise),  // 红色
                    ("0%", UIColor.gray),                    // 灰色（基准线）
                    ("-27.34%", Constants.Color.stockFall)   // 绿色
                ]
                for (index, labelData) in rightLabels.enumerated() {
                    let label = UILabel()
                    label.text = labelData.0
                    label.font = UIFont.systemFont(ofSize: 10)
                    label.textColor = labelData.1
                    label.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.8) // 半透明背景
                    view.addSubview(label)
                    label.translatesAutoresizingMaskIntoConstraints = false
                    
                    let yPosition = CGFloat(index) * (view.bounds.height / CGFloat(max(rightLabels.count - 1, 1)))
                    NSLayoutConstraint.activate([
                        label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
                        label.topAnchor.constraint(equalTo: view.topAnchor, constant: yPosition - 8)
                    ])
                }
            } else {
                // 成交量刻度（左右两侧都显示）
                let labels = ["1万", "0"]
                for (index, text) in labels.enumerated() {
                    // 左侧标签
                    let leftLabel = UILabel()
                    leftLabel.text = text
                    leftLabel.font = UIFont.systemFont(ofSize: 10)
                    leftLabel.textColor = Constants.Color.textSecondary
                    leftLabel.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.8)
                    view.addSubview(leftLabel)
                    leftLabel.translatesAutoresizingMaskIntoConstraints = false
                    
                    // 右侧标签
                    let rightLabel = UILabel()
                    rightLabel.text = text
                    rightLabel.font = UIFont.systemFont(ofSize: 10)
                    rightLabel.textColor = Constants.Color.textSecondary
                    rightLabel.backgroundColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.8)
                    view.addSubview(rightLabel)
                    rightLabel.translatesAutoresizingMaskIntoConstraints = false
                    
                    let yPosition = CGFloat(index) * view.bounds.height
                    NSLayoutConstraint.activate([
                        leftLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
                        leftLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: yPosition - 8),
                        
                        rightLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
                        rightLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: yPosition - 8)
                    ])
                }
            }
        }
    }
    
    private func setupFundsSection() {
        contentView.addSubview(fundsContainer)
        fundsContainer.backgroundColor = .white
        fundsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "今日资金"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .black
        fundsContainer.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 饼图
        let pieChartView = UIView()
        pieChartView.backgroundColor = .white
        fundsContainer.addSubview(pieChartView)
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        
        // 流入流出详情
        let fundsStackView = UIStackView()
        fundsStackView.axis = .vertical
        fundsStackView.spacing = 12
        fundsContainer.addSubview(fundsStackView)
        fundsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let fundsData: [(String, String, Bool)] = [
            ("大单买入", "1.06亿", true),
            ("中单买入", "4931.48万", true),
            ("小单买入", "1084.71万", true),
            ("大单卖出", "1.06亿", false),
            ("中单卖出", "4931.48万", false),
            ("小单卖出", "1084.71万", false)
        ]
        
        for fund in fundsData {
            let fundView = createFundRow(title: fund.0, value: fund.1, isInflow: fund.2)
            fundsStackView.addArrangedSubview(fundView)
        }
        
        // 汇总信息
        let summaryContainer = UIView()
        fundsContainer.addSubview(summaryContainer)
        summaryContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let summaryData: [(String, String, Bool)] = [
            ("流入", "4560.61万", true),
            ("流出", "1558.56万", false),
            ("净值", "3002.05万", true)
        ]
        
        let summaryStackView = UIStackView()
        summaryStackView.axis = .horizontal
        summaryStackView.distribution = .fillEqually
        summaryStackView.spacing = 16
        summaryContainer.addSubview(summaryStackView)
        summaryStackView.translatesAutoresizingMaskIntoConstraints = false
        
        for summary in summaryData {
            let summaryView = createSummaryView(title: summary.0, value: summary.1, isPositive: summary.2)
            summaryStackView.addArrangedSubview(summaryView)
        }
        
        // 净流入柱状图
        let netFlowContainer = UIView()
        fundsContainer.addSubview(netFlowContainer)
        netFlowContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let netFlowTitleLabel = UILabel()
        netFlowTitleLabel.text = "净流入"
        netFlowTitleLabel.font = UIFont.systemFont(ofSize: 14)
        netFlowTitleLabel.textColor = Constants.Color.textPrimary
        netFlowContainer.addSubview(netFlowTitleLabel)
        netFlowTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let netFlowChartView = UIView()
        netFlowChartView.backgroundColor = .white
        netFlowContainer.addSubview(netFlowChartView)
        netFlowChartView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            fundsContainer.topAnchor.constraint(equalTo: chartContainer.bottomAnchor, constant: 16),
            fundsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            fundsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            fundsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            titleLabel.topAnchor.constraint(equalTo: fundsContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: fundsContainer.leadingAnchor, constant: 16),
            
            pieChartView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            pieChartView.centerXAnchor.constraint(equalTo: fundsContainer.centerXAnchor),
            pieChartView.widthAnchor.constraint(equalToConstant: 200),
            pieChartView.heightAnchor.constraint(equalToConstant: 200),
            
            fundsStackView.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 16),
            fundsStackView.leadingAnchor.constraint(equalTo: fundsContainer.leadingAnchor, constant: 16),
            fundsStackView.trailingAnchor.constraint(equalTo: fundsContainer.trailingAnchor, constant: -16),
            
            summaryContainer.topAnchor.constraint(equalTo: fundsStackView.bottomAnchor, constant: 16),
            summaryContainer.leadingAnchor.constraint(equalTo: fundsContainer.leadingAnchor, constant: 16),
            summaryContainer.trailingAnchor.constraint(equalTo: fundsContainer.trailingAnchor, constant: -16),
            summaryContainer.heightAnchor.constraint(equalToConstant: 60),
            
            summaryStackView.topAnchor.constraint(equalTo: summaryContainer.topAnchor),
            summaryStackView.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor),
            summaryStackView.trailingAnchor.constraint(equalTo: summaryContainer.trailingAnchor),
            summaryStackView.bottomAnchor.constraint(equalTo: summaryContainer.bottomAnchor),
            
            netFlowContainer.topAnchor.constraint(equalTo: summaryContainer.bottomAnchor, constant: 16),
            netFlowContainer.leadingAnchor.constraint(equalTo: fundsContainer.leadingAnchor, constant: 16),
            netFlowContainer.trailingAnchor.constraint(equalTo: fundsContainer.trailingAnchor, constant: -16),
            netFlowContainer.heightAnchor.constraint(equalToConstant: 100),
            netFlowContainer.bottomAnchor.constraint(equalTo: fundsContainer.bottomAnchor, constant: -16),
            
            netFlowTitleLabel.topAnchor.constraint(equalTo: netFlowContainer.topAnchor),
            netFlowTitleLabel.leadingAnchor.constraint(equalTo: netFlowContainer.leadingAnchor),
            
            netFlowChartView.topAnchor.constraint(equalTo: netFlowTitleLabel.bottomAnchor, constant: 8),
            netFlowChartView.leadingAnchor.constraint(equalTo: netFlowContainer.leadingAnchor),
            netFlowChartView.trailingAnchor.constraint(equalTo: netFlowContainer.trailingAnchor),
            netFlowChartView.bottomAnchor.constraint(equalTo: netFlowContainer.bottomAnchor)
        ])
        
        // 绘制饼图
        drawPieChart(in: pieChartView)
        
        // 绘制净流入柱状图
        drawNetFlowChart(in: netFlowChartView)
    }
    
    private func createSummaryView(title: String, value: String, isPositive: Bool) -> UIView {
        let container = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = Constants.Color.textSecondary
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.boldSystemFont(ofSize: 14)
        valueLabel.textColor = isPositive ? Constants.Color.stockRise : Constants.Color.stockFall
        container.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func drawPieChart(in view: UIView) {
        // 饼图数据：35.18%, 16.35%, 3.60%, 23.38%, 17.70%, 3.79%
        let segments: [(CGFloat, UIColor)] = [
            (0.3518, UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)),      // 红色
            (0.1635, UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)),     // 橙色
            (0.0360, UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)),     // 深橙色
            (0.2338, UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)),      // 深绿色
            (0.1770, UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0)),     // 中绿色
            (0.0379, UIColor(red: 0.0, green: 0.9, blue: 0.0, alpha: 1.0))      // 浅绿色
        ]
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
            let radius = min(view.bounds.width, view.bounds.height) / 2 - 20
            var startAngle: CGFloat = -CGFloat.pi / 2 // 从顶部开始
            
            for segment in segments {
                let endAngle = startAngle + segment.0 * 2 * CGFloat.pi
                
                let path = UIBezierPath()
                path.move(to: center)
                path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                path.close()
                
                let shapeLayer = CAShapeLayer()
                shapeLayer.path = path.cgPath
                shapeLayer.fillColor = segment.1.cgColor
                
                // 添加动画
                let animation = CABasicAnimation(keyPath: "path")
                let startPath = UIBezierPath()
                startPath.move(to: center)
                startPath.addArc(withCenter: center, radius: 0, startAngle: startAngle, endAngle: startAngle, clockwise: true)
                startPath.close()
                animation.fromValue = startPath.cgPath
                animation.toValue = path.cgPath
                animation.duration = 0.5
                animation.beginTime = CACurrentMediaTime() + Double(segments.firstIndex(where: { $0.0 == segment.0 }) ?? 0) * 0.1
                shapeLayer.add(animation, forKey: "drawSegment")
                
                view.layer.addSublayer(shapeLayer)
                startAngle = endAngle
            }
            
            // 添加中心文字
            let centerLabel = UILabel()
            centerLabel.text = "今日资金"
            centerLabel.font = UIFont.systemFont(ofSize: 14)
            centerLabel.textColor = Constants.Color.textPrimary
            centerLabel.textAlignment = .center
            view.addSubview(centerLabel)
            centerLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                centerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                centerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
    }
    
    private func drawNetFlowChart(in view: UIView) {
        // 净流入数据：大单 35593087, 中单 -4091780, 小单 -583219
        let netFlowData: [(String, Double, Bool)] = [
            ("大单", 35593087, true),
            ("中单", -4091780, false),
            ("小单", -583219, false)
        ]
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let width = view.bounds.width
            let height = view.bounds.height
            let maxValue = 40000000.0 // 最大值用于归一化
            let barWidth = (width - 32) / CGFloat(netFlowData.count) - 16
            
            for (index, data) in netFlowData.enumerated() {
                let normalizedValue = abs(data.1) / maxValue
                let barHeight = CGFloat(normalizedValue) * (height - 30)
                let x = 16 + CGFloat(index) * (width / CGFloat(netFlowData.count))
                let y = height - barHeight - 15
                
                let barPath = UIBezierPath(rect: CGRect(x: x, y: y, width: barWidth, height: barHeight))
                
                let shapeLayer = CAShapeLayer()
                shapeLayer.path = barPath.cgPath
                shapeLayer.fillColor = data.2 ? Constants.Color.stockFall.cgColor : Constants.Color.stockRise.cgColor
                
                // 添加标签
                let label = UILabel()
                label.text = data.0
                label.font = UIFont.systemFont(ofSize: 10)
                label.textColor = Constants.Color.textSecondary
                label.textAlignment = .center
                view.addSubview(label)
                label.translatesAutoresizingMaskIntoConstraints = false
                
                let valueLabel = UILabel()
                valueLabel.text = String(format: "%.0f", data.1)
                valueLabel.font = UIFont.systemFont(ofSize: 9)
                valueLabel.textColor = Constants.Color.textPrimary
                valueLabel.textAlignment = .center
                view.addSubview(valueLabel)
                valueLabel.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: x + barWidth / 2),
                    label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
                    
                    valueLabel.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: x + barWidth / 2),
                    valueLabel.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -2)
                ])
                
                // 添加动画
                let animation = CABasicAnimation(keyPath: "path")
                animation.fromValue = UIBezierPath(rect: CGRect(x: x, y: height - 15, width: barWidth, height: 0)).cgPath
                animation.toValue = barPath.cgPath
                animation.duration = 0.5
                animation.beginTime = CACurrentMediaTime() + Double(index) * 0.1
                shapeLayer.add(animation, forKey: "drawBar")
                
                view.layer.addSublayer(shapeLayer)
            }
        }
    }
    
    private func createFundRow(title: String, value: String, isInflow: Bool) -> UIView {
        let container = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = Constants.Color.textPrimary
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        valueLabel.textColor = isInflow ? Constants.Color.stockRise : Constants.Color.stockFall
        container.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return container
    }
    
    private func setupBottomBar() {
        view.addSubview(bottomBar)
        bottomBar.backgroundColor = .white
        bottomBar.layer.shadowColor = UIColor.black.cgColor
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomBar.layer.shadowRadius = 4
        bottomBar.layer.shadowOpacity = 0.1
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        
        // 买入按钮
        buyButton.setTitle("买入", for: .normal)
        buyButton.setTitleColor(.white, for: .normal)
        buyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        buyButton.backgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0)
        buyButton.layer.cornerRadius = 8
        buyButton.addTarget(self, action: #selector(buyTapped), for: .touchUpInside)
        bottomBar.addSubview(buyButton)
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 卖出按钮
        sellButton.setTitle("卖出", for: .normal)
        sellButton.setTitleColor(.white, for: .normal)
        sellButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        sellButton.backgroundColor = UIColor(red: 255/255, green: 152/255, blue: 0/255, alpha: 1.0)
        sellButton.layer.cornerRadius = 8
        sellButton.addTarget(self, action: #selector(sellTapped), for: .touchUpInside)
        bottomBar.addSubview(sellButton)
        sellButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 自选按钮
        favoriteButton.setTitle("自选", for: .normal)
        favoriteButton.setTitleColor(Constants.Color.orange, for: .normal)
        favoriteButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        favoriteButton.layer.borderWidth = 1
        favoriteButton.layer.borderColor = Constants.Color.orange.cgColor
        favoriteButton.layer.cornerRadius = 8
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        bottomBar.addSubview(favoriteButton)
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 60 + Constants.Navigation.safeAreaBottom),
            
            buyButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            buyButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            buyButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 48) / 3),
            buyButton.heightAnchor.constraint(equalToConstant: 44),
            
            sellButton.leadingAnchor.constraint(equalTo: buyButton.trailingAnchor, constant: 8),
            sellButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            sellButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 48) / 3),
            sellButton.heightAnchor.constraint(equalToConstant: 44),
            
            favoriteButton.leadingAnchor.constraint(equalTo: sellButton.trailingAnchor, constant: 8),
            favoriteButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            favoriteButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupData() {
        // 从后端获取基础价格信息
        fetchStockPrice()
        // 从东财公开接口获取详细行情数据（换手率、市盈率、五档等）
        fetchEastMoneyQuote()
    }
    
    // MARK: - 后端接口：获取股票当前价格
    private func fetchStockPrice() {
        guard !stockCode.isEmpty else { return }
        SecureNetworkManager.shared.request(
            api: "/api/stock/stockDetail",
            method: .get,
            params: ["code": stockCode]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any] else { return }
                
                if let price = data["now_price"] as? Double {
                    self.currentPrice = price
                }
                if let yc = data["yesterday_close"] as? Double {
                    self.yesterdayClose = yc
                    self.change = self.currentPrice - yc
                    self.changePercent = yc > 0 ? (self.change / yc * 100) : 0
                    self.isRising = self.change >= 0
                }
                self.updateOverview()
            case .failure(_): break
            }
        }
    }
    
    // MARK: - 东财公开接口：获取完整行情数据
    private func fetchEastMoneyQuote() {
        // 根据 exchange 推导 secid
        let marketId: String
        switch exchange {
        case "沪": marketId = "1"
        case "京": marketId = "0"
        default:   marketId = "0"  // 深
        }
        let secid = "\(marketId).\(stockCode)"
        
        // f31-f40: 买卖五档, f43:最高 f44:最低 f46:今开 f60:昨收
        // f47:成交量 f48:成交额 f168:换手率 f162:市盈率 f167:市净率
        // f116:总市值 f117:流通市值 f169:振幅
        let fields = "f43,f44,f46,f47,f48,f60,f116,f117,f162,f167,f168,f169,f31,f32,f33,f34,f35,f36,f37,f38,f39,f40,f170,f171"
        let urlStr = "https://push2.eastmoney.com/api/qt/stock/get?secid=\(secid)&fields=\(fields)&ut=fa5fd1943c7b386f172d6893dbfba10b"
        
        guard let url = URL(string: urlStr) else { return }
        var request = URLRequest(url: url)
        request.setValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any] else {
                return
            }
            DispatchQueue.main.async {
                // 价格相关（东财单位: 分 → 除以100，部分字段本身就是元）
                // 东财 push2 的 stock/get 返回值已是正常数值无需除 100
                if let high = d["f43"] as? Double, high > 0 { self.highest = high }
                if let low = d["f44"] as? Double, low > 0 { self.lowest = low }
                if let open = d["f46"] as? Double, open > 0 { self.todayOpen = open }
                if let yClose = d["f60"] as? Double, yClose > 0 { self.yesterdayClose = yClose }
                
                // 成交量/额
                if let vol = d["f47"] as? Double {
                    if vol >= 10000 {
                        self.volume = String(format: "%.2f万手", vol / 10000.0)
                    } else {
                        self.volume = String(format: "%.0f手", vol)
                    }
                }
                if let amount = d["f48"] as? Double {
                    if amount >= 100_000_000 {
                        self.turnover = String(format: "%.2f亿", amount / 100_000_000.0)
                    } else if amount >= 10_000 {
                        self.turnover = String(format: "%.2f万", amount / 10_000.0)
                    } else {
                        self.turnover = String(format: "%.0f", amount)
                    }
                }
                
                // 指标
                if let tr = d["f168"] as? Double { self.turnoverRate = tr }
                if let pe = d["f162"] as? Double { self.peRatio = pe }
                if let pb = d["f167"] as? Double { self.pbRatio = pb }
                if let amp = d["f169"] as? Double { self.amplitude = amp }
                
                // 市值
                if let totalMV = d["f116"] as? Double {
                    if totalMV >= 100_000_000 {
                        self.totalMarketCap = String(format: "%.2f亿", totalMV / 100_000_000.0)
                    } else if totalMV >= 10_000 {
                        self.totalMarketCap = String(format: "%.2f万", totalMV / 10_000.0)
                    } else {
                        self.totalMarketCap = String(format: "%.0f", totalMV)
                    }
                }
                if let circMV = d["f117"] as? Double {
                    if circMV >= 100_000_000 {
                        self.circulatingMarketCap = String(format: "%.2f亿", circMV / 100_000_000.0)
                    } else if circMV >= 10_000 {
                        self.circulatingMarketCap = String(format: "%.2f万", circMV / 10_000.0)
                    } else {
                        self.circulatingMarketCap = String(format: "%.0f", circMV)
                    }
                }
                
                // 更新 Overview 指标区域
                self.updateOverview()
                
                // 更新买卖五档
                // 卖5-卖1: f31/f32, f33/f34, f35/f36, f37/f38, f39/f40
                // 买1-买5: f170 之后... 实际上 push2 的五档字段：
                // 卖: f31(卖5价) f32(卖5量) f33(卖4价) f34(卖4量) f35(卖3价) f36(卖3量) f37(卖2价) f38(卖2量) f39(卖1价) f40(卖1量)
                // 买: 需要额外字段，通常五档在 push2 用不同的 fields
                // 这里仅更新卖盘部分，如果有数据的话
            }
        }.resume()
    }
    
    // MARK: - 更新 UI
    private func updateOverview() {
        // 更新价格
        priceLabel.text = String(format: "%.2f", currentPrice)
        
        // 更新涨跌额/幅
        let sign = change >= 0 ? "+" : ""
        changeLabel.text = String(format: "%@%.2f", sign, change)
        changePercentLabel.text = String(format: "%@%.2f%%", sign, changePercent)
        
        // 更新颜色
        let color = isRising ? Constants.Color.stockRise : Constants.Color.stockFall
        priceLabel.textColor = color
        changeLabel.textColor = color
        changePercentLabel.textColor = color
        
        // 更新指标网格
        let metrics: [(String, String)] = [
            ("换手率", String(format: "%.2f%%", turnoverRate)),
            ("市盈率", String(format: "%.2f", peRatio)),
            ("今开", String(format: "%.2f", todayOpen)),
            ("昨收", String(format: "%.2f", yesterdayClose)),
            ("振幅", String(format: "%.2f%%", amplitude)),
            ("总市值", totalMarketCap),
            ("流动市值", circulatingMarketCap),
            ("最低", String(format: "%.2f", lowest)),
            ("最高", String(format: "%.2f", highest)),
            ("成交量", volume),
            ("成交额", turnover),
            ("市净率", String(format: "%.2f", pbRatio))
        ]
        
        // 遍历 metricsContainer 中的 StackView，更新 valueLabel
        if let stackView = metricsContainer.subviews.first as? UIStackView {
            var metricIndex = 0
            for rowView in stackView.arrangedSubviews {
                if let rowStack = rowView as? UIStackView {
                    for cellView in rowStack.arrangedSubviews {
                        if metricIndex < metrics.count {
                            // cellView 中第二个子视图是 valueLabel
                            let labels = cellView.subviews.compactMap { $0 as? UILabel }
                            if labels.count >= 2 {
                                labels[1].text = metrics[metricIndex].1
                            }
                            metricIndex += 1
                        }
                    }
                }
            }
        }
    }
    
    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: Date())
    }
    
    private var hasDrawnCharts = false
    
    private func updateChartType() {
        // 切换图表类型时的动画
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self = self else { return }
            self.priceChartView.alpha = 0.3
            self.volumeChartView.alpha = 0.3
        }) { [weak self] _ in
            guard let self = self else { return }
            // 重新绘制图表
            self.drawPriceChart()
            self.drawVolumeChart()
            self.addChartLabels(to: self.priceChartView, isPriceChart: true)
            self.addChartLabels(to: self.volumeChartView, isPriceChart: false)
            
            UIView.animate(withDuration: 0.3) {
                self.priceChartView.alpha = 1.0
                self.volumeChartView.alpha = 1.0
            }
        }
    }
    
    @objc private func showFullScreenChart() {
        // 强制横屏
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        
        let fullScreenVC = FullScreenChartViewController()
        fullScreenVC.chartType = selectedChartType
        fullScreenVC.stockName = stockName
        fullScreenVC.stockCode = stockCode
        fullScreenVC.modalPresentationStyle = .fullScreen
        fullScreenVC.modalTransitionStyle = .crossDissolve
        present(fullScreenVC, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 布局完成后绘制图表（只初始化一次，避免重复添加图层）
        guard priceChartView.bounds.width > 0,
              volumeChartView.bounds.width > 0 else { return }
        
        if !hasDrawnCharts {
            hasDrawnCharts = true
            priceChartView.layoutIfNeeded()
            volumeChartView.layoutIfNeeded()
            drawPriceChart()
            drawVolumeChart()
            addChartLabels(to: priceChartView, isPriceChart: true)
            addChartLabels(to: volumeChartView, isPriceChart: false)
        }
    }
    
    // MARK: - Actions
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func serviceTapped() {
        SecureNetworkManager.shared.request(
            api: "/api/stock/getconfig",
            method: .get,
            params: [:]
        ) { result in
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      var kfUrl = data["kf_url"] as? String,
                      !kfUrl.isEmpty else {
                    DispatchQueue.main.async { Toast.show("获取客服地址失败") }
                    return
                }
                if !kfUrl.hasPrefix("http") { kfUrl = "https://" + kfUrl }
                guard let url = URL(string: kfUrl) else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.open(url)
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
    
    @objc private func chartTypeChanged() {
        selectedChartType = ChartType(rawValue: chartTypeSegmentedControl.selectedSegmentIndex) ?? .minute
    }
    
    @objc private func buyTapped() {
        let vc = StockTradeViewController()
        vc.stockName    = stockName
        vc.stockCode    = stockCode
        vc.exchange     = exchange
        vc.currentPrice = currentPrice
        vc.changeAmount  = Double(change >= 0 ? "+\(String(format: "%.2f", change))"
                                       : String(format: "%.2f", change)) ?? 0
        vc.changePercent = Double(changePercent >= 0 ? "+\(String(format: "%.2f", changePercent))"
                                              : String(format: "%.2f", changePercent)) ?? 0
        // 根据 exchange 推导完整 allcode
        let pfx: String
        switch exchange {
        case "沪": pfx = "sh"
        case "深": pfx = "sz"
        case "北", "京": pfx = "bj"
        default:   pfx = stockCode.count == 6 && (stockCode.hasPrefix("6")) ? "sh" : "sz"
        }
        vc.stockAllcode = "\(pfx)\(stockCode)"
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func sellTapped() {
        let vc = AccountTradeViewController()
        vc.stockName = stockName
        vc.stockCode = stockCode
        vc.exchange = exchange
        vc.currentPrice = String(format: "%.2f", currentPrice)
        vc.tradeType = .sell
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func favoriteTapped() {
        // TODO: 实现自选功能
        Toast.show("自选功能待实现")
    }
}

