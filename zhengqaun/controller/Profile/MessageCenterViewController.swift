//
//  MessageCenterViewController.swift
//  zhengqaun
//

import UIKit

/// 消息模型
struct Message {
    let id: String
    let typeLabel: String   // 认缴通知 / 中签通知 等 (这里用解析方式或默认设为通知)
    let content: String
    let date: String        // 完整时间 2026-01-07 20:37:37
    var isRead: Bool
}

/// 站内消息列表：导航栏白底+站内消息+全部已读，列表为类型标签+时间+内容+已读，底部「没有更多了」
class MessageCenterViewController: ZQViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let markAllReadButton = UIButton(type: .system)
    private let emptyLabel = UILabel()
    private var messages: [Message] = []
    
    // 分页用
    private var currentPage = 1
    private var isLoading = false
    private var isNoMoreData = false
    private let noMoreLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupEmptyLabel()
        loadData(isRefresh: true)
    }

    private func setupNavigationBar() {
        gk_navTitle = "站内消息"
        gk_navBackgroundColor = .white
        gk_navTintColor = .black
        gk_navTitleColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_statusBarStyle = .default
        gk_navLineHidden = false
        gk_navItemRightSpace = 15
        gk_backStyle = .black

        markAllReadButton.setTitle("全部已读", for: .normal)
        markAllReadButton.setTitleColor(UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0), for: .normal)
        markAllReadButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        markAllReadButton.addTarget(self, action: #selector(markAllReadTapped), for: .touchUpInside)
        gk_navRightBarButtonItem = UIBarButtonItem(customView: markAllReadButton)
    }

    private func setupUI() {
        view.backgroundColor = .white

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let footer = UIView()
        footer.backgroundColor = .white
        
        noMoreLabel.text = "没有更多了"
        noMoreLabel.font = UIFont.systemFont(ofSize: 13)
        noMoreLabel.textColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        noMoreLabel.textAlignment = .center
        noMoreLabel.isHidden = true
        footer.addSubview(noMoreLabel)
        noMoreLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noMoreLabel.centerXAnchor.constraint(equalTo: footer.centerXAnchor),
            noMoreLabel.topAnchor.constraint(equalTo: footer.topAnchor, constant: 20),
            noMoreLabel.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: -20)
        ])
        footer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 56)
        tableView.tableFooterView = footer

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight + 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    /// 配置空数据提示
    private func setupEmptyLabel() {
        emptyLabel.text = "暂无消息"
        emptyLabel.font = UIFont.systemFont(ofSize: 15)
        emptyLabel.textColor = Constants.Color.textTertiary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }

    private func loadData(isRefresh: Bool = false) {
        guard !isLoading else { return }
        if isRefresh {
            currentPage = 1
            isNoMoreData = false
        }
        guard !isNoMoreData else { return }
        
        isLoading = true
        if isRefresh && messages.isEmpty {
        }
        
        let params: [String: Any] = ["page": currentPage]
        
        SecureNetworkManager.shared.request(api: Api.message_list_api, method: .post, params: params) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let response):
                guard response.statusCode == 200,
                      let dec = response.decrypted,
                      let code = dec["code"] as? Int, code == 1 else {
                    if isRefresh {
                        self.messages = []
                        self.tableView.reloadData()
                        self.emptyLabel.isHidden = false
                    }
                    return
                }
                
                var newItems: [Message] = []
                if let dataDict = dec["data"] as? [String: Any],
                   let listDict = dataDict["list"] as? [String: Any],
                   let arr = listDict["data"] as? [[String: Any]] {
                    
                    for itemInfo in arr {
                        let idVal = "\(itemInfo["id"] ?? "")"
                        let titleVal = "\(itemInfo["title"] ?? "")"
                        let dateVal = "\(itemInfo["createtime"] ?? "")"
                        let isReadVal = "\(itemInfo["is_read"] ?? "0")" == "1"
                        
                        // 提取通知前缀（如果有），否则默认为"系统通知"
                        var tLabel = "系统通知"
                        var pureContent = titleVal
                        if titleVal.contains("通知") {
                            // 拆取前几个字作为分类
                            if let r = titleVal.range(of: "通知") {
                                let prefix = titleVal[..<r.upperBound]
                                tLabel = String(prefix)
                            }
                        }
                        
                        newItems.append(Message(id: idVal, typeLabel: tLabel, content: pureContent, date: dateVal, isRead: isReadVal))
                    }
                    
                    if isRefresh {
                        self.messages = newItems
                    } else {
                        self.messages.append(contentsOf: newItems)
                    }
                    
                    // 分页判断
                    let lastPage = listDict["last_page"] as? Int ?? 1
                    if self.currentPage >= lastPage || arr.isEmpty {
                        self.isNoMoreData = true
                        self.noMoreLabel.isHidden = self.messages.isEmpty
                    } else {
                        self.currentPage += 1
                        self.noMoreLabel.isHidden = true
                    }
                }
                
                self.tableView.reloadData()
                self.emptyLabel.isHidden = !self.messages.isEmpty
                
            case .failure(let error):
                if isRefresh {
                    self.messages = []
                    self.tableView.reloadData()
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }

    @objc private func markAllReadTapped() {
        // 由于没有真实的全读接口，我们仅把本地全漂红
        messages = messages.map {
            var m = $0
            m.isRead = true
            return m
        }
        tableView.reloadData()
        Toast.show("全部已读")
    }
}

// MARK: - UITableViewDataSource
extension MessageCenterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MessageCenterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == messages.count - 1 && !isNoMoreData && !isLoading {
            loadData()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var message = messages[indexPath.row]
        if !message.isRead {
            message.isRead = true
            messages[indexPath.row] = message
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        let detailVC = MessageDetailViewController()
        detailVC.message = message
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - MessageCell（类型标签 + 时间 + 内容，右侧已读）
class MessageCell: UITableViewCell {

    private let typeTag = UILabel()
    private let timeLabel = UILabel()
    private let contentLabel = UILabel()
    private let statusLabel = UILabel()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white

        typeTag.font = UIFont.systemFont(ofSize: 11)
        typeTag.textColor = .white
        typeTag.backgroundColor = UIColor(red: 0.95, green: 0.55, blue: 0.0, alpha: 1.0) // 橙色
        typeTag.layer.cornerRadius = 2
        typeTag.clipsToBounds = true
        typeTag.textAlignment = .center
        contentView.addSubview(typeTag)
        typeTag.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        contentView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        contentLabel.numberOfLines = 0
        contentView.addSubview(contentLabel)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = UIFont.systemFont(ofSize: 15)
        statusLabel.textColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        statusLabel.textAlignment = .right
        contentView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        separator.backgroundColor = Constants.Color.separator
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            typeTag.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            typeTag.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            typeTag.heightAnchor.constraint(equalToConstant: 20),
            typeTag.widthAnchor.constraint(equalToConstant: 56),

            timeLabel.leadingAnchor.constraint(equalTo: typeTag.trailingAnchor, constant: 6),
            timeLabel.centerYAnchor.constraint(equalTo: typeTag.centerYAnchor),

            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusLabel.centerYAnchor.constraint(equalTo: typeTag.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: timeLabel.trailingAnchor, constant: 8),

            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentLabel.topAnchor.constraint(equalTo: typeTag.bottomAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }

    func configure(with message: Message) {
        typeTag.text = message.typeLabel
        timeLabel.text = "时间:" + message.date
        contentLabel.text = message.content
        statusLabel.text = message.isRead ? "已读" : ""
        statusLabel.textColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    }
}
