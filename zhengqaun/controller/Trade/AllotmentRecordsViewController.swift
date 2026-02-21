//
//  AllotmentRecordsViewController.swift
//  zhengqaun
//
//  配售记录：入口为个人中心的"配售记录"按钮
//

import UIKit

/// 配售记录数据模型
struct AllotmentRecord {
    let exchange: String  // "深"、"沪"等
    let stockName: String // 公司名
    let stockCode: String // 代码
    let issuePrice: String // 发行价格 "¥ 21.93"
    let allotmentRate: String // 中签率 "0.00%"
    let totalIssued: String // 发行总数 "3671.6万股"
}

class AllotmentRecordsViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let navBlue = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0)
    
    // 数据源（后续可动态加载）
    private var records: [AllotmentRecord] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupTableView()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = navBlue
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "配售记录"
        gk_navLineHidden = true
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
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
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AllotmentRecordCell.self, forCellReuseIdentifier: "AllotmentRecordCell")
        
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
            AllotmentRecord(exchange: "深", stockName: "舒泰神", stockCode: "300204", issuePrice: "¥ 21.93", allotmentRate: "0.00%", totalIssued: "3671.6万股"),
            AllotmentRecord(exchange: "深", stockName: "舒泰神", stockCode: "300204", issuePrice: "¥ 21.93", allotmentRate: "0.00%", totalIssued: "3671.6万股"),
            AllotmentRecord(exchange: "深", stockName: "舒泰神", stockCode: "300204", issuePrice: "¥ 21.93", allotmentRate: "0.00%", totalIssued: "3671.6万股"),
            AllotmentRecord(exchange: "深", stockName: "舒泰神", stockCode: "300204", issuePrice: "¥ 21.93", allotmentRate: "0.00%", totalIssued: "3671.6万股")
        ]
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AllotmentRecordsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AllotmentRecordCell", for: indexPath) as! AllotmentRecordCell
        cell.configure(with: records[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120 // 根据卡片内容计算：16 + 32 + 12 + 24 + 4 + 20 + 16 = 124，取 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: 处理点击事件
    }
}

// MARK: - AllotmentRecordCell
class AllotmentRecordCell: UITableViewCell {
    
    private let cardView = UIView()
    private let exchangeLbl = UILabel()
    private let nameLbl = UILabel()
    private let codeLbl = UILabel()
    private let detailBtn = UIButton(type: .system)
    private let priceLbl = UILabel()
    private let rateLbl = UILabel()
    private let totalLbl = UILabel()
    private let priceTag = UILabel()
    private let rateTag = UILabel()
    private let totalTag = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 8
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOpacity = 0.08
        
        let pad: CGFloat = 16
        
