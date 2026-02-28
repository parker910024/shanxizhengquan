//
//  HomeViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit
import SafariServices

class HomeViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    // 顶部搜索栏容器（不在tableView内）
    private let topBarView = UIView()
    private let searchBar = UIView()
    private let searchTextField = UITextField()
    
    // 数据源（与 new UI 一致：2 行 x 5 列）
    private var bannerImages: [UIImage] = []
    /// Banner 图片链接（接口返回，可能多张）
    private var bannerUrls: [String] = []
    private var menuItems: [(String, String)] = [
        ("极速开户", "icon_home_1"),
        ("市场行情", "icon_home_7"),
        ("持仓记录", "icon2"),
        ("银证转入", "icon1"),
        ("银证转出", "icon11"),
        ("新股申购", "icon_home_6"),
        ("场外撮合交易", "icon_home_9"),
        ("线下配售", "icon12"),
        ("AI智投", "icon_home_13"),
        ("龙虎榜", "icon4")
    ]
    /// 原始菜单列表（用于开关过滤）
    private let allMenuItems: [(String, String)] = [
        ("极速开户", "icon_home_1"),
        ("市场行情", "icon_home_7"),
        ("持仓记录", "icon2"),
        ("银证转入", "icon1"),
        ("银证转出", "icon11"),
        ("新股申购", "icon_home_6"),
        ("场外撮合交易", "icon_home_9"),
        ("线下配售", "icon12"),
        ("AI智投", "icon_home_13"),
        ("龙虎榜", "icon4")
    ]

    /// 新股申购提醒弹框容器（每次进入首页显示）
    private var newStockReminderOverlay: UIView?
    /// 预加载的新闻数据
    private var preloadedNewsData: [[(String, String, String)]] = []
    /// 涨平跌家数
    private var riseCount = 0
    private var flatCount = 0
    private var fallCount = 0
    /// A股主力净流入（亿）
    private var mainFundFlowText = ""
    private var mainFundFlowPositive = false
    /// 今日大盘
    private var marketIndexName = ""
    private var marketIndexPrice = ""
    private var marketIndexChange = ""
    private var marketIndexPct = ""
    private var marketIndexIsDown = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // 加载市场数据（北向/南向 + 涨平跌 + 主力净流入）
        loadMarketData()
        // 今日大盘
        loadIndexMarket()
        showNewStockReminderPopupIfNeeded()
        // 中签弹窗
        loadBallotPopup()
        // 加载功能开关配置
        FeatureSwitchManager.shared.loadConfig()
        NotificationCenter.default.addObserver(self, selector: #selector(featureSwitchDidUpdate), name: FeatureSwitchManager.didUpdateNotification, object: nil)
        // 提前加载新闻数据
        preloadNewsData()
        
        SecureNetworkManager.shared.request(api: "/api/index/banner", method: .get, params: [:]) { res in
            switch res {
            case .success(let res):
                print("status =", res.statusCode)
                print("raw =", res.raw)          // 原始响应
                print("decrypted =", res.decrypted ?? "无法解密") // 解密后的明文（如果能解）
                let dict = res.decrypted
                print(dict ?? "nil")
                if dict?["code"] as? NSNumber != 1 {

                    DispatchQueue.main.async {
                        Toast.showInfo(dict?["msg"] as? String ?? "")
                    }
                    return
                }
                let dataArray = (dict?["data"] as? [String: Any])?["list"] as? [[String: Any]]
                guard let arr = dataArray else { return }
                let base = vpnDataModel.shared.selectAddress ?? ""
                let urls = arr.compactMap { dict -> String? in
                    guard let path = dict["image"] as? String, !path.isEmpty else { return nil }
                    return base + path
                }
                DispatchQueue.main.async { [weak self] in
                    self?.bannerUrls = urls
                    self?.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                }
            case .failure(let error):
                print("error =", error.localizedDescription)
                Toast.showError(error.localizedDescription)
            }
        }
    }

    /// 功能开关更新后刷新菜单
    @objc private func featureSwitchDidUpdate() {
        let mgr = FeatureSwitchManager.shared
        menuItems = allMenuItems
            .filter { item in
                if item.0 == "新股申购" && !mgr.isXgsgEnabled { return false }
                return true
            }
            .map { item in
                if item.0 == "线下配售" {
                    return (mgr.nameXxps, item.1)
                }
                if item.0 == "场外撮合交易" {
                    return (mgr.nameDzjy, item.1)
                }
                return item
            }
        tableView.reloadData()
    }

    /// 在 viewDidLoad 时提前加载新闻数据
    private func preloadNewsData() {
        // Tab 配置与安卓保持一致：动态/7X24/盘面/投顾/要闻
        let newsTypes = [
            ["type": "1", "name": "动态"],
            ["type": "2", "name": "7X24"],
            ["type": "3", "name": "盘面"],
            ["type": "3", "name": "投顾"],
            ["type": "4", "name": "要闻"],
        ]
        // 去重 type，避免重复请求
        let uniqueTypes = Array(Set(newsTypes.map { $0["type"] ?? "" }))
        let group = DispatchGroup()
        var allNews = [(String, String, String, String)]()
        for type in uniqueTypes {
            group.enter()
            SecureNetworkManager.shared.request(api: "/api/Indexnew/getGuoneinews", method: .get, params: ["page": "1", "size": "20", "type": type]) { res in
                defer { group.leave() }
                if case .success(let success) = res,
                   let root = success.decrypted?["data"] as? [String: Any],
                   let list = root["list"] as? [[String: Any]] {
                    for item in list {
                        let title = item["news_title"] as? String ?? ""
                        // 优先使用 news_time_text（友好时间），为空则回退 news_time
                        let timeText = item["news_time_text"] as? String ?? ""
                        let time = timeText.isEmpty ? (item["news_time"] as? String ?? "") : timeText
                        let content = item["news_content"] as? String ?? ""
                        allNews.append((type, title, time, content))
                    }
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            var result = [[(String, String, String)]]()
            for newsType in newsTypes {
                let t = newsType["type"] ?? ""
                result.append(allNews.filter { $0.0 == t }.map { ($0.1, $0.2, $0.3) })
            }
            self.preloadedNewsData = result
            // 刷新直击热点/盘面 (row 4) 和 新闻列表 (row 5)
            self.tableView.reloadRows(at: [
                IndexPath(row: 4, section: 0),
                IndexPath(row: 5, section: 0)
            ], with: .none)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    /// 每次进入首页请求新股申购提醒接口，有数据则弹框
    private func showNewStockReminderPopupIfNeeded() {
        guard newStockReminderOverlay == nil else { return }
        
        SecureNetworkManager.shared.request(
            api: Api.subscribe_api,
            method: .get,
            params: ["page": "1", "type": "0"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard res.statusCode == 200,
                      let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["list"] as? [[String: Any]],
                      !list.isEmpty else { return }
                
                DispatchQueue.main.async {
                    self.displayNewStockReminderPopup(with: Array(list.prefix(3)))
                }
            case .failure:
                break
            }
        }
    }

    private func displayNewStockReminderPopup(with list: [[String: Any]]) {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        newStockReminderOverlay = overlay

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.isUserInteractionEnabled = true
        overlay.addSubview(card)
        let cardBgImageView = UIImageView(image: UIImage(named: "tankuangbg"))
        cardBgImageView.contentMode = .scaleToFill
        cardBgImageView.clipsToBounds = true
        cardBgImageView.translatesAutoresizingMaskIntoConstraints = false
        // 降低优先级，防止背景图的固有尺寸撑大卡片
        cardBgImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        cardBgImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        cardBgImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        cardBgImageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        card.insertSubview(cardBgImageView, at: 0)
        NSLayoutConstraint.activate([
            cardBgImageView.topAnchor.constraint(equalTo: card.topAnchor),
            cardBgImageView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            cardBgImageView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            cardBgImageView.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "今日新股申购提醒"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        let bellImageView = UIImageView(image: UIImage(named: "lingdang"))
        bellImageView.contentMode = .scaleAspectFit
        bellImageView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(bellImageView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        for item in list {
            // 获取真实的股票数据：每个 item 可能包裹在 sub_info 数组的第一项里
            guard let subInfoArr = item["sub_info"] as? [[String: Any]],
                  let realItem = subInfoArr.first else { continue }
            
            let name   = realItem["name"] as? String ?? (realItem["title"] as? String ?? "")
            let code   = realItem["sgcode"] as? String ?? (realItem["code"] as? String ?? "")
            // 注意从 Any 中安全提取可能为 NSNumber 类型的金额
            let fx_price = realItem["fx_price"]
            let cai_buy  = realItem["cai_buy"]
            let priceVal = fx_price != nil ? "\(fx_price!)" : (cai_buy != nil ? "\(cai_buy!)" : "0")
            
            let sgTypeStr: String
            if let typeInt = realItem["sg_type"] as? Int {
                sgTypeStr = "\(typeInt)"
            } else if let typeStr = realItem["sg_type"] as? String {
                sgTypeStr = typeStr
            } else {
                sgTypeStr = "\(realItem["type"] ?? "")"
            }
            
            let market: String = {
                switch sgTypeStr { case "1": return "沪"; case "2": return "深"; case "3": return "创"; case "4": return "北"; case "5": return "科"; default: return "沪" }
            }()

            let row = makeNewStockReminderRow(exchange: market, code: code, name: name, price: "\(priceVal)/股")
            stack.addArrangedSubview(row)
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: stack.trailingAnchor)
            ])
        }

        let subscribeBtn = UIButton(type: .system)
        subscribeBtn.setTitle("去申购", for: .normal)
        subscribeBtn.setTitleColor(.white, for: .normal)
        subscribeBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        subscribeBtn.backgroundColor = UIColor(red: 0.9, green: 0.2, blue: 0.15, alpha: 1)
        subscribeBtn.layer.cornerRadius = 22
        subscribeBtn.addTarget(self, action: #selector(newStockReminderGoSubscribe), for: .touchUpInside)
        subscribeBtn.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(subscribeBtn)

        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.backgroundColor = UIColor(red: 0.55, green: 0.55, blue: 0.56, alpha: 1)
        closeBtn.layer.cornerRadius = 20
        closeBtn.addTarget(self, action: #selector(dismissNewStockReminderPopup), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(closeBtn)

        let cardW: CGFloat = 315
        let bellW: CGFloat = 136
        let bellH: CGFloat = 109
        let cardPadding: CGFloat = 20
        let titleTop: CGFloat = 24
        let titleToStack: CGFloat = 20
        let stackToBtn: CGFloat = 24
        let btnBottom: CGFloat = 24
        let closeBtnSize: CGFloat = 40
        let cardToClose: CGFloat = 16
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -20),
            card.widthAnchor.constraint(equalToConstant: cardW),
            // 不设固定高度，由内容自动撑开

            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPadding),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: titleTop),

            bellImageView.topAnchor.constraint(equalTo: card.topAnchor, constant: -20),
            bellImageView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: 20),
            bellImageView.widthAnchor.constraint(equalToConstant: bellW),
            bellImageView.heightAnchor.constraint(equalToConstant: bellH),

            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPadding),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -15),
            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: titleToStack),

            subscribeBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPadding),
            subscribeBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPadding),
            subscribeBtn.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: stackToBtn),
            subscribeBtn.heightAnchor.constraint(equalToConstant: 44),
            subscribeBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -btnBottom),

            closeBtn.topAnchor.constraint(equalTo: card.bottomAnchor, constant: cardToClose),
            closeBtn.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            closeBtn.widthAnchor.constraint(equalToConstant: closeBtnSize),
            closeBtn.heightAnchor.constraint(equalToConstant: closeBtnSize)
        ])
    }

    /// 列表每项：左侧两行（第一行 沪+代码，第二行 N至信），右侧价格相对两行上下居中
    private func makeNewStockReminderRow(exchange: String, code: String, name: String, price: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        let line1 = UIView()
        let badge = UILabel()
        badge.text = exchange
        badge.font = UIFont.systemFont(ofSize: 11)
        badge.textColor = .white
        badge.backgroundColor = Constants.Color.stockRise
        badge.layer.cornerRadius = 2
        badge.clipsToBounds = true
        badge.textAlignment = .center
        let codeLabel = UILabel()
        codeLabel.text = code
        codeLabel.font = UIFont.systemFont(ofSize: 14)
        codeLabel.textColor = Constants.Color.textSecondary
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.textColor = Constants.Color.textPrimary
        let priceLabel = UILabel()
        priceLabel.text = price
        priceLabel.font = UIFont.systemFont(ofSize: 14)
        priceLabel.textColor = Constants.Color.textSecondary
        priceLabel.textAlignment = .right
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.lineBreakMode = .byTruncatingTail
        line1.translatesAutoresizingMaskIntoConstraints = false
        badge.translatesAutoresizingMaskIntoConstraints = false
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        line1.addSubview(badge)
        line1.addSubview(codeLabel)
        row.addSubview(priceLabel)
        row.addSubview(line1)
        row.addSubview(nameLabel)
        let lineGap: CGFloat = 6
        NSLayoutConstraint.activate([
            priceLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            priceLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: row.leadingAnchor),
            line1.topAnchor.constraint(equalTo: row.topAnchor),
            line1.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            line1.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -12),
            line1.heightAnchor.constraint(equalToConstant: 20),
            badge.leadingAnchor.constraint(equalTo: line1.leadingAnchor),
            badge.centerYAnchor.constraint(equalTo: line1.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 18),
            badge.heightAnchor.constraint(equalToConstant: 16),
            codeLabel.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 6),
            codeLabel.centerYAnchor.constraint(equalTo: line1.centerYAnchor),
            codeLabel.trailingAnchor.constraint(lessThanOrEqualTo: line1.trailingAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: line1.bottomAnchor, constant: lineGap),
            nameLabel.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -12)
        ])
        return row
    }

    @objc private func dismissNewStockReminderPopup() {
        newStockReminderOverlay?.removeFromSuperview()
        newStockReminderOverlay = nil
    }

    @objc private func newStockReminderGoSubscribe() {
        dismissNewStockReminderPopup()
        let vc = NewStockSubscriptionViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func setupUI() {
        // 隐藏导航栏
        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = true
        self.gk_navigationBar.isHidden = true
        
        setupTopBar()
        setupTableView()
    }
    
    private func setupTopBar() {
        view.addSubview(topBarView)
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        // 与 Banner 图 logo 区域深蓝一致，适配白字/图标
        topBarView.backgroundColor = .red // #1C3B5C
        
        // 搜索栏
        searchBar.backgroundColor = .white
        searchBar.layer.cornerRadius = 20
        topBarView.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        // 搜索图标
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        searchBar.addSubview(searchIcon)
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // 搜索文本框
        let placeholderText = "输入股票代码/简拼"
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 14)
        ]
        searchTextField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: placeholderAttributes)
        searchTextField.font = UIFont.systemFont(ofSize: 14)
        searchTextField.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        searchTextField.isUserInteractionEnabled = false // 禁用输入，只能点击跳转
        searchBar.addSubview(searchTextField)
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击手势，点击搜索框跳转到搜索页面
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(searchBarTapped))
        searchBar.addGestureRecognizer(tapGesture)
        searchBar.isUserInteractionEnabled = true
        
        // 右侧图标
        let headphoneIcon = UIButton(type: .system)
        headphoneIcon.setImage(UIImage(systemName: "headphones"), for: .normal)
        headphoneIcon.tintColor = .white
        headphoneIcon.addTarget(self, action: #selector(openCustomerService), for: .touchUpInside)
        topBarView.addSubview(headphoneIcon)
        headphoneIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let messageIcon = UIButton(type: .system)
        messageIcon.setImage(UIImage(systemName: "envelope"), for: .normal)
        messageIcon.tintColor = .white
        messageIcon.addTarget(self, action: #selector(messageIconTapped), for: .touchUpInside)
        topBarView.addSubview(messageIcon)
        messageIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topBarView.topAnchor.constraint(equalTo: view.topAnchor),
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBarView.heightAnchor.constraint(equalToConstant: 56 + Constants.Navigation.safeAreaTop),
            
            searchBar.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.safeAreaTop),
            searchBar.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor, constant: -80),
            searchBar.heightAnchor.constraint(equalToConstant: 40),
            
            searchIcon.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: 12),
            searchIcon.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),
            
            searchTextField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 8),
            searchTextField.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: -12),
            searchTextField.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            
            headphoneIcon.leadingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: 12),
            headphoneIcon.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            headphoneIcon.widthAnchor.constraint(equalToConstant: 25),
            headphoneIcon.heightAnchor.constraint(equalToConstant: 24),
            
            messageIcon.leadingAnchor.constraint(equalTo: headphoneIcon.trailingAnchor, constant: 10),
            messageIcon.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            messageIcon.widthAnchor.constraint(equalToConstant: 25),
            messageIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    @objc private func openCustomerService() {
//        guard let url = URL(string: "https://www.htsc.com.cn") else { return }
//        let vc = SFSafariViewController(url: url)
//        present(vc, animated: true)
        // 从配置接口获取客服 URL
        SecureNetworkManager.shared.request(
            api: "/api/stock/getconfig",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      var kfUrl = data["kf_url"] as? String,
                      !kfUrl.isEmpty else {
                    DispatchQueue.main.async { Toast.show("获取客服地址失败") }
                    return
                }
                // 补全协议头
                if !kfUrl.hasPrefix("http") {
                    kfUrl = "https://" + kfUrl
                }
                guard let url = URL(string: kfUrl) else { return }
                DispatchQueue.main.async {
                   let safari = SFSafariViewController(url: url)
                    self.navigationController?.present(safari, animated: true)
                }
            case .failure(_):
                DispatchQueue.main.async { Toast.show("获取客服地址失败") }
            }
        }
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        
        // 注册cell
        tableView.register(BannerTableViewCell.self, forCellReuseIdentifier: "BannerCell")
        tableView.register(MenuGridTableViewCell.self, forCellReuseIdentifier: "MenuGridCell")
        tableView.register(ImageBannerTableViewCell.self, forCellReuseIdentifier: "ImageBannerCell")
        tableView.register(FundFlowTableViewCell.self, forCellReuseIdentifier: "FundFlowCell")
        tableView.register(HotSpotMarketTableViewCell.self, forCellReuseIdentifier: "HotSpotMarketCell")
        tableView.register(NewsTableViewCell.self, forCellReuseIdentifier: "NewsCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func messageIconTapped() {
        let vc = MessageCenterViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func searchBarTapped() {
        let vc = StockSearchViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 根据标题获取新闻内容（示例方法，实际应该从服务器获取）
    private func getNewsContent(for title: String) -> String {
        // 返回提供的HTML内容
//        return "<div class=\"txtinfos\" id=\"ContentBody\" style=\"margin-top:0;\">\n                            \n                                <!--文章主体-->\n<p>　　沪指本周累计涨0.13%，深证成指跌0.58%，创业板指跌1.25%。A股后市怎么走？看看机构怎么说：</p ><p>　　<strong>①<span id=\"stock_1.600030\"><a target=\"_blank\" href= \"http://quote.eastmoney.com/unify/r/1.600030\" class=\"keytip\" data-code=\"1,600030\">中信证券</a ></span><span id=\"quote_1.600030\"></span>：开年后市场震荡向上的概率更高</strong></p ><p>　　<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.600030\" class=\"em_stock_key_common\" data-code=\"1,600030\">中信证券</span>表示，考虑到去年末的资金热度并不算高，人心思涨的环境下开年后市场震荡向上的概率更高。前期共识性品种调整后再上车大概率是机构资金主要的考虑方向，例如有色、海外算力、<span id=\"bk_90.BK1036\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK1036\" class=\"keytip\" data-code=\"90,BK1036\">半导体</a ></span><span id=\"bkquote_90.BK1036\"></span>自主可控等，有些偏游资风格的品种也属于这一类别，比如<span id=\"bk_90.BK0963\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0963\" class=\"keytip\" data-code=\"90,BK0963\">商业航天</a ></span><span id=\"bkquote_90.BK0963\"></span>、<span id=\"stock_0.300024\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/0.300024\" class=\"keytip\" data-code=\"0,300024\">机器人</a ></span><span id=\"quote_0.300024\"></span>等。免税、航空等出行服务相关行业应是增量布局重点，优质的地产开发商也是考虑对象。中期维度下，更青睐一些热度和持仓集中度相对较低，但关注度开始提升、催化开始增多且长期ROE有提升空间的板块，如化工、<span id=\"bk_90.BK0739\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0739\" class=\"keytip\" data-code=\"90,BK0739\">工程机械</a ></span><span id=\"bkquote_90.BK0739\"></span>、电力设备及<span id=\"bk_90.BK0493\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0493\" class=\"keytip\" data-code=\"90,BK0493\">新能源</a ></span><span id=\"bkquote_90.BK0493\"></span>等，对高景气、高热度但是股价滞涨的板块则相对谨慎。同时，一些新的产业题材（如<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0963\" class=\"em_stock_key_common\" data-code=\"90,BK0963\">商业航天</span>）可能还会反复演绎，值得持续关注。</p ><p>　　<strong>②<span id=\"stock_1.601059\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601059\" class=\"keytip\" data-code=\"1,601059\">信达证券</a ></span><span id=\"quote_1.601059\"></span>：春季行情可能缓步启动</strong></p ><p>　　<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601059\" class=\"em_stock_key_common\" data-code=\"1,601059\">信达证券</span>表示，春节前流动性环境大概率较好，市场可能继续偏强，但1月可能会有一些波动。这一次春节前市场位置不低，此前经验来看，交易量下降到低位后恢复初期通常是缓涨。本次春季行情可能是缓步启动，后续指数突破需要验证经济数据等能否继续加速。资金层面，当前<span id=\"bk_90.BK0474\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0474\" class=\"keytip\" data-code=\"90,BK0474\">保险</a ></span><span id=\"bkquote_90.BK0474\"></span>、私募等机构资金仍有较强的补仓动力，短期在演绎产业趋势强或者催化较多的主题，但主题行情的持续性需要验证实际的订单或业绩。</p ><p>　　<strong>③<span id=\"stock_1.601788\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601788\" class=\"keytip\" data-code=\"1,601788\">光大证券</a ></span><span id=\"quote_1.601788\"></span>：消费与成长有望成为春季行情的两条主线</strong></p ><p>　　<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601788\" class=\"em_stock_key_common\" data-code=\"1,601788\">光大证券</span>表示，当前来看，2025年12月下旬的上涨或许是本轮春季行情起点。对于1月份指数的行情，投资者或许应该保持耐心。消费与成长有望成为今年春季行情的两条主线。1月行业配置方面，关注电子、电力设备、<span id=\"bk_90.BK0478\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0478\" class=\"keytip\" data-code=\"90,BK0478\">有色金属</a ></span><span id=\"bkquote_90.BK0478\"></span>、汽车等。若市场风格为成长，五维行业比较框架打分靠前的行业分别为电子、电力设备、通信、<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0478\" class=\"em_stock_key_common\" data-code=\"90,BK0478\">有色金属</span>、汽车、国防<span id=\"bk_90.BK0490\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0490\" class=\"keytip\" data-code=\"90,BK0490\">军工</a ></span><span id=\"bkquote_90.BK0490\"></span>；若1月份市场风格为防御，五维行业比较框架打分靠前的行业分别为非银金融、电子、<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0478\" class=\"em_stock_key_common\" data-code=\"90,BK0478\">有色金属</span>、电力设备、汽车、交通运输等。</p ><p>　　<strong>④<span id=\"stock_0.002670\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/0.002670\" class=\"keytip\" data-code=\"0,002670\">国盛证券</a ></span><span id=\"quote_0.002670\"></span>：配置趋势共识，博弈产业催化</strong></p ><p>　　<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/0.002670\" class=\"em_stock_key_common\" data-code=\"0,002670\">国盛证券</span>表示，大势层面，中期趋势依旧向上，短期保持交易思维。配置维度，当前科技与周期的双主线思维共识较强，宜重点围绕市场共识配置处于趋势中的资产，科技领域优先重点关注AI算力、<span id=\"bk_90.BK0989\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0989\" class=\"keytip\" data-code=\"90,BK0989\">储能</a ></span><span id=\"bkquote_90.BK0989\"></span>、<span id=\"bk_90.BK1137\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK1137\" class=\"keytip\" data-code=\"90,BK1137\">存储芯片</a ></span><span id=\"bkquote_90.BK1137\"></span>等，周期领域优先关注反内卷与涨价验证的交集方向，如有色、化工、钢铁等。交易维度，短期重点围绕产业催化参与，国内优先关注<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0963\" class=\"em_stock_key_common\" data-code=\"90,BK0963\">商业航天</span>、软件<span id=\"bk_90.BK1104\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK1104\" class=\"keytip\" data-code=\"90,BK1104\">信创</a ></span><span id=\"bkquote_90.BK1104\"></span>等；海外映射类优先关注<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/0.300024\" class=\"em_stock_key_common\" data-code=\"0,300024\">机器人</span>、<span id=\"bk_90.BK1037\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK1037\" class=\"keytip\" data-code=\"90,BK1037\">消费电子</a ></span><span id=\"bkquote_90.BK1037\"></span>、互联网传媒等AI应用端的催化反馈。</p ><p>　　<strong>⑤<span id=\"stock_1.601881\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601881\" class=\"keytip\" data-code=\"1,601881\">中国银河</a ></span><span id=\"quote_1.601881\"></span><span id=\"bk_90.BK0473\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0473\" class=\"keytip\" data-code=\"90,BK0473\">证券</a ></span><span id=\"bkquote_90.BK0473\"></span>：硬科技与消费共振，港股后市可期</strong></p ><p>　　<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601881\" class=\"em_stock_key_common\" data-code=\"1,601881\">中国银河</span><span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0473\" class=\"em_stock_key_common\" data-code=\"90,BK0473\">证券</span>表示，展望未来，在多重积极因素共振下，港股市场交投活跃度有望持续上升，预计港股整体震荡上行。配置方面，建议关注以下板块：（1）科技板块仍是中长期投资主线，在产业链涨价、并购重组等多重利好共振下，有望震荡上行。（2）消费板块有望持续受益于政策支持，且当前估值处于相对低位，中长期上涨空间较大，后续需关注政策落地力度及消费数据改善情况。</p ><p class=\"em_media\">（文章来源：第一财经）</p >                        </div>"
        return ""
    }
    
    var totalSouth = ""
    var totalNorth = ""

    // MARK: - 市场数据加载（北向/南向 + 涨平跌 + A股主力净流入）
    private func loadMarketData() {
        let group = DispatchGroup()

        // 1. 北向/南向资金（东方财富 kamt，直接 JSON 请求）
        group.enter()
        let kamtUrlStr = "https://push2delay.eastmoney.com/api/qt/kamt/get?fields1=f1,f2,f3,f4&fields2=f51,f52,f53,f54,f56,f62,f63,f65,f66"
        if let url = URL(string: kamtUrlStr) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                defer { group.leave() }
                guard let self = self, let data = data,
                      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let res = root["data"] as? [String: Any] else { return }
                // 北向 = 沪股通 + 深股通
                let hk2sh = res["hk2sh"] as? [String: Any]
                let hk2sz = res["hk2sz"] as? [String: Any]
                let northAmt = ((hk2sh?["netBuyAmt"] as? Double) ?? 0) + ((hk2sz?["netBuyAmt"] as? Double) ?? 0)
                self.totalNorth = String(format: "%.2f", northAmt / 10000.0)
                // 南向 = 港股通沪 + 港股通深
                let sh2hk = res["sh2hk"] as? [String: Any]
                let sz2hk = res["sz2hk"] as? [String: Any]
                let southAmt = ((sh2hk?["netBuyAmt"] as? Double) ?? 0) + ((sz2hk?["netBuyAmt"] as? Double) ?? 0)
                self.totalSouth = String(format: "%.2f", southAmt / 10000.0)
            }.resume()
        } else { group.leave() }

        // 2. 涨平跌分布（东方财富 clist 拉全 A 股涨跌幅并计算）
        group.enter()
        fetchAllStockChangePcts { [weak self] pcts in
            defer { group.leave() }
            guard let self = self else { return }
            var rise = 0; var fall = 0; var flat = 0
            for p in pcts {
                if p > 0 { rise += 1 }
                else if p < 0 { fall += 1 }
                else { flat += 1 }
            }
            self.riseCount = rise
            self.fallCount = fall
            self.flatCount = flat
        }

        // 3. A股主力净流入（东方财富 ulist f62 字段，元→亿）
        group.enter()
        let mainFundUrl = "https://push2delay.eastmoney.com/api/qt/ulist/get?fltt=2&invt=2&secids=1.000001,0.399001&fields=f62,f184"
        if let url = URL(string: mainFundUrl) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                defer { group.leave() }
                guard let self = self, let data = data,
                      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let dataObj = root["data"] as? [String: Any] else { return }
                let diff = self.parseDiffItems(dataObj["diff"])
                var totalYuan = 0.0
                for item in diff {
                    totalYuan += (item["f62"] as? Double) ?? 0
                }
                let yi = totalYuan / 100_000_000.0
                self.mainFundFlowPositive = totalYuan >= 0
                self.mainFundFlowText = (totalYuan < 0 ? "-" : "") + String(format: "%.2f亿", abs(yi))
            }.resume()
        } else { group.leave() }

        group.notify(queue: .main) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    /// 解析东方财富 diff 字段（兼容数组和字典两种格式）
    private func parseDiffItems(_ raw: Any?) -> [[String: Any]] {
        if let arr = raw as? [[String: Any]] { return arr }
        if let dict = raw as? [String: Any] {
            // 字典格式 {"0": {...}, "1": {...}}，提取所有值
            return dict.values.compactMap { $0 as? [String: Any] }
        }
        return []
    }

    /// 分页拉取全 A 股涨跌幅（东方财富 clist API）
    private func fetchAllStockChangePcts(completion: @escaping ([Double]) -> Void) {
        let pageSize = 5000
        let baseUrl = "https://push2delay.eastmoney.com/api/qt/clist/get?pn=1&pz=\(pageSize)&po=1&np=1&fltt=2&invt=2&fid=f3&fs=m:0+t:6,m:0+t:13,m:0+t:80,m:1+t:2,m:0+t:81&fields=f3,f12&ut=fa5fd1943c7b386f172d6893dbfba10b"
        guard let url = URL(string: baseUrl) else { completion([]); return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data,
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataObj = root["data"] as? [String: Any] else {
                completion([]); return
            }
            let diff = self.parseDiffItems(dataObj["diff"])
            if diff.isEmpty { completion([]); return }

            let total = (dataObj["total"] as? Int) ?? diff.count
            var pcts = diff.compactMap { $0["f3"] as? Double }
            let totalPages = (total + pageSize - 1) / pageSize
            if totalPages <= 1 { completion(pcts); return }

            let remainGroup = DispatchGroup()
            let lock = NSLock()
            for page in 2...totalPages {
                remainGroup.enter()
                let pageUrl = "https://push2delay.eastmoney.com/api/qt/clist/get?pn=\(page)&pz=\(pageSize)&po=1&np=1&fltt=2&invt=2&fid=f3&fs=m:0+t:6,m:0+t:13,m:0+t:80,m:1+t:2,m:0+t:81&fields=f3,f12&ut=fa5fd1943c7b386f172d6893dbfba10b"
                guard let u = URL(string: pageUrl) else { remainGroup.leave(); continue }
                URLSession.shared.dataTask(with: u) { [weak self] d, _, _ in
                    defer { remainGroup.leave() }
                    guard let self = self, let d = d,
                          let r = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                          let dd = r["data"] as? [String: Any] else { return }
                    let df = self.parseDiffItems(dd["diff"])
                    let pagePcts = df.compactMap { $0["f3"] as? Double }
                    lock.lock()
                    pcts.append(contentsOf: pagePcts)
                    lock.unlock()
                }.resume()
            }
            remainGroup.notify(queue: .global()) {
                completion(pcts)
            }
        }.resume()
    }

    // MARK: - 今日大盘（后端接口）
    private func loadIndexMarket() {
        SecureNetworkManager.shared.request(
            api: "/api/Indexnew/sandahangqing_new",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            if case .success(let res) = result,
               let dict = res.decrypted,
               let data = dict["data"] as? [String: Any],
               let list = data["list"] as? [[String: Any]],
               let first = list.first,
               let arr = first["allcodes_arr"] as? [String], arr.count >= 6 {
                self.marketIndexName = arr[1]
                self.marketIndexPrice = arr[3]
                self.marketIndexChange = arr[4]
                self.marketIndexPct = arr[5]
                self.marketIndexIsDown = arr[4].hasPrefix("-")
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [IndexPath(row: 4, section: 0)], with: .none)
                }
            }
        }
    }

    // MARK: - 中签弹窗
    private func loadBallotPopup() {
        SecureNetworkManager.shared.request(
            api: "/api/stock/ballot",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            if case .success(let res) = result,
               let dict = res.decrypted,
               let data = dict["data"] as? [String: Any],
               let infoArr = data["info"] as? [[String: Any]],
               !infoArr.isEmpty {
                let pending = infoArr.filter {
                    let syRenjiao = $0["sy_renjiao"] as? Double ?? 0
                    let renjiao = $0["renjiao"] as? String ?? "1"
                    return syRenjiao > 0 || renjiao == "0"
                }
                guard !pending.isEmpty else { return }
                let first = pending[0]
                let name = first["name"] as? String ?? ""
                let code = first["code"] as? String ?? ""
                let zqNums = first["zq_nums"] as? Int ?? 0
                let syRenjiao = first["sy_renjiao"] as? Double ?? 0
                let sgPrice = first["sg_fx_price"] as? Double ?? 0
                let zqNum = first["zq_num"] as? Int ?? 0
                let amount = syRenjiao > 0 ? syRenjiao : sgPrice * Double(zqNum)
                DispatchQueue.main.async {
                    self.showBallotPopup(name: name, code: code, quantity: "\(zqNums)手", amount: String(format: "￥%.2f", amount), count: pending.count)
                }
            }
        }
    }

    /// 显示中签弹窗
    private func showBallotPopup(name: String, code: String, quantity: String, amount: String, count: Int) {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(overlay)

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        overlay.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = "🎉 恭喜中签"
        titleLbl.font = .boldSystemFont(ofSize: 20)
        titleLbl.textAlignment = .center
        card.addSubview(titleLbl)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let infoLbl = UILabel()
        infoLbl.text = "\(name)(\(code))\n中签数量：\(quantity)\n待缴金额：\(amount)"
        if count > 1 { infoLbl.text! += "\n共 \(count) 只中签股票" }
        infoLbl.numberOfLines = 0
        infoLbl.font = .systemFont(ofSize: 15)
        infoLbl.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        infoLbl.textAlignment = .center
        card.addSubview(infoLbl)
        infoLbl.translatesAutoresizingMaskIntoConstraints = false

        let goBtn = UIButton(type: .system)
        goBtn.setTitle("去认缴", for: .normal)
        goBtn.titleLabel?.font = .boldSystemFont(ofSize: 16)
        goBtn.setTitleColor(.white, for: .normal)
        goBtn.backgroundColor = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1)
        goBtn.layer.cornerRadius = 22
        card.addSubview(goBtn)
        goBtn.translatesAutoresizingMaskIntoConstraints = false

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("关闭", for: .normal)
        closeBtn.setTitleColor(.gray, for: .normal)
        card.addSubview(closeBtn)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            card.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 40),
            card.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -40),
            titleLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            titleLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            infoLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 16),
            infoLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            infoLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            goBtn.topAnchor.constraint(equalTo: infoLbl.bottomAnchor, constant: 20),
            goBtn.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            goBtn.widthAnchor.constraint(equalToConstant: 180),
            goBtn.heightAnchor.constraint(equalToConstant: 44),
            closeBtn.topAnchor.constraint(equalTo: goBtn.bottomAnchor, constant: 10),
            closeBtn.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            closeBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        closeBtn.addAction(UIAction { _ in overlay.removeFromSuperview() }, for: .touchUpInside)
        goBtn.addAction(UIAction { [weak self] _ in
            overlay.removeFromSuperview()
            // 对齐安卓：跳转到我的新股页面，默认选中"中签" Tab
            let vc = MyNewStocksViewController()
            vc.initialTab = 1 // 1=中签
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
    }
}




