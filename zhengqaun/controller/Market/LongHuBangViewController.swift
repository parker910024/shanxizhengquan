//
//  LongHuBangViewController.swift
//  zhengqaun
//
//  龙虎榜：日期选择 + 列头（名称、收盘、净买入、涨跌幅）+ 股票日榜列表
//

import UIKit

/// 龙虎榜单条数据
struct LongHuBangItem {
    let name: String       // 股票名称，如 "N 至信"
    let code: String       // 股票代码，如 "000060"
    let exchange: String   // 交易所，如 "沪"、"深"
    let close: String      // 收盘价，如 "8.75"
    let netBuy: String     // 净买入，如 "8.75亿"
    let changePercent: String // 涨跌幅，如 "8.75%"
}

class LongHuBangViewController: ZQViewController {

    private let dateBar = UIView()
    private let prevDateButton = UIButton(type: .system)
    private let dateLabel = UILabel()
    private let calendarButton = UIButton(type: .system)
    private let nextDateButton = UIButton(type: .system)

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let columnHeaderView = UIView()

    private var listData: [LongHuBangItem] = []
    private let cellSpacing: CGFloat = 4
    private let navH = Constants.Navigation.totalNavigationHeight

    /// 当前选中的日期，用于左右箭头加减、日期选择器
    private var selectedDate: Date = {
        var c = Calendar.current
        c.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        return c.date(from: DateComponents(year: 2026, month: 1, day: 28)) ?? Date()
    }() {
        didSet { updateDateLabel(); loadData() }
    }
    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupDateBar()
        updateDateLabel()
        setupColumnHeader()
        setupTableView()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "龙虎榜"
        gk_navLineHidden = false
        gk_statusBarStyle = .default
        gk_backStyle = .black
    }

    private func setupDateBar() {
        dateBar.backgroundColor = .white
        dateBar.layer.borderColor = UIColor(red: 0.82, green: 0.82, blue: 0.84, alpha: 1).cgColor
        dateBar.layer.borderWidth = 1.5
        dateBar.layer.cornerRadius = 8
        view.addSubview(dateBar)
        dateBar.translatesAutoresizingMaskIntoConstraints = false

        prevDateButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        prevDateButton.tintColor = Constants.Color.textPrimary
        prevDateButton.addTarget(self, action: #selector(prevDateTapped), for: .touchUpInside)
        dateBar.addSubview(prevDateButton)
        prevDateButton.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = UIFont.boldSystemFont(ofSize: 15)
        dateLabel.textColor = Constants.Color.textPrimary
        dateBar.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.isUserInteractionEnabled = true
        dateLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDatePicker)))

        calendarButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        calendarButton.tintColor = Constants.Color.textSecondary
        calendarButton.addTarget(self, action: #selector(showDatePicker), for: .touchUpInside)
        dateBar.addSubview(calendarButton)
        calendarButton.translatesAutoresizingMaskIntoConstraints = false

        nextDateButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        nextDateButton.tintColor = Constants.Color.textPrimary
        nextDateButton.addTarget(self, action: #selector(nextDateTapped), for: .touchUpInside)
        dateBar.addSubview(nextDateButton)
        nextDateButton.translatesAutoresizingMaskIntoConstraints = false

        let dateBarHorizontalMargin: CGFloat = 16
        let dateBarTopMargin: CGFloat = 14
        NSLayoutConstraint.activate([
            dateBar.topAnchor.constraint(equalTo: view.topAnchor, constant: navH + dateBarTopMargin),
            dateBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: dateBarHorizontalMargin),
            dateBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -dateBarHorizontalMargin),
            dateBar.heightAnchor.constraint(equalToConstant: 40),

            prevDateButton.leadingAnchor.constraint(equalTo: dateBar.leadingAnchor, constant: 12),
            prevDateButton.centerYAnchor.constraint(equalTo: dateBar.centerYAnchor),
            prevDateButton.widthAnchor.constraint(equalToConstant: 44),
            prevDateButton.heightAnchor.constraint(equalToConstant: 40),

            dateLabel.centerXAnchor.constraint(equalTo: dateBar.centerXAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: dateBar.centerYAnchor),

            calendarButton.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 8),
            calendarButton.centerYAnchor.constraint(equalTo: dateBar.centerYAnchor),
            calendarButton.widthAnchor.constraint(equalToConstant: 40),
            calendarButton.heightAnchor.constraint(equalToConstant: 40),

            nextDateButton.trailingAnchor.constraint(equalTo: dateBar.trailingAnchor, constant: -12),
            nextDateButton.centerYAnchor.constraint(equalTo: dateBar.centerYAnchor),
            nextDateButton.widthAnchor.constraint(equalToConstant: 44),
            nextDateButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupColumnHeader() {
        columnHeaderView.backgroundColor = .white
        let titles = ["名称", "收盘", "净买入", "涨跌幅"]
        let gray = Constants.Color.textTertiary
        let lead: CGFloat = 14
        let trail: CGFloat = 14
        let wClose: CGFloat = 52
        let wNetBuy: CGFloat = 68
        let wChange: CGFloat = 52

        let nameH = UILabel()
        nameH.text = titles[0]
        nameH.font = UIFont.systemFont(ofSize: 12)
        nameH.textColor = gray
        nameH.textAlignment = .left
        columnHeaderView.addSubview(nameH)
        nameH.translatesAutoresizingMaskIntoConstraints = false

        let closeH = UILabel()
        closeH.text = titles[1]
        closeH.font = UIFont.systemFont(ofSize: 12)
        closeH.textColor = gray
        closeH.textAlignment = .right
        columnHeaderView.addSubview(closeH)
        closeH.translatesAutoresizingMaskIntoConstraints = false

        let netBuyH = UILabel()
        netBuyH.text = titles[2]
        netBuyH.font = UIFont.systemFont(ofSize: 12)
        netBuyH.textColor = gray
        netBuyH.textAlignment = .right
        columnHeaderView.addSubview(netBuyH)
        netBuyH.translatesAutoresizingMaskIntoConstraints = false

        let changeH = UILabel()
        changeH.text = titles[3]
        changeH.font = UIFont.systemFont(ofSize: 12)
        changeH.textColor = gray
        changeH.textAlignment = .right
        columnHeaderView.addSubview(changeH)
        changeH.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameH.leadingAnchor.constraint(equalTo: columnHeaderView.leadingAnchor, constant: lead),
            nameH.centerYAnchor.constraint(equalTo: columnHeaderView.centerYAnchor),

            changeH.trailingAnchor.constraint(equalTo: columnHeaderView.trailingAnchor, constant: -trail),
            changeH.centerYAnchor.constraint(equalTo: columnHeaderView.centerYAnchor),
            changeH.widthAnchor.constraint(equalToConstant: wChange),

            netBuyH.trailingAnchor.constraint(equalTo: changeH.leadingAnchor, constant: -8),
            netBuyH.centerYAnchor.constraint(equalTo: columnHeaderView.centerYAnchor),
            netBuyH.widthAnchor.constraint(equalToConstant: wNetBuy),

            closeH.trailingAnchor.constraint(equalTo: netBuyH.leadingAnchor, constant: -8),
            closeH.centerYAnchor.constraint(equalTo: columnHeaderView.centerYAnchor),
            closeH.widthAnchor.constraint(equalToConstant: wClose),
            closeH.leadingAnchor.constraint(greaterThanOrEqualTo: nameH.trailingAnchor, constant: 8)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.register(LongHuBangCell.self, forCellReuseIdentifier: "LongHuBangCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let headerWrap = UIView()
        headerWrap.backgroundColor = .white
        headerWrap.addSubview(columnHeaderView)
        columnHeaderView.translatesAutoresizingMaskIntoConstraints = false
        let sepLine = UIView()
        sepLine.backgroundColor = Constants.Color.separator
        headerWrap.addSubview(sepLine)
        sepLine.translatesAutoresizingMaskIntoConstraints = false
        let columnHeaderHeight: CGFloat = 32
        let headerGap: CGFloat = 6
        NSLayoutConstraint.activate([
            columnHeaderView.leadingAnchor.constraint(equalTo: headerWrap.leadingAnchor),
            columnHeaderView.trailingAnchor.constraint(equalTo: headerWrap.trailingAnchor),
            columnHeaderView.topAnchor.constraint(equalTo: headerWrap.topAnchor),
            columnHeaderView.heightAnchor.constraint(equalToConstant: columnHeaderHeight),
            sepLine.leadingAnchor.constraint(equalTo: headerWrap.leadingAnchor),
            sepLine.trailingAnchor.constraint(equalTo: headerWrap.trailingAnchor),
            sepLine.topAnchor.constraint(equalTo: columnHeaderView.bottomAnchor, constant: headerGap),
            sepLine.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
        headerWrap.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: columnHeaderHeight + headerGap + 1 / UIScreen.main.scale)
        tableView.tableHeaderView = headerWrap

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: dateBar.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let header = tableView.tableHeaderView, tableView.bounds.width > 0 && header.frame.width != tableView.bounds.width {
            var f = header.frame
            f.size.width = tableView.bounds.width
            header.frame = f
            tableView.tableHeaderView = header
        }
    }

    private func updateDateLabel() {
        dateLabel.text = dateFormatter.string(from: selectedDate)
    }

    private func loadData() {
        listData = [
            LongHuBangItem(name: "N至信", code: "000060", exchange: "沪", close: "8.75", netBuy: "8.75亿", changePercent: "8.75%"),
            LongHuBangItem(name: "N至信", code: "000060", exchange: "沪", close: "8.75", netBuy: "8.75亿", changePercent: "8.75%"),
            LongHuBangItem(name: "N至信", code: "000060", exchange: "沪", close: "8.75", netBuy: "8.75亿", changePercent: "8.75%")
        ]
        tableView.reloadData()
    }

    /// 左箭头：前一天
    @objc private func prevDateTapped() {
        if let d = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = d
        }
    }

    /// 右箭头：后一天
    @objc private func nextDateTapped() {
        if let d = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            selectedDate = d
        }
    }

    /// 点击日期或日历图标：弹出日期选择
    @objc private func showDatePicker() {
        let pickerVC = LongHuBangDatePickerViewController()
        pickerVC.initialDate = selectedDate
        pickerVC.onConfirm = { [weak self] date in
            self?.selectedDate = date
        }
        if #available(iOS 15.0, *) {
            if let sheet = pickerVC.sheetPresentationController {
                if #available(iOS 16.0, *) {
                    let id = UISheetPresentationController.Detent.Identifier("datePicker")
                    let detent = UISheetPresentationController.Detent.custom(identifier: id) { _ in 280 }
                    sheet.detents = [detent, .medium()]
                } else {
                    sheet.detents = [.medium()]
                }
                sheet.prefersGrabberVisible = true
            }
        }
        present(pickerVC, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension LongHuBangViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return listData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LongHuBangCell", for: indexPath) as! LongHuBangCell
        cell.configure(with: listData[indexPath.section])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : cellSpacing
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = listData[indexPath.section]
        let vc = StockDetailViewController()
        vc.stockCode = item.code
        vc.stockName = item.name
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - 日期选择弹窗（半屏 sheet）
private class LongHuBangDatePickerViewController: UIViewController {
    var initialDate: Date = Date()
    var onConfirm: ((Date) -> Void)?

    private let datePicker = UIDatePicker()
    private let toolbar = UIView()
    private let cancelBtn = UIButton(type: .system)
    private let confirmBtn = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        datePicker.datePickerMode = .date
        datePicker.date = initialDate
        datePicker.maximumDate = Date()
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.timeZone = TimeZone(identifier: "Asia/Shanghai")
        view.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false

        toolbar.backgroundColor = UIColor(white: 0.97, alpha: 1)
        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(Constants.Color.textSecondary, for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        toolbar.addSubview(cancelBtn)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        confirmBtn.setTitle("确定", for: .normal)
        confirmBtn.setTitleColor(Constants.Color.primaryBlue, for: .normal)
        confirmBtn.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        toolbar.addSubview(confirmBtn)
        confirmBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),
            cancelBtn.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),
            cancelBtn.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            confirmBtn.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -16),
            confirmBtn.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            datePicker.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            datePicker.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    @objc private func cancelTapped() { dismiss(animated: true) }
    @objc private func confirmTapped() {
        onConfirm?(datePicker.date)
        dismiss(animated: true)
    }
}

