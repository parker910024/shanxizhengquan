//
//  StockSearchViewController.swift
//  zhengqaun
//
//  股票搜索页面
//

import UIKit

/// 股票搜索结果数据模型
struct StockSearchResult {
    let exchange: String      // 交易所类型："深"、"沪"、"京"等
    let name: String          // 股票名称
    let code: String          // 股票代码
    let abbreviation: String  // 简拼
}

class StockSearchViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    // 搜索输入框
    private let searchBar = UIView()
    private let searchTextField = UITextField()
    
    // 股票列表表头
    private let listHeaderView = UIView()
    private let listTitleLabel = UILabel()
    
    // 空状态
    private let emptyStateView = UIView()
    private let emptyIcon = UIImageView()
    
    // 数据源（全部股票数据，用于搜索匹配）
    private let allStocks: [StockSearchResult] = [
        StockSearchResult(exchange: "深", name: "天溯计量", code: "301449", abbreviation: "TSJL"),
        StockSearchResult(exchange: "京", name: "江天科技", code: "920121", abbreviation: "JTKJ"),
        StockSearchResult(exchange: "沪", name: "超颖电子", code: "603175", abbreviation: "CYDZ"),
        StockSearchResult(exchange: "深", name: "天溯计量", code: "301449", abbreviation: "TSJL"),
        StockSearchResult(exchange: "京", name: "江天科技", code: "920121", abbreviation: "JTKJ"),
        StockSearchResult(exchange: "沪", name: "超颖电子", code: "603175", abbreviation: "CYDZ"),
        StockSearchResult(exchange: "深", name: "天溯计量", code: "301449", abbreviation: "TSJL"),
        StockSearchResult(exchange: "京", name: "江天科技", code: "920121", abbreviation: "JTKJ"),
        StockSearchResult(exchange: "沪", name: "超颖电子", code: "603175", abbreviation: "CYDZ"),
        StockSearchResult(exchange: "深", name: "天溯计量", code: "301449", abbreviation: "TSJL"),
        StockSearchResult(exchange: "京", name: "江天科技", code: "920121", abbreviation: "JTKJ"),
        StockSearchResult(exchange: "沪", name: "超颖电子", code: "603175", abbreviation: "CYDZ"),
        StockSearchResult(exchange: "深", name: "天溯计量", code: "301449", abbreviation: "TSJL"),
        StockSearchResult(exchange: "京", name: "江天科技", code: "920121", abbreviation: "JTKJ")
    ]
    
    // 搜索结果数据源（动态更新）
    private var searchResults: [StockSearchResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupTableView()
        setupHeaderView()
        setupEmptyState()
        updateUI()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0)
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "搜索"
        gk_navLineHidden = true
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // 浅灰色
    }
    
    private func setupTableView() {
        let navH = Constants.Navigation.totalNavigationHeight
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // 浅灰色背景
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StockSearchCell.self, forCellReuseIdentifier: "StockSearchCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupHeaderView() {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // 浅灰色背景
        
        // 搜索输入框（白色背景）
        searchBar.backgroundColor = .white
        searchBar.layer.cornerRadius = 8
        headerView.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        searchTextField.placeholder = "请输入股票代码/名称"
        searchTextField.font = UIFont.systemFont(ofSize: 14)
        searchTextField.textColor = Constants.Color.textPrimary
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextFieldDidChange), for: .editingChanged)
        searchBar.addSubview(searchTextField)
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // "股票列表"标题行（白色背景）
        listHeaderView.backgroundColor = .white
        headerView.addSubview(listHeaderView)
        listHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        listTitleLabel.text = "股票列表"
        listTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        listTitleLabel.textColor = Constants.Color.textPrimary
        listTitleLabel.textAlignment = .center
        listHeaderView.addSubview(listTitleLabel)
        listTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 表头标签（名称、代码、简拼）- 浅灰色背景，字体小一点
        let headerRowView = UIView()
        headerRowView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // 浅灰色背景
        headerView.addSubview(headerRowView)
        headerRowView.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = "名称"
        nameLabel.font = UIFont.systemFont(ofSize: 12) // 字体小一点
        nameLabel.textColor = Constants.Color.textPrimary
        nameLabel.textAlignment = .left
        headerRowView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let codeLabel = UILabel()
        codeLabel.text = "代码"
        codeLabel.font = UIFont.systemFont(ofSize: 12) // 字体小一点
        codeLabel.textColor = Constants.Color.textPrimary
        codeLabel.textAlignment = .center
        headerRowView.addSubview(codeLabel)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let abbreviationLabel = UILabel()
        abbreviationLabel.text = "简拼"
        abbreviationLabel.font = UIFont.systemFont(ofSize: 12) // 字体小一点
        abbreviationLabel.textColor = Constants.Color.textPrimary
        abbreviationLabel.textAlignment = .right
        headerRowView.addSubview(abbreviationLabel)
        abbreviationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 搜索框
            searchBar.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            searchBar.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 40),
            
            searchTextField.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: 12),
            searchTextField.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: -12),
            searchTextField.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            
            // "股票列表"标题行（白色背景）
            listHeaderView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            listHeaderView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            listHeaderView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            listHeaderView.heightAnchor.constraint(equalToConstant: 44),
            
            listTitleLabel.centerXAnchor.constraint(equalTo: listHeaderView.centerXAnchor),
            listTitleLabel.centerYAnchor.constraint(equalTo: listHeaderView.centerYAnchor),
            
            // 表头行（名称、代码、简拼）- 距离"股票列表"20pt，浅灰色背景
            headerRowView.topAnchor.constraint(equalTo: listHeaderView.bottomAnchor, constant: 10),
            headerRowView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerRowView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerRowView.heightAnchor.constraint(equalToConstant: 40),
            headerRowView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            nameLabel.leadingAnchor.constraint(equalTo: headerRowView.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: headerRowView.centerYAnchor),
            nameLabel.widthAnchor.constraint(equalTo: headerRowView.widthAnchor, multiplier: 0.4),
            
            codeLabel.centerXAnchor.constraint(equalTo: headerRowView.centerXAnchor),
            codeLabel.centerYAnchor.constraint(equalTo: headerRowView.centerYAnchor),
            codeLabel.widthAnchor.constraint(equalTo: headerRowView.widthAnchor, multiplier: 0.3),
            
            abbreviationLabel.trailingAnchor.constraint(equalTo: headerRowView.trailingAnchor, constant: -16),
            abbreviationLabel.centerYAnchor.constraint(equalTo: headerRowView.centerYAnchor),
            abbreviationLabel.widthAnchor.constraint(equalTo: headerRowView.widthAnchor, multiplier: 0.3)
        ])
        
        // 设置headerView高度：16 + 40 + 16 + 44 + 20 + 40 = 176
        headerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 176)
        tableView.tableHeaderView = headerView
    }
    
    private func setupEmptyState() {
        emptyStateView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // 浅灰色背景
        emptyStateView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 400)
        
        // 空状态图标（使用系统图标模拟空盒子）
        emptyIcon.image = UIImage(systemName: "tray")
        emptyIcon.tintColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        emptyIcon.contentMode = .scaleAspectFit
        emptyStateView.addSubview(emptyIcon)
        emptyIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emptyIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyIcon.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 80),
            emptyIcon.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        tableView.backgroundView = emptyStateView
    }
    
    private func updateUI() {
        // 无论是否有数据，都要刷新tableView
        tableView.reloadData()
        
        if searchResults.isEmpty {
            // 显示空状态
            tableView.backgroundView = emptyStateView
        } else {
            // 显示列表
            tableView.backgroundView = nil
        }
    }
    
    @objc private func searchTextFieldDidChange() {
        // 动态搜索
        performSearch()
    }
    
    private func performSearch() {
        guard let keyword = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !keyword.isEmpty else {
            // 输入框为空时清空tableview
            searchResults = []
            updateUI()
            return
        }
        
        // 动态匹配数据源：只匹配名称和代码，只要包含就显示
        searchResults = allStocks.filter { stock in
            // 匹配股票名称或代码（包含即显示）
            stock.name.contains(keyword) || stock.code.contains(keyword)
        }
        
        updateUI()
    }
}