extension NSDictionary {
    func safeValueForKey(_ key: String) -> Any? {
        var value: Any? = nil
        if allKeys.contains(where: { "\($0)" == key }) {
            value = object(forKey: key)
        }
        return value
    }
}

// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6 // Banner, MenuGrid, ImageBanner, 资金数据, 直击热点|涨平跌|今日大盘, News
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            // Banner轮播图（优先用接口返回的 URL，否则用本地图）
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerCell", for: indexPath) as! BannerTableViewCell
            if !bannerUrls.isEmpty {
                cell.configure(with: bannerUrls)
            } else {
                cell.configure(with: bannerImages)
            }
            cell.onBannerTap = { [weak self] _ in
//                let vc = RegisterViewController()
//                let nav = UINavigationController(rootViewController: vc)
//                nav.modalPresentationStyle = .fullScreen
//                self?.present(nav, animated: true)
            }
            return cell
        case 1:
            // 菜单网格
            let cell = tableView.dequeueReusableCell(withIdentifier: "MenuGridCell", for: indexPath) as! MenuGridTableViewCell
            cell.configure(with: menuItems)
            cell.onItemTap = { [weak self] index, title in
                let mgr = FeatureSwitchManager.shared
                // 龙虎榜是第 10 项（index 9），用索引兜底避免标题字符不一致导致无反应
                if index == 9 || title == "龙虎榜" {
                    let vc = LongHuBangViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                    return
                }
                
                if title == "新股申购" || (!mgr.nameXgsg.isEmpty && title == mgr.nameXgsg) {
                    let vc = NewStockSubscriptionViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                    return
                }
                
                switch title {
                case "极速开户":
                    // 对齐个人中心实名认证逻辑：先查询认证状态再决定跳转
                    Task { @MainActor in
                        do {
                            let userResult = try await SecureNetworkManager.shared.request(api: Api.user_info_api, method: .get, params: [:])
                            if let dict = userResult.decrypted, let data = dict["data"] as? [String: Any], let info = data["list"] as? [String: Any] {
                                let isAuth = info["is_auth"] as? Int ?? 0
                                if isAuth == 1 {
                                    // 已认证：跳转认证结果页
                                    let resultVC = RealNameAuthResultViewController()
                                    resultVC.hidesBottomBarWhenPushed = true
                                    self?.navigationController?.pushViewController(resultVC, animated: true)
                                    return
                                }
                            }
                            // 未认证：查询认证详情
                            let detailResult = try await SecureNetworkManager.shared.request(api: Api.authenticationDetail_api, method: .get, params: ["page": 1, "size": 10])
                            if let dict = detailResult.decrypted, let detail = dict["data"] as? [String: Any], let json = detail["detail"] {
                                if dict["msg"] as? String != "success" {
                                    Toast.showInfo(dict["msg"] as? String ?? "")
                                    return
                                }
                                let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
                                let model = try JSONDecoder().decode(AuthenticationDetailModel.self, from: jsonData)
                                if model.isAudit == "1" {
                                    let resultVC = RealNameAuthResultViewController()
                                    resultVC.name = model.name
                                    resultVC.idCard = "\(model.idCard)"
                                    resultVC.hidesBottomBarWhenPushed = true
                                    self?.navigationController?.pushViewController(resultVC, animated: true)
                                } else if model.isAudit == "3" {
                                    Toast.showInfo("审核中...")
                                } else {
                                    let vc = RealNameAuthViewController()
                                    vc.hidesBottomBarWhenPushed = true
                                    self?.navigationController?.pushViewController(vc, animated: true)
                                }
                            } else {
                                // 无认证记录：直接跳转认证页面
                                let vc = RealNameAuthViewController()
                                vc.hidesBottomBarWhenPushed = true
                                self?.navigationController?.pushViewController(vc, animated: true)
                            }
                        } catch {
                            // 请求失败：兜底跳转认证页面
                            let vc = RealNameAuthViewController()
                            vc.hidesBottomBarWhenPushed = true
                            self?.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                case "市场行情":
                    if let tabBar = self?.tabBarController, let vcs = tabBar.viewControllers, vcs.count > 1,
                       let marketNav = vcs[1] as? UINavigationController,
                       let marketVC = marketNav.viewControllers.first as? MarketViewController {
                        tabBar.selectedIndex = 1
                        marketVC.switchToTab(index: 0)
                    }
                case "持仓记录":
                    let vc = MyHoldingsViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                case "银证转入":
                    let vc = BankTransferIntroViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                case "银证转出":
                    let vc = BankTransferIntroViewController()
                    vc.initialTabIndex = 1 // 默认选中银证转出
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                case "场外撮合交易":
                    fallthrough
                case _ where !mgr.nameDzjy.isEmpty && title == mgr.nameDzjy:
                    // 对齐安卓：跳转到行情页面的天启护盘 tab（index 3）
                    if let tabBar = self?.tabBarController, let vcs = tabBar.viewControllers, vcs.count > 1,
                       let marketNav = vcs[1] as? UINavigationController,
                       let marketVC = marketNav.viewControllers.first as? MarketViewController {
                        tabBar.selectedIndex = 1
                        marketVC.switchToTab(index: 3)
                    }
                case "线下配售":
                    // 对齐安卓：跳转到行情页面的战略配售 tab（index 2）
                    if let tabBar = self?.tabBarController, let vcs = tabBar.viewControllers, vcs.count > 1,
                       let marketNav = vcs[1] as? UINavigationController,
                       let marketVC = marketNav.viewControllers.first as? MarketViewController {
                        tabBar.selectedIndex = 1
                        marketVC.switchToTab(index: 2)
                    }
                case "AI智投":
                    let vc = SmartStockSelectionViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                default:
                    break
                }
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageBannerCell", for: indexPath) as! ImageBannerTableViewCell
            cell.configure(with: [])
            cell.onBannerTap = { [weak self] _ in
                let vc = RegisterViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self?.present(nav, animated: true)
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FundFlowCell", for: indexPath) as! FundFlowTableViewCell
            cell.bindData(totalNorth, totalSouth, mainFund: mainFundFlowText, mainFundIsPositive: mainFundFlowPositive)
            return cell
        case 4:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "HotSpotMarketCell", for: indexPath) as! HotSpotMarketTableViewCell
            cell.onHotspotTap = { [weak self] in
                guard let self = self else { return }
                // 点击直击热点跳到当前 tab 第一条新闻详情
                if !self.preloadedNewsData.isEmpty, let firstNews = self.preloadedNewsData.first?.first {
                    let detailVC = NewsDetailViewController()
                    detailVC.htmlContent = firstNews.2
                    detailVC.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(detailVC, animated: true)
                }
            }
            // 绑定直击热点新闻（取第一条）
            if !preloadedNewsData.isEmpty, let firstNews = preloadedNewsData.first?.first {
                cell.bindHotspot(title: firstNews.0, time: firstNews.1)
            }
            // 绑定涨平跌和今日大盘数据
            cell.bindMarketData(rise: riseCount, flat: flatCount, fall: fallCount,
                                indexName: marketIndexName, indexPrice: marketIndexPrice,
                                indexChange: marketIndexChange, indexPct: marketIndexPct,
                                isDown: marketIndexIsDown)
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath) as! NewsTableViewCell
            cell.onNewsItemTapped = { [weak self] title, time, content in
                // 跳转到新闻详情页
                let detailVC = NewsDetailViewController()
                // 设置HTML内容（示例内容，实际应该根据title从服务器获取）
                // detailVC.htmlContent = self?.getNewsContent(for: title)
                detailVC.htmlContent = content
                detailVC.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(detailVC, animated: true)
            }
            cell.onNewsDataLoaded = { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadRows(at: [IndexPath(row: 5, section: 0)], with: .none)
            }
            // 如果已有预加载数据，直接绑定
            if !preloadedNewsData.isEmpty {
                cell.bindPreloadedData(preloadedNewsData)
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate
extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            // Banner 高度按屏幕宽度比例自适应，确保图片完整显示
            return UIScreen.main.bounds.width * 318.0 / 787.0
        case 1:
            return 188
        case 2:
            return 110 + 20
        case 3:
            return 64
        case 4:
            return 260
        case 5:
            return UITableView.automaticDimension
        default:
            return 44
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 5:
            return 320
        default:
            return 100
        }
    }
}

