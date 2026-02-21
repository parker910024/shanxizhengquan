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
    
    // 数据源
    private var bannerImages: [UIImage] = [] // Banner图片数组
    private let menuItems = [
        ("新股申购", "chart.line.uptrend.xyaxis"),
        ("我的新股", "person.badge.plus"),
        ("大宗交易", "square.stack.3d.up"),
        ("线下配售", "building.2"),
        ("我的自选", "square.and.arrow.up"),
        ("沪深行情", "chart.bar"),
        ("银证转账", "arrow.triangle.2.circlepath"),
        ("新股日历", "calendar")
    ]
    
    // 弹窗数据（由外部传入）
    var popupData: HomePopupData?
    private var hasShownPopup = false // 标记是否已显示过弹窗
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        
        // 模拟弹窗数据（测试用，实际应该由外部传入）
        popupData = HomePopupData(
            title: "恭喜您中签",
            subtitle: "今日中签1只新股",
            stockName: "科马材料",
            stockCode: "920086",
            quantity: "10000手",
            amount: "1166000",
            buttonTitle: "前往认缴"
        )
        
        showPopupIfNeeded()
    }
    
    /// 显示弹窗（如果需要）
    private func showPopupIfNeeded() {
        // 只在 viewDidLoad 时显示一次，且必须有数据
        guard !hasShownPopup, let data = popupData else {
            return
        }
        
        hasShownPopup = true
        
        // 延迟一点显示，确保视图已完全加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            let popup = HomePopupView()
            popup.configure(with: data)
            popup.onButtonTapped = { [weak self] in
                // TODO: 处理按钮点击事件，如跳转到认缴页面
                print("前往认缴按钮被点击")
            }
            popup.show(in: self.view)
        }
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
        topBarView.backgroundColor = UIColor(hex: 0x003EAC)
        
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
        searchTextField.placeholder = "股票代码/简拼"
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
        return "<div class=\"txtinfos\" id=\"ContentBody\" style=\"margin-top:0;\">\n                            \n                                <!--文章主体-->\n<p>　　沪指本周累计涨0.13%，深证成指跌0.58%，创业板指跌1.25%。A股后市怎么走？看看机构怎么说：</p ><p>　　<strong>①<span id=\"stock_1.600030\"><a target=\"_blank\" href= \"http://quote.eastmoney.com/unify/r/1.600030\" class=\"keytip\" data-code=\"1,600030\">中信证券</a ></span><span id=\"quote_1.600030\"></span>：开年后市场震荡向上的概率更高</strong></p ><p>　　<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.600030\" class=\"em_stock_key_common\" data-code=\"1,600030\">中信证券</span>表示，考虑到去年末的资金热度并不算高，人心思涨的环境下开年后市场震荡向上的概率更高。前期共识性品种调整后再上车大概率是机构资金主要的考虑方向，例如有色、海外算力、<span id=\"bk_90.BK1036\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK1036\" class=\"keytip\" data-code=\"90,BK1036\">半导体</a ></span><span id=\"bkquote_90.BK1036\"></span>自主可控等，有些偏游资风格的品种也属于这一类别，比如<span id=\"bk_90.BK0963\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0963\" class=\"keytip\" data-code=\"90,BK0963\">商业航天</a ></span><span id=\"bkquote_90.BK0963\"></span>、<span id=\"stock_0.300024\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/0.300024\" class=\"keytip\" data-code=\"0,300024\">机器人</a ></span><span id=\"quote_0.300024\"></span>等。免税、航空等出行服务相关行业应是增量布局重点，优质的地产开发商也是考虑对象。中期维度下，更青睐一些热度和持仓集中度相对较低，但关注度开始提升、催化开始增多且长期ROE有提升空间的板块，如化工、<span id=\"bk_90.BK0739\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0739\" class=\"keytip\" data-code=\"90,BK0739\">工程机械</a ></span><span id=\"bkquote_90.BK0739\"></span>、电力设备及<span id=\"bk_90.BK0493\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0493\" class=\"keytip\" data-code=\"90,BK0493\">新能源</a ></span><span id=\"bkquote_90.BK0493\"></span>等，对高景气、高热度但是股价滞涨的板块则相对谨慎。同时，一些新的产业题材（如<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0963\" class=\"em_stock_key_common\" data-code=\"90,BK0963\">商业航天</span>）可能还会反复演绎，值得持续关注。</p ><p>　　<strong>②<span id=\"stock_1.601059\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601059\" class=\"keytip\" data-code=\"1,601059\">信达证券</a ></span><span id=\"quote_1.601059\"></span>：春季行情可能缓步启动</strong></p ><p>　　<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601059\" class=\"em_stock_key_common\" data-code=\"1,601059\">信达证券</span>表示，春节前流动性环境大概率较好，市场可能继续偏强，但1月可能会有一些波动。这一次春节前市场位置不低，此前经验来看，交易量下降到低位后恢复初期通常是缓涨。本次春季行情可能是缓步启动，后续指数突破需要验证经济数据等能否继续加速。资金层面，当前<span id=\"bk_90.BK0474\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0474\" class=\"keytip\" data-code=\"90,BK0474\">保险</a ></span><span id=\"bkquote_90.BK0474\"></span>、私募等机构资金仍有较强的补仓动力，短期在演绎产业趋势强或者催化较多的主题，但主题行情的持续性需要验证实际的订单或业绩。</p ><p>　　<strong>③<span id=\"stock_1.601788\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601788\" class=\"keytip\" data-code=\"1,601788\">光大证券</a ></span><span id=\"quote_1.601788\"></span>：消费与成长有望成为春季行情的两条主线</strong></p ><p>　　<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601788\" class=\"em_stock_key_common\" data-code=\"1,601788\">光大证券</span>表示，当前来看，2025年12月下旬的上涨或许是本轮春季行情起点。对于1月份指数的行情，投资者或许应该保持耐心。消费与成长有望成为今年春季行情的两条主线。1月行业配置方面，关注电子、电力设备、<span id=\"bk_90.BK0478\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0478\" class=\"keytip\" data-code=\"90,BK0478\">有色金属</a ></span><span id=\"bkquote_90.BK0478\"></span>、汽车等。若市场风格为成长，五维行业比较框架打分靠前的行业分别为电子、电力设备、通信、<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0478\" class=\"em_stock_key_common\" data-code=\"90,BK0478\">有色金属</span>、汽车、国防<span id=\"bk_90.BK0490\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0490\" class=\"keytip\" data-code=\"90,BK0490\">军工</a ></span><span id=\"bkquote_90.BK0490\"></span>；若1月份市场风格为防御，五维行业比较框架打分靠前的行业分别为非银金融、电子、<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0478\" class=\"em_stock_key_common\" data-code=\"90,BK0478\">有色金属</span>、电力设备、汽车、交通运输等。</p ><p>　　<strong>④<span id=\"stock_0.002670\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/0.002670\" class=\"keytip\" data-code=\"0,002670\">国盛证券</a ></span><span id=\"quote_0.002670\"></span>：配置趋势共识，博弈产业催化</strong></p ><p>　　<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/0.002670\" class=\"em_stock_key_common\" data-code=\"0,002670\">国盛证券</span>表示，大势层面，中期趋势依旧向上，短期保持交易思维。配置维度，当前科技与周期的双主线思维共识较强，宜重点围绕市场共识配置处于趋势中的资产，科技领域优先重点关注AI算力、<span id=\"bk_90.BK0989\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0989\" class=\"keytip\" data-code=\"90,BK0989\">储能</a ></span><span id=\"bkquote_90.BK0989\"></span>、<span id=\"bk_90.BK1137\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK1137\" class=\"keytip\" data-code=\"90,BK1137\">存储芯片</a ></span><span id=\"bkquote_90.BK1137\"></span>等，周期领域优先关注反内卷与涨价验证的交集方向，如有色、化工、钢铁等。交易维度，短期重点围绕产业催化参与，国内优先关注<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0963\" class=\"em_stock_key_common\" data-code=\"90,BK0963\">商业航天</span>、软件<span id=\"bk_90.BK1104\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK1104\" class=\"keytip\" data-code=\"90,BK1104\">信创</a ></span><span id=\"bkquote_90.BK1104\"></span>等；海外映射类优先关注<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/0.300024\" class=\"em_stock_key_common\" data-code=\"0,300024\">机器人</span>、<span id=\"bk_90.BK1037\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK1037\" class=\"keytip\" data-code=\"90,BK1037\">消费电子</a ></span><span id=\"bkquote_90.BK1037\"></span>、互联网传媒等AI应用端的催化反馈。</p ><p>　　<strong>⑤<span id=\"stock_1.601881\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601881\" class=\"keytip\" data-code=\"1,601881\">中国银河</a ></span><span id=\"quote_1.601881\"></span><span id=\"bk_90.BK0473\"><a target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0473\" class=\"keytip\" data-code=\"90,BK0473\">证券</a ></span><span id=\"bkquote_90.BK0473\"></span>：硬科技与消费共振，港股后市可期</strong></p ><p>　　<span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/1.601881\" class=\"em_stock_key_common\" data-code=\"1,601881\">中国银河</span><span web=\"1\" target=\"_blank\" href=\"http://quote.eastmoney.com/unify/r/90.BK0473\" class=\"em_stock_key_common\" data-code=\"90,BK0473\">证券</span>表示，展望未来，在多重积极因素共振下，港股市场交投活跃度有望持续上升，预计港股整体震荡上行。配置方面，建议关注以下板块：（1）科技板块仍是中长期投资主线，在产业链涨价、并购重组等多重利好共振下，有望震荡上行。（2）消费板块有望持续受益于政策支持，且当前估值处于相对低位，中长期上涨空间较大，后续需关注政策落地力度及消费数据改善情况。</p ><p class=\"em_media\">（文章来源：第一财经）</p >                        </div>"
    }
}

// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4 // Banner, MenuGrid, ImageBanner, News
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            // Banner轮播图
            let cell = tableView.dequeueReusableCell(withIdentifier: "BannerCell", for: indexPath) as! BannerTableViewCell
            cell.configure(with: bannerImages)
            cell.onBannerTap = {  index in
                // 处理banner点击事件
                print("Banner tapped at index: \(index)")
            }
            return cell
        case 1:
            // 菜单网格
            let cell = tableView.dequeueReusableCell(withIdentifier: "MenuGridCell", for: indexPath) as! MenuGridTableViewCell
            cell.configure(with: menuItems)
            cell.onItemTap = { [weak self] index, title in
                // 处理菜单项点击事件
                print("Menu item tapped: \(title) at index: \(index)")
                // 这里可以添加跳转逻辑
                if title == "新股申购" || title == "新股日历" {
                    let vc = NewStockSubscriptionViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else if title == "我的新股" {
                    let vc = MyNewStocksViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else if title == "我的自选" {
                    let vc = MyWatchlistViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else if title == "线下配售" {
                    // 与个人中心「配售记录」一致，跳转到 AllotmentRecordsViewController
                    let vc = AllotmentRecordsViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else if title == "银证转账" {
                    // 与个人中心银证转入一致，跳转到 BankSecuritiesTransferViewController，默认选择转入tab
                    let vc = BankSecuritiesTransferViewController()
                    vc.initialTabIndex = 0   // 0: 银证转入
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else if title == "大宗交易" {
                    let vc = BlockTradingViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else if title == "沪深行情" {
                    // 切换 TabBar 到行情页（索引 1），并默认选中「沪深」分组
                    if let tabBarController = self?.tabBarController as? MainTabBarController,
                       let viewControllers = tabBarController.viewControllers,
                       viewControllers.count > 1,
                       let marketNav = viewControllers[1] as? UINavigationController,
                       let marketVC = marketNav.viewControllers.first as? MarketViewController {
                        tabBarController.selectedIndex = 1
                        marketVC.switchToTab(index: 1) // 0:自选, 1:沪深
                    } else {
                        // 兜底：直接 present 一个新的行情页并切换到沪深
                        let marketVC = MarketViewController()
                        marketVC.switchToTab(index: 1)
                        marketVC.hidesBottomBarWhenPushed = true
                        self?.navigationController?.pushViewController(marketVC, animated: true)
                    }
                }
            }
            return cell
        case 2:
            // 城市Banner图
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageBannerCell", for: indexPath) as! ImageBannerTableViewCell
            // 可以传入多张图片，暂时使用空数组（会显示默认图片）
            cell.configure(with: [])
            cell.onBannerTap = {  index in
                // 处理城市banner点击事件
                print("City Banner tapped at index: \(index)")
            }
            return cell
        case 3:
            // 新闻列表
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath) as! NewsTableViewCell
            cell.onNewsItemTapped = { [weak self] title, time in
                // 跳转到新闻详情页
                let detailVC = NewsDetailViewController()
                // 设置HTML内容（示例内容，实际应该根据title从服务器获取）
                detailVC.htmlContent = self?.getNewsContent(for: title)
                detailVC.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(detailVC, animated: true)
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
            return 162 // Banner高度
        case 1:
            return 180
        case 2:
            return 110 + 32 // 城市Banner高度110 + 上下间距32
        case 3:
            return UITableView.automaticDimension
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 3:
            return 200
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
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10), // 顶部间距15
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15) // 底部间距15
        ])
    }
    
    func configure(with items: [(String, String)]) {
        self.items = items
        
        // 清除旧的视图
        containerView.subviews.forEach { $0.removeFromSuperview() }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20 // 上下两个item的间距是20
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建两行
        for row in 0..<2 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 0
            
            for col in 0..<4 {
                let index = row * 4 + col
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
        
        let iconImageView = UIImageView(image: UIImage(named: iconName))
        iconImageView.contentMode = .scaleAspectFill
        container.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14) // 文字大小14
        titleLabel.textColor = UIColor(hexString: "#1C1C1C") ?? UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0) // 颜色#1C1C1C
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2 // 最多2行
        titleLabel.lineBreakMode = .byTruncatingTail
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
        contentStack.spacing = 10 // 图标与文字间距10
        contentStack.distribution = .fill
        container.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.addArrangedSubview(iconImageView)
        contentStack.addArrangedSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            // 图标37*37
            iconImageView.widthAnchor.constraint(equalToConstant: 37),
            iconImageView.heightAnchor.constraint(equalToConstant: 37),
            
            // contentStack居中
            contentStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 4),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -4),
            
            // 文字宽度限制
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80) // 确保文字不会太宽
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
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
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
    private var newsData: [[(String, String)]] = [] // 不同分类的新闻数据
    var onNewsItemTapped: ((String, String) -> Void)? // 新闻项点击回调 (title, time)
    
    // 新闻数据源（示例数据，实际应该从网络或数据库获取）
    private let newsDataSource: [[(String, String)]] = [
        // 国内经济
        [
            ("元旦假期全社会跨区域人员流动量预计5.9亿人次元旦假期全社会跨区域人员流动量预计5.9亿人次元旦假期全社会跨区域人员流动量预计5.9亿人次", "2026-01-03 16:21:24"),
            ("2026购在中国暨新春消费季启动", "2026-01-03 16:21:24"),
            ("国内经济持续稳定增长，消费市场活跃", "2026-01-03 15:30:00")
        ],
        // 国外经济
        [
            ("全球股市震荡，投资者关注美联储政策", "2026-01-03 16:21:24"),
            ("欧洲央行维持利率不变，市场反应积极", "2026-01-03 16:21:24"),
            ("亚洲市场表现强劲，科技股领涨", "2026-01-03 15:30:00")
        ],
        // 证券要闻
        [
            ("A股市场迎来开门红，三大指数集体上涨", "2026-01-03 16:21:24"),
            ("证监会发布新规，规范市场交易行为", "2026-01-03 16:21:24"),
            ("券商板块表现亮眼，多只个股涨停", "2026-01-03 15:30:00")
        ],
        // 公司资讯
        [
            ("多家上市公司发布业绩预告", "2026-01-03 16:21:24"),
            ("科技公司加大研发投入，布局新赛道", "2026-01-03 16:21:24"),
            ("新能源企业获得重大订单，股价上涨", "2026-01-03 15:30:00")
        ]
    ]
    
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
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 新闻标签
        containerView.addSubview(tabView)
        tabView.translatesAutoresizingMaskIntoConstraints = false
        
        let tabs = ["国内经济", "国外经济", "证券要闻", "公司资讯"]
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
            
            newsStackView.topAnchor.constraint(equalTo: tabView.bottomAnchor, constant: 16),
            newsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            newsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            newsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
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
        for (index, button) in tabButtons.enumerated() {
            if index == selectedIndex {
                // 选中状态：蓝色背景，白色文字
                button.backgroundColor = UIColor(hex: 0x1B47B7)
                button.layer.cornerRadius = 6
                button.setTitleColor(.white, for: .normal)
            } else {
                // 未选中状态：白色背景，灰色文字
                button.backgroundColor = UIColor(hex: 0xF8F9FB)
                button.layer.cornerRadius = 0
                button.setTitleColor(UIColor(hex:0x1C1C1C), for: .normal)
            }
        }
    }
    
    private func updateNewsList() {
        // 清除旧的新闻项
        newsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 获取当前分类的新闻数据
        let currentNews = newsDataSource[selectedIndex]
        
        // 添加新的新闻项
        for (index, news) in currentNews.enumerated() {
            let newsItemView = createNewsItemView(title: news.0, time: news.1)
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
    }
    
    private func createNewsItemView(title: String, time: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.isUserInteractionEnabled = true
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = UIColor(hex: 0x1C1C1C) // 标题黑色
        titleLabel.numberOfLines = 2 // 不限制行数，根据内容自动换行
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.isUserInteractionEnabled = false
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let timeLabel = UILabel()
        timeLabel.text = "发布时间:\(time)" // 注意冒号后面没有空格
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = UIColor(hex: 0xADADAD) // 浅灰色
        timeLabel.isUserInteractionEnabled = false
        container.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(newsItemTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        
        // 使用关联对象存储标题和时间
        objc_setAssociatedObject(container, &AssociatedKeys.newsTitle, title, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        objc_setAssociatedObject(container, &AssociatedKeys.newsTime, time, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        
        NSLayoutConstraint.activate([
            // 标题顶部间距
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            // 发布时间在标题下方，间距8
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            // 底部间距
            timeLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        
        return container
    }
    
    @objc private func newsItemTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view,
              let title = objc_getAssociatedObject(view, &AssociatedKeys.newsTitle) as? String,
              let time = objc_getAssociatedObject(view, &AssociatedKeys.newsTime) as? String else {
            return
        }
        onNewsItemTapped?(title, time)
    }
}

// 关联对象键
private struct AssociatedKeys {
    static var newsTitle = "newsTitle"
    static var newsTime = "newsTime"
}
