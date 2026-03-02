//
//  BlockTradingViewController.swift
//  zhengqaun
//
//  大宗交易（天启护盘）列表：对齐安卓 BlockTradeAdapter + BuyBlockTradeDialog
//

import UIKit

/// 大宗交易数据模型（对齐安卓 BlockTradeItem，兼容后端数字/字符串）
struct BlockTradingRecord {
    let id: Int
    let stockName: String      // title
    let exchange: String       // 市场标识：沪/深/创/京/科
    let stockCode: String      // code
    let allcode: String        // 完整代码如 sh688108
    let currentPrice: String   // 现价 cai_price
    let tradingPrice: String   // 交易价 cai_buy
    let discountRate: String   // 折扣率(%) rate
    let maxNum: Int            // 最大可买手数
    let type: Int              // 1沪 2深 3创业 4北交 5科创 6基金
    let rawData: [String: Any] // 原始数据
}

class BlockTradingViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private var records: [BlockTradingRecord] = []
    private var balance: Double = 0  // 可用余额
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupTableView()
        loadData()
        loadTitle()
    }
    
    /// 对齐安卓：从后端 getConfig 获取 dz_syname 作为页面标题
    private func loadTitle() {
        SecureNetworkManager.shared.request(
            api: "/api/stock/getconfig",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                if let dict = res.decrypted,
                   let data = dict["data"] as? [String: Any],
                   let name = data["dz_syname"] as? String,
                   !name.trimmingCharacters(in: .whitespaces).isEmpty {
                    DispatchQueue.main.async {
                        self.gk_navTitle = name.trimmingCharacters(in: .whitespaces)
                    }
                }
            case .failure(_): break
            }
        }
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
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = .zero
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
        
        // 空状态
        emptyLabel.text = "暂无数据"
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textColor = Constants.Color.textSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 加载指示器
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - 从 API 加载大宗交易列表（对齐安卓 /api/dzjy/lst）
    private func loadData() {
        loadingIndicator.startAnimating()
        emptyLabel.isHidden = true
        
        SecureNetworkManager.shared.request(
            api: "/api/dzjy/lst",
            method: .get,
            params: ["page": "1", "size": "50"]
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
            }
            
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        self.records = []
                        self.tableView.reloadData()
                        self.emptyLabel.isHidden = false
                    }
                    return
                }
                
                // 对齐安卓：兼容余额为数字或字符串
                let balanceVal = data["balance"]
                if let num = balanceVal as? NSNumber {
                    self.balance = num.doubleValue
                } else if let str = balanceVal as? String, let d = Double(str) {
                    self.balance = d
                } else {
                    self.balance = 0
                }
                
                var items: [BlockTradingRecord] = []
                for item in list {
                    // id 兼容
                    let idVal: Int
                    if let n = item["id"] as? Int { idVal = n }
                    else if let n = item["id"] as? NSNumber { idVal = n.intValue }
                    else { idVal = Int("\(item["id"] ?? "0")") ?? 0 }
                    
                    let title = item["title"] as? String ?? "--"
                    let code = item["code"] as? String ?? "--"
                    let allcode = item["allcode"] as? String ?? ""
                    let cai_price = item["cai_price"] as? String ?? "\(item["cai_price"] ?? "0")"
                    let cai_buy = item["cai_buy"] as? String ?? "\(item["cai_buy"] ?? "0")"
                    
                    // rate 兼容数字/字符串
                    let rate: Double
                    if let d = item["rate"] as? Double { rate = d }
                    else if let n = item["rate"] as? NSNumber { rate = n.doubleValue }
                    else if let s = item["rate"] as? String, let d = Double(s) { rate = d }
                    else { rate = 0 }
                    
                    // max_num 兼容数字/字符串（对齐安卓 maxNumInt()）
                    let maxNum: Int
                    if let n = item["max_num"] as? Int { maxNum = n }
                    else if let n = item["max_num"] as? NSNumber { maxNum = n.intValue }
                    else if let s = item["max_num"] as? String, let n = Int(s) { maxNum = n }
                    else { maxNum = 0 }
                    
                    // type
                    let typeVal: Int
                    if let n = item["type"] as? Int { typeVal = n }
                    else if let n = item["type"] as? NSNumber { typeVal = n.intValue }
                    else { typeVal = Int("\(item["type"] ?? "1")") ?? 1 }
                    
                    // 市场标识（对齐安卓 getMarketTag，北交所=京）
                    let exchange: String
                    switch typeVal {
                    case 1: exchange = "沪"
                    case 2: exchange = "深"
                    case 3: exchange = "创"
                    case 4: exchange = "京"
                    case 5: exchange = "科"
                    case 6: exchange = "基"
                    default: exchange = ""
                    }
                    
                    // 折扣率格式化（对齐安卓：整数不显示小数，否则保留两位）
                    let rateStr: String
                    if rate == Double(Int(rate)) {
                        rateStr = "\(Int(rate))"
                    } else {
                        rateStr = String(format: "%.2f", rate)
                    }
                    
                    items.append(BlockTradingRecord(
                        id: idVal,
                        stockName: title,
                        exchange: exchange,
                        stockCode: code,
                        allcode: allcode,
                        currentPrice: cai_price,
                        tradingPrice: cai_buy,
                        discountRate: rateStr,
                        maxNum: maxNum,
                        type: typeVal,
                        rawData: item
                    ))
                }
                
                DispatchQueue.main.async {
                    self.records = items
                    self.tableView.reloadData()
                    self.emptyLabel.isHidden = !items.isEmpty
                }
                
            case .failure(_):
                DispatchQueue.main.async {
                    self.records = []
                    self.tableView.reloadData()
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }
    
    /// 打开大宗交易记录列表
    @objc private func openTradingRecords() {
        let vc = BlockTradingListViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 显示买入弹窗（传入真实余额和最大可买数据）
    private func showBuyAlert(for record: BlockTradingRecord) {
        let alert = BlockTradingBuyAlertView(record: record, balance: balance)
        alert.onConfirm = { [weak self] quantity in
            self?.doBuyBlockTrade(record: record, quantity: quantity)
        }
        alert.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(alert)
        
        NSLayoutConstraint.activate([
            alert.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            alert.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            alert.topAnchor.constraint(equalTo: view.topAnchor),
            alert.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    /// 执行大宗买入（对齐安卓 POST api/dzjy/addStrategy_zfa）
    private func doBuyBlockTrade(record: BlockTradingRecord, quantity: Int) {
        loadingIndicator.startAnimating()
        SecureNetworkManager.shared.request(
            api: "/api/dzjy/addStrategy_zfa",
            method: .post,
            params: ["allcode": record.allcode, "canBuy": quantity]
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                switch result {
                case .success(let res):
                    if let dict = res.decrypted,
                       let code = dict["code"] as? NSNumber, code.intValue == 1 {
                        let msg = dict["msg"] as? String ?? "买入成功"
                        Toast.show(msg)
                        self.loadData() // 刷新列表
                    } else {
                        let msg = (res.decrypted?["msg"] as? String) ?? "买入失败，请重试"
                        Toast.show(msg)
                    }
                case .failure(_):
                    Toast.show("买入失败，请重试")
                }
            }
        }
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
        return 80
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "BlockTradingHeaderView") as! BlockTradingHeaderView
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - BlockTradingHeaderView (表头：股票名称/现价/交易价/折扣率(%)/操作)
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
        contentView.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        
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
        
        // 股票名称
        stockNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        stockNameLabel.textColor = Constants.Color.textPrimary
        stockNameLabel.textAlignment = .left
        contentView.addSubview(stockNameLabel)
        stockNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 市场标签
        exchangeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        exchangeLabel.textColor = .white
        exchangeLabel.textAlignment = .center
        exchangeLabel.backgroundColor = Constants.Color.stockRise
        exchangeLabel.layer.cornerRadius = 2
        exchangeLabel.layer.masksToBounds = true
        contentView.addSubview(exchangeLabel)
        exchangeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票代码
        stockCodeLabel.font = UIFont.systemFont(ofSize: 13)
        stockCodeLabel.textColor = Constants.Color.textSecondary
        stockCodeLabel.textAlignment = .left
        contentView.addSubview(stockCodeLabel)
        stockCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 现价
        currentPriceLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        currentPriceLabel.textColor = Constants.Color.textPrimary
        currentPriceLabel.textAlignment = .center
        contentView.addSubview(currentPriceLabel)
        currentPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 交易价
        tradingPriceLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        tradingPriceLabel.textColor = Constants.Color.textPrimary
        tradingPriceLabel.textAlignment = .center
        contentView.addSubview(tradingPriceLabel)
        tradingPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 折扣率
        discountRateLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        discountRateLabel.textColor = Constants.Color.textPrimary
        discountRateLabel.textAlignment = .center
        contentView.addSubview(discountRateLabel)
        discountRateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 买入按钮
        buyButton.setTitle("买入", for: .normal)
        buyButton.setTitleColor(.white, for: .normal)
        buyButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        buyButton.backgroundColor = Constants.Color.stockRise
        buyButton.layer.cornerRadius = 4
        buyButton.addTarget(self, action: #selector(buyButtonTapped), for: .touchUpInside)
        contentView.addSubview(buyButton)
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 分隔线
        separatorLine.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        contentView.addSubview(separatorLine)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stockNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            stockNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stockNameLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.25),
            
            exchangeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            exchangeLabel.topAnchor.constraint(equalTo: stockNameLabel.bottomAnchor, constant: 6),
            exchangeLabel.widthAnchor.constraint(equalToConstant: 15),
            exchangeLabel.heightAnchor.constraint(equalToConstant: 15),
            
            stockCodeLabel.leadingAnchor.constraint(equalTo: exchangeLabel.trailingAnchor, constant: 6),
            stockCodeLabel.centerYAnchor.constraint(equalTo: exchangeLabel.centerYAnchor),
            
            currentPriceLabel.leadingAnchor.constraint(equalTo: stockNameLabel.trailingAnchor),
            currentPriceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            currentPriceLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.18),
            
            tradingPriceLabel.leadingAnchor.constraint(equalTo: currentPriceLabel.trailingAnchor),
            tradingPriceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tradingPriceLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.18),
            
            discountRateLabel.leadingAnchor.constraint(equalTo: tradingPriceLabel.trailingAnchor),
            discountRateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            discountRateLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.19),
            
            buyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            buyButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            buyButton.widthAnchor.constraint(equalToConstant: 53),
            buyButton.heightAnchor.constraint(equalToConstant: 30),
            
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

