//
//  BlockTradingViewController.swift
//  zhengqaun
//
//  大宗交易：入口为首页的"大宗交易"按钮
//

import UIKit

/// 大宗交易数据模型
struct BlockTradingRecord {
    let stockName: String      // 股票名称，如"赛诺医疗"
    let exchange: String       // 交易所类型，如"深"、"沪"
    let stockCode: String      // 股票代码，如"688108"
    let currentPrice: String   // 现价，如"2259.23"
    let tradingPrice: String   // 交易价，如"22.59"
    let discountRate: String   // 折扣率，如"55.8"
}

class BlockTradingViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let navBlue = UIColor(red: 26/255, green: 81/255, blue: 185/255, alpha: 1.0) // #1A51B9
    
    // 数据源（后续可动态加载）
    private var records: [BlockTradingRecord] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupTableView()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "大宗交易"
        gk_navLineHidden = false
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
        gk_backStyle = .black
        
        // 右上角「交易记录」按钮
        let recordButton = UIButton(type: .system)
        recordButton.setTitle("交易记录", for: .normal)
        recordButton.setTitleColor(Constants.Color.textPrimary, for: .normal)
        recordButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        recordButton.addTarget(self, action: #selector(openTradingRecords), for: .touchUpInside)
        gk_navRightBarButtonItem = UIBarButtonItem(customView: recordButton)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    private func setupTableView() {
        let navH = Constants.Navigation.totalNavigationHeight
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .never // 防止系统自动调整contentInset
        tableView.contentInset = .zero // 确保没有额外的内边距
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BlockTradingHeaderView.self, forHeaderFooterViewReuseIdentifier: "BlockTradingHeaderView")
        tableView.register(BlockTradingCell.self, forCellReuseIdentifier: "BlockTradingCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func loadData() {
        // TODO: 从网络或本地加载数据
        // 示例数据
        records = [
            BlockTradingRecord(stockName: "赛诺医疗", exchange: "深", stockCode: "688108", currentPrice: "2259.23", tradingPrice: "22.59", discountRate: "55.8"),
            BlockTradingRecord(stockName: "赛诺医疗", exchange: "深", stockCode: "688108", currentPrice: "2259.23", tradingPrice: "22.59", discountRate: "55.8")
        ]
        tableView.reloadData()
    }
    
    /// 打开大宗交易记录列表
    @objc private func openTradingRecords() {
        let vc = BlockTradingListViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 显示买入弹窗
    private func showBuyAlert(for record: BlockTradingRecord) {
        let alert = BlockTradingBuyAlertView(record: record)
        alert.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(alert)
        
        NSLayoutConstraint.activate([
            alert.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            alert.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            alert.topAnchor.constraint(equalTo: view.topAnchor),
            alert.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension BlockTradingViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockTradingCell", for: indexPath) as! BlockTradingCell
        let record = records[indexPath.row]
        cell.configure(with: record)
        cell.onBuyTapped = { [weak self] in
            self?.showBuyAlert(for: record)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80 // 根据内容计算行高
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "BlockTradingHeaderView") as! BlockTradingHeaderView
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44 // 表头高度
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: 处理点击事件
    }
}

// MARK: - BlockTradingHeaderView (表头)
class BlockTradingHeaderView: UITableViewHeaderFooterView {
    
    private let stockNameLabel = UILabel()
    private let currentPriceLabel = UILabel()
    private let tradingPriceLabel = UILabel()
    private let discountRateLabel = UILabel()
    private let operationLabel = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0) // #F8F8F8
        
        let pad: CGFloat = 16
        
        stockNameLabel.text = "股票名称"
        stockNameLabel.font = UIFont.systemFont(ofSize: 14)
        stockNameLabel.textColor = Constants.Color.textPrimary
        stockNameLabel.textAlignment = .left
        contentView.addSubview(stockNameLabel)
        stockNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        currentPriceLabel.text = "现价"
        currentPriceLabel.font = UIFont.systemFont(ofSize: 14)
        currentPriceLabel.textColor = Constants.Color.textPrimary
        currentPriceLabel.textAlignment = .center
        contentView.addSubview(currentPriceLabel)
        currentPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        tradingPriceLabel.text = "交易价"
        tradingPriceLabel.font = UIFont.systemFont(ofSize: 14)
        tradingPriceLabel.textColor = Constants.Color.textPrimary
        tradingPriceLabel.textAlignment = .center
        contentView.addSubview(tradingPriceLabel)
        tradingPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        discountRateLabel.text = "折扣率(%)"
        discountRateLabel.font = UIFont.systemFont(ofSize: 14)
        discountRateLabel.textColor = Constants.Color.textPrimary
        discountRateLabel.textAlignment = .center
        contentView.addSubview(discountRateLabel)
        discountRateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        operationLabel.text = "操作"
        operationLabel.font = UIFont.systemFont(ofSize: 14)
        operationLabel.textColor = Constants.Color.textPrimary
        operationLabel.textAlignment = .right
        contentView.addSubview(operationLabel)
        operationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stockNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            stockNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stockNameLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.25),
            
            currentPriceLabel.leadingAnchor.constraint(equalTo: stockNameLabel.trailingAnchor),
            currentPriceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            currentPriceLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.18),
            
            tradingPriceLabel.leadingAnchor.constraint(equalTo: currentPriceLabel.trailingAnchor),
            tradingPriceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tradingPriceLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.18),
            
            discountRateLabel.leadingAnchor.constraint(equalTo: tradingPriceLabel.trailingAnchor),
            discountRateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            discountRateLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.19),
            
            operationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            operationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            operationLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.2)
        ])
    }
}