// MARK: - Banner Cell (轮播图)
class BannerTableViewCell: UITableViewCell {
    private let scrollView = UIScrollView()
    private var bannerViews: [UIImageView] = []
    private var autoScrollTimer: Timer?
    private var currentPage: Int = 0
    private var images: [UIImage] = []
    var onBannerTap: ((Int) -> Void)? // 点击回调
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopAutoScroll()
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.bounces = false
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(bannerTapped))
        scrollView.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    @objc private func bannerTapped() {
        onBannerTap?(currentPage)
    }
    
    func configure(with images: [UIImage]) {
        // 停止之前的定时器
        stopAutoScroll()
        
        // 清除旧的banner
        bannerViews.forEach { $0.removeFromSuperview() }
        bannerViews.removeAll()
        
        // 如果没有图片，创建一个默认的蓝色banner
        self.images = images.isEmpty ? [createDefaultBannerImage()] : images
        
        let screenWidth = UIScreen.main.bounds.width
        let bannerHeight = screenWidth * 318.0 / 787.0
        
        for (index, image) in self.images.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleToFill
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            scrollView.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: CGFloat(index) * screenWidth),
                imageView.widthAnchor.constraint(equalToConstant: screenWidth),
                imageView.heightAnchor.constraint(equalToConstant: bannerHeight),
                imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])
            
            bannerViews.append(imageView)
        }
        
        scrollView.contentSize = CGSize(width: screenWidth * CGFloat(self.images.count), height: bannerHeight)
        currentPage = 0
        
        // 如果有多张图片，启动自动滚动
        if self.images.count > 1 {
            startAutoScroll()
        }
    }

    /// 从 URL 加载 Banner（支持多张）
    func configure(with imageUrls: [String]) {
        stopAutoScroll()
        bannerViews.forEach { $0.removeFromSuperview() }
        bannerViews.removeAll()
        self.images = []

        guard !imageUrls.isEmpty else {
            configure(with: [UIImage]())
            return
        }

        let screenWidth = UIScreen.main.bounds.width
        let bannerHeight = screenWidth * 318.0 / 787.0
        let placeholder = createDefaultBannerImage()
        
        for (index, urlString) in imageUrls.enumerated() {
            let imageView = UIImageView(image: placeholder)
            imageView.contentMode = .scaleToFill
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            scrollView.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: CGFloat(index) * screenWidth),
                imageView.widthAnchor.constraint(equalToConstant: screenWidth),
                imageView.heightAnchor.constraint(equalToConstant: bannerHeight),
                imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])
            bannerViews.append(imageView)

            guard let url = URL(string: urlString) else { continue }
            URLSession.shared.dataTask(with: url) { [weak imageView] data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    imageView?.image = img
                }
            }.resume()
        }

        self.images = [UIImage](repeating: placeholder, count: imageUrls.count)
        scrollView.contentSize = CGSize(width: screenWidth * CGFloat(imageUrls.count), height: bannerHeight)
        currentPage = 0
        if imageUrls.count > 1 {
            startAutoScroll()
        }
    }
    
    private func startAutoScroll() {
        stopAutoScroll()
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.scrollToNextPage()
        }
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    private func scrollToNextPage() {
        guard images.count > 1 else { return }
        
        currentPage = (currentPage + 1) % images.count
        let screenWidth = UIScreen.main.bounds.width
        let offsetX = CGFloat(currentPage) * screenWidth
        
        UIView.animate(withDuration: 0.3) {
            self.scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
        }
    }
    
    private func createDefaultBannerImage() -> UIImage {
        return UIImage(named: "topBanner")!
    }
}

