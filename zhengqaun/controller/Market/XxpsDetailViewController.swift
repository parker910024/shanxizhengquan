//
//  XxpsDetailViewController.swift
//  zhengqaun
//
//  线下配售详情页：基本资料 + 战略配售手数 + 配售按钮 + 密钥弹框
//

import UIKit

class XxpsDetailViewController: ZQViewController {

    // MARK: - 传入参数
    var stockId: String = ""

    // MARK: - 颜色
    private let themeRed  = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1)
    private let bgColor   = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
    private let textPrimary = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1)
    private let textSecondary = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    private let lineColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)

    // MARK: - 数据
    private var stockCode: String = ""
    private var stockName: String = ""
    private var fxPrice: Double = 0        // 发行价
    private var contentKey: String = ""    // 密钥（content），为空不弹框
    private var psMax: Int = 10000000      // 最大配售手数
    private var currentNums: Int = 1       // 当前选择手数

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentViewWrapper = UIView()
    private var detailLabels: [String: UILabel] = [:]
    private let numsLabel = UILabel()
    private let submitButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadDetailData()
    }

    private func setupNavigationBar() {
        gk_navTitle = "线下配售"
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .black
        gk_navBackgroundColor = .white
        gk_navLineHidden = false
        gk_backStyle = .black
    }

    // MARK: - 构建 UI
    private func setupUI() {
        view.backgroundColor = bgColor

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentViewWrapper.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentViewWrapper)

        let navH = Constants.Navigation.totalNavigationHeight

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentViewWrapper.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentViewWrapper.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentViewWrapper.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentViewWrapper.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentViewWrapper.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        // ═══ 1. 基本资料区域 ═══
        let infoCard = UIView()
        infoCard.backgroundColor = .white
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        contentViewWrapper.addSubview(infoCard)

        let infoTitle = makeSectionTitle("基本资料")
        infoCard.addSubview(infoTitle)

        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(infoStack)

        let infoRows = [
            "股票代码",
            "所属行业",
            "发行市盈",
            "板块",
            "发行价",
            "发行总量(万股)"
        ]
        for (i, title) in infoRows.enumerated() {
            let row = makeRow(title: title, showLine: i < infoRows.count - 1)
            infoStack.addArrangedSubview(row)
        }

        NSLayoutConstraint.activate([
            infoCard.topAnchor.constraint(equalTo: contentViewWrapper.topAnchor, constant: 10),
            infoCard.leadingAnchor.constraint(equalTo: contentViewWrapper.leadingAnchor, constant: 12),
            infoCard.trailingAnchor.constraint(equalTo: contentViewWrapper.trailingAnchor, constant: -12),

            infoTitle.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 12),
            infoTitle.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),

            infoStack.topAnchor.constraint(equalTo: infoTitle.bottomAnchor, constant: 4),
            infoStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            infoStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            infoStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -8),
        ])

        // ═══ 2. 战略配售手数区域 ═══
        let numsCard = UIView()
        numsCard.backgroundColor = .white
        numsCard.translatesAutoresizingMaskIntoConstraints = false
        contentViewWrapper.addSubview(numsCard)

        let numsTitle = makeSectionTitle("战略配售手数")
        numsCard.addSubview(numsTitle)

        // 减号按钮
        let minusBtn = UIButton(type: .system)
        minusBtn.setTitle("−", for: .normal)
        minusBtn.setTitleColor(textPrimary, for: .normal)
        minusBtn.titleLabel?.font = .systemFont(ofSize: 22, weight: .medium)
        minusBtn.layer.borderWidth = 1
        minusBtn.layer.borderColor = lineColor.cgColor
        minusBtn.layer.cornerRadius = 4
        minusBtn.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)
        minusBtn.translatesAutoresizingMaskIntoConstraints = false
        numsCard.addSubview(minusBtn)

        // 数量标签
        numsLabel.text = "\(currentNums)"
        numsLabel.textAlignment = .center
        numsLabel.font = .systemFont(ofSize: 16, weight: .medium)
        numsLabel.textColor = textPrimary
        numsLabel.layer.borderWidth = 1
        numsLabel.layer.borderColor = lineColor.cgColor
        numsLabel.translatesAutoresizingMaskIntoConstraints = false
        numsCard.addSubview(numsLabel)

        // 加号按钮
        let plusBtn = UIButton(type: .system)
        plusBtn.setTitle("+", for: .normal)
        plusBtn.setTitleColor(textPrimary, for: .normal)
        plusBtn.titleLabel?.font = .systemFont(ofSize: 22, weight: .medium)
        plusBtn.layer.borderWidth = 1
        plusBtn.layer.borderColor = lineColor.cgColor
        plusBtn.layer.cornerRadius = 4
        plusBtn.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
        plusBtn.translatesAutoresizingMaskIntoConstraints = false
        numsCard.addSubview(plusBtn)

        // 提交按钮
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        submitButton.backgroundColor = themeRed
        submitButton.layer.cornerRadius = 6
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        numsCard.addSubview(submitButton)
        updateSubmitButtonTitle()

        NSLayoutConstraint.activate([
            numsCard.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: 10),
            numsCard.leadingAnchor.constraint(equalTo: contentViewWrapper.leadingAnchor, constant: 12),
            numsCard.trailingAnchor.constraint(equalTo: contentViewWrapper.trailingAnchor, constant: -12),
            numsCard.bottomAnchor.constraint(equalTo: contentViewWrapper.bottomAnchor, constant: -30),

            numsTitle.topAnchor.constraint(equalTo: numsCard.topAnchor, constant: 12),
            numsTitle.leadingAnchor.constraint(equalTo: numsCard.leadingAnchor, constant: 16),

            // 减号
            minusBtn.topAnchor.constraint(equalTo: numsTitle.bottomAnchor, constant: 12),
            minusBtn.leadingAnchor.constraint(equalTo: numsCard.leadingAnchor, constant: 16),
            minusBtn.widthAnchor.constraint(equalToConstant: 40),
            minusBtn.heightAnchor.constraint(equalToConstant: 40),

            // 数量
            numsLabel.topAnchor.constraint(equalTo: minusBtn.topAnchor),
            numsLabel.leadingAnchor.constraint(equalTo: minusBtn.trailingAnchor),
            numsLabel.trailingAnchor.constraint(equalTo: plusBtn.leadingAnchor),
            numsLabel.heightAnchor.constraint(equalToConstant: 40),

            // 加号
            plusBtn.topAnchor.constraint(equalTo: minusBtn.topAnchor),
            plusBtn.trailingAnchor.constraint(equalTo: numsCard.trailingAnchor, constant: -16),
            plusBtn.widthAnchor.constraint(equalToConstant: 40),
            plusBtn.heightAnchor.constraint(equalToConstant: 40),

            // 提交按钮
            submitButton.topAnchor.constraint(equalTo: minusBtn.bottomAnchor, constant: 16),
            submitButton.leadingAnchor.constraint(equalTo: numsCard.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: numsCard.trailingAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 44),
            submitButton.bottomAnchor.constraint(equalTo: numsCard.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - 辅助 UI 构建
    private func makeSectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .boldSystemFont(ofSize: 16)
        l.textColor = textPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private func makeRow(title: String, showLine: Bool) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let tl = UILabel()
        tl.text = title
        tl.font = .systemFont(ofSize: 14)
        tl.textColor = textSecondary
        tl.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(tl)

        let vl = UILabel()
        vl.text = "--"
        vl.font = .systemFont(ofSize: 14)
        vl.textColor = textPrimary
        vl.textAlignment = .right
        vl.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(vl)

        detailLabels[title] = vl

        NSLayoutConstraint.activate([
            tl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            tl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            vl.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            vl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])

        if showLine {
            let line = UIView()
            line.backgroundColor = lineColor
            line.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(line)
            NSLayoutConstraint.activate([
                line.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
                line.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                line.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                line.heightAnchor.constraint(equalToConstant: 0.5),
            ])
        }

        return row
    }

    // MARK: - 网络请求
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
                // 配售最大手数
                let psMaxVal = data["psmax"]
                if let maxStr = psMaxVal as? String, let maxInt = Int(maxStr) {
                    self.psMax = maxInt
                } else if let maxInt = psMaxVal as? Int {
                    self.psMax = maxInt
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
        // 基本数据
        stockName = info["name"] as? String ?? ""
        stockCode = info["code"] as? String ?? ""
        contentKey = info["content"] as? String ?? ""

        if let p = info["fx_price"] as? String, let pv = Double(p) {
            fxPrice = pv
        } else if let p = info["fx_price"] as? Double {
            fxPrice = p
        }

        let fxRateStr = "\(info["fx_rate"] ?? "0")%"
        let industry = info["industry"] as? String ?? ""

        // 板块
        let sgTypeStr: String
        if let typeInt = info["sg_type"] as? Int {
            sgTypeStr = "\(typeInt)"
        } else if let typeStr = info["sg_type"] as? String {
            sgTypeStr = typeStr
        } else {
            sgTypeStr = ""
        }
        let marketName: String = {
            switch sgTypeStr {
            case "1": return "沪市"
            case "2": return "深市"
            case "3": return "创业板"
            case "4": return "北交所"
            case "5": return "科创板"
            default: return ""
            }
        }()

        // 发行总量(万股)
        let fxNumStr = formatToWan(info["fx_num"])

        // 填充 UI
        detailLabels["股票代码"]?.text = stockCode
        detailLabels["所属行业"]?.text = industry.isEmpty ? "--" : industry
        detailLabels["发行市盈"]?.text = fxRateStr
        detailLabels["板块"]?.text = marketName
        detailLabels["发行价"]?.text = String(format: "%.2f", fxPrice)
        detailLabels["发行价"]?.textColor = themeRed
        detailLabels["发行总量(万股)"]?.text = fxNumStr

        gk_navTitle = stockName.isEmpty ? "线下配售" : stockName
        updateSubmitButtonTitle()
    }

    private func formatToWan(_ raw: Any?) -> String {
        guard let raw = raw else { return "0" }
        if let intVal = raw as? Int {
            return String(format: "%.1f", Double(intVal) / 10000.0)
        } else if let strVal = raw as? String, let dVal = Double(strVal) {
            return String(format: "%.1f", dVal / 10000.0)
        }
        return "\(raw)"
    }

    // MARK: - 手数操作
    @objc private func minusTapped() {
        guard currentNums > 1 else { return }
        currentNums -= 1
        numsLabel.text = "\(currentNums)"
        updateSubmitButtonTitle()
    }

    @objc private func plusTapped() {
        currentNums += 1
        numsLabel.text = "\(currentNums)"
        updateSubmitButtonTitle()
    }

    private func updateSubmitButtonTitle() {
        let total = fxPrice * Double(currentNums) * 100  // 每手100股
        let totalStr = String(format: "%.2f", total)
        submitButton.setTitle("¥\(totalStr) 战略配售", for: .normal)
    }

    // MARK: - 提交
    @objc private func submitTapped() {
        guard !stockCode.isEmpty else { return }

        // content 不为空则弹密钥框，为空直接提交
        if !contentKey.isEmpty {
            showMiyaoAlert()
        } else {
            performXxpsSubscribe(miyao: "")
        }
    }

    /// 弹出密钥输入框
    private func showMiyaoAlert() {
        let alert = UIAlertController(title: "密钥", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "请输入密钥"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "立即提交", style: .default, handler: { [weak self, weak alert] _ in
            let miyao = alert?.textFields?.first?.text ?? ""
            self?.performXxpsSubscribe(miyao: miyao)
        }))
        present(alert, animated: true)
    }

    /// 调用线下配售买入接口
    private func performXxpsSubscribe(miyao: String) {
        submitButton.isEnabled = false

        SecureNetworkManager.shared.request(
            api: "/api/subscribe/xxadd",
            method: .post,
            params: [
                "code": stockCode,
                "sg_nums": currentNums,
                "miyao": miyao
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.submitButton.isEnabled = true

                switch result {
                case .success(let res):
                    let dict = res.decrypted
                    let code = dict?["code"] as? Int ?? 0
                    let msg = dict?["msg"] as? String ?? "配售成功"
                    if code == 1 {
                        Toast.show(msg)
                        self?.navigationController?.popViewController(animated: true)
                    } else {
                        Toast.show(msg)
                    }
                case .failure(let err):
                    Toast.show("提交失败: \(err.localizedDescription)")
                }
            }
        }
    }
}