// MARK: - UITextFieldDelegate
extension StockSearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        performSearch()
        return true
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension StockSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < searchResults.count else {
            return UITableViewCell()
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StockSearchCell", for: indexPath) as? StockSearchCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: searchResults[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < searchResults.count else { return }
        let result = searchResults[indexPath.row]
        
        // 跳转到行情详情页
        let detailVC = StockDetailViewController()
        detailVC.stockName = result.name
        detailVC.stockCode = result.code
        detailVC.exchange = result.exchange
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - StockSearchCell
class StockSearchCell: UITableViewCell {
    
    private let exchangeLabel = UILabel()
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let abbreviationLabel = UILabel()
    private let separatorLine = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        
        // 交易所标签（图标样式）
        exchangeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        exchangeLabel.textColor = .white
        exchangeLabel.textAlignment = .center
        exchangeLabel.layer.cornerRadius = 4
        exchangeLabel.layer.masksToBounds = true
        contentView.addSubview(exchangeLabel)
        exchangeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票名称
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.textColor = Constants.Color.textPrimary
        nameLabel.textAlignment = .left
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 股票代码
        codeLabel.font = UIFont.systemFont(ofSize: 15)
        codeLabel.textColor = Constants.Color.textPrimary
        codeLabel.textAlignment = .center
        contentView.addSubview(codeLabel)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 简拼
        abbreviationLabel.font = UIFont.systemFont(ofSize: 15)
        abbreviationLabel.textColor = Constants.Color.textPrimary
        abbreviationLabel.textAlignment = .right
        contentView.addSubview(abbreviationLabel)
        abbreviationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 分隔线
        separatorLine.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        contentView.addSubview(separatorLine)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            exchangeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            exchangeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            exchangeLabel.widthAnchor.constraint(equalToConstant: 15),
            exchangeLabel.heightAnchor.constraint(equalToConstant: 15),
            
            nameLabel.leadingAnchor.constraint(equalTo: exchangeLabel.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4, constant: -40),
            
            codeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            codeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            codeLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3),
            
            abbreviationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            abbreviationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            abbreviationLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.3),
            
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func configure(with result: StockSearchResult) {
        exchangeLabel.text = result.exchange
        
        // 根据交易所类型设置不同的背景色
        switch result.exchange {
        case "深":
            exchangeLabel.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0) // 浅蓝色
        case "沪":
            exchangeLabel.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.5, alpha: 1.0) // 浅橙色/红色
        case "京":
            exchangeLabel.backgroundColor = UIColor(red: 0.85, green: 0.7, blue: 1.0, alpha: 1.0) // 浅紫色
        default:
            exchangeLabel.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0) // 默认浅蓝色
        }
        
        nameLabel.text = result.name
        codeLabel.text = result.code
        abbreviationLabel.text = result.abbreviation
    }
}
