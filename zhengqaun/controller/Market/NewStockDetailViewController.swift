//
//  NewStockDetailViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/2/23.
//

import UIKit

class NewStockDetailViewController: ZQViewController {
    
    // 传入的股票ID，用于请求详情
    var stockId: String = ""
    
    // 当前的新股代码，请求申购接口时使用
    private var currentSgCode: String = ""
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 存放所有的行视图
    private let listStackView = UIStackView()
    
    // 底部申购按钮
    private let submitButton = UIButton(type: .system)
    
    // UI 需要更新的数据项引用
    private var detailLabels: [String: UILabel] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadDetailData()
    }
    
    private func setupNavigationBar() {
        gk_navTitle = "新股申购"
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .black
        gk_navBackgroundColor = .white
        gk_navLineHidden = false
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // 列表区域
        listStackView.axis = .vertical
        listStackView.backgroundColor = .white
        listStackView.distribution = .fillProportionally
        listStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(listStackView)
        
        // 底部申购按钮
        submitButton.setTitle("一键申购", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        submitButton.backgroundColor = UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1.0) // 红色
        submitButton.layer.cornerRadius = 22
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(submitButton)
        
        let navH = Constants.Navigation.totalNavigationHeight
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -16),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            listStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            listStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            listStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            listStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // 预设各项的占位UI
        setupRows()
    }
    
    private func setupRows() {
        let titles = [
            "股票名称",
            "申购代码",
            "行业市盈",
            "所属板块",
            "发行价格",
            "发行数量(万股)",
            "网上发行数量(万股)"
        ]
        
        for (index, title) in titles.enumerated() {
            let rowView = UIView()
            rowView.translatesAutoresizingMaskIntoConstraints = false
            rowView.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
            titleLabel.font = UIFont.systemFont(ofSize: 14)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            rowView.addSubview(titleLabel)
            
            let valueLabel = UILabel()
            valueLabel.text = "--"
            valueLabel.textColor = .black
            valueLabel.font = UIFont.systemFont(ofSize: 14)
            valueLabel.translatesAutoresizingMaskIntoConstraints = false
            rowView.addSubview(valueLabel)
            
            // 下划线
            if index < titles.count - 1 {
                let line = UIView()
                line.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
                line.translatesAutoresizingMaskIntoConstraints = false
                rowView.addSubview(line)
                
                NSLayoutConstraint.activate([
                    line.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 16),
                    line.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
                    line.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                    line.heightAnchor.constraint(equalToConstant: 0.5)
                ])
            }
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                
                valueLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -16),
                valueLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor)
            ])
            
            detailLabels[title] = valueLabel
            listStackView.addArrangedSubview(rowView)
        }
    }
    
    private func loadDetailData() {
        guard !stockId.isEmpty else { return }
        
        SecureNetworkManager.shared.request(
            api: "/api/subscribe/lstDetail",
            method: .get,
            params: ["id": stockId]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard res.statusCode == 200,
                      let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let info = data["info"] as? [String: Any] else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.updateUI(with: info)
                }
                
            case .failure(let err):
                DispatchQueue.main.async {
                    Toast.show("获取详情失败: \(err.localizedDescription)")
                }
            }
        }
    }
    
    private func updateUI(with info: [String: Any]) {
        let name = info["name"] as? String ?? ""
        let sgCode = info["sgcode"] as? String ?? ""
        self.currentSgCode = sgCode
        let fxRate = "\(info["fx_rate"] ?? "0")%"
        
        let sgTypeStr: String
        if let typeInt = info["sg_type"] as? Int {
            sgTypeStr = "\(typeInt)"
        } else if let typeStr = info["sg_type"] as? String {
            sgTypeStr = typeStr
        } else {
            sgTypeStr = "\(info["type"] ?? "")"
        }
        
        // 板块转换
        let market: String = {
            switch sgTypeStr { case "1": return "沪"; case "2": return "深"; case "3": return "创"; case "4": return "北"; case "5": return "科"; default: return "沪" }
        }()
        
        let fxPrice = "\(info["fx_price"] ?? "0")"
        
        // 发行数量/网上发行数量计算(万股)
        let fxNumStr = formatToWan(info["fx_num"])
        let wsFxNumStr = formatToWan(info["wsfx_num"])
        
        detailLabels["股票名称"]?.text = name
        detailLabels["申购代码"]?.text = sgCode
        detailLabels["行业市盈"]?.text = fxRate
        detailLabels["所属板块"]?.text = market
        detailLabels["发行价格"]?.text = fxPrice
        detailLabels["发行数量(万股)"]?.text = fxNumStr
        detailLabels["网上发行数量(万股)"]?.text = wsFxNumStr
        
        gk_navTitle = name.isEmpty ? "新股详情" : name
    }
    
    private func formatToWan(_ raw: Any?) -> String {
        guard let raw = raw else { return "0" }
        if let intVal = raw as? Int {
            return String(format: "%.2f", Double(intVal) / 10000.0)
        } else if let strVal = raw as? String, let dVal = Double(strVal) {
            return String(format: "%.2f", dVal / 10000.0)
        }
        return "\(raw)"
    }
    
    @objc private func submitTapped() {
        guard !currentSgCode.isEmpty else { return }
        
        let alert = UIAlertController(title: "提示", message: "确定申购吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { [weak self] _ in
            self?.performSubscribe()
        }))
        present(alert, animated: true)
    }
    
    private func performSubscribe() {
        // loading
        submitButton.isEnabled = false
        
        SecureNetworkManager.shared.request(
            api: "/api/subscribe/add",
            method: .post,
            params: ["code": currentSgCode]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.submitButton.isEnabled = true
                
                switch result {
                case .success(let res):
                    if res.statusCode == 200 {
                        let msg = res.decrypted?["msg"] as? String ?? "申购成功"
                        Toast.show(msg)
                    } else {
                        Toast.show("申购异常(Code: \(res.statusCode))")
                    }
                case .failure(let err):
                    Toast.show("提交失败: \(err.localizedDescription)")
                }
            }
        }
    }
}