extension BannerTableViewCell: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        if pageIndex != currentPage && pageIndex >= 0 && pageIndex < images.count {
            currentPage = pageIndex
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 用户开始拖拽时暂停自动滚动
        stopAutoScroll()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 用户结束拖拽时恢复自动滚动（如果有多张图片）
        if images.count > 1 {
            startAutoScroll()
        }
    }
}

// MARK: - Menu Grid Cell
class MenuGridTableViewCell: UITableViewCell {
    private let containerView = UIView()
    private var items: [(String, String)] = []
    var onItemTap: ((Int, String) -> Void)? // 点击回调 (index, title)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with items: [(String, String)]) {
        self.items = items
        
        // 清除旧的视图
        containerView.subviews.forEach { $0.removeFromSuperview() }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 14
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 2 行 x 5 列（与 new UI 一致）
        for row in 0..<2 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 0
            for col in 0..<5 {
                let index = row * 5 + col
                if index < items.count {
                    let iconView = createMenuIconView(title: items[index].0, iconName: items[index].1, index: index)
                    rowStack.addArrangedSubview(iconView)
                }
            }
            stackView.addArrangedSubview(rowStack)
        }
        
        // stackView紧贴containerView，不留额外间距
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func createMenuIconView(title: String, iconName: String, index: Int) -> UIView {
        let container = UIView()
        container.isUserInteractionEnabled = true
        
        let iconImageView = UIImageView(image: UIImage(named: iconName) ?? UIImage(systemName: iconName))
        iconImageView.contentMode = .scaleAspectFit
        container.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14) // 文字大小14
        titleLabel.textColor = UIColor(hexString: "#1C1C1C") ?? UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0) // 颜色#1C1C1C
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2 // 最多2行
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.tag = index // 使用tag保存索引
        
        // 使用垂直StackView来精确控制布局
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 8
        contentStack.distribution = .fill
        container.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.addArrangedSubview(iconImageView)
        contentStack.addArrangedSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            // 图标37*37
            iconImageView.widthAnchor.constraint(equalToConstant: 22),
            iconImageView.heightAnchor.constraint(equalToConstant: 22),
            
            // contentStack居中
            contentStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 4),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -4),
            
            // 文字宽度限制
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 64)
        ])
        
        return container
    }
    
    @objc private func itemTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        let index = view.tag
        
        if index < items.count {
            onItemTap?(index, items[index].0)
        }
    }
}