// MARK: - BlockTradingCell
class BlockTradingCell: UITableViewCell {
    
    private let stockNameLabel = UILabel()
    private let exchangeLabel = UILabel()
    private let stockCodeLabel = UILabel()
    private let currentPriceLabel = UILabel()
    private let tradingPriceLabel = UILabel()
    private let discountRateLabel = UILabel()
    private let buyButton = UIButton(type: .system)
    private let separatorLine = UIView()
    
    /// 买入按钮点击回调，由控制器设置
    var onBuyTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        
        let pad: CGFloat = 16
        
        // 股票名称列（左侧）
        stockNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        stockNameLabel.textColor = Constants.Color.textPrimary
        stockNameLabel.textAlignment = .left
        contentView.addSubview(stockNameLabel)
        stockNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 交易所标签（图标样式）
        exchangeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        exchangeLabel.textColor = .white
        exchangeLabel.textAlignment = .center
        exchangeLabel.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0) // 浅蓝色背景
        exchangeLabel.layer.cornerRadius = 4
        exchangeLabel.layer.masksToBounds = true
        contentView.addSubview(exchangeLabel)
        exchangeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票代码
        stockCodeLabel.font = UIFont.systemFont(ofSize: 13)
        stockCodeLabel.textColor = Constants.Color.textSecondary
        stockCodeLabel.textAlignment = .left
        contentView.addSubview(stockCodeLabel)
        stockCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 现价列（居中）
        currentPriceLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        currentPriceLabel.textColor = Constants.Color.textPrimary
        currentPriceLabel.textAlignment = .center
        contentView.addSubview(currentPriceLabel)
        currentPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 交易价列（居中）
        tradingPriceLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        tradingPriceLabel.textColor = Constants.Color.textPrimary
        tradingPriceLabel.textAlignment = .center
        contentView.addSubview(tradingPriceLabel)
        tradingPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 折扣率列（居中）
        discountRateLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        discountRateLabel.textColor = Constants.Color.textPrimary
        discountRateLabel.textAlignment = .center
        contentView.addSubview(discountRateLabel)
        discountRateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 买入按钮（右侧）
        buyButton.setTitle("买入", for: .normal)
        buyButton.setTitleColor(.white, for: .normal)
        buyButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        buyButton.backgroundColor = UIColor(red: 26/255, green: 81/255, blue: 185/255, alpha: 1.0) // 导航栏蓝色
        buyButton.layer.cornerRadius = 4
        buyButton.addTarget(self, action: #selector(buyButtonTapped), for: .touchUpInside)
        contentView.addSubview(buyButton)
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 分隔线
        separatorLine.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // 浅灰色
        contentView.addSubview(separatorLine)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 股票名称列
            stockNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            stockNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stockNameLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.25),
            
            // 交易所标签和代码（在股票名称下方）
            exchangeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            exchangeLabel.topAnchor.constraint(equalTo: stockNameLabel.bottomAnchor, constant: 6),
            exchangeLabel.widthAnchor.constraint(equalToConstant: 15),
            exchangeLabel.heightAnchor.constraint(equalToConstant: 15),
            
            stockCodeLabel.leadingAnchor.constraint(equalTo: exchangeLabel.trailingAnchor, constant: 6),
            stockCodeLabel.centerYAnchor.constraint(equalTo: exchangeLabel.centerYAnchor),
            
            // 现价列
            currentPriceLabel.leadingAnchor.constraint(equalTo: stockNameLabel.trailingAnchor),
            currentPriceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            currentPriceLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.18),
            
            // 交易价列
            tradingPriceLabel.leadingAnchor.constraint(equalTo: currentPriceLabel.trailingAnchor),
            tradingPriceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tradingPriceLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.18),
            
            // 折扣率列
            discountRateLabel.leadingAnchor.constraint(equalTo: tradingPriceLabel.trailingAnchor),
            discountRateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            discountRateLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.19),
            
            // 买入按钮
            buyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            buyButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            buyButton.widthAnchor.constraint(equalToConstant: 53),
            buyButton.heightAnchor.constraint(equalToConstant: 30),
            
            // 分隔线
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func configure(with record: BlockTradingRecord) {
        stockNameLabel.text = record.stockName
        exchangeLabel.text = record.exchange
        stockCodeLabel.text = record.stockCode
        currentPriceLabel.text = record.currentPrice
        tradingPriceLabel.text = record.tradingPrice
        discountRateLabel.text = record.discountRate
    }
    
    @objc private func buyButtonTapped() {
        onBuyTapped?()
    }
}

