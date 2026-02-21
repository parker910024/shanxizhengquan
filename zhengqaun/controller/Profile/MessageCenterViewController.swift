//
//  MessageCenterViewController.swift
//  zhengqaun
//

import UIKit

/// 消息状态
enum MessageStatus {
    case unread
    case read
}

/// 消息模型：类型标签、时间、内容、状态
struct Message {
    let id: String
    let typeLabel: String   // 认缴通知 / 中签通知 等
    let content: String
    let date: String        // 完整时间 2026-01-07 20:37:37
    let status: MessageStatus
}

/// 站内消息列表：导航栏白底+站内消息+全部已读，列表为类型标签+时间+内容+已读，底部「没有更多了」
class MessageCenterViewController: ZQViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let markAllReadButton = UIButton(type: .system)
    private var messages: [Message] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadData()
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
        let noMoreLabel = UILabel()
        noMoreLabel.text = "没有更多了"
        noMoreLabel.font = UIFont.systemFont(ofSize: 13)
        noMoreLabel.textColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        noMoreLabel.textAlignment = .center
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

    private func loadData() {
        messages = [
            Message(id: "1", typeLabel: "认缴通知", content: "您已认缴股票至信股份!", date: "2026-01-07 20:37:37", status: .read),
            Message(id: "2", typeLabel: "中签通知", content: "您已认缴股票至信股份!", date: "2026-01-07 20:37:37", status: .read)
        ]
        tableView.reloadData()
    }

    @objc private func markAllReadTapped() {
        messages = messages.map { Message(id: $0.id, typeLabel: $0.typeLabel, content: $0.content, date: $0.date, status: .read) }
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var message = messages[indexPath.row]
        if message.status == .unread {
            message = Message(id: message.id, typeLabel: message.typeLabel, content: message.content, date: message.date, status: .read)
            messages[indexPath.row] = message
            tableView.reloadRows(at: [indexPath], with: .none)
        }
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

        typeTag.font = UIFont.systemFont(ofSize: 12)
        typeTag.textColor = .white
        typeTag.backgroundColor = UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0)
        typeTag.layer.cornerRadius = 4
        typeTag.clipsToBounds = true
        typeTag.textAlignment = .center
        contentView.addSubview(typeTag)
        typeTag.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.font = UIFont.systemFont(ofSize: 13)
        timeLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.44, alpha: 1.0)
        contentView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentLabel.font = UIFont.systemFont(ofSize: 15)
        contentLabel.textColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        contentLabel.numberOfLines = 0
        contentView.addSubview(contentLabel)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        contentView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        separator.backgroundColor = UIColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1.0)
        contentView.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            typeTag.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            typeTag.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            typeTag.heightAnchor.constraint(equalToConstant: 22),
            typeTag.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            timeLabel.leadingAnchor.constraint(equalTo: typeTag.trailingAnchor, constant: 8),
            timeLabel.centerYAnchor.constraint(equalTo: typeTag.centerYAnchor),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),

            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusLabel.centerYAnchor.constraint(equalTo: typeTag.centerYAnchor),

            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentLabel.topAnchor.constraint(equalTo: typeTag.bottomAnchor, constant: 10),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

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
        statusLabel.text = message.status == .read ? "已读" : "未读"
        statusLabel.textColor = message.status == .read
            ? UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
            : UIColor(red: 0.4, green: 0.4, blue: 0.44, alpha: 1.0)
    }
}