// MARK: - Image Banner Cell (城市Banner)
class ImageBannerTableViewCell: UITableViewCell {
    private let scrollView = UIScrollView()
    private var bannerViews: [UIImageView] = []
    private var autoScrollTimer: Timer?
    private var currentPage: Int = 0
    private var images: [UIImage] = []
    var onBannerTap: ((Int) -> Void)? // 点击回调
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopAutoScroll()
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.bounces = false
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(bannerTapped))
        scrollView.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            scrollView.heightAnchor.constraint(equalToConstant: 110)
        ])
    }
    
    @objc private func bannerTapped() {
        onBannerTap?(currentPage)
    }
    
    func configure(with images: [UIImage]) {
        // 停止之前的定时器
        stopAutoScroll()
        
        // 清除旧的banner
        bannerViews.forEach { $0.removeFromSuperview() }
        bannerViews.removeAll()
        
        // 如果没有图片，创建一个默认的城市banner
        self.images = images.isEmpty ? [createCityBannerImage()] : images
        
        let screenWidth = UIScreen.main.bounds.width
        let bannerWidth = screenWidth - 20 // 左右各10的间距
        
        for (index, image) in self.images.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.isUserInteractionEnabled = true
            scrollView.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: CGFloat(index) * bannerWidth),
                imageView.widthAnchor.constraint(equalToConstant: bannerWidth),
                imageView.heightAnchor.constraint(equalToConstant: 110),
                imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])
            
            bannerViews.append(imageView)
        }
        
        scrollView.contentSize = CGSize(width: bannerWidth * CGFloat(self.images.count), height: 110)
        currentPage = 0
        
        // 如果有多张图片，启动自动滚动
        if self.images.count > 1 {
            startAutoScroll()
        }
    }
    
    private func startAutoScroll() {
        stopAutoScroll()
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.scrollToNextPage()
        }
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    private func scrollToNextPage() {
        guard images.count > 1 else { return }
        
        currentPage = (currentPage + 1) % images.count
        let screenWidth = UIScreen.main.bounds.width
        let bannerWidth = screenWidth - 20
        let offsetX = CGFloat(currentPage) * bannerWidth
        
        UIView.animate(withDuration: 0.3) {
            self.scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
        }
    }
    
    private func createCityBannerImage() -> UIImage {
        return UIImage(named: "centerBanner")!
    }
}