// MARK: - 买入弹窗视图
/// 大宗交易买入弹窗：显示股票信息，可输入/调整买入数量
private class BlockTradingBuyAlertView: UIView, UITextFieldDelegate {
    
    private let containerView = UIView()
    
    private let stockNameValueLabel = UILabel()
    private let stockCodeValueLabel = UILabel()
    private let currentPriceValueLabel = UILabel()
    private let availableAmountValueLabel = UILabel()
    private let maxBuyValueLabel = UILabel()
    private let payAmountValueLabel = UILabel()
    
    private let minusButton = UIButton(type: .system)
    private let plusButton = UIButton(type: .system)
    private let quantityTextField = UITextField()
    
    // 简单的演示用数据：可用余额、最大可买按价格和一个固定总额计算
    private var currentPrice: Double = 0
    private var availableAmount: Double = 0
    private var maxBuyLots: Int = 0
    private var quantityLots: Int = 1 {
        didSet { updateAmountLabels() }
    }
    
    init(record: BlockTradingRecord) {
        super.init(frame: .zero)
        setupBackground()
        setupContainer()
        configure(with: record)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBackground() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }
    
    private func setupContainer() {
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24)
        ])
        
        func makeRow(title: String, valueLabel: UILabel) -> UIStackView {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = UIFont.systemFont(ofSize: 14)
            titleLabel.textColor = Constants.Color.textSecondary
            
            valueLabel.font = UIFont.systemFont(ofSize: 16)
            valueLabel.textColor = Constants.Color.textPrimary
            valueLabel.textAlignment = .right
            
            let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
            row.axis = .horizontal
            row.distribution = .fill
            titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            return row
        }
        
        stackView.addArrangedSubview(makeRow(title: "股票名称", valueLabel: stockNameValueLabel))
        stackView.addArrangedSubview(makeRow(title: "股票代码", valueLabel: stockCodeValueLabel))
        stackView.addArrangedSubview(makeRow(title: "当前价", valueLabel: currentPriceValueLabel))
        stackView.addArrangedSubview(makeRow(title: "可用余额", valueLabel: availableAmountValueLabel))
        stackView.addArrangedSubview(makeRow(title: "最大购买", valueLabel: maxBuyValueLabel))
        stackView.addArrangedSubview(makeRow(title: "支付金额", valueLabel: payAmountValueLabel))
        
        // 数量(手)行
        let qtyTitleLabel = UILabel()
        qtyTitleLabel.text = "数量(手)"
        qtyTitleLabel.font = UIFont.systemFont(ofSize: 14)
        qtyTitleLabel.textColor = Constants.Color.textSecondary
        
        minusButton.setTitle("－", for: .normal)
        minusButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        minusButton.setTitleColor(Constants.Color.textPrimary, for: .normal)
        minusButton.layer.cornerRadius = 4
        minusButton.layer.borderWidth = 1
        minusButton.layer.borderColor = Constants.Color.separator.cgColor
        minusButton.addTarget(self, action: #selector(decreaseQuantity), for: .touchUpInside)
        
        plusButton.setTitle("＋", for: .normal)
        plusButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        plusButton.setTitleColor(Constants.Color.textPrimary, for: .normal)
        plusButton.layer.cornerRadius = 4
        plusButton.layer.borderWidth = 1
        plusButton.layer.borderColor = Constants.Color.separator.cgColor
        plusButton.addTarget(self, action: #selector(increaseQuantity), for: .touchUpInside)
        
        quantityTextField.font = UIFont.systemFont(ofSize: 16)
        quantityTextField.textAlignment = .center
        quantityTextField.keyboardType = .numberPad
        quantityTextField.layer.borderWidth = 1
        quantityTextField.layer.borderColor = Constants.Color.separator.cgColor
        quantityTextField.layer.cornerRadius = 4
        quantityTextField.delegate = self
        quantityTextField.addTarget(self, action: #selector(quantityChanged), for: .editingChanged)
        quantityTextField.widthAnchor.constraint(equalToConstant: 60).isActive = true
        quantityTextField.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        minusButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        minusButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        plusButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        plusButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        let qtyControlStack = UIStackView(arrangedSubviews: [minusButton, quantityTextField, plusButton])
        qtyControlStack.axis = .horizontal
        qtyControlStack.spacing = 12
        qtyControlStack.alignment = .center
        
        let qtyRow = UIStackView(arrangedSubviews: [qtyTitleLabel, qtyControlStack])
        qtyRow.axis = .horizontal
        qtyRow.distribution = .fill
        qtyTitleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        stackView.addArrangedSubview(qtyRow)
        
        // 按钮行
        let buttonsStack = UIStackView()
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 16
        buttonsStack.distribution = .fillEqually
        containerView.addSubview(buttonsStack)
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(Constants.Color.stockRise, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelButton.layer.cornerRadius = 20
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = Constants.Color.stockRise.cgColor
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        confirmButton.backgroundColor = Constants.Color.stockRise
        confirmButton.layer.cornerRadius = 20
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        buttonsStack.addArrangedSubview(cancelButton)
        buttonsStack.addArrangedSubview(confirmButton)
        
        NSLayoutConstraint.activate([
            buttonsStack.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 24),
            buttonsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            buttonsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            buttonsStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            confirmButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func configure(with record: BlockTradingRecord) {
        stockNameValueLabel.text = record.stockName
        stockCodeValueLabel.text = record.stockCode
        currentPriceValueLabel.text = record.tradingPrice
        
        // 简单模拟：可用余额固定一个值，最大购买 = 可用余额 / 交易价 / 100（按手计算）
        currentPrice = Double(record.tradingPrice) ?? 0
        availableAmount = 79475.82
        if currentPrice > 0 {
            let lots = Int(availableAmount / (currentPrice * 100))
            maxBuyLots = max(lots, 0)
        } else {
            maxBuyLots = 0
        }
        
        availableAmountValueLabel.text = String(format: "%.2f", availableAmount)
        maxBuyValueLabel.text = "\(maxBuyLots)"
        
        quantityLots = 2
        quantityTextField.text = "\(quantityLots)"
    }
    
    private func updateAmountLabels() {
        let pay = currentPrice * Double(quantityLots) * 100
        payAmountValueLabel.text = String(format: "%.2f", pay)
    }
    
    // MARK: - Actions
    @objc private func decreaseQuantity() {
        if quantityLots > 1 {
            quantityLots -= 1
            quantityTextField.text = "\(quantityLots)"
        }
    }
    
    @objc private func increaseQuantity() {
        if maxBuyLots > 0 {
            quantityLots = min(quantityLots + 1, maxBuyLots)
            quantityTextField.text = "\(quantityLots)"
        } else {
            quantityLots += 1
            quantityTextField.text = "\(quantityLots)"
        }
    }
    
    @objc private func quantityChanged() {
        let text = quantityTextField.text ?? ""
        let value = Int(text) ?? 0
        quantityLots = max(1, value)
        quantityTextField.text = "\(quantityLots)"
    }
    
    @objc private func cancelTapped() {
        removeFromSuperview()
    }
    
    @objc private func confirmTapped() {
        // 这里可以回调给外部，当前实现仅关闭弹窗
        removeFromSuperview()
    }
    
    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 仅允许数字输入
        if string.isEmpty { return true }
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
    }
}