// MARK: - LongHuBangCell
private class LongHuBangCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()
    private let exchangeBadge = UILabel()
    private let closeLabel = UILabel()
    private let netBuyLabel = UILabel()
    private let changePercentLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        selectionStyle = .default
        backgroundColor = .white

        nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        nameLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        codeLabel.font = UIFont.systemFont(ofSize: 11)
        codeLabel.textColor = Constants.Color.textSecondary
        contentView.addSubview(codeLabel)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        exchangeBadge.font = UIFont.systemFont(ofSize: 9)
        exchangeBadge.textColor = .white
        exchangeBadge.backgroundColor = Constants.Color.stockRise
        exchangeBadge.layer.cornerRadius = 2
        exchangeBadge.clipsToBounds = true
        exchangeBadge.textAlignment = .center
        contentView.addSubview(exchangeBadge)
        exchangeBadge.translatesAutoresizingMaskIntoConstraints = false

        closeLabel.font = UIFont.boldSystemFont(ofSize: 13)
        closeLabel.textColor = Constants.Color.textPrimary
        closeLabel.textAlignment = .right
        contentView.addSubview(closeLabel)
        closeLabel.translatesAutoresizingMaskIntoConstraints = false

        netBuyLabel.font = UIFont.boldSystemFont(ofSize: 13)
        netBuyLabel.textColor = Constants.Color.stockRise
        netBuyLabel.textAlignment = .right
        contentView.addSubview(netBuyLabel)
        netBuyLabel.translatesAutoresizingMaskIntoConstraints = false

        changePercentLabel.font = UIFont.boldSystemFont(ofSize: 13)
        changePercentLabel.textColor = Constants.Color.stockRise
        changePercentLabel.textAlignment = .right
        contentView.addSubview(changePercentLabel)
        changePercentLabel.translatesAutoresizingMaskIntoConstraints = false

        let pad: CGFloat = 14
        let innerSpacing: CGFloat = 8
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            codeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: innerSpacing),

            exchangeBadge.leadingAnchor.constraint(equalTo: codeLabel.trailingAnchor, constant: 5),
            exchangeBadge.centerYAnchor.constraint(equalTo: codeLabel.centerYAnchor),
            exchangeBadge.widthAnchor.constraint(equalToConstant: 14),
            exchangeBadge.heightAnchor.constraint(equalToConstant: 12),

            changePercentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            changePercentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            changePercentLabel.widthAnchor.constraint(equalToConstant: 52),

            netBuyLabel.trailingAnchor.constraint(equalTo: changePercentLabel.leadingAnchor, constant: -8),
            netBuyLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            netBuyLabel.widthAnchor.constraint(equalToConstant: 68),

            closeLabel.trailingAnchor.constraint(equalTo: netBuyLabel.leadingAnchor, constant: -8),
            closeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            closeLabel.widthAnchor.constraint(equalToConstant: 52),
            closeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: exchangeBadge.trailingAnchor, constant: 10)
        ])
    }

    func configure(with item: LongHuBangItem) {
        nameLabel.text = item.name
        codeLabel.text = item.code
        exchangeBadge.text = item.exchange
        closeLabel.text = item.close
        netBuyLabel.text = item.netBuy
        changePercentLabel.text = item.changePercent
    }
}