// MARK: - 资金数据（北上/南向/A股主力）
class FundFlowTableViewCell: UITableViewCell {
    
    let stack = UIStackView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
        let themeGreen = UIColor(red: 0, green: 0.6, blue: 0.2, alpha: 1.0)
        let items: [(String, String, UIColor)] = [
            ("北上资金净流入", "1344.81亿", themeRed),
            ("南向资金流入", "-1344.81亿", themeGreen),
            ("A股主力净流入", "-1344.81亿", themeGreen)
        ]
        for item in items {
            let v = makeFundColumn(title: item.0, value: item.1, valueColor: item.2)
            stack.addArrangedSubview(v)
        }
        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    private func makeFundColumn(title: String, value: String, valueColor: UIColor) -> UIView {
        let wrap = UIStackView()
        wrap.axis = .vertical
        wrap.spacing = 4
        wrap.alignment = .center
        let t = UILabel()
        t.text = title
        t.font = UIFont.systemFont(ofSize: 14)
        t.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        let v = UILabel()
        v.text = value
        v.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        v.textColor = valueColor
        wrap.addArrangedSubview(t)
        wrap.addArrangedSubview(v)
        return wrap
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func bindData(_ north: String, _ south: String, mainFund: String = "", mainFundIsPositive: Bool = false) {
        stack.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        
        let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
        let themeGreen = UIColor(red: 0, green: 0.6, blue: 0.2, alpha: 1.0)
        let northColor: UIColor = north.hasPrefix("-") ? themeGreen : themeRed
        let southColor: UIColor = south.hasPrefix("-") ? themeGreen : themeRed
        let mainFundColor: UIColor = mainFundIsPositive ? themeRed : themeGreen
        let mainFundText = mainFund.isEmpty ? "--" : mainFund
        let items: [(String, String, UIColor)] = [
            ("北上资金净流入", "\(north)亿", northColor),
            ("南向资金流入", "\(south)亿", southColor),
            ("A股主力净流入", mainFundText, mainFundColor)
        ]
        for item in items {
            let v = makeFundColumn(title: item.0, value: item.1, valueColor: item.2)
            stack.addArrangedSubview(v)
        }
        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
}

// MARK: - 直击热点 | 涨平跌分布 / 今日大盘（左右结构，右列上下结构）
class HotSpotMarketTableViewCell: UITableViewCell {
    private let containerView = UIView()
    private let leftCard = UIView()
    private let rightStack = UIStackView()
    private let hotspotTitleLabel = UILabel()
    private let hotspotHeadlineLabel = UILabel()
    private let hotspotTimeLabel = UILabel()
    private let zhijiredianImageView = UIImageView()
    private let riseFlatFallCard = UIView()
    private let marketCard = UIView()
    private let riseNumbersLabel = UILabel()
    private let marketPointsLabel = UILabel()
    private let marketPctLabel = UILabel()
    private let marketIndexLabel = UILabel()
    var onHotspotTap: (() -> Void)?

    private let themeRed = UIColor(red: 224/255, green: 92/255, blue: 92/255, alpha: 1.0)   // #E05C5C
    private let themeBlue = UIColor(red: 58/255, green: 124/255, blue: 224/255, alpha: 1.0) // #3A7CE0
    private let themeGreen = UIColor(red: 92/255, green: 200/255, blue: 100/255, alpha: 1.0) // #5CC864
    private let textDark = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)    // #2B2C31
    private let textSecondary = UIColor(red: 0.45, green: 0.45, blue: 0.48, alpha: 1.0)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // 左列：直击热点
        leftCard.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0) // #F8F9FE
        leftCard.layer.cornerRadius = 12
        leftCard.layer.shadowColor = UIColor.black.cgColor
        leftCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        leftCard.layer.shadowRadius = 8
        leftCard.layer.shadowOpacity = 0.08
        containerView.addSubview(leftCard)
        leftCard.translatesAutoresizingMaskIntoConstraints = false

