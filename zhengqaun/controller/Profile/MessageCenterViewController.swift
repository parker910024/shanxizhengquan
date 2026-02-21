//
//  MessageCenterViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

/// 消息状态
enum MessageStatus {
    case unread  // 未读
    case read    // 已读
}

/// 消息模型
struct Message {
    let id: String
    let content: String
    let date: String
    let status: MessageStatus
}

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
        gk_navTitle = "消息中心"
        gk_navBackgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // #1976D2
        gk_navTitleColor = .white
        gk_statusBarStyle = .lightContent
        gk_navItemRightSpace = 15 // 设置右侧间距为15
        
        // 右侧"全部已读"按钮
        markAllReadButton.setTitle("全部已读", for: .normal)
        markAllReadButton.setTitleColor(.white, for: .normal)
        markAllReadButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        markAllReadButton.addTarget(self, action: #selector(markAllReadTapped), for: .touchUpInside)
        gk_navRightBarButtonItem = UIBarButtonItem(customView: markAllReadButton)
    }
    
    private func setupUI() {
        view.backgroundColor = Constants.Color.backgroundMain
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = Constants.Color.backgroundMain
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight + 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func loadData() {
        // 模拟消息数据
        messages = [
            Message(id: "1", content: "消息内容", date: "2026-01-06", status: .unread),
            Message(id: "2", content: "消息内容", date: "2026-01-06", status: .read),
            Message(id: "3", content: "消息内容", date: "2026-01-06", status: .unread)
        ]
        tableView.reloadData()
    }
    
    @objc private func markAllReadTapped() {
        // 将所有消息标记为已读
        messages = messages.map { Message(id: $0.id, content: $0.content, date: $0.date, status: .read) }
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
        return 90 // 增加高度以确保日期完整显示
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 标记为已读
        var message = messages[indexPath.row]
        if message.status == .unread {
            message = Message(id: message.id, content: message.content, date: message.date, status: .read)
            messages[indexPath.row] = message
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        
        // TODO: 跳转到消息详情页面
    }
}

// MARK: - MessageCell
class MessageCell: UITableViewCell {
    
    private let containerView = UIView()
    private let iconView = UIView()
    private let iconImageView = UIImageView()
    private let contentLabel = UILabel()
    private let dateLabel = UILabel()
    private let statusLabel = UILabel()
    
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
        
        // 消息图标（橙色圆形背景）
        iconView.backgroundColor = UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0) // 橙色
        iconView.layer.cornerRadius = 20
        containerView.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        iconImageView.image = UIImage(systemName: "message.fill")
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconView.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 消息内容
        contentLabel.text = "消息内容"
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.textColor = Constants.Color.textPrimary
        containerView.addSubview(contentLabel)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 日期
        dateLabel.text = "2026-01-06"
        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textColor = Constants.Color.textSecondary
        containerView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 状态标签
        statusLabel.font = UIFont.systemFont(ofSize: 12)
        statusLabel.textAlignment = .right
        containerView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            contentLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            contentLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -12),
            
            dateLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            dateLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -12),
            dateLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func configure(with message: Message) {
        contentLabel.text = message.content
        dateLabel.text = message.date
        
        switch message.status {
        case .unread:
            statusLabel.text = "未读消息"
            statusLabel.textColor = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0) // 绿色
        case .read:
            statusLabel.text = "已读"
            statusLabel.textColor = Constants.Color.stockRise // 红色
        }
    }
}

