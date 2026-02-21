//
//  StockListTableViewCell.swift
//  zhengqaun
//
//  自选/行情股票列表 Cell：名称、最新价、涨幅（我的自选页使用）
//

import UIKit

// MARK: - Stock List Cell (股票列表：名称 / 最新价 / 涨幅)
class StockListTableViewCell: UITableViewCell {
    private let containerView = UIView()
    private let headerView = UIView()
    private let stockStackView = UIStackView()
    var onStockTapped: ((String, String, String) -> Void)? // (name, code, exchange)
    private var stocksData: [(String, String, String, String, Bool)] = []

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

        // 表头
        headerView.backgroundColor = Constants.Color.backgroundMain
        containerView.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = "名称"
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.textColor = Constants.Color.textSecondary
        headerView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let priceLabel = UILabel()
        priceLabel.text = "最新价"
        priceLabel.font = UIFont.systemFont(ofSize: 15)
        priceLabel.textColor = Constants.Color.textSecondary
        headerView.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        let changeContainer = UIView()
        headerView.addSubview(changeContainer)
        changeContainer.translatesAutoresizingMaskIntoConstraints = false
        let sortIcon = UIImageView(image: UIImage(systemName: "arrowtriangle.up"))
        sortIcon.tintColor = Constants.Color.orange
        sortIcon.contentMode = .scaleAspectFit
        changeContainer.addSubview(sortIcon)
        sortIcon.translatesAutoresizingMaskIntoConstraints = false
        let changeLabel = UILabel()
        changeLabel.text = "涨幅"
        changeLabel.font = UIFont.systemFont(ofSize: 15)
        changeLabel.textColor = Constants.Color.textSecondary
        changeContainer.addSubview(changeLabel)
        changeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sortIcon.leadingAnchor.constraint(equalTo: changeContainer.leadingAnchor),
            sortIcon.centerYAnchor.constraint(equalTo: changeContainer.centerYAnchor),
            sortIcon.widthAnchor.constraint(equalToConstant: 10),
            sortIcon.heightAnchor.constraint(equalToConstant: 10),
            changeLabel.leadingAnchor.constraint(equalTo: sortIcon.trailingAnchor, constant: 2),
            changeLabel.centerYAnchor.constraint(equalTo: changeContainer.centerYAnchor),
            changeLabel.trailingAnchor.constraint(equalTo: changeContainer.trailingAnchor)
        ])

        // 股票列表
        stockStackView.axis = .vertical
        stockStackView.spacing = 0
        containerView.addSubview(stockStackView)
        stockStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 40),

            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: Constants.Spacing.lg),
            nameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            priceLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            priceLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            changeContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -Constants.Spacing.lg),
            changeContainer.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            stockStackView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            stockStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stockStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stockStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    func configure(with stocks: [(String, String, String, String, Bool)]) {
        self.stocksData = stocks
        stockStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, stock) in stocks.enumerated() {
            let stockRow = createStockRow(
                name: stock.0,
                code: stock.1,
                price: stock.2,
                change: stock.3,
                isRising: stock.4,
                index: index
            )
            stockStackView.addArrangedSubview(stockRow)
        }

        let endLabel = UILabel()
        endLabel.text = "--END--"
        endLabel.font = UIFont.systemFont(ofSize: 12)
        endLabel.textColor = Constants.Color.textTertiary
        endLabel.textAlignment = .center
        stockStackView.addArrangedSubview(endLabel)
    }

    /// 交易所徽章颜色: 深-浅蓝, 京-浅紫, 沪-浅橙, 创-浅绿, 科-浅粉
    private static func badgeColor(for exchange: String) -> UIColor {
        switch exchange {
        case "深": return UIColor(red: 0.26, green: 0.65, blue: 0.96, alpha: 1.0)
        case "京": return UIColor(red: 0.67, green: 0.28, blue: 0.74, alpha: 1.0)
        case "沪": return UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
        case "创": return UIColor(red: 0.4, green: 0.73, blue: 0.42, alpha: 1.0)
        case "科": return UIColor(red: 0.93, green: 0.25, blue: 0.48, alpha: 1.0)
        default:  return Constants.Color.textTertiary
        }
    }

    private func createStockRow(name: String, code: String, price: String, change: String, isRising: Bool, index: Int) -> UIView {
        let row = UIView()
        row.backgroundColor = .white
        row.tag = index

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(stockRowTapped(_:)))
        row.addGestureRecognizer(tapGesture)
        row.isUserInteractionEnabled = true

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.textColor = Constants.Color.textPrimary
        row.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let parts = code.split(separator: " ", maxSplits: 1).map(String.init)
        let exchange = parts.first ?? ""
        let codeNum = parts.count > 1 ? parts[1] : code

        let badge = UILabel()
        badge.text = exchange
        badge.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        badge.textColor = .white
        badge.backgroundColor = Self.badgeColor(for: exchange)
        badge.layer.cornerRadius = 3
        badge.clipsToBounds = true
        badge.textAlignment = .center
        row.addSubview(badge)
        badge.translatesAutoresizingMaskIntoConstraints = false

        let codeLabel = UILabel()
        codeLabel.text = codeNum
        codeLabel.font = UIFont.systemFont(ofSize: 12)
        codeLabel.textColor = Constants.Color.textTertiary
        row.addSubview(codeLabel)
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        let priceLabel = UILabel()
        priceLabel.text = price
        priceLabel.font = UIFont.systemFont(ofSize: 15)
        priceLabel.textColor = isRising ? Constants.Color.stockRise : Constants.Color.stockFall
        priceLabel.textAlignment = .center
        row.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        let changeLabel = UILabel()
        changeLabel.text = change.hasPrefix("+") || change.hasPrefix("-") ? change : (isRising ? "+\(change)" : change)
        changeLabel.font = UIFont.systemFont(ofSize: 15)
        changeLabel.textColor = isRising ? Constants.Color.stockRise : Constants.Color.stockFall
        changeLabel.textAlignment = .right
        row.addSubview(changeLabel)
        changeLabel.translatesAutoresizingMaskIntoConstraints = false

        let line = UIView()
        line.backgroundColor = Constants.Color.separator
        row.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: Constants.Spacing.lg),
            nameLabel.topAnchor.constraint(equalTo: row.topAnchor, constant: 10),
            badge.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: Constants.Spacing.lg),
            badge.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            badge.widthAnchor.constraint(equalToConstant: 20),
            badge.heightAnchor.constraint(equalToConstant: 16),
            codeLabel.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 4),
            codeLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            codeLabel.bottomAnchor.constraint(lessThanOrEqualTo: row.bottomAnchor, constant: -10),
            priceLabel.centerXAnchor.constraint(equalTo: row.centerXAnchor),
            priceLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            changeLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -Constants.Spacing.lg),
            changeLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            line.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: Constants.Spacing.lg),
            line.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -Constants.Spacing.lg),
            line.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            row.heightAnchor.constraint(equalToConstant: 62)
        ])

        return row
    }

    @objc private func stockRowTapped(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view else { return }
        let index = row.tag
        if index < stocksData.count {
            let stock = stocksData[index]
            let parts = stock.1.split(separator: " ", maxSplits: 1).map(String.init)
            let exchange = parts.first ?? ""
            let codeNum = parts.count > 1 ? parts[1] : stock.1
            onStockTapped?(stock.0, codeNum, exchange)
        }
    }
}