        let tagView = UIView()
        tagView.backgroundColor = themeRed
        tagView.layer.cornerRadius = 6
        leftCard.addSubview(tagView)
        tagView.translatesAutoresizingMaskIntoConstraints = false
        let broadcastIcon = UIImageView(image: UIImage(systemName: "antenna.radiowaves.left.and.right"))
        broadcastIcon.tintColor = .white
        broadcastIcon.contentMode = .scaleAspectFit
        tagView.addSubview(broadcastIcon)
        broadcastIcon.translatesAutoresizingMaskIntoConstraints = false
        hotspotTitleLabel.text = "直击热点"
        hotspotTitleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        hotspotTitleLabel.textColor = .white
        tagView.addSubview(hotspotTitleLabel)
        hotspotTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            broadcastIcon.leadingAnchor.constraint(equalTo: tagView.leadingAnchor, constant: 8),
            broadcastIcon.centerYAnchor.constraint(equalTo: tagView.centerYAnchor),
            broadcastIcon.widthAnchor.constraint(equalToConstant: 14),
            broadcastIcon.heightAnchor.constraint(equalToConstant: 14),
            hotspotTitleLabel.leadingAnchor.constraint(equalTo: broadcastIcon.trailingAnchor, constant: 6),
            hotspotTitleLabel.trailingAnchor.constraint(equalTo: tagView.trailingAnchor, constant: -10),
            hotspotTitleLabel.centerYAnchor.constraint(equalTo: tagView.centerYAnchor),
            tagView.heightAnchor.constraint(equalToConstant: 28)
        ])

        hotspotHeadlineLabel.text = "加载中..."
        hotspotHeadlineLabel.font = UIFont.boldSystemFont(ofSize: 14)
        hotspotHeadlineLabel.textColor = textDark
        hotspotHeadlineLabel.numberOfLines = 3
        hotspotHeadlineLabel.lineBreakMode = .byTruncatingTail
        hotspotHeadlineLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        hotspotHeadlineLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        leftCard.addSubview(hotspotHeadlineLabel)
        hotspotHeadlineLabel.translatesAutoresizingMaskIntoConstraints = false

        hotspotTimeLabel.text = ""
        hotspotTimeLabel.font = UIFont.systemFont(ofSize: 11)
        hotspotTimeLabel.textColor = textSecondary
        leftCard.addSubview(hotspotTimeLabel)
        hotspotTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        zhijiredianImageView.image = UIImage(named: "zhijiredian")
        zhijiredianImageView.contentMode = .scaleAspectFill
        zhijiredianImageView.clipsToBounds = true
        zhijiredianImageView.layer.cornerRadius = 8
        leftCard.addSubview(zhijiredianImageView)
        zhijiredianImageView.translatesAutoresizingMaskIntoConstraints = false

        let leftTap = UITapGestureRecognizer(target: self, action: #selector(hotspotTapped))
        leftCard.addGestureRecognizer(leftTap)
        leftCard.isUserInteractionEnabled = true

        rightStack.axis = .vertical
        rightStack.distribution = .fillEqually
        rightStack.spacing = 10
        rightStack.alignment = .fill
        containerView.addSubview(rightStack)
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        riseFlatFallCard.backgroundColor = UIColor(red: 241/255, green: 250/255, blue: 255/255, alpha: 1.0) // #F1FAFF
        riseFlatFallCard.layer.cornerRadius = 12
        riseFlatFallCard.layer.shadowColor = UIColor.black.cgColor
        riseFlatFallCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        riseFlatFallCard.layer.shadowRadius = 8
        riseFlatFallCard.layer.shadowOpacity = 0.08
        let riseTitle = UILabel()
        riseTitle.text = "涨平跌分布"
        riseTitle.font = UIFont.boldSystemFont(ofSize: 18)
        riseTitle.textColor = themeBlue
        riseNumbersLabel.font = UIFont.boldSystemFont(ofSize: 18)
        let riseStr = "-- : -- : --"
        let riseAttr = NSMutableAttributedString(string: riseStr)
        riseAttr.addAttribute(.foregroundColor, value: themeRed, range: NSRange(location: 0, length: 2))
        riseAttr.addAttribute(.foregroundColor, value: textDark, range: NSRange(location: 5, length: 2))
        riseAttr.addAttribute(.foregroundColor, value: themeGreen, range: NSRange(location: 10, length: 2))
        riseNumbersLabel.attributedText = riseAttr
        let riseLabels = UILabel()
        riseLabels.font = UIFont.systemFont(ofSize: 18)
        let labStr = "涨 : 平 : 跌"
        let labAttr = NSMutableAttributedString(string: labStr)
        labAttr.addAttribute(.foregroundColor, value: themeRed, range: NSRange(location: 0, length: 1))
        labAttr.addAttribute(.foregroundColor, value: textDark, range: NSRange(location: 4, length: 1))
        labAttr.addAttribute(.foregroundColor, value: themeGreen, range: NSRange(location: 8, length: 1))
        riseLabels.attributedText = labAttr
        let riseStack = UIStackView(arrangedSubviews: [riseTitle, riseNumbersLabel, riseLabels])
        riseStack.axis = .vertical
        riseStack.spacing = 10
        riseStack.alignment = .leading
        riseFlatFallCard.addSubview(riseStack)
        riseStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            riseStack.topAnchor.constraint(equalTo: riseFlatFallCard.topAnchor, constant: 12),
            riseStack.leadingAnchor.constraint(equalTo: riseFlatFallCard.leadingAnchor, constant: 12),
            riseStack.trailingAnchor.constraint(equalTo: riseFlatFallCard.trailingAnchor, constant: -12),
            riseStack.bottomAnchor.constraint(lessThanOrEqualTo: riseFlatFallCard.bottomAnchor, constant: -12)
        ])
        rightStack.addArrangedSubview(riseFlatFallCard)

        marketCard.backgroundColor = UIColor(red: 241/255, green: 250/255, blue: 255/255, alpha: 1.0) // #F1FAFF
        marketCard.layer.cornerRadius = 12
        marketCard.layer.shadowColor = UIColor.black.cgColor
        marketCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        marketCard.layer.shadowRadius = 8
        marketCard.layer.shadowOpacity = 0.08
        let marketTitle = UILabel()
        marketTitle.text = "今日大盘"
        marketTitle.font = UIFont.boldSystemFont(ofSize: 18)
        marketTitle.textColor = themeBlue
        let marketRow = UIStackView()
        marketRow.axis = .horizontal
        marketRow.spacing = 10
        marketRow.alignment = .center
        marketPointsLabel.text = "--"
        marketPointsLabel.font = UIFont.boldSystemFont(ofSize: 22)
        marketPointsLabel.textColor = textSecondary
        marketPctLabel.text = "--%"
        marketPctLabel.font = UIFont.boldSystemFont(ofSize: 22)
        marketPctLabel.textColor = textSecondary
        marketIndexLabel.text = "加载中..."
        marketIndexLabel.font = UIFont.systemFont(ofSize: 14)
        marketIndexLabel.textColor = textDark
        marketRow.addArrangedSubview(marketPointsLabel)
        marketRow.addArrangedSubview(marketPctLabel)
        marketCard.addSubview(marketTitle)
        marketCard.addSubview(marketRow)
        marketCard.addSubview(marketIndexLabel)
        marketTitle.translatesAutoresizingMaskIntoConstraints = false
        marketRow.translatesAutoresizingMaskIntoConstraints = false
        marketIndexLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            marketTitle.topAnchor.constraint(equalTo: marketCard.topAnchor, constant: 12),
            marketTitle.leadingAnchor.constraint(equalTo: marketCard.leadingAnchor, constant: 12),
            marketRow.topAnchor.constraint(equalTo: marketTitle.bottomAnchor, constant: 8),
            marketRow.leadingAnchor.constraint(equalTo: marketCard.leadingAnchor, constant: 12),
            marketIndexLabel.topAnchor.constraint(equalTo: marketRow.bottomAnchor, constant: 4),
            marketIndexLabel.leadingAnchor.constraint(equalTo: marketCard.leadingAnchor, constant: 12),
            marketIndexLabel.bottomAnchor.constraint(lessThanOrEqualTo: marketCard.bottomAnchor, constant: -12)
        ])
        rightStack.addArrangedSubview(marketCard)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            leftCard.topAnchor.constraint(equalTo: containerView.topAnchor),
            leftCard.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            leftCard.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            leftCard.widthAnchor.constraint(equalTo: rightStack.widthAnchor),

            rightStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            rightStack.leadingAnchor.constraint(equalTo: leftCard.trailingAnchor, constant: 14),
            rightStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            rightStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            tagView.leadingAnchor.constraint(equalTo: leftCard.leadingAnchor, constant: 12),
            tagView.topAnchor.constraint(equalTo: leftCard.topAnchor, constant: 12),

            hotspotHeadlineLabel.topAnchor.constraint(equalTo: tagView.bottomAnchor, constant: 10),
            hotspotHeadlineLabel.leadingAnchor.constraint(equalTo: leftCard.leadingAnchor, constant: 12),
            hotspotHeadlineLabel.trailingAnchor.constraint(equalTo: leftCard.trailingAnchor, constant: -12),

            hotspotTimeLabel.topAnchor.constraint(equalTo: hotspotHeadlineLabel.bottomAnchor, constant: 6),
            hotspotTimeLabel.leadingAnchor.constraint(equalTo: leftCard.leadingAnchor, constant: 12),

            zhijiredianImageView.topAnchor.constraint(equalTo: hotspotTimeLabel.bottomAnchor, constant: 8),
            zhijiredianImageView.centerXAnchor.constraint(equalTo: leftCard.centerXAnchor),
            zhijiredianImageView.widthAnchor.constraint(equalToConstant: 115),
            zhijiredianImageView.heightAnchor.constraint(equalToConstant: 98),
            zhijiredianImageView.bottomAnchor.constraint(equalTo: leftCard.bottomAnchor, constant: -12)
        ])
    }

    @objc private func hotspotTapped() {
        onHotspotTap?()
    }

    /// 绑定直击热点新闻
    func bindHotspot(title: String, time: String) {
        hotspotHeadlineLabel.text = title
        hotspotTimeLabel.text = time
    }

    /// 绑定真实市场数据
    func bindMarketData(rise: Int, flat: Int, fall: Int,
                        indexName: String, indexPrice: String,
                        indexChange: String, indexPct: String, isDown: Bool) {
        // 涨平跌
        let rStr = "\(rise)"
        let fltStr = "\(flat)"
        let fallStr = "\(fall)"
        let full = "\(rStr) : \(fltStr) : \(fallStr)"
        let attr = NSMutableAttributedString(string: full)
        attr.addAttribute(.foregroundColor, value: themeRed, range: NSRange(location: 0, length: rStr.count))
        let flatLoc = rStr.count + 3
        attr.addAttribute(.foregroundColor, value: textDark, range: NSRange(location: flatLoc, length: fltStr.count))
        let fallLoc = flatLoc + fltStr.count + 3
        attr.addAttribute(.foregroundColor, value: themeGreen, range: NSRange(location: fallLoc, length: fallStr.count))
        riseNumbersLabel.attributedText = attr

        // 今日大盘
        let priceColor = isDown ? themeGreen : themeRed
        marketPointsLabel.text = indexChange
        marketPointsLabel.textColor = priceColor
        marketPctLabel.text = "\(indexPct)%"
        marketPctLabel.textColor = priceColor
        marketIndexLabel.text = "\(indexName) \(indexPrice)"
    }
}

extension ImageBannerTableViewCell: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let screenWidth = UIScreen.main.bounds.width
        let bannerWidth = screenWidth - 20
        let pageIndex = Int(round(scrollView.contentOffset.x / bannerWidth))
        if pageIndex != currentPage && pageIndex >= 0 && pageIndex < images.count {
            currentPage = pageIndex
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 用户开始拖拽时暂停自动滚动
        stopAutoScroll()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 用户结束拖拽时恢复自动滚动（如果有多张图片）
        if images.count > 1 {
            startAutoScroll()
        }
    }
}

