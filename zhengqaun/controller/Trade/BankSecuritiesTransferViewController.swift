//
//  BankSecuritiesTransferViewController.swift
//  zhengqaun
//
//  银证转账：入口为 银证转入、银证转出 两个按钮，严格按 UI 图实现。
//

import UIKit

class BankSecuritiesTransferViewController: ZQViewController {

    /// 初始选中的 Tab：0 银证转入，1 银证转出
    var initialTabIndex: Int = 0

    private let navBlue = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0)
    private let tabActiveBlue = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
    private let tabInactiveGray = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
    private let listBgGray = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // #F5F5F5
    private let iconOrange = UIColor(red: 0.9, green: 0.6, blue: 0.1, alpha: 1.0)

    private var selectedIndex: Int = 0
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var segmentContainer: UIView!
    private var btnIn: UIButton!
    private var btnOut: UIButton!
    private var underline: UIView!
    private var transferInView: UIView!
    private var transferOutView: UIView!
    private var underlineLeading: NSLayoutConstraint?
    private var contentBottomIn: NSLayoutConstraint?
    private var contentBottomOut: NSLayoutConstraint?

    private let introText = "由于该账户受证券监管部门监督,根据证监部2021反洗黑钱金融条例,为了避免出现不法分子黑钱投入机构交易单元席位,导致三方存管账户全面冻结带来的损失,因采取更高效审查机制支付通道,用户需通过多元化方式进行注资,三方存管和银行之间搭建的支付通道风控机制,进行出入金交易,三方存管账户进行一道关卡过滤黑钱!"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        selectedIndex = initialTabIndex
        setupNavBar()
        setupSegment()
        setupScrollView()
        setupTransferInContent()
        setupTransferOutContent()
        selectTab(selectedIndex)
    }

    private func setupNavBar() {
        gk_navBackgroundColor = navBlue
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "银证转账"
        gk_navLineHidden = true
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
    }

    private func setupSegment() {
        let wrap = UIView()
        wrap.backgroundColor = .white
        view.addSubview(wrap)
        wrap.translatesAutoresizingMaskIntoConstraints = false
        segmentContainer = wrap

        btnIn = UIButton(type: .system)
        btnIn.setTitle("银证转入", for: .normal)
        btnIn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        btnIn.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
        btnIn.tag = 0
        wrap.addSubview(btnIn)
        btnIn.translatesAutoresizingMaskIntoConstraints = false

        btnOut = UIButton(type: .system)
        btnOut.setTitle("银证转出", for: .normal)
        btnOut.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btnOut.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
        btnOut.tag = 1
        wrap.addSubview(btnOut)
        btnOut.translatesAutoresizingMaskIntoConstraints = false

        underline = UIView()
        underline.backgroundColor = tabActiveBlue
        wrap.addSubview(underline)
        underline.translatesAutoresizingMaskIntoConstraints = false
        wrap.bringSubviewToFront(underline)

        let ulc = underline.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 0)
        underlineLeading = ulc

        let navH = Constants.Navigation.totalNavigationHeight
        NSLayoutConstraint.activate([
            wrap.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            wrap.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wrap.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wrap.heightAnchor.constraint(equalToConstant: 44),

            btnIn.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            btnIn.topAnchor.constraint(equalTo: wrap.topAnchor),
            btnIn.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            btnIn.widthAnchor.constraint(equalTo: wrap.widthAnchor, multiplier: 0.5),

            btnOut.leadingAnchor.constraint(equalTo: btnIn.trailingAnchor),
            btnOut.topAnchor.constraint(equalTo: wrap.topAnchor),
            btnOut.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            btnOut.widthAnchor.constraint(equalTo: wrap.widthAnchor, multiplier: 0.5),

            underline.heightAnchor.constraint(equalToConstant: 3),
            underline.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            underline.widthAnchor.constraint(equalToConstant: 20),
            ulc
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let tabW = segmentContainer.bounds.width * 0.5
        let lineW: CGFloat = 20
        underlineLeading?.constant = (tabW - lineW) / 2 + CGFloat(selectedIndex) * tabW
    }

    @objc private func segmentTapped(_ sender: UIButton) {
        let idx = sender.tag
        if idx == selectedIndex { return }
        selectedIndex = idx
        selectTab(selectedIndex)
    }

    private func selectTab(_ idx: Int) {
        let activeFont = UIFont.boldSystemFont(ofSize: 15)
        let inactiveFont = UIFont.systemFont(ofSize: 15)
        btnIn.setTitleColor(idx == 0 ? tabActiveBlue : tabInactiveGray, for: .normal)
        btnIn.titleLabel?.font = idx == 0 ? activeFont : inactiveFont
        btnOut.setTitleColor(idx == 1 ? tabActiveBlue : tabInactiveGray, for: .normal)
        btnOut.titleLabel?.font = idx == 1 ? activeFont : inactiveFont

        transferInView.isHidden = idx != 0
        transferOutView.isHidden = idx != 1

        contentBottomIn?.isActive = false
        contentBottomOut?.isActive = false
        (idx == 0 ? contentBottomIn : contentBottomOut)?.isActive = true

        let tabW = segmentContainer.bounds.width * 0.5
        let lineW: CGFloat = 20
        UIView.animate(withDuration: 0.25) {
            self.underlineLeading?.constant = (tabW - lineW) / 2 + CGFloat(idx) * tabW
            self.segmentContainer.layoutIfNeeded()
        }
    }

    private func setupScrollView() {
        let navH = Constants.Navigation.totalNavigationHeight
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delaysContentTouches = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - 银证转入：列表容器 + 简介说明
    private func setupTransferInContent() {
        let wrap = UIView()
        wrap.backgroundColor = .white
        contentView.addSubview(wrap)
        wrap.translatesAutoresizingMaskIntoConstraints = false
        transferInView = wrap

        let listBg = UIView()
        listBg.backgroundColor = listBgGray
        listBg.layer.cornerRadius = 10
        listBg.layer.shadowColor = UIColor.black.cgColor
        listBg.layer.shadowOffset = CGSize(width: 0, height: 1)
        listBg.layer.shadowRadius = 3
        listBg.layer.shadowOpacity = 0.06
        wrap.addSubview(listBg)
        listBg.translatesAutoresizingMaskIntoConstraints = false

        let pad: CGFloat = 16
        let cardInset: CGFloat = 12
        let rowH: CGFloat = 48
        let sepH = 1 / UIScreen.main.scale
        let items = ["银证转入(银证转入金额1000.00-10000.00)", "银证转入(银证转入金额1000.00-10000.00)", "银证转入(银证转入金额1000.00-10000.00)"]

        var prev: UIView?
        for (i, text) in items.enumerated() {
            let row = makeTransferInRow(text: text)
            row.tag = i
            let tap = UITapGestureRecognizer(target: self, action: #selector(transferInRowTapped(_:)))
            row.addGestureRecognizer(tap)
            row.isUserInteractionEnabled = true
            listBg.addSubview(row)
            row.translatesAutoresizingMaskIntoConstraints = false

            let topAnchor = prev == nil ? listBg.topAnchor : prev!.bottomAnchor
            let topC: CGFloat = prev == nil ? cardInset : 0
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: topAnchor, constant: topC),
                row.leadingAnchor.constraint(equalTo: listBg.leadingAnchor, constant: pad),
                row.trailingAnchor.constraint(equalTo: listBg.trailingAnchor, constant: -pad),
                row.heightAnchor.constraint(equalToConstant: rowH)
            ])

            if i < items.count - 1 {
                let sep = UIView()
                sep.backgroundColor = Constants.Color.separator
                listBg.addSubview(sep)
                sep.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    sep.topAnchor.constraint(equalTo: row.bottomAnchor),
                    sep.leadingAnchor.constraint(equalTo: listBg.leadingAnchor),
                    sep.trailingAnchor.constraint(equalTo: listBg.trailingAnchor),
                    sep.heightAnchor.constraint(equalToConstant: sepH)
                ])
                prev = sep
            } else {
                prev = row
            }
        }

        let introTitle = UILabel()
        introTitle.text = "简介说明"
        introTitle.font = UIFont.boldSystemFont(ofSize: 16)
        introTitle.textColor = .systemRed
        wrap.addSubview(introTitle)
        introTitle.translatesAutoresizingMaskIntoConstraints = false

        let introBody = UILabel()
        introBody.text = introText
        introBody.font = UIFont.systemFont(ofSize: 14)
        introBody.textColor = .systemRed
        introBody.numberOfLines = 0
        wrap.addSubview(introBody)
        introBody.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            listBg.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 16),
            listBg.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: pad),
            listBg.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -pad),
            listBg.bottomAnchor.constraint(equalTo: prev!.bottomAnchor, constant: cardInset)
        ])

        NSLayoutConstraint.activate([
            wrap.topAnchor.constraint(equalTo: contentView.topAnchor),
            wrap.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            wrap.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            introTitle.topAnchor.constraint(equalTo: listBg.bottomAnchor, constant: 24),
            introTitle.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: pad),
            introTitle.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -pad),

            introBody.topAnchor.constraint(equalTo: introTitle.bottomAnchor, constant: 8),
            introBody.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: pad),
            introBody.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -pad),
            introBody.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -24)
        ])
        contentBottomIn = contentView.bottomAnchor.constraint(equalTo: wrap.bottomAnchor)
    }

    private func makeTransferInRow(text: String) -> UIView {
        let r = UIView()
        let iv = UIImageView(image: UIImage(systemName: "yensign"))
        iv.tintColor = iconOrange
        iv.contentMode = .scaleAspectFit
        r.addSubview(iv)
        iv.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = Constants.Color.textPrimary
        r.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iv.leadingAnchor.constraint(equalTo: r.leadingAnchor),
            iv.centerYAnchor.constraint(equalTo: r.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 22),
            iv.heightAnchor.constraint(equalToConstant: 22),
            lbl.leadingAnchor.constraint(equalTo: iv.trailingAnchor, constant: 12),
            lbl.centerYAnchor.constraint(equalTo: r.centerYAnchor),
            lbl.trailingAnchor.constraint(lessThanOrEqualTo: r.trailingAnchor)
        ])
        return r
    }
    
    /// 点击任意一条银证转入列表，进入单笔转入页面
    @objc private func transferInRowTapped(_ sender: UITapGestureRecognizer) {
        let vc = BankTransferInViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 银证转出：T+1、可转出、银行卡、转出金额、转出按钮、转账记录列表
    private func setupTransferOutContent() {
        let wrap = UIView()
        wrap.backgroundColor = .white
        contentView.addSubview(wrap)
        wrap.translatesAutoresizingMaskIntoConstraints = false
        transferOutView = wrap

        let pad: CGFloat = 16
        let rowH: CGFloat = 48

        let (r1, _) = makeDetailRow(left: "T+1资金", right: "¥ 0.00", rightColor: .systemRed)
        let (r2, _) = makeDetailRow(left: "可转出金额", right: "6946.39", rightColor: Constants.Color.textPrimary)
        let (r3, _) = makeDetailRow(left: "银行卡", right: "64646464646464646", rightColor: Constants.Color.textPrimary)

        let amountStack = UIView()
        let amountLbl = UILabel()
        amountLbl.text = "转出金额"
        amountLbl.font = UIFont.systemFont(ofSize: 15)
        amountLbl.textColor = Constants.Color.textPrimary
        amountStack.addSubview(amountLbl)
        amountLbl.translatesAutoresizingMaskIntoConstraints = false

        let rightBox = UIView()
        rightBox.isUserInteractionEnabled = true
        let yenLbl = UILabel()
        yenLbl.text = "¥"
        yenLbl.font = UIFont.systemFont(ofSize: 15)
        yenLbl.textColor = Constants.Color.textPrimary
        rightBox.addSubview(yenLbl)
        yenLbl.translatesAutoresizingMaskIntoConstraints = false

        let tf = UITextField()
        tf.placeholder = "200"
        tf.text = "200"
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.textColor = Constants.Color.textPrimary
        tf.textAlignment = .right
        tf.keyboardType = .decimalPad
        tf.isUserInteractionEnabled = true
        rightBox.addSubview(tf)
        tf.translatesAutoresizingMaskIntoConstraints = false

        amountStack.addSubview(rightBox)
        rightBox.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            amountLbl.leadingAnchor.constraint(equalTo: amountStack.leadingAnchor),
            amountLbl.centerYAnchor.constraint(equalTo: amountStack.centerYAnchor),

            rightBox.trailingAnchor.constraint(equalTo: amountStack.trailingAnchor),
            rightBox.centerYAnchor.constraint(equalTo: amountStack.centerYAnchor),
            rightBox.leadingAnchor.constraint(equalTo: amountLbl.trailingAnchor, constant: 8),
            rightBox.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            yenLbl.leadingAnchor.constraint(equalTo: rightBox.leadingAnchor),
            yenLbl.centerYAnchor.constraint(equalTo: rightBox.centerYAnchor),

            tf.leadingAnchor.constraint(equalTo: yenLbl.trailingAnchor, constant: 2),
            tf.trailingAnchor.constraint(equalTo: rightBox.trailingAnchor),
            tf.centerYAnchor.constraint(equalTo: rightBox.centerYAnchor),
            tf.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])

        let hint = UILabel()
        hint.text = "最小转出金额100"
        hint.font = UIFont.systemFont(ofSize: 12)
        hint.textColor = Constants.Color.textTertiary
        wrap.addSubview(hint)
        hint.translatesAutoresizingMaskIntoConstraints = false

        let submit = UIButton(type: .system)
        submit.setTitle("转出", for: .normal)
        submit.setTitleColor(.white, for: .normal)
        submit.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        submit.backgroundColor = navBlue
        submit.layer.cornerRadius = 10
        submit.addTarget(self, action: #selector(transferOutTapped), for: .touchUpInside)
        wrap.addSubview(submit)
        submit.translatesAutoresizingMaskIntoConstraints = false

        wrap.addSubview(r1)
        wrap.addSubview(r2)
        wrap.addSubview(r3)
        wrap.addSubview(amountStack)
        r1.translatesAutoresizingMaskIntoConstraints = false
        r2.translatesAutoresizingMaskIntoConstraints = false
        r3.translatesAutoresizingMaskIntoConstraints = false
        amountStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            wrap.topAnchor.constraint(equalTo: contentView.topAnchor),
            wrap.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            wrap.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            r1.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 16),
            r1.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: pad),
            r1.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -pad),
            r1.heightAnchor.constraint(equalToConstant: rowH),

            r2.topAnchor.constraint(equalTo: r1.bottomAnchor),
            r2.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: pad),
            r2.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -pad),
            r2.heightAnchor.constraint(equalToConstant: rowH),

            r3.topAnchor.constraint(equalTo: r2.bottomAnchor),
            r3.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: pad),
            r3.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -pad),
            r3.heightAnchor.constraint(equalToConstant: rowH),

            amountStack.topAnchor.constraint(equalTo: r3.bottomAnchor),
            amountStack.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: pad),
            amountStack.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -pad),
            amountStack.heightAnchor.constraint(equalToConstant: rowH),

            hint.topAnchor.constraint(equalTo: amountStack.bottomAnchor, constant: 4),
            hint.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: pad),

            submit.topAnchor.constraint(equalTo: hint.bottomAnchor, constant: 24),
            submit.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 20),
            submit.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -20),
            submit.heightAnchor.constraint(equalToConstant: 48)
        ])

        // 转账记录列表（3 条示例）
        let historyData: [(amount: String, status: String, date: String)] = [
            ("-333", "银证转出中:", "2025-12-23 13:56:13"),
            ("-333", "银证转出中:", "2025-12-23 13:56:13"),
            ("-333", "银证转出中:", "2025-12-23 13:56:13")
        ]
        let historyGap: CGFloat = 16
        var prevHistory: UIView?
        for item in historyData {
            let cell = makeTransferHistoryCell(amount: item.amount, status: item.status, date: item.date)
            wrap.addSubview(cell)
            cell.translatesAutoresizingMaskIntoConstraints = false
            let topAnchor = prevHistory == nil ? submit.bottomAnchor : prevHistory!.bottomAnchor
            let topC: CGFloat = prevHistory == nil ? 24 : historyGap
            NSLayoutConstraint.activate([
                cell.topAnchor.constraint(equalTo: topAnchor, constant: topC),
                cell.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: pad),
                cell.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -pad)
            ])
            prevHistory = cell
        }

        NSLayoutConstraint.activate([
            prevHistory!.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -24)
        ])
        contentBottomOut = contentView.bottomAnchor.constraint(equalTo: wrap.bottomAnchor)
    }

    /// 单条转账记录：Line1 银证转出 | 金额(红)；Line2 状态(蓝)；Line3 时间(灰)
    private func makeTransferHistoryCell(amount: String, status: String, date: String) -> UIView {
        let c = UIView()

        let L1Left = UILabel()
        L1Left.text = "银证转出"
        L1Left.font = UIFont.systemFont(ofSize: 15)
        L1Left.textColor = Constants.Color.textPrimary
        c.addSubview(L1Left)
        L1Left.translatesAutoresizingMaskIntoConstraints = false

        let L1Right = UILabel()
        L1Right.text = amount
        L1Right.font = UIFont.systemFont(ofSize: 15)
        L1Right.textColor = .systemRed
        c.addSubview(L1Right)
        L1Right.translatesAutoresizingMaskIntoConstraints = false

        let L2 = UILabel()
        L2.text = status
        L2.font = UIFont.systemFont(ofSize: 14)
        L2.textColor = tabActiveBlue
        c.addSubview(L2)
        L2.translatesAutoresizingMaskIntoConstraints = false

        let L3 = UILabel()
        L3.text = date
        L3.font = UIFont.systemFont(ofSize: 12)
        L3.textColor = Constants.Color.textTertiary
        c.addSubview(L3)
        L3.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            L1Left.topAnchor.constraint(equalTo: c.topAnchor),
            L1Left.leadingAnchor.constraint(equalTo: c.leadingAnchor),
            L1Right.centerYAnchor.constraint(equalTo: L1Left.centerYAnchor),
            L1Right.trailingAnchor.constraint(equalTo: c.trailingAnchor),

            L2.topAnchor.constraint(equalTo: L1Left.bottomAnchor, constant: 6),
            L2.leadingAnchor.constraint(equalTo: c.leadingAnchor),

            L3.topAnchor.constraint(equalTo: L2.bottomAnchor, constant: 4),
            L3.leadingAnchor.constraint(equalTo: c.leadingAnchor),
            L3.bottomAnchor.constraint(equalTo: c.bottomAnchor)
        ])
        return c
    }

    private func makeDetailRow(left: String, right: String, rightColor: UIColor) -> (UIView, UILabel) {
        let r = UIView()
        let l = UILabel()
        l.text = left
        l.font = UIFont.systemFont(ofSize: 15)
        l.textColor = Constants.Color.textPrimary
        r.addSubview(l)
        l.translatesAutoresizingMaskIntoConstraints = false

        let v = UILabel()
        v.text = right
        v.font = UIFont.systemFont(ofSize: 15)
        v.textColor = rightColor
        r.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            l.leadingAnchor.constraint(equalTo: r.leadingAnchor),
            l.centerYAnchor.constraint(equalTo: r.centerYAnchor),
            v.trailingAnchor.constraint(equalTo: r.trailingAnchor),
            v.centerYAnchor.constraint(equalTo: r.centerYAnchor)
        ])
        return (r, v)
    }

    @objc private func transferOutTapped() {
        // 弹出支付密码输入框
        let passwordView = PaymentPasswordView()
        passwordView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passwordView)
        
        NSLayoutConstraint.activate([
            passwordView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            passwordView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passwordView.topAnchor.constraint(equalTo: view.topAnchor),
            passwordView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - 支付密码输入视图（6位数字 + 自定义数字键盘）
private class PaymentPasswordView: UIView {
    
    private let dimView = UIView()
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private var dotLabels: [UILabel] = []
    private var password: String = "" {
        didSet { updateDots() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 灰色蒙层
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        addSubview(dimView)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        
        // 底部容器
        containerView.backgroundColor = .white
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 12
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        
        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            // 整体高度至少 360，使密码区不显得太矮
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 360)
        ])
        
        // 标题
        titleLabel.text = "请输入支付密码"
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = Constants.Color.textPrimary
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 密码 6 个输入位（用下划线 + ● 表示）
        let dotsStack = UIStackView()
        dotsStack.axis = .horizontal
        dotsStack.alignment = .center
        dotsStack.distribution = .fillEqually
        dotsStack.spacing = 18
        containerView.addSubview(dotsStack)
        dotsStack.translatesAutoresizingMaskIntoConstraints = false
        
        for _ in 0..<6 {
            let underline = UIView()
            underline.backgroundColor = Constants.Color.separator
            underline.heightAnchor.constraint(equalToConstant: 2).isActive = true
            
            let dot = UILabel()
            dot.text = ""
            dot.font = UIFont.systemFont(ofSize: 22)
            dot.textAlignment = .center
            dot.textColor = Constants.Color.textPrimary
            
            let wrapper = UIStackView(arrangedSubviews: [dot, underline])
            wrapper.axis = .vertical
            wrapper.alignment = .fill
            wrapper.distribution = .fill
            wrapper.spacing = 10
            
            dotsStack.addArrangedSubview(wrapper)
            dotLabels.append(dot)
        }
        
        // 数字键盘
        let keypad = createKeypad()
        containerView.addSubview(keypad)
        keypad.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            dotsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            dotsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 50),
            dotsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -50),
            
            keypad.topAnchor.constraint(equalTo: dotsStack.bottomAnchor, constant: 32),
            keypad.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            keypad.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            keypad.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func createKeypad() -> UIView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.distribution = .fillEqually
        grid.spacing = 0
        
        let numbers = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["取消", "0", "⌫"]
        ]
        
        for row in numbers {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 0
            
            for title in row {
                let btn = UIButton(type: .system)
                btn.setTitle(title, for: .normal)
                btn.titleLabel?.font = UIFont.systemFont(ofSize: 24)
                btn.setTitleColor(Constants.Color.textPrimary, for: .normal)
                btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
            }
            grid.addArrangedSubview(rowStack)
        }
        return grid
    }
    
    private func updateDots() {
        for (i, label) in dotLabels.enumerated() {
            if i < password.count {
                label.text = "•"
            } else {
                label.text = ""
            }
        }
        
        if password.count == 6 {
            // 这里可以加入校验/网络请求，当前先简单延时关闭
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.removeFromSuperview()
            }
        }
    }
    
    @objc private func keyTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        switch title {
        case "取消":
            removeFromSuperview()
        case "⌫":
            if !password.isEmpty {
                password.removeLast()
            }
        default:
            // 数字
            if password.count < 6, Int(title) != nil {
                password.append(title)
            }
        }
    }
}
