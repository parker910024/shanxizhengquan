//
//  HomeViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

class HomeViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    // 顶部搜索栏容器（不在tableView内）
    private let topBarView = UIView()
    private let searchBar = UIView()
    private let searchTextField = UITextField()
    
    // 数据源（与 new UI 一致：2 行 x 5 列）
    private var bannerImages: [UIImage] = []
    private var menuItems: [(String, String)] = [
        ("极速开户", "icon_home_1"),
        ("市场行情", "icon_home_7"),
        ("持仓记录", "icon2"),
        ("银证转入", "icon1"),
        ("银证转出", "icon11"),
        ("新股申购", "icon_home_6"),
        ("场外撮合交易", "icon_home_9"),
        ("智能选股", "icon12"),
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
        ("智能选股", "icon12"),
        ("AI智投", "icon_home_13"),
        ("龙虎榜", "icon4")
    ]

    /// 新股申购提醒弹框容器（每次进入首页显示）
    private var newStockReminderOverlay: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // 南向/北向资金
        capitalInflow()
        showNewStockReminderPopupIfNeeded()
        // 加载功能开关配置
        FeatureSwitchManager.shared.loadConfig()
        NotificationCenter.default.addObserver(self, selector: #selector(featureSwitchDidUpdate), name: FeatureSwitchManager.didUpdateNotification, object: nil)
    }

    /// 功能开关更新后刷新菜单
    @objc private func featureSwitchDidUpdate() {
        let mgr = FeatureSwitchManager.shared
        menuItems = allMenuItems.filter { item in
            let title = item.0
            if title == "新股申购" && !mgr.isXgsgEnabled { return false }
            return true
        }
        tableView.reloadData()
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
        let cardH: CGFloat = 335
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
            card.heightAnchor.constraint(equalToConstant: cardH),

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
        topBarView.backgroundColor = UIColor(red: 28/255, green: 59/255, blue: 92/255, alpha: 1.0) // #1C3B5C
        
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
        searchTextField.placeholder = "输入股票代码/简拼"
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
    // MARK: 北向/南向资金流入
    func capitalInflow() {
        guard let url = URL(string: "https://push2.eastmoney.com/api/qt/kamt/get?fields1=f1,f2,f3,f4&fields2=f51,f52,f53,f54,f56,f60,f61,f62,f63,f65,f66&ut=fa5fd1943c7b386f172d6893dbfba10b&cb=jQuery112304419911490366253_1771774863303&_=1771774863305") else { return }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { [weak self] data, response, err in
            guard let self = self else { return }
            let res = response as? HTTPURLResponse
            if res?.statusCode != 200 { return }
            // 网络请求成功
            guard let data = data else { return }
            guard let string = String(data: data, encoding: .utf8) else { return }
            let temp = string.replacingOccurrences(of: "jQuery112304419911490366253_1771774863303(", with: "")
            let jsonString = temp[temp.startIndex ..< temp.index(temp.endIndex, offsetBy: -2)]
            guard let jsonData = jsonString.data(using: .utf8) else { return }
            guard let root = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) else { return }
            guard let dict = root as? NSDictionary else { return }
            guard let res = dict.safeValueForKey("data") as? NSDictionary else { return }
            // 南向
            if let south1 = res.safeValueForKey("hk2sh") as? NSDictionary, let south2 = res.safeValueForKey("hk2sz") as? NSDictionary {
                if let sfunds1 = south1.safeValueForKey("buySellAmt") as? Double, let sfunds2 = south2.safeValueForKey("buySellAmt") as? Double {
                    totalSouth = String(format: "%.2f", sfunds1 / 10000.0 + sfunds2 / 10000.0)
                }
            }
            // 北向
            if let north1 = res.safeValueForKey("hk2sh") as? NSDictionary, let north2 = res.safeValueForKey("hk2sz") as? NSDictionary {
                if let nfunds1 = north1.safeValueForKey("buySellAmt") as? Double, let nfunds2 = north2.safeValueForKey("buySellAmt") as? Double {
                    totalNorth = String(format: "%.2f", nfunds1/10000.0 + nfunds2/10000.0)
                }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                tableView.reloadData()
            }
        }.resume()
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
            // Banner轮播图
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerCell", for: indexPath) as! BannerTableViewCell
            cell.configure(with: bannerImages)
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
                // 龙虎榜是第 10 项（index 9），用索引兜底避免标题字符不一致导致无反应
                if index == 9 || title == "龙虎榜" {
                    let vc = LongHuBangViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                    return
                }
                switch title {
                case "极速开户":
                    let vc = RegisterViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self?.present(nav, animated: true)
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
                case "新股申购":
                    let vc = NewStockSubscriptionViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                case "场外撮合交易":
                    let vc = BlockTradingListViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                case "智能选股", "AI智投":
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
            cell.bindData(totalNorth, totalSouth)
            return cell
        case 4:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "HotSpotMarketCell", for: indexPath) as! HotSpotMarketTableViewCell
            cell.onHotspotTap = { [weak self] in
                let detailVC = NewsDetailViewController()
                detailVC.htmlContent = self?.getNewsContent(for: "今夜突发公告!多只大牛股紧急提示风险!")
                detailVC.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(detailVC, animated: true)
            }
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
            return 152
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
        
        for (index, image) in self.images.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            scrollView.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: CGFloat(index) * screenWidth),
                imageView.widthAnchor.constraint(equalToConstant: screenWidth),
                imageView.heightAnchor.constraint(equalToConstant: 140),
                imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])
            
            bannerViews.append(imageView)
        }
        
        scrollView.contentSize = CGSize(width: screenWidth * CGFloat(self.images.count), height: 140)
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
    
    func bindData(_ north: String, _ south: String) {
        stack.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        
        let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
        let themeGreen = UIColor(red: 0, green: 0.6, blue: 0.2, alpha: 1.0)
        let items: [(String, String, UIColor)] = [
            ("北上资金净流入", "\(north)亿", themeRed),
            ("南向资金流入", "-\(south)亿", themeGreen),
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

        hotspotHeadlineLabel.text = "今夜突发公告!\n多只大牛股紧..."
        hotspotHeadlineLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        hotspotHeadlineLabel.textColor = textDark
        hotspotHeadlineLabel.numberOfLines = 2
        hotspotHeadlineLabel.lineBreakMode = .byTruncatingTail
        hotspotHeadlineLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        hotspotHeadlineLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        leftCard.addSubview(hotspotHeadlineLabel)
        hotspotHeadlineLabel.translatesAutoresizingMaskIntoConstraints = false

        hotspotTimeLabel.text = "2026-01-28 21:25:26"
        hotspotTimeLabel.font = UIFont.systemFont(ofSize: 14)
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
        let riseNumbers = UILabel()
        riseNumbers.font = UIFont.boldSystemFont(ofSize: 18)
        let riseStr = "1636 : 79 : 3485"
        let riseAttr = NSMutableAttributedString(string: riseStr)
        riseAttr.addAttribute(.foregroundColor, value: themeRed, range: NSRange(location: 0, length: 4))
        riseAttr.addAttribute(.foregroundColor, value: textDark, range: NSRange(location: 5, length: 5))
        riseAttr.addAttribute(.foregroundColor, value: themeGreen, range: NSRange(location: 10, length: 4))
        riseNumbers.attributedText = riseAttr
        let riseLabels = UILabel()
        riseLabels.font = UIFont.systemFont(ofSize: 18)
        let labStr = "涨 : 平 : 跌"
        let labAttr = NSMutableAttributedString(string: labStr)
        labAttr.addAttribute(.foregroundColor, value: themeRed, range: NSRange(location: 0, length: 1))
        labAttr.addAttribute(.foregroundColor, value: textDark, range: NSRange(location: 4, length: 1))
        labAttr.addAttribute(.foregroundColor, value: themeGreen, range: NSRange(location: 8, length: 1))
        riseLabels.attributedText = labAttr
        let riseStack = UIStackView(arrangedSubviews: [riseTitle, riseNumbers, riseLabels])
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
        let marketPoints = UILabel()
        marketPoints.text = "-2.49"
        marketPoints.font = UIFont.boldSystemFont(ofSize: 22)
        marketPoints.textColor = themeGreen
        let marketPct = UILabel()
        marketPct.text = "-0.16%"
        marketPct.font = UIFont.boldSystemFont(ofSize: 22)
        marketPct.textColor = themeGreen
        let marketIndex = UILabel()
        marketIndex.text = "北证50 1562.45"
        marketIndex.font = UIFont.systemFont(ofSize: 14)
        marketIndex.textColor = textDark
        marketRow.addArrangedSubview(marketPoints)
        marketRow.addArrangedSubview(marketPct)
        marketCard.addSubview(marketTitle)
        marketCard.addSubview(marketRow)
        marketCard.addSubview(marketIndex)
        marketTitle.translatesAutoresizingMaskIntoConstraints = false
        marketRow.translatesAutoresizingMaskIntoConstraints = false
        marketIndex.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            marketTitle.topAnchor.constraint(equalTo: marketCard.topAnchor, constant: 12),
            marketTitle.leadingAnchor.constraint(equalTo: marketCard.leadingAnchor, constant: 12),
            marketRow.topAnchor.constraint(equalTo: marketTitle.bottomAnchor, constant: 8),
            marketRow.leadingAnchor.constraint(equalTo: marketCard.leadingAnchor, constant: 12),
            marketIndex.topAnchor.constraint(equalTo: marketRow.bottomAnchor, constant: 4),
            marketIndex.leadingAnchor.constraint(equalTo: marketCard.leadingAnchor, constant: 12),
            marketIndex.bottomAnchor.constraint(lessThanOrEqualTo: marketCard.bottomAnchor, constant: -12)
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
        loadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let newsTypeModels = [
        ["type": "1", "name": "国内经济"],
        ["type": "2", "name": "国际经济"],
        ["type": "3", "name": "证券要闻"],
        ["type": "4", "name": "公司咨询"],
    ]

    private func loadData() {
        
        let group = DispatchGroup()
        var news = [(String, String, String, String)]()
        newsTypeModels.forEach {
            group.enter()
            let type: String = $0["type"] ?? ""
            SecureNetworkManager.shared.request(api: "/api/Indexnew/getGuoneinews", method: .get, params: ["page": "1", "size":"3", "type": type]) { res in
                switch res {
                case .success(let success):
                    guard let root = success.decrypted?["data"] as? [String: Any] else { return }
                    guard let list = root["list"] as? [[String: Any]] else { return }
                    for item in list {
                        let news_time = item["news_time"] as? String
                        let news_title = item["news_title"] as? String
                        let news_content = item["news_content"] as? String
                        news.append((type, news_title ?? "", news_time ?? "", news_content ?? ""))
                    }
                    group.leave()
                case .failure(let failure):
                    group.leave()
                    DispatchQueue.main.async {
                        Toast.showInfo(failure.localizedDescription)
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            /// 新闻按分类处理
            newsTypeModels.forEach({ [weak self] newType in
                guard let self = self else { return }
                newsData.append(news.filter({ $0.0 == newType["type"]}).map({($0.1, $0.2, $0.3)}))
            })
            updateTabSelection()
            updateNewsList()
            onNewsDataLoaded?()
        }
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
        
        // 初始化选中状态和新闻列表
        updateTabSelection()
        updateNewsList()
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
                let sepH = separator.heightAnchor.constraint(equalToConstant: 1)
                sepH.priority = UILayoutPriority(999)
                sepH.isActive = true
            }
        }
    }
    
    private func createNewsItemView(title: String, time: String, content: String, index: Int = 0) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.isUserInteractionEnabled = true

        let badgeLabel = UILabel()
        if index < 4 {
            badgeLabel.text = "\(index + 1)"
            badgeLabel.font = UIFont.boldSystemFont(ofSize: 12)
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
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0) // #2B2C31
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.isUserInteractionEnabled = false
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let timeLabel = UILabel()
        timeLabel.text = time
        timeLabel.font = UIFont.systemFont(ofSize: 12)
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
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ]
        let titleToTime = timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6)
        titleToTime.priority = UILayoutPriority(999)
        constraints.append(titleToTime)
        if hasBadge {
            constraints += [
                badgeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                badgeLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
                badgeLabel.widthAnchor.constraint(equalToConstant: 22),
                badgeLabel.heightAnchor.constraint(equalToConstant: 22),
                titleLabel.leadingAnchor.constraint(equalTo: badgeLabel.trailingAnchor, constant: 10)
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