// MARK: - 买入弹窗视图（对齐安卓 BuyBlockTradeDialog）
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
    
    private var tradingPrice: Double = 0
    private var availableAmount: Double = 0
    private var maxBuyLots: Int = 0
    private var quantityLots: Int = 1 {
        didSet { updateAmountLabels() }
    }
    
    /// 确认回调，传出购买手数
    var onConfirm: ((Int) -> Void)?
    
    init(record: BlockTradingRecord, balance: Double) {
        super.init(frame: .zero)
        setupBackground()
        setupContainer()
        configure(with: record, balance: balance)
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
        cancelButton.setTitleColor(Constants.Color.textSecondary, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelButton.layer.cornerRadius = 20
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(white: 0.85, alpha: 1.0).cgColor
        cancelButton.backgroundColor = .white
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
    
    private func configure(with record: BlockTradingRecord, balance: Double) {
        stockNameValueLabel.text = record.stockName
        stockCodeValueLabel.text = record.stockCode
        
        tradingPrice = Double(record.tradingPrice) ?? 0
        currentPriceValueLabel.text = record.currentPrice
        
        availableAmount = balance
        maxBuyLots = record.maxNum
        
        availableAmountValueLabel.text = String(format: "%.2f", availableAmount)
        maxBuyValueLabel.text = "\(maxBuyLots)"
        
        quantityLots = min(1, maxBuyLots)
        quantityTextField.text = "\(max(quantityLots, 1))"
        updateAmountLabels()
    }
    
    private func updateAmountLabels() {
        let pay = tradingPrice * Double(quantityLots) * 100
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
        } else {
            quantityLots += 1
        }
        quantityTextField.text = "\(quantityLots)"
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
        if quantityLots <= 0 {
            Toast.show("请输入购买数量")
            return
        }
        if maxBuyLots > 0 && quantityLots > maxBuyLots {
            Toast.show("超过最大可买数量")
            return
        }
        onConfirm?(quantityLots)
        removeFromSuperview()
    }
    
    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
    }
}
