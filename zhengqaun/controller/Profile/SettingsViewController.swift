//
//  SettingsViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

class SettingsViewController: ZQViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let logoutButton = UIButton(type: .system)
    
    private var settingsItems: [(title: String, value: String?)] = [
        ("个人信息", nil),
        ("版本更新", "当前版本8.8.9"),
        ("清理缓存", "计算中...")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadCacheSize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 每次显示时重新计算缓存大小
        loadCacheSize()
    }
    
    private func loadCacheSize() {
        // 在后台线程计算缓存大小
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let cacheSize = CacheManager.shared.calculateCacheSize()
            let formattedSize = CacheManager.shared.formatCacheSize(cacheSize)
            
            DispatchQueue.main.async {
                self?.updateCacheSize(formattedSize)
            }
        }
    }
    
    private func updateCacheSize(_ size: String) {
        settingsItems[2].value = size
        tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
    }
    
    private func setupNavigationBar() {
        gk_navTitle = "设置"
        gk_navBackgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // #1976D2
        gk_navTitleColor = .white
        gk_statusBarStyle = .lightContent
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 设置表格视图
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Constants.Color.separator
        tableView.backgroundColor = .white
        tableView.isScrollEnabled = false
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // 退出登录按钮
        logoutButton.setTitle("退出登录", for: .normal)
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        logoutButton.backgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // #1976D2
        logoutButton.layer.cornerRadius = 8
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        view.addSubview(logoutButton)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: CGFloat(settingsItems.count * 50)),
            
            logoutButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 40),
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func logoutTapped() {
        // 显示确认对话框
        let alert = UIAlertController(title: "提示", message: "确定要退出登录吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        present(alert, animated: true)
    }
    
    private func performLogout() {
        // 清除登录状态
        UserAuthManager.shared.isLoggedIn = false
        
        // 切换到登录页面
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.switchToLogin()
        }
    }
    
    private func clearCache() {
        // 显示确认对话框
        let alert = UIAlertController(title: "清理缓存", message: "确定要清理所有缓存吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            self?.performClearCache()
        })
        present(alert, animated: true)
    }
    
    private func performClearCache() {
        // 显示清理中状态
        settingsItems[2].value = "清理中..."
        tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
        
        // 执行清理
        CacheManager.shared.clearCache { [weak self] success, message in
            if success {
                Toast.show("缓存已清理")
                // 重新计算缓存大小
                self?.loadCacheSize()
            } else {
                Toast.show("清理失败：\(message)")
                // 即使失败也重新计算，显示当前大小
                self?.loadCacheSize()
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "SettingsCell")
        let item = settingsItems[indexPath.row]
        
        cell.textLabel?.text = item.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.textLabel?.textColor = Constants.Color.textPrimary
        
        if let value = item.value {
            cell.detailTextLabel?.text = value
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
            cell.detailTextLabel?.textColor = Constants.Color.textSecondary
        }
        
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = settingsItems[indexPath.row]
        switch item.title {
        case "个人信息":
            // TODO: 跳转到个人信息页面
            let vc = PersonalProfileViewController()
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
            break
        case "版本更新":
            // TODO: 检查版本更新
            Toast.show("当前已是最新版本")
            break
        case "清理缓存":
            clearCache()
            break
        default:
            break
        }
    }
}

