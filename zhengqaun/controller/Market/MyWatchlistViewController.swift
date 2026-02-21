//
//  MyWatchlistViewController.swift
//  zhengqaun
//
//  首页「我的自选」列表，样式参考行情页自选模块
//

import UIKit

class MyWatchlistViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    /// 自选列表数据：(名称, 代码(含交易所), 最新价, 涨幅, 是否上涨)
    private var stocks: [(String, String, String, String, Bool)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = Constants.Color.themeBlue
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "我的自选"
        gk_navLineHidden = true
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = Constants.Color.backgroundMain
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.register(StockListTableViewCell.self, forCellReuseIdentifier: "WatchlistStockCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight + 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadData() {
        // 模拟自选数据，样式与行情页一致
        stocks = [
            ("舒泰神", "深 300204", "27.32", "-0.98%", false),
            ("中钢天源", "深 002057", "8.65", "-0.92%", false),
            ("芭薇股份", "京 837023", "6.28", "-0.63%", false),
            ("兴图新科", "沪 688081", "18.52", "+1.61%", true)
        ]
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension MyWatchlistViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1   // 整个列表用一个 StockListTableViewCell 承载
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WatchlistStockCell", for: indexPath) as! StockListTableViewCell
        cell.configure(with: stocks)
        cell.onStockTapped = { [weak self] name, code, exchange in
            guard let self = self else { return }
            let detailVC = StockDetailViewController()
            detailVC.stockName = name
            detailVC.stockCode = code
            detailVC.exchange = exchange
            detailVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 260
    }
}