        // 第一行：交易所标签（图标样式）
        exchangeLbl.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        exchangeLbl.textColor = .white
        exchangeLbl.textAlignment = .center
        exchangeLbl.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0) // 浅蓝色背景
        exchangeLbl.layer.cornerRadius = 4
        exchangeLbl.layer.masksToBounds = true
        cardView.addSubview(exchangeLbl)
        exchangeLbl.translatesAutoresizingMaskIntoConstraints = false
        
        nameLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        nameLbl.textColor = Constants.Color.textPrimary
        cardView.addSubview(nameLbl)
        nameLbl.translatesAutoresizingMaskIntoConstraints = false
        
        codeLbl.font = UIFont.systemFont(ofSize: 14)
        codeLbl.textColor = Constants.Color.textSecondary
        cardView.addSubview(codeLbl)
        codeLbl.translatesAutoresizingMaskIntoConstraints = false
        
        detailBtn.setTitle("详情+", for: .normal)
        detailBtn.setTitleColor(.systemRed, for: .normal)
        detailBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        cardView.addSubview(detailBtn)
        detailBtn.translatesAutoresizingMaskIntoConstraints = false
        
        // 第二行
        priceLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        priceLbl.textColor = Constants.Color.textPrimary
        priceLbl.textAlignment = .left
        cardView.addSubview(priceLbl)
        priceLbl.translatesAutoresizingMaskIntoConstraints = false
        
        rateLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        rateLbl.textColor = Constants.Color.textPrimary
        rateLbl.textAlignment = .center
        cardView.addSubview(rateLbl)
        rateLbl.translatesAutoresizingMaskIntoConstraints = false
        
        totalLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        totalLbl.textColor = Constants.Color.textPrimary
        totalLbl.textAlignment = .right
        cardView.addSubview(totalLbl)
        totalLbl.translatesAutoresizingMaskIntoConstraints = false
        
        // 第三行
        priceTag.text = "发行价格"
        priceTag.font = UIFont.systemFont(ofSize: 12)
        priceTag.textColor = Constants.Color.textTertiary
        priceTag.textAlignment = .left
        cardView.addSubview(priceTag)
        priceTag.translatesAutoresizingMaskIntoConstraints = false
        
        rateTag.text = "中签率"
        rateTag.font = UIFont.systemFont(ofSize: 12)
        rateTag.textColor = Constants.Color.textTertiary
        rateTag.textAlignment = .center
        cardView.addSubview(rateTag)
        rateTag.translatesAutoresizingMaskIntoConstraints = false
        
        totalTag.text = "发行总数"
        totalTag.font = UIFont.systemFont(ofSize: 12)
        totalTag.textColor = Constants.Color.textTertiary
        totalTag.textAlignment = .right
        cardView.addSubview(totalTag)
        totalTag.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // 第一行
            exchangeLbl.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: pad),
            exchangeLbl.topAnchor.constraint(equalTo: cardView.topAnchor, constant: pad),
            exchangeLbl.widthAnchor.constraint(equalToConstant: 24),
            exchangeLbl.heightAnchor.constraint(equalToConstant: 24),
            
            nameLbl.leadingAnchor.constraint(equalTo: exchangeLbl.trailingAnchor, constant: 8),
            nameLbl.centerYAnchor.constraint(equalTo: exchangeLbl.centerYAnchor),
            
            codeLbl.leadingAnchor.constraint(equalTo: nameLbl.trailingAnchor, constant: 6),
            codeLbl.centerYAnchor.constraint(equalTo: exchangeLbl.centerYAnchor),
            
            detailBtn.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -pad),
            detailBtn.centerYAnchor.constraint(equalTo: exchangeLbl.centerYAnchor),
            
            // 第二行
            priceLbl.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: pad),
            priceLbl.topAnchor.constraint(equalTo: exchangeLbl.bottomAnchor, constant: 12),
            priceLbl.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 1.0/3.0, constant: -pad * 2),
            
            rateLbl.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            rateLbl.centerYAnchor.constraint(equalTo: priceLbl.centerYAnchor),
            rateLbl.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 1.0/3.0, constant: -pad * 2),
            
            totalLbl.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -pad),
            totalLbl.centerYAnchor.constraint(equalTo: priceLbl.centerYAnchor),
            totalLbl.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 1.0/3.0, constant: -pad * 2),
            
            // 第三行
            priceTag.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: pad),
            priceTag.topAnchor.constraint(equalTo: priceLbl.bottomAnchor, constant: 4),
            priceTag.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 1.0/3.0, constant: -pad * 2),
            
            rateTag.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            rateTag.centerYAnchor.constraint(equalTo: priceTag.centerYAnchor),
            rateTag.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 1.0/3.0, constant: -pad * 2),
            
            totalTag.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -pad),
            totalTag.centerYAnchor.constraint(equalTo: priceTag.centerYAnchor),
            totalTag.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 1.0/3.0, constant: -pad * 2),
            totalTag.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -pad)
        ])
    }
    
    func configure(with record: AllotmentRecord) {
        exchangeLbl.text = record.exchange
        nameLbl.text = record.stockName
        codeLbl.text = record.stockCode
        priceLbl.text = record.issuePrice
        rateLbl.text = record.allotmentRate
        totalLbl.text = record.totalIssued
    }
}