// MARK: - News Cell
class NewsTableViewCell: UITableViewCell {
    private let containerView = UIView()
    private let tabView = UIView()
    private let newsStackView = UIStackView()
    private var tabButtons: [UIButton] = []
    private var selectedIndex: Int = 0
    private var newsData: [[(String, String, String)]] = [] // 不同分类的新闻数据
    var onNewsItemTapped: ((String, String, String) -> Void)? // 新闻项点击回调 (title, time, content)
    var onNewsDataLoaded: (() -> Void)? // 新闻数据加载完成后回调，用于让 tableView 重新计算行高
    
    // 新闻数据源（与 new UI 一致：动态/7X24/盘面/投顾/要闻/更多）
//    private var newsDataSource: [[(String, String)]] = []
//    private let newsData: [[(String, String)]] = [
//        [
//            ("今夜突发公告!多只大牛股紧急提示风险!", "01-28 21:25"),
//            ("2026购在中国暨新春消费季启动", "01-28 20:15"),
//            ("国内经济持续稳定增长，消费市场活跃", "01-28 18:30")
//        ],
//        [
//            ("全球股市震荡，投资者关注美联储政策", "01-28 21:20"),
//            ("欧洲央行维持利率不变，市场反应积极", "01-28 20:10"),
//            ("亚洲市场表现强劲，科技股领涨", "01-28 18:00")
//        ],
//        [
//            ("A股市场迎来开门红，三大指数集体上涨", "01-28 21:15"),
//            ("证监会发布新规，规范市场交易行为", "01-28 20:00"),
//            ("券商板块表现亮眼，多只个股涨停", "01-28 17:45")
//        ],
//        [
//            ("多家上市公司发布业绩预告", "01-28 21:10"),
//            ("科技公司加大研发投入，布局新赛道", "01-28 19:50"),
//            ("新能源企业获得重大订单，股价上涨", "01-28 17:30")
//        ],
//        [
//            ("要闻汇总：政策与市场双轮驱动", "01-28 21:05"),
//            ("机构看好春季行情", "01-28 19:40"),
//            ("北向资金持续流入", "01-28 17:15")
//        ],
//        [
//            ("更多资讯敬请关注", "01-28 21:00"),
//            ("行业研报与策略", "01-28 19:30"),
//            ("市场数据与解读", "01-28 17:00")
//        ]
//    ]
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Tab 配置与安卓保持一致：动态/7X24/盘面/投顾/要闻
    private let newsTypeModels = [
        ["type": "1", "name": "动态"],
        ["type": "2", "name": "7X24"],
        ["type": "3", "name": "盘面"],
        ["type": "3", "name": "投顾"],
        ["type": "4", "name": "要闻"],
    ]

    private func loadData() {
        // 去重 type，避免重复请求
        let uniqueTypes = Array(Set(newsTypeModels.map { $0["type"] ?? "" }))
        let group = DispatchGroup()
        var news = [(String, String, String, String)]()
        for type in uniqueTypes {
            group.enter()
            SecureNetworkManager.shared.request(api: "/api/Indexnew/getGuoneinews", method: .get, params: ["page": "1", "size": "20", "type": type]) { res in
                defer { group.leave() }
                switch res {
                case .success(let success):
                    guard let root = success.decrypted?["data"] as? [String: Any],
                          let list = root["list"] as? [[String: Any]] else { return }
                    for item in list {
                        let news_title = item["news_title"] as? String ?? ""
                        // 优先使用 news_time_text（友好时间），为空则回退 news_time
                        let timeText = item["news_time_text"] as? String ?? ""
                        let news_time = timeText.isEmpty ? (item["news_time"] as? String ?? "") : timeText
                        let news_content = item["news_content"] as? String ?? ""
                        news.append((type, news_title, news_time, news_content))
                    }
                case .failure(let failure):
                    DispatchQueue.main.async {
                        Toast.showInfo(failure.localizedDescription)
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            /// 新闻按分类处理（同 type 的 Tab 共享数据）
            newsTypeModels.forEach({ [weak self] newType in
                guard let self = self else { return }
                newsData.append(news.filter({ $0.0 == newType["type"]}).map({($0.1, $0.2, $0.3)}))
            })
            updateTabSelection()
            updateNewsList()
            onNewsDataLoaded?()
        }
    }

    /// 接收外部预加载好的新闻数据，直接渲染
    func bindPreloadedData(_ data: [[(String, String, String)]]) {
        guard !data.isEmpty else { return }
        newsData = data
        updateTabSelection()
        updateNewsList()
        onNewsDataLoaded?()
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        containerView.backgroundColor = .white
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 新闻标签
        containerView.addSubview(tabView)
        tabView.translatesAutoresizingMaskIntoConstraints = false
        let tabs = newsTypeModels.map({ $0["name"] })
        let tabStackView = UIStackView()
        tabStackView.axis = .horizontal
        tabStackView.distribution = .fillEqually
        tabStackView.spacing = 0
        tabView.addSubview(tabStackView)
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        
        for (index, tabTitle) in tabs.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(tabTitle, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            button.tag = index
            button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            button.layer.cornerRadius = 6
            tabStackView.addArrangedSubview(button)
            tabButtons.append(button)
        }
        
        // 新闻列表
        newsStackView.axis = .vertical
        newsStackView.spacing = 0 // 间距由item内部控制
        containerView.addSubview(newsStackView)
        newsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            tabView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            tabView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            tabView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            tabView.heightAnchor.constraint(equalToConstant: 34),
            
            tabStackView.topAnchor.constraint(equalTo: tabView.topAnchor),
            tabStackView.leadingAnchor.constraint(equalTo: tabView.leadingAnchor),
            tabStackView.trailingAnchor.constraint(equalTo: tabView.trailingAnchor),
            tabStackView.bottomAnchor.constraint(equalTo: tabView.bottomAnchor),
            
            newsStackView.topAnchor.constraint(equalTo: tabView.bottomAnchor, constant: 10),
            newsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            newsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            newsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
        
        // 初始化选中状态
        updateTabSelection()
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let newIndex = sender.tag
        guard newIndex != selectedIndex else { return }
        
        selectedIndex = newIndex
        updateTabSelection()
        updateNewsList()
    }
    
    private func updateTabSelection() {
        let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
        for (index, button) in tabButtons.enumerated() {
            if index == selectedIndex {
                button.setTitleColor(themeRed, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            } else {
                button.setTitleColor(UIColor(hex: 0x1C1C1C), for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            }
            button.backgroundColor = .clear
        }
    }
    
    private func updateNewsList() {
        // 清除旧的新闻项（含占位）
        newsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if newsData.isEmpty {
            let placeholder = UIView()
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            newsStackView.addArrangedSubview(placeholder)
            NSLayoutConstraint.activate([
                placeholder.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
            ])
            return
        }
        // 获取当前分类的新闻数据
        if selectedIndex >= newsData.count { return }
        let currentNews = newsData[selectedIndex]
        
        // 添加新的新闻项（前几项带红色数字角标）
        for (index, news) in currentNews.enumerated() {
            let newsItemView = createNewsItemView(title: news.0, time: news.1, content: news.2, index: index)
            newsStackView.addArrangedSubview(newsItemView)
            
            // 如果不是最后一项，添加分隔线
            if index < currentNews.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor(hex: 0xF6F6F6) // 浅灰色分隔线
                newsStackView.addArrangedSubview(separator)
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
            }
        }
        
        // 底部弹性间距，吸收 stackView .fill 分布产生的多余空间，防止新闻条目被拉伸
        let bottomSpacer = UIView()
        bottomSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        newsStackView.addArrangedSubview(bottomSpacer)
    }
    
    private func createNewsItemView(title: String, time: String, content: String, index: Int = 0) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.isUserInteractionEnabled = true
        // 防止被 stackView 拉伸导致标题和时间之间出现大间隔
        container.setContentHuggingPriority(.required, for: .vertical)
        container.setContentCompressionResistancePriority(.required, for: .vertical)

        let badgeLabel = UILabel()
        if index < 4 {
            badgeLabel.text = "\(index + 1)"
            badgeLabel.font = UIFont.boldSystemFont(ofSize: 11)
            badgeLabel.textColor = .white
            badgeLabel.backgroundColor = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
            badgeLabel.textAlignment = .center
            badgeLabel.layer.cornerRadius = 4
            badgeLabel.clipsToBounds = true
        }
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(badgeLabel)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.isUserInteractionEnabled = false
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let timeLabel = UILabel()
        timeLabel.text = time
        timeLabel.font = UIFont.systemFont(ofSize: 11)
        timeLabel.textColor = UIColor(hex: 0xADADAD)
        timeLabel.isUserInteractionEnabled = false
        container.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(newsItemTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        
        // 使用关联对象存储标题和时间
        objc_setAssociatedObject(container, &AssociatedKeys.newsTitle, title, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        objc_setAssociatedObject(container, &AssociatedKeys.newsTime, time, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        objc_setAssociatedObject(container, &AssociatedKeys.newsContent, content, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        
        let hasBadge = index < 4
        var constraints: [NSLayoutConstraint] = [
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ]
        if hasBadge {
            constraints += [
                badgeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                badgeLabel.topAnchor.constraint(equalTo: titleLabel.topAnchor),
                badgeLabel.widthAnchor.constraint(equalToConstant: 18),
                badgeLabel.heightAnchor.constraint(equalToConstant: 18),
                titleLabel.leadingAnchor.constraint(equalTo: badgeLabel.trailingAnchor, constant: 8)
            ]
        } else {
            constraints.append(titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor))
        }
        NSLayoutConstraint.activate(constraints)

        return container
    }

    @objc private func newsItemTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view,
              let title = objc_getAssociatedObject(view, &AssociatedKeys.newsTitle) as? String,
              let time = objc_getAssociatedObject(view, &AssociatedKeys.newsTime) as? String,
              let content = objc_getAssociatedObject(view, &AssociatedKeys.newsContent) as? String else {
            return
        }
        onNewsItemTapped?(title, time, content)
    }
}

// 关联对象键
private struct AssociatedKeys {
    static var newsTitle = "newsTitle"
    static var newsTime = "newsTime"
    static var newsContent = "newsContent"
}
