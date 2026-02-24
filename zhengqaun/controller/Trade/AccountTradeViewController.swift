//
//  AccountTradeViewController.swift
//  zhengqaun
//
//  账户交易页面：买入/卖出
//

import UIKit

class AccountTradeViewController: ZQViewController {
    
    // MARK: - Properties
    var stockName: String = "汉得信息"
    var stockCode: String = "300170"
    var exchange: String = "深"
    var currentPrice: String = "22.67"
    var tradeType: TradeType = .buy // 买入或卖出
    var sellBuyPrice: String = "--"   // 卖出时的买入价
    var sellHoldingQty: String = "0"  // 卖出时的持仓手数
    var useProvidedHoldings: Bool = false // 是否使用外部传入的持仓数据（不被接口覆盖）
    
    var limitUpPrice: String = ""
    var limitDownPrice: String = ""
    
    enum TradeType {
        case buy  // 买入
        case sell // 卖出
    }
    
    // UI Components
    private var segmentContainer: UIView!
    private var buyButton: UIButton!
    private var sellButton: UIButton!
    private var underline: UIView!
    private var underlineLeading: NSLayoutConstraint?
    private var selectedIndex: Int = 0 // 0: 买入, 1: 卖出
    
    // 买入页面
    private let buyView = UIView()
    private var buyPriceLabel: UILabel!
    private var limitUpDownLabel: UILabel!
    private var positionButtons: [UIButton] = []
    private var buyQuantityTextField: UITextField!
    private var buyQuantityMinusButton: UIButton?
    private var buyQuantityPlusButton: UIButton?
    private var sellQuantityMinusButton: UIButton?
    private var sellQuantityPlusButton: UIButton?
    private var serviceFeeLabel: UILabel!
    private var availableAmountLabel: UILabel!
    private var payableLabel: UILabel!
    private let buyConfirmButton = UIButton(type: .system)
    
    // 代码输入与查询（买入/卖出内嵌的用于布局占位；实际交互用 overlay）
    private var buyCodeTextField: UITextField!
    private var sellCodeTextField: UITextField!
    private var buyCodeQueryButton: UIButton!
    private var sellCodeQueryButton: UIButton!
    /// 主 view 上的代码输入层，保证可输入、可点查询
    private var codeInputOverlay: UIView!
    private var codeInputOverlayTextField: UITextField!
    private var codeInputOverlayQueryButton: UIButton!
    private var buyCurrentPriceLabel: UILabel!  // 买入页「现价」右侧
    private var sellCurrentPriceLabel: UILabel! // 卖出页「现价」右侧

    // 卖出页面
    private let sellView = UIView()
    private var buyPriceSellLabel: UILabel!
    private var holdingQuantityLabel: UILabel!
    private var sellPositionButtons: [UIButton] = []
    private var sellQuantityTextField: UITextField!
    private var totalAmountLabel: UILabel!
    private let sellConfirmButton = UIButton(type: .system)
    
    private let navBlue = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0)
    private let tabActiveBlue = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0)
    private let tabInactiveGray = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    
    // 数据
    private var buyQuantity: Int = 0
    private var sellQuantity: Int = 0
    private var selectedPositionIndex: Int = -1 // 初始未选择
    private var selectedSellPositionIndex: Int = -1 // 初始未选择
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // 买入 tab 已隐藏，始终使用卖出
        selectedIndex = 1
        
        setupNavigationBar()
        setupSegment()
        setupBuyView()
        setupSellView()
        setupCodeInputOverlay()
        selectTab(selectedIndex)
        loadStockData()
        
        // 在 view 加载后，处理当前可见标签页的数量行控件
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.selectedIndex == 0 {
                // 处理买入的数量行控件
                self.processBuyQuantityControlsIfNeeded()
            } else {
                // 处理卖出的数量行控件
                self.processSellQuantityControlsIfNeeded()
            }
            // 更新数量行控件的显示状态
            self.ensureQuantityControlsOnTop()
            // 代码输入层置于最前，保证可输入、可点查询
            if let overlay = self.codeInputOverlay {
                self.view.bringSubviewToFront(overlay)
            }
        }
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = navBlue
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "账户交易"
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
        
        buyButton = UIButton(type: .system)
        buyButton.setTitle("买入", for: .normal)
        buyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        buyButton.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
        buyButton.tag = 0
        buyButton.isHidden = true    // 隐藏买入 tab
        wrap.addSubview(buyButton)
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        
        sellButton = UIButton(type: .system)
        sellButton.setTitle("卖出", for: .normal)
        sellButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        sellButton.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
        sellButton.tag = 1
        wrap.addSubview(sellButton)
        sellButton.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            buyButton.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            buyButton.topAnchor.constraint(equalTo: wrap.topAnchor),
            buyButton.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            buyButton.widthAnchor.constraint(equalToConstant: 0),
            
            sellButton.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            sellButton.topAnchor.constraint(equalTo: wrap.topAnchor),
            sellButton.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            sellButton.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            
            underline.heightAnchor.constraint(equalToConstant: 3),
            underline.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            underline.widthAnchor.constraint(equalToConstant: 20),
            ulc
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let fullW = segmentContainer.bounds.width
        let lineW: CGFloat = 20
        // 买入已隐藏，卖出占满全宽，下划线居中
        underlineLeading?.constant = (fullW - lineW) / 2
        
        // 验证按钮 frame 和可点击区域
        verifyButtonFrames()
        
        // 确保按钮在最上层
        ensureButtonsOnTop()
        
        // 确保数量行控件也在最上层
        ensureQuantityControlsOnTop()
        // 代码输入层始终在最前
        if let overlay = codeInputOverlay {
            view.bringSubviewToFront(overlay)
        }
    }
    
    private func ensureButtonsOnTop() {
        // 确保买入按钮在最上层
        for button in positionButtons {
            if let container = button.superview {
                container.bringSubviewToFront(button)
                // 确保 container 在 buyView 的最上层
                if let buyView = container.superview {
                    buyView.bringSubviewToFront(container)
                    // 确保 buyView 在 view 的最上层（如果可见）
                    if !buyView.isHidden {
                        view.bringSubviewToFront(buyView)
                    }
                }
            }
        }
        
        // 确保卖出按钮在最上层
        for button in sellPositionButtons {
            if let container = button.superview {
                container.bringSubviewToFront(button)
                // 确保 container 在 sellView 的最上层
                if let sellView = container.superview {
                    sellView.bringSubviewToFront(container)
                    // 确保 sellView 在 view 的最上层（如果可见）
                    if !sellView.isHidden {
                        view.bringSubviewToFront(sellView)
                    }
                }
            }
        }
    }
    
    private func ensureQuantityControlsOnTop() {
        // 根据当前选中的标签页，只显示对应的数量行控件
        if selectedIndex == 0 {
            // 买入模式：显示买入控件，隐藏卖出控件
            if let minusBtn = buyQuantityMinusButton {
                view.bringSubviewToFront(minusBtn)
                minusBtn.isHidden = false
                minusBtn.isUserInteractionEnabled = true
                minusBtn.isEnabled = true
                print("✅ 买入减号按钮 - frame: \(minusBtn.frame), isUserInteractionEnabled: \(minusBtn.isUserInteractionEnabled), isEnabled: \(minusBtn.isEnabled)")
            } else {
                print("⚠️ buyQuantityMinusButton 为 nil")
            }
            if let textField = buyQuantityTextField {
                view.bringSubviewToFront(textField)
                textField.isHidden = false
                textField.isUserInteractionEnabled = true
                textField.isEnabled = true
                print("✅ 买入输入框 - frame: \(textField.frame), isUserInteractionEnabled: \(textField.isUserInteractionEnabled), isEnabled: \(textField.isEnabled)")
            } else {
                print("⚠️ buyQuantityTextField 为 nil")
            }
            if let plusBtn = buyQuantityPlusButton {
                view.bringSubviewToFront(plusBtn)
                plusBtn.isHidden = false
                plusBtn.isUserInteractionEnabled = true
                plusBtn.isEnabled = true
                print("✅ 买入加号按钮 - frame: \(plusBtn.frame), isUserInteractionEnabled: \(plusBtn.isUserInteractionEnabled), isEnabled: \(plusBtn.isEnabled)")
            } else {
                print("⚠️ buyQuantityPlusButton 为 nil")
            }
            
            // 隐藏卖出控件
            if let minusBtn = sellQuantityMinusButton {
                minusBtn.isHidden = true
                minusBtn.isUserInteractionEnabled = false
            }
            if let textField = sellQuantityTextField {
                textField.isHidden = true
                textField.isUserInteractionEnabled = false
            }
            if let plusBtn = sellQuantityPlusButton {
                plusBtn.isHidden = true
                plusBtn.isUserInteractionEnabled = false
            }
        } else {
            // 卖出模式：显示卖出控件，隐藏买入控件
            if let minusBtn = sellQuantityMinusButton {
                view.bringSubviewToFront(minusBtn)
                minusBtn.isHidden = false
                minusBtn.isUserInteractionEnabled = true
                minusBtn.isEnabled = true
            }
            if let textField = sellQuantityTextField {
                view.bringSubviewToFront(textField)
                textField.isHidden = false
                textField.isUserInteractionEnabled = true
                textField.isEnabled = true
            }
            if let plusBtn = sellQuantityPlusButton {
                view.bringSubviewToFront(plusBtn)
                plusBtn.isHidden = false
                plusBtn.isUserInteractionEnabled = true
                plusBtn.isEnabled = true
            }
            
            // 隐藏买入控件
            if let minusBtn = buyQuantityMinusButton {
                minusBtn.isHidden = true
                minusBtn.isUserInteractionEnabled = false
            }
            if let textField = buyQuantityTextField {
                textField.isHidden = true
                textField.isUserInteractionEnabled = false
            }
            if let plusBtn = buyQuantityPlusButton {
                plusBtn.isHidden = true
                plusBtn.isUserInteractionEnabled = false
            }
        }
    }
    
    private func verifyButtonFrames() {
        print("=== 验证按钮 Frame ===")
        for (index, button) in positionButtons.enumerated() {
            print("买入按钮 \(index): frame=\(button.frame), superview=\(type(of: button.superview)), isEnabled=\(button.isEnabled), isUserInteractionEnabled=\(button.isUserInteractionEnabled)")
            if button.frame.width == 0 || button.frame.height == 0 {
                print("⚠️ 按钮 \(index) frame 为 0！")
            }
        }
        for (index, button) in sellPositionButtons.enumerated() {
            print("卖出按钮 \(index): frame=\(button.frame), superview=\(type(of: button.superview)), isEnabled=\(button.isEnabled), isUserInteractionEnabled=\(button.isUserInteractionEnabled)")
            if button.frame.width == 0 || button.frame.height == 0 {
                print("⚠️ 按钮 \(index) frame 为 0！")
            }
        }
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
        buyButton.setTitleColor(idx == 0 ? tabActiveBlue : tabInactiveGray, for: .normal)
        buyButton.titleLabel?.font = idx == 0 ? activeFont : inactiveFont
        sellButton.setTitleColor(idx == 1 ? tabActiveBlue : tabInactiveGray, for: .normal)
        sellButton.titleLabel?.font = idx == 1 ? activeFont : inactiveFont
        
        buyView.isHidden = idx != 0
        sellView.isHidden = idx != 1
        
        updateBottomButtons()
        
        let fullW = segmentContainer.bounds.width
        let lineW: CGFloat = 20
        UIView.animate(withDuration: 0.25) {
            self.underlineLeading?.constant = (fullW - lineW) / 2
            self.segmentContainer.layoutIfNeeded()
        }
        
        // 切换标签时，处理对应标签页的数量行控件
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if idx == 0 {
                // 切换到买入：处理买入的数量行控件
                self.processBuyQuantityControlsIfNeeded()
            } else {
                // 切换到卖出：处理卖出的数量行控件
                self.processSellQuantityControlsIfNeeded()
            }
            // 更新数量行控件的显示状态
            self.ensureQuantityControlsOnTop()
        }
    }
    
    // MARK: - 处理买入数量行控件
    private func processBuyQuantityControlsIfNeeded() {
        // 如果已经处理过，跳过
        if buyQuantityMinusButton != nil || buyQuantityPlusButton != nil {
            return
        }
        
        // 找到买入的数量行 container
        guard let quantityContainer = findQuantityContainer(in: buyView) else {
            print("⚠️ 未找到买入数量行 container")
            return
        }
        
        // 找到控件
        guard let (minusBtn, textFld, plusBtn) = findQuantityControls(in: quantityContainer) else {
            print("⚠️ 未找到买入数量行控件")
            return
        }
        
        // 处理控件
        moveQuantityControlsToView(container: quantityContainer, isBuy: true, minusButton: minusBtn, textField: textFld, plusButton: plusBtn)
    }
    
    // MARK: - 处理卖出数量行控件
    private func processSellQuantityControlsIfNeeded() {
        // 如果已经处理过，跳过
        if sellQuantityMinusButton != nil || sellQuantityPlusButton != nil {
            return
        }
        
        // 找到卖出的数量行 container
        guard let quantityContainer = findQuantityContainer(in: sellView) else {
            print("⚠️ 未找到卖出数量行 container")
            return
        }
        
        // 找到控件
        guard let (minusBtn, textFld, plusBtn) = findQuantityControls(in: quantityContainer) else {
            print("⚠️ 未找到卖出数量行控件")
            return
        }
        
        // 处理控件
        moveQuantityControlsToView(container: quantityContainer, isBuy: false, minusButton: minusBtn, textField: textFld, plusButton: plusBtn)
    }
    
    // MARK: - 辅助方法：查找数量行 container
    private func findQuantityContainer(in parent: UIView) -> UIView? {
        // 查找包含 "买入手数" 或 "卖出手数" 的 container
        for subview in parent.subviews {
            for label in subview.subviews {
                if let titleLabel = label as? UILabel,
                   (titleLabel.text == "买入手数" || titleLabel.text == "卖出手数") {
                    return subview
                }
            }
        }
        return nil
    }
    
    // MARK: - 辅助方法：查找数量行控件
    private func findQuantityControls(in container: UIView) -> (minusButton: UIButton, textField: UITextField, plusButton: UIButton)? {
        var minusBtn: UIButton?
        var textFld: UITextField?
        var plusBtn: UIButton?
        
        // 查找 inputContainer
        guard let inputContainer = container.subviews.first(where: { 
            $0.backgroundColor == UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) 
        }) else {
            return nil
        }
        
        // 查找控件
        for subview in inputContainer.subviews {
            if let btn = subview as? UIButton, btn.title(for: .normal) == "-" {
                minusBtn = btn
            } else if let btn = subview as? UIButton, btn.title(for: .normal) == "+" {
                plusBtn = btn
            } else if let tf = subview as? UITextField {
                textFld = tf
            }
        }
        
        guard let minus = minusBtn, let text = textFld, let plus = plusBtn else {
            return nil
        }
        
        return (minus, text, plus)
    }
    
    private func setupBuyView() {
        buyView.isUserInteractionEnabled = true
        buyView.clipsToBounds = false // 确保按钮不被裁剪
        // 重要：确保 buyView 不会拦截触摸事件，只传递触摸事件给子视图
        buyView.isMultipleTouchEnabled = true
        view.addSubview(buyView)
        buyView.translatesAutoresizingMaskIntoConstraints = false
        
        var lastView: UIView?
        
        // 代码（可输入 + 查询）
        lastView = addCodeInputRow(to: buyView, after: nil, isBuy: true)
        
        // 现价（可点击编辑）
        buyCurrentPriceLabel = UILabel()
        buyCurrentPriceLabel.text = currentPrice
        buyCurrentPriceLabel.textColor = .red
        buyCurrentPriceLabel.font = UIFont.systemFont(ofSize: 15)
        buyCurrentPriceLabel.textAlignment = .right
        buyCurrentPriceLabel.isUserInteractionEnabled = true
        lastView = addEditableInfoRow(to: buyView, after: lastView, title: "现价", valueView: buyCurrentPriceLabel) { [weak self] newValue in
            self?.currentPrice = newValue
            self?.buyPriceLabel.text = newValue
            self?.updateLimitUpDown()
            self?.calculateBuyAmount()
        }
        
        // 买入价格（可点击编辑）
        buyPriceLabel = UILabel()
        buyPriceLabel.text = currentPrice
        buyPriceLabel.textColor = .red
        buyPriceLabel.font = UIFont.systemFont(ofSize: 15)
        buyPriceLabel.textAlignment = .right
        buyPriceLabel.isUserInteractionEnabled = true
        lastView = addEditableInfoRow(to: buyView, after: lastView, title: "买入价格", valueView: buyPriceLabel) { [weak self] newValue in
            self?.buyPriceLabel.text = newValue
            self?.updateLimitUpDown()
            self?.calculateBuyAmount()
        }
        
        // 涨跌停（可点击编辑）
        limitUpDownLabel = UILabel()
        limitUpDownLabel.font = UIFont.systemFont(ofSize: 15)
        limitUpDownLabel.textAlignment = .right
        limitUpDownLabel.isUserInteractionEnabled = true
        updateLimitUpDown()
        lastView = addEditableInfoRow(to: buyView, after: lastView, title: "涨跌停", valueView: limitUpDownLabel) { _ in }
        
        // 仓位
        lastView = addPositionRow(to: buyView, after: lastView, isBuy: true)
        
        // 买入手数
        lastView = addQuantityRow(to: buyView, after: lastView, isBuy: true)
        
        // 服务费（可点击编辑）
        serviceFeeLabel = UILabel()
        serviceFeeLabel.text = "0.00"
        serviceFeeLabel.textColor = .black
        serviceFeeLabel.font = UIFont.systemFont(ofSize: 15)
        serviceFeeLabel.textAlignment = .right
        serviceFeeLabel.isUserInteractionEnabled = true
        lastView = addEditableInfoRow(to: buyView, after: lastView, title: "服务费 元0.01%", valueView: serviceFeeLabel) { [weak self] newValue in
            self?.serviceFeeLabel.text = newValue
        }
        
        // 可用金额（可点击编辑）
        availableAmountLabel = UILabel()
        availableAmountLabel.text = "0"
        availableAmountLabel.textColor = .black
        availableAmountLabel.font = UIFont.systemFont(ofSize: 15)
        availableAmountLabel.textAlignment = .right
        availableAmountLabel.isUserInteractionEnabled = true
        lastView = addEditableInfoRow(to: buyView, after: lastView, title: "可用金额", valueView: availableAmountLabel) { [weak self] newValue in
            self?.availableAmountLabel.text = newValue
        }
        
        // 应付(元)（可点击编辑）
        payableLabel = UILabel()
        payableLabel.text = "0.00"
        payableLabel.textColor = .black
        payableLabel.font = UIFont.systemFont(ofSize: 15)
        payableLabel.textAlignment = .right
        payableLabel.isUserInteractionEnabled = true
        lastView = addEditableInfoRow(to: buyView, after: lastView, title: "应付(元)", valueView: payableLabel) { [weak self] newValue in
            self?.payableLabel.text = newValue
        }
        
        // 顶部约束
        let navH = Constants.Navigation.totalNavigationHeight
        NSLayoutConstraint.activate([
            buyView.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor),
            buyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buyView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80)
        ])
    }
    
    private func setupSellView() {
        sellView.isUserInteractionEnabled = true
        sellView.clipsToBounds = false // 确保按钮不被裁剪
        view.addSubview(sellView)
        sellView.translatesAutoresizingMaskIntoConstraints = false
        sellView.isHidden = true
        
        var lastView: UIView?
        
        // 代码（可输入 + 查询）
        lastView = addCodeInputRow(to: sellView, after: nil, isBuy: false)
        
        // 买入价（只读）
        buyPriceSellLabel = UILabel()
        buyPriceSellLabel.text = sellBuyPrice
        buyPriceSellLabel.textColor = .black
        buyPriceSellLabel.font = UIFont.systemFont(ofSize: 15)
        buyPriceSellLabel.textAlignment = .right
        lastView = addInfoRow(to: sellView, after: lastView, title: "买入价", valueView: buyPriceSellLabel)
        
        // 现价（只读）
        sellCurrentPriceLabel = UILabel()
        sellCurrentPriceLabel.text = currentPrice
        sellCurrentPriceLabel.textColor = .red
        sellCurrentPriceLabel.font = UIFont.systemFont(ofSize: 15)
        sellCurrentPriceLabel.textAlignment = .right
        lastView = addInfoRow(to: sellView, after: lastView, title: "现价", valueView: sellCurrentPriceLabel)
        
        // 持仓手数（只读）
        holdingQuantityLabel = UILabel()
        holdingQuantityLabel.text = sellHoldingQty
        holdingQuantityLabel.textColor = .black
        holdingQuantityLabel.font = UIFont.systemFont(ofSize: 15)
        holdingQuantityLabel.textAlignment = .right
        lastView = addInfoRow(to: sellView, after: lastView, title: "持仓手数", valueView: holdingQuantityLabel)
        
        // 仓位
        lastView = addPositionRow(to: sellView, after: lastView, isBuy: false)
        
        // 卖出手数
        lastView = addQuantityRow(to: sellView, after: lastView, isBuy: false)
        
        // 总额(元)（只读）
        totalAmountLabel = UILabel()
        totalAmountLabel.text = "0.00"
        totalAmountLabel.textColor = .black
        totalAmountLabel.font = UIFont.systemFont(ofSize: 15)
        totalAmountLabel.textAlignment = .right
        lastView = addInfoRow(to: sellView, after: lastView, title: "总额(元)", valueView: totalAmountLabel)
        
        // 顶部约束
        let navH = Constants.Navigation.totalNavigationHeight
        NSLayoutConstraint.activate([
            sellView.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor),
            sellView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sellView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sellView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80)
        ])
    }
    
    // MARK: - 主 view 上的代码输入层（保证可输入、可点查询）
    private func setupCodeInputOverlay() {
        codeInputOverlay = UIView()
        codeInputOverlay.backgroundColor = .white
        codeInputOverlay.isUserInteractionEnabled = true
        view.addSubview(codeInputOverlay)
        codeInputOverlay.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "代码"
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        codeInputOverlay.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        codeInputOverlayTextField = UITextField()
        codeInputOverlayTextField.text = stockCode
        codeInputOverlayTextField.placeholder = "输入股票代码"
        codeInputOverlayTextField.font = UIFont.systemFont(ofSize: 15)
        codeInputOverlayTextField.textColor = .black
        codeInputOverlayTextField.keyboardType = .numberPad
        codeInputOverlayTextField.borderStyle = .roundedRect
        codeInputOverlayTextField.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        codeInputOverlayTextField.translatesAutoresizingMaskIntoConstraints = false
        codeInputOverlay.addSubview(codeInputOverlayTextField)

        codeInputOverlayQueryButton = UIButton(type: .system)
        codeInputOverlayQueryButton.setTitle("查询", for: .normal)
        codeInputOverlayQueryButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        codeInputOverlayQueryButton.setTitleColor(navBlue, for: .normal)
        codeInputOverlayQueryButton.addTarget(self, action: #selector(queryStockTapped), for: .touchUpInside)
        codeInputOverlayQueryButton.translatesAutoresizingMaskIntoConstraints = false
        codeInputOverlay.addSubview(codeInputOverlayQueryButton)

        let sep = UIView()
        sep.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        codeInputOverlay.addSubview(sep)
        sep.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            codeInputOverlay.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor),
            codeInputOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            codeInputOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            codeInputOverlay.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: codeInputOverlay.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: codeInputOverlay.centerYAnchor),
            codeInputOverlayQueryButton.trailingAnchor.constraint(equalTo: codeInputOverlay.trailingAnchor, constant: -16),
            codeInputOverlayQueryButton.centerYAnchor.constraint(equalTo: codeInputOverlay.centerYAnchor),
            codeInputOverlayQueryButton.widthAnchor.constraint(equalToConstant: 44),
            codeInputOverlayTextField.trailingAnchor.constraint(equalTo: codeInputOverlayQueryButton.leadingAnchor, constant: -8),
            codeInputOverlayTextField.centerYAnchor.constraint(equalTo: codeInputOverlay.centerYAnchor),
            codeInputOverlayTextField.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            codeInputOverlayTextField.heightAnchor.constraint(equalToConstant: 34),
            sep.leadingAnchor.constraint(equalTo: codeInputOverlay.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: codeInputOverlay.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: codeInputOverlay.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    // MARK: - 代码输入行（可输入 + 查询）- 仅作布局占位，实际交互用 overlay
    private func addCodeInputRow(to parent: UIView, after previousView: UIView?, isBuy: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.isUserInteractionEnabled = true
        parent.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "代码"
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let textField = UITextField()
        textField.text = stockCode
        textField.placeholder = "输入股票代码"
        textField.font = UIFont.systemFont(ofSize: 15)
        textField.textColor = .black
        textField.keyboardType = .numberPad
        textField.borderStyle = .roundedRect
        textField.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        textField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textField)
        if isBuy {
            buyCodeTextField = textField
        } else {
            sellCodeTextField = textField
        }

        let queryBtn = UIButton(type: .system)
        queryBtn.setTitle("查询", for: .normal)
        queryBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        queryBtn.setTitleColor(navBlue, for: .normal)
        queryBtn.addTarget(self, action: #selector(queryStockTapped), for: .touchUpInside)
        queryBtn.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(queryBtn)
        if isBuy {
            buyCodeQueryButton = queryBtn
        } else {
            sellCodeQueryButton = queryBtn
        }

        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        container.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            queryBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            queryBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            queryBtn.widthAnchor.constraint(equalToConstant: 44),
            textField.trailingAnchor.constraint(equalTo: queryBtn.leadingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textField.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            textField.heightAnchor.constraint(equalToConstant: 34),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])

        if let prev = previousView {
            container.topAnchor.constraint(equalTo: prev.bottomAnchor).isActive = true
        } else {
            container.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
        }
        return container
    }

    @objc private func queryStockTapped() {
        let code = codeInputOverlayTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !code.isEmpty else {
            Toast.show("请输入股票代码")
            return
        }
        stockCode = code
        buyCodeTextField?.text = code
        sellCodeTextField?.text = code
        // 调用真实 API 加载数据
        loadStockData()
    }

    // MARK: - 可编辑信息行（点击右侧数值弹出编辑）
    private func addEditableInfoRow(to parent: UIView, after previousView: UIView?, title: String, valueView: UIView, onEdit: @escaping (String) -> Void) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.isUserInteractionEnabled = true
        parent.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(valueView)
        valueView.translatesAutoresizingMaskIntoConstraints = false

        let tap = UITapGestureRecognizer(target: self, action: #selector(editableValueTapped(_:)))
        valueView.addGestureRecognizer(tap)
        valueView.gestureRecognizers?.forEach { $0.cancelsTouchesInView = false }
        Self.editableCallbacks[ObjectIdentifier(valueView)] = onEdit

        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        container.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            valueView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])

        if let prev = previousView {
            container.topAnchor.constraint(equalTo: prev.bottomAnchor).isActive = true
        } else {
            container.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
        }
        return container
    }

    private static var editableCallbacks: [ObjectIdentifier: (String) -> Void] = [:]

    @objc private func editableValueTapped(_ gesture: UITapGestureRecognizer) {
        guard let valueView = gesture.view else { return }
        let callback = Self.editableCallbacks[ObjectIdentifier(valueView)]
        let current = (valueView as? UILabel)?.text ?? ""
        let alert = UIAlertController(title: "修改", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = current
            tf.keyboardType = .decimalPad
            tf.placeholder = "输入新值"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            let newValue = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !newValue.isEmpty else { return }
            (valueView as? UILabel)?.text = newValue
            callback?(newValue)
        })
        present(alert, animated: true)
    }

    // MARK: - Helper Methods
    
    private func addInfoRow(to parent: UIView, after previousView: UIView?, title: String, value: String, valueColor: UIColor = .black) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.isUserInteractionEnabled = false
        parent.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        titleLabel.isUserInteractionEnabled = false
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 15)
        valueLabel.textColor = valueColor
        valueLabel.textAlignment = .right
        valueLabel.isUserInteractionEnabled = false
        container.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        separator.isUserInteractionEnabled = false
        container.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        if let prev = previousView {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: prev.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: parent.topAnchor)
            ])
        }
        
        return container
    }
    
    private func addInfoRow(to parent: UIView, after previousView: UIView?, title: String, valueView: UIView) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.isUserInteractionEnabled = false
        parent.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        titleLabel.isUserInteractionEnabled = false
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(valueView)
        valueView.translatesAutoresizingMaskIntoConstraints = false
        
        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        separator.isUserInteractionEnabled = false
        container.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            valueView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        if let prev = previousView {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: prev.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: parent.topAnchor)
            ])
        }
        
        return container
    }
    
    // MARK: - 仓位行 - 按钮直接添加到view
    private func addPositionRow(to parent: UIView, after previousView: UIView?, isBuy: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.isUserInteractionEnabled = true
        container.clipsToBounds = false // 确保按钮不被裁剪
        // 重要：确保 container 不会拦截触摸事件，只传递触摸事件给子视图
        container.isMultipleTouchEnabled = true
        parent.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "仓位"
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        titleLabel.isUserInteractionEnabled = false
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let positions = ["1/4", "1/3", "1/2", "全仓"]
        var buttons: [UIButton] = []
        
        // 按钮直接添加到container，同时添加到view作为测试
        for (index, position) in positions.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(position, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            button.layer.cornerRadius = 4
            button.tag = index
            button.isUserInteractionEnabled = true
            button.isEnabled = true
            button.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
            button.setTitleColor(.black, for: .normal)
            button.setTitleColor(.white, for: .selected)
            button.setTitleColor(.white, for: .highlighted)
            button.adjustsImageWhenHighlighted = false
            button.adjustsImageWhenDisabled = false
            
            // 直接添加到container
            container.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            
            // 添加target-action - 使用多种事件确保能响应
            if isBuy {
                button.addTarget(self, action: #selector(buyPositionTapped(_:)), for: .touchUpInside)
                // 添加 touchDown 用于调试
                button.addTarget(self, action: #selector(buyPositionTouchDown(_:)), for: .touchDown)
            } else {
                button.addTarget(self, action: #selector(sellPositionTapped(_:)), for: .touchUpInside)
                // 添加 touchDown 用于调试
                button.addTarget(self, action: #selector(sellPositionTouchDown(_:)), for: .touchDown)
            }
            
            buttons.append(button)
        }
        
        if isBuy {
            positionButtons = buttons
        } else {
            sellPositionButtons = buttons
        }
        
        // 设置按钮约束 - 从右到左排列
        guard buttons.count >= 4 else { return container }
        
        // 全仓（最右边）
        NSLayoutConstraint.activate([
            buttons[3].trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            buttons[3].centerYAnchor.constraint(equalTo: container.centerYAnchor),
            buttons[3].widthAnchor.constraint(equalToConstant: 55),
            buttons[3].heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // 1/2
        NSLayoutConstraint.activate([
            buttons[2].trailingAnchor.constraint(equalTo: buttons[3].leadingAnchor, constant: -8),
            buttons[2].centerYAnchor.constraint(equalTo: container.centerYAnchor),
            buttons[2].widthAnchor.constraint(equalToConstant: 55),
            buttons[2].heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // 1/3
        NSLayoutConstraint.activate([
            buttons[1].trailingAnchor.constraint(equalTo: buttons[2].leadingAnchor, constant: -8),
            buttons[1].centerYAnchor.constraint(equalTo: container.centerYAnchor),
            buttons[1].widthAnchor.constraint(equalToConstant: 55),
            buttons[1].heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // 1/4（最左边）
        NSLayoutConstraint.activate([
            buttons[0].trailingAnchor.constraint(equalTo: buttons[1].leadingAnchor, constant: -8),
            buttons[0].centerYAnchor.constraint(equalTo: container.centerYAnchor),
            buttons[0].widthAnchor.constraint(equalToConstant: 55),
            buttons[0].heightAnchor.constraint(equalToConstant: 30)
        ])
        
        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        separator.isUserInteractionEnabled = false
        container.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // 先添加 separator，再添加按钮，确保按钮在最上层
        for button in buttons {
            container.bringSubviewToFront(button)
        }
        
        // 确保 separator 不会拦截触摸事件（虽然已经设置了 isUserInteractionEnabled = false）
        separator.isHidden = false // 确保可见但不拦截触摸
        
        if let prev = previousView {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: prev.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: parent.topAnchor)
            ])
        }
        
        updatePositionButtons(isBuy: isBuy)
        
        // 确保按钮在最上层，并且延迟执行以确保约束已生效
        DispatchQueue.main.async {
            // 先确保所有非交互视图在底层
            titleLabel.superview?.sendSubviewToBack(titleLabel)
            separator.superview?.sendSubviewToBack(separator)
            
            // 然后将按钮移到最上层
            for button in buttons {
                container.bringSubviewToFront(button)
                // 确保按钮可以接收触摸事件
                button.isExclusiveTouch = false
                // 确保按钮的父视图可以传递触摸事件
                if let superview = button.superview {
                    superview.isUserInteractionEnabled = true
                }
            }
            
            // 重要：将按钮直接添加到 view 上，绕过 container 和 buyView/sellView
            // 这样可以确保按钮能接收触摸事件，就像 buyConfirmButton 一样
            for (index, button) in buttons.enumerated() {
                if button.frame.width == 0 || button.frame.height == 0 {
                    print("警告：按钮 \(index) frame 不正确: \(button.frame)")
                    continue
                }
                
                // 计算按钮在 view 坐标系中的绝对位置
                guard let containerFrame = container.superview?.convert(container.frame, to: self.view) else {
                    continue
                }
                
                let buttonAbsoluteFrame = CGRect(
                    x: containerFrame.origin.x + button.frame.origin.x,
                    y: containerFrame.origin.y + button.frame.origin.y,
                    width: button.frame.width,
                    height: button.frame.height
                )
                
                print("按钮 \(index) 绝对位置: \(buttonAbsoluteFrame)")
                
                // 创建一个新的按钮，直接添加到 view 上
                let directButton = UIButton(type: .custom)
                directButton.setTitle(button.title(for: .normal), for: .normal)
                directButton.titleLabel?.font = button.titleLabel?.font
                directButton.layer.cornerRadius = button.layer.cornerRadius
                directButton.tag = button.tag
                directButton.isUserInteractionEnabled = true
                directButton.isEnabled = true
                directButton.backgroundColor = button.backgroundColor
                directButton.setTitleColor(button.titleColor(for: .normal), for: .normal)
                directButton.setTitleColor(button.titleColor(for: .selected), for: .selected)
                directButton.setTitleColor(button.titleColor(for: .highlighted), for: .highlighted)
                directButton.adjustsImageWhenHighlighted = false
                directButton.adjustsImageWhenDisabled = false
                
                // 添加事件处理
                if isBuy {
                    directButton.addTarget(self, action: #selector(self.buyPositionTapped(_:)), for: .touchUpInside)
                    directButton.addTarget(self, action: #selector(self.buyPositionTouchDown(_:)), for: .touchDown)
                } else {
                    directButton.addTarget(self, action: #selector(self.sellPositionTapped(_:)), for: .touchUpInside)
                    directButton.addTarget(self, action: #selector(self.sellPositionTouchDown(_:)), for: .touchDown)
                }
                
                // 隐藏原始按钮
                button.isHidden = true
                button.isUserInteractionEnabled = false
                
                // 将新按钮添加到 view
                self.view.addSubview(directButton)
                directButton.translatesAutoresizingMaskIntoConstraints = false
                
                // 设置约束，使用绝对位置
                NSLayoutConstraint.activate([
                    directButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: buttonAbsoluteFrame.origin.x),
                    directButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: buttonAbsoluteFrame.origin.y),
                    directButton.widthAnchor.constraint(equalToConstant: buttonAbsoluteFrame.width),
                    directButton.heightAnchor.constraint(equalToConstant: buttonAbsoluteFrame.height)
                ])
                
                // 更新数组中的按钮引用
                if isBuy, let buttonIndex = self.positionButtons.firstIndex(of: button) {
                    self.positionButtons[buttonIndex] = directButton
                } else if !isBuy, let buttonIndex = self.sellPositionButtons.firstIndex(of: button) {
                    self.sellPositionButtons[buttonIndex] = directButton
                }
            }
        }
        
        return container
    }
    
    // MARK: - 数量行
    private func addQuantityRow(to parent: UIView, after previousView: UIView?, isBuy: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.isUserInteractionEnabled = true
        container.clipsToBounds = false
        container.isMultipleTouchEnabled = true
        parent.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = isBuy ? "买入手数" : "卖出手数"
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        titleLabel.isUserInteractionEnabled = false
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 输入容器
        let inputContainer = UIView()
        inputContainer.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        inputContainer.layer.cornerRadius = 4
        inputContainer.isUserInteractionEnabled = true
        container.addSubview(inputContainer)
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 减号按钮
        let minusButton = UIButton(type: .custom)
        minusButton.setTitle("-", for: .normal)
        minusButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        minusButton.setTitleColor(.black, for: .normal)
        minusButton.isUserInteractionEnabled = true
        minusButton.backgroundColor = .clear
        if isBuy {
            minusButton.addTarget(self, action: #selector(buyQuantityMinus), for: .touchUpInside)
        } else {
            minusButton.addTarget(self, action: #selector(sellQuantityMinus), for: .touchUpInside)
        }
        inputContainer.addSubview(minusButton)
        minusButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 输入框
        let textField = UITextField()
        textField.text = "0"
        textField.font = UIFont.systemFont(ofSize: 15)
        textField.textColor = .black
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 4
        textField.isUserInteractionEnabled = true
        textField.isEnabled = true
        textField.borderStyle = .none
        if isBuy {
            textField.addTarget(self, action: #selector(buyQuantityChanged), for: .editingChanged)
            buyQuantityTextField = textField
        } else {
            textField.addTarget(self, action: #selector(sellQuantityChanged), for: .editingChanged)
            sellQuantityTextField = textField
        }
        inputContainer.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // 加号按钮
        let plusButton = UIButton(type: .custom)
        plusButton.setTitle("+", for: .normal)
        plusButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        plusButton.setTitleColor(.black, for: .normal)
        plusButton.isUserInteractionEnabled = true
        plusButton.backgroundColor = .clear
        if isBuy {
            plusButton.addTarget(self, action: #selector(buyQuantityPlus), for: .touchUpInside)
        } else {
            plusButton.addTarget(self, action: #selector(sellQuantityPlus), for: .touchUpInside)
        }
        inputContainer.addSubview(plusButton)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        
        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        separator.isUserInteractionEnabled = false
        container.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            inputContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            inputContainer.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            inputContainer.widthAnchor.constraint(equalToConstant: 120),
            inputContainer.heightAnchor.constraint(equalToConstant: 36),
            
            minusButton.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 8),
            minusButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: 30),
            minusButton.heightAnchor.constraint(equalToConstant: 30),
            
            textField.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor, constant: 4),
            textField.trailingAnchor.constraint(equalTo: plusButton.leadingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 30),
            
            plusButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -8),
            plusButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 30),
            plusButton.heightAnchor.constraint(equalToConstant: 30),
            
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        if let prev = previousView {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: prev.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: parent.topAnchor)
            ])
        }
        
        // 延迟处理数量行控件，确保布局完成
        // 只处理当前可见的标签页对应的控件，避免卖出控件拦截买入控件的事件
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 检查是否应该处理这个控件
            let shouldProcess = (isBuy && self.selectedIndex == 0) || (!isBuy && self.selectedIndex == 1)
            if shouldProcess {
                self.moveQuantityControlsToView(container: container, isBuy: isBuy, minusButton: minusButton, textField: textField, plusButton: plusButton)
            } else {
                // 如果当前不可见，先隐藏原始控件，避免拦截事件
                minusButton.isHidden = true
                minusButton.isUserInteractionEnabled = false
                textField.isHidden = true
                textField.isUserInteractionEnabled = false
                plusButton.isHidden = true
                plusButton.isUserInteractionEnabled = false
                print("⚠️ \(isBuy ? "买入" : "卖出")数量行控件当前不可见，已隐藏")
            }
        }
        
        return container
    }
    
    private func updatePositionButtons(isBuy: Bool) {
        let buttons = isBuy ? positionButtons : sellPositionButtons
        let selectedIndex = isBuy ? selectedPositionIndex : selectedSellPositionIndex
        
        guard !buttons.isEmpty else { return }
        
        let selectedBlue = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0)
        
        for (index, button) in buttons.enumerated() {
            if index == selectedIndex {
                button.backgroundColor = selectedBlue
                button.setTitleColor(.white, for: .normal)
                button.isSelected = true
            } else {
                button.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
                button.setTitleColor(.black, for: .normal)
                button.isSelected = false
            }
            button.isUserInteractionEnabled = true
            button.isEnabled = true
        }
    }
    
    @objc private func buyPositionTouchDown(_ sender: UIButton) {
        print("🔵 买入仓位按钮 touchDown: tag = \(sender.tag), frame = \(sender.frame)")
    }
    
    @objc private func buyPositionTapped(_ sender: UIButton) {
        print("✅ 买入仓位按钮被点击: tag = \(sender.tag), frame = \(sender.frame)")
        selectedPositionIndex = sender.tag
        updatePositionButtons(isBuy: true)
        calculateBuyAmount()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func sellPositionTouchDown(_ sender: UIButton) {
        print("🔵 卖出仓位按钮 touchDown: tag = \(sender.tag), frame = \(sender.frame)")
    }
    
    @objc private func sellPositionTapped(_ sender: UIButton) {
        print("✅ 卖出仓位按钮被点击: tag = \(sender.tag), frame = \(sender.frame)")
        selectedSellPositionIndex = sender.tag
        updatePositionButtons(isBuy: false)
        calculateSellAmount()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - 将数量行的控件移到 view 上
    private func moveQuantityControlsToView(container: UIView, isBuy: Bool, minusButton: UIButton, textField: UITextField, plusButton: UIButton) {
        // 检查是否已经处理过
        if isBuy && (buyQuantityMinusButton != nil || buyQuantityPlusButton != nil) {
            print("⚠️ 买入数量行控件已经处理过，跳过")
            return
        }
        if !isBuy && (sellQuantityMinusButton != nil || sellQuantityPlusButton != nil) {
            print("⚠️ 卖出数量行控件已经处理过，跳过")
            return
        }
        
        // 计算各个控件在 view 中的绝对位置
        guard let minusFrame = minusButton.superview?.convert(minusButton.frame, to: self.view),
              let textFieldFrame = textField.superview?.convert(textField.frame, to: self.view),
              let plusFrame = plusButton.superview?.convert(plusButton.frame, to: self.view) else {
            print("⚠️ 无法计算\(isBuy ? "买入" : "卖出")数量行控件的绝对位置")
            print("   minusButton.superview: \(String(describing: minusButton.superview))")
            print("   textField.superview: \(String(describing: textField.superview))")
            print("   plusButton.superview: \(String(describing: plusButton.superview))")
            return
        }
        
        print("✅ \(isBuy ? "买入" : "卖出")数量行控件位置 - minus: \(minusFrame), textField: \(textFieldFrame), plus: \(plusFrame)")
        
        // 创建新的减号按钮，直接添加到 view
        let directMinusButton = UIButton(type: .custom)
        directMinusButton.setTitle("-", for: .normal)
        directMinusButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        directMinusButton.setTitleColor(.black, for: .normal)
        directMinusButton.isUserInteractionEnabled = true
        directMinusButton.isEnabled = true
        directMinusButton.backgroundColor = .clear
        if isBuy {
            directMinusButton.addTarget(self, action: #selector(buyQuantityMinus), for: .touchUpInside)
            buyQuantityMinusButton = directMinusButton
        } else {
            directMinusButton.addTarget(self, action: #selector(sellQuantityMinus), for: .touchUpInside)
            sellQuantityMinusButton = directMinusButton
        }
        self.view.addSubview(directMinusButton)
        directMinusButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            directMinusButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: minusFrame.origin.x),
            directMinusButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: minusFrame.origin.y),
            directMinusButton.widthAnchor.constraint(equalToConstant: minusFrame.width),
            directMinusButton.heightAnchor.constraint(equalToConstant: minusFrame.height)
        ])
        
        // 创建新的输入框，直接添加到 view
        let directTextField = UITextField()
        directTextField.text = textField.text
        directTextField.font = UIFont.systemFont(ofSize: 15)
        directTextField.textColor = .black
        directTextField.textAlignment = .center
        directTextField.keyboardType = .numberPad
        directTextField.backgroundColor = .white
        directTextField.layer.cornerRadius = 4
        directTextField.isUserInteractionEnabled = true
        directTextField.isEnabled = true
        directTextField.borderStyle = .none
        if isBuy {
            directTextField.addTarget(self, action: #selector(buyQuantityChanged), for: .editingChanged)
            buyQuantityTextField = directTextField
        } else {
            directTextField.addTarget(self, action: #selector(sellQuantityChanged), for: .editingChanged)
            sellQuantityTextField = directTextField
        }
        self.view.addSubview(directTextField)
        directTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            directTextField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: textFieldFrame.origin.x),
            directTextField.topAnchor.constraint(equalTo: self.view.topAnchor, constant: textFieldFrame.origin.y),
            directTextField.widthAnchor.constraint(equalToConstant: textFieldFrame.width),
            directTextField.heightAnchor.constraint(equalToConstant: textFieldFrame.height)
        ])
        
        // 创建新的加号按钮，直接添加到 view
        let directPlusButton = UIButton(type: .custom)
        directPlusButton.setTitle("+", for: .normal)
        directPlusButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        directPlusButton.setTitleColor(.black, for: .normal)
        directPlusButton.isUserInteractionEnabled = true
        directPlusButton.isEnabled = true
        directPlusButton.backgroundColor = .clear
        if isBuy {
            directPlusButton.addTarget(self, action: #selector(buyQuantityPlus), for: .touchUpInside)
            buyQuantityPlusButton = directPlusButton
        } else {
            directPlusButton.addTarget(self, action: #selector(sellQuantityPlus), for: .touchUpInside)
            sellQuantityPlusButton = directPlusButton
        }
        self.view.addSubview(directPlusButton)
        directPlusButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            directPlusButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: plusFrame.origin.x),
            directPlusButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: plusFrame.origin.y),
            directPlusButton.widthAnchor.constraint(equalToConstant: plusFrame.width),
            directPlusButton.heightAnchor.constraint(equalToConstant: plusFrame.height)
        ])
        
        // 隐藏原始控件
        minusButton.isHidden = true
        minusButton.isUserInteractionEnabled = false
        textField.isHidden = true
        textField.isUserInteractionEnabled = false
        plusButton.isHidden = true
        plusButton.isUserInteractionEnabled = false
        
        print("✅ \(isBuy ? "买入" : "卖出")数量行控件已移到 view 上")
        print("   directMinusButton.frame: \(directMinusButton.frame)")
        print("   directTextField.frame: \(directTextField.frame)")
        print("   directPlusButton.frame: \(directPlusButton.frame)")
        
        // 立即验证 frame（在下一个 runloop）
        DispatchQueue.main.async {
            print("   延迟验证 - directMinusButton.frame: \(directMinusButton.frame), isUserInteractionEnabled: \(directMinusButton.isUserInteractionEnabled)")
            print("   延迟验证 - directTextField.frame: \(directTextField.frame), isUserInteractionEnabled: \(directTextField.isUserInteractionEnabled)")
            print("   延迟验证 - directPlusButton.frame: \(directPlusButton.frame), isUserInteractionEnabled: \(directPlusButton.isUserInteractionEnabled)")
        }
    }
    
    @objc private func buyQuantityMinus() {
        print("✅✅✅ buyQuantityMinus 被调用")
        guard let textField = buyQuantityTextField else {
            print("⚠️ buyQuantityTextField 为 nil")
            return
        }
        var quantity = Int(textField.text ?? "0") ?? 0
        if quantity > 0 {
            quantity -= 1
            buyQuantity = quantity
            textField.text = "\(quantity)"
            calculateBuyAmount()
        }
    }
    
    @objc private func buyQuantityPlus() {
        print("✅✅✅ buyQuantityPlus 被调用")
        guard let textField = buyQuantityTextField else {
            print("⚠️ buyQuantityTextField 为 nil")
            return
        }
        var quantity = Int(textField.text ?? "0") ?? 0
        quantity += 1
        buyQuantity = quantity
        textField.text = "\(quantity)"
        calculateBuyAmount()
    }
    
    @objc private func buyQuantityChanged() {
        guard let textField = buyQuantityTextField else { return }
        buyQuantity = Int(textField.text ?? "0") ?? 0
        calculateBuyAmount()
    }
    
    @objc private func sellQuantityMinus() {
        print("✅ sellQuantityMinus 被调用")
        guard let textField = sellQuantityTextField else { return }
        var quantity = Int(textField.text ?? "0") ?? 0
        if quantity > 0 {
            quantity -= 1
            sellQuantity = quantity
            textField.text = "\(quantity)"
            calculateSellAmount()
        }
    }
    
    @objc private func sellQuantityPlus() {
        print("✅ sellQuantityPlus 被调用")
        guard let textField = sellQuantityTextField else { return }
        var quantity = Int(textField.text ?? "0") ?? 0
        quantity += 1
        sellQuantity = quantity
        textField.text = "\(quantity)"
        calculateSellAmount()
    }
    
    @objc private func sellQuantityChanged() {
        guard let textField = sellQuantityTextField else { return }
        sellQuantity = Int(textField.text ?? "0") ?? 0
        calculateSellAmount()
    }
    
    private func calculateBuyAmount() {
        let price = Double(currentPrice) ?? 0.0
        let total = Double(buyQuantity) * price
        let serviceFee = total * 0.0001 // 0.01%
        
        serviceFeeLabel.text = String(format: "%.2f", serviceFee)
        payableLabel.text = String(format: "%.2f", total + serviceFee)
    }
    
    private func calculateSellAmount() {
        let price = Double(currentPrice) ?? 0.0
        let total = Double(sellQuantity) * 100.0 * price
        
        totalAmountLabel.text = String(format: "%.2f", total)
    }
    
    private func loadStockData() {
        updateLimitUpDown()
        fetchStockDetail(for: stockCode)
        fetchUserAssets()
        if selectedIndex == 1 {
            fetchSellHoldings(for: stockCode)
        }
    }
    
    private func fetchStockDetail(for code: String) {
        guard !code.isEmpty else { return }
        
        let marketId: String
        switch exchange {
        case "沪": marketId = "1"
        case "深": marketId = "0"
        case "京": marketId = "0"
        default:   marketId = code.hasPrefix("6") ? "1" : "0"
        }
        let secid = "\(marketId).\(code)"
        let fields = "f43,f44,f46,f60"
        let urlStr = "https://push2.eastmoney.com/api/qt/stock/get?secid=\(secid)&fields=\(fields)&ut=fa5fd1943c7b386f172d6893dbfba10b"
        
        guard let url = URL(string: urlStr) else { return }
        var request = URLRequest(url: url)
        request.setValue("https://quote.eastmoney.com/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any] else {
                return
            }
            DispatchQueue.main.async {
                // 东财返回的分时最新价并不在上述 fields 中，如果有传过来的 currentPrice 先继续使用
                let price = self.currentPrice
                
                self.buyPriceLabel?.text = price
                self.buyCurrentPriceLabel?.text = price
                self.sellCurrentPriceLabel?.text = price
                
                // 仅在非外部指定持仓时才去使用最新价作为买入价显示
                if !self.useProvidedHoldings {
                    self.buyPriceSellLabel?.text = price
                }
                
                self.stockName = d["f58"] as? String ?? self.stockName
                
                if let yClose = d["f60"] as? Double, yClose > 0 {
                    let limitPercent: Double
                    if code.hasPrefix("30") || code.hasPrefix("68") {
                        limitPercent = 0.20
                    } else if ["43", "83", "87", "92"].contains(where: { code.hasPrefix($0) }) {
                        limitPercent = 0.30
                    } else if (self.stockName.contains("ST")) {
                        limitPercent = 0.05
                    } else {
                        limitPercent = 0.10
                    }
                    
                    self.limitUpPrice = String(format: "%.2f", yClose * (1 + limitPercent))
                    self.limitDownPrice = String(format: "%.2f", yClose * (1 - limitPercent))
                }
                
                self.updateLimitUpDown()
                if self.selectedIndex == 0 {
                    self.calculateBuyAmount()
                } else {
                    self.calculateSellAmount()
                }
            }
        }.resume()
    }
    
    private func fetchUserAssets() {
        SecureNetworkManager.shared.request(
            api: "/api/user/getUserPrice_all1",
            method: .get,
            params: [:]
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let res):
                    guard let dict = res.decrypted,
                          let data = dict["data"] as? [String: Any],
                          let list = data["list"] as? [String: Any] else { return }
                    let balance = list["balance"] as? Double ?? 0.0
                    self?.availableAmountLabel?.text = String(format: "%.2f", balance)
                case .failure(_):
                    break
                }
            }
        }
    }
    
    private func fetchSellHoldings(for code: String) {
        guard !code.isEmpty else { return }
        SecureNetworkManager.shared.request(
            api: "/api/deal/mrSellLst",
            method: .get,
            params: ["keyword": code]
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let res):
                    guard let dict = res.decrypted,
                          let data = dict["data"] as? [[String: Any]],
                          let holding = data.first else { 
                        if self?.useProvidedHoldings == true {
                            self?.holdingQuantityLabel?.text = self?.sellHoldingQty
                            self?.buyPriceSellLabel?.text = self?.sellBuyPrice
                        } else {
                            self?.holdingQuantityLabel?.text = "0"
                            self?.buyPriceSellLabel?.text = "--"
                        }
                        return 
                    }
                    let num = holding["number"] as? String ?? "0"
                    self?.holdingQuantityLabel?.text = num
                    
                    // 设置买入价（持仓成本价）
                    let buyPrice = "\(holding["buyprice"] ?? "--")"
                    self?.buyPriceSellLabel?.text = buyPrice
                case .failure(_):
                    if self?.useProvidedHoldings == true {
                        self?.holdingQuantityLabel?.text = self?.sellHoldingQty
                        self?.buyPriceSellLabel?.text = self?.sellBuyPrice
                    }
                    break
                }
            }
        }
    }
    
    private func updateLimitUpDown() {
        if limitUpPrice.isEmpty || limitUpPrice == "0.00" || limitUpPrice == "--" {
            let price = Double(currentPrice) ?? 0.0
            
            let limitPercent: Double
            if stockCode.hasPrefix("30") || stockCode.hasPrefix("68") {
                limitPercent = 0.20
            } else if ["43", "83", "87", "92"].contains(where: { stockCode.hasPrefix($0) }) {
                limitPercent = 0.30
            } else if (stockName.contains("ST")) {
                limitPercent = 0.05
            } else {
                limitPercent = 0.10
            }
            limitUpPrice = String(format: "%.2f", price * (1 + limitPercent))
            limitDownPrice = String(format: "%.2f", price * (1 - limitPercent))
        }
        
        let limitUpText = limitUpPrice
        let limitDownText = limitDownPrice
        let fullText = "跌停: \(limitDownText)  涨停: \(limitUpText)"
        
        let attributedText = NSMutableAttributedString(string: fullText)
        if let range = fullText.range(of: "跌停: \(limitDownText)") {
            let nsRange = NSRange(range, in: fullText)
            attributedText.addAttribute(.foregroundColor, value: UIColor.green, range: nsRange)
        }
        if let range = fullText.range(of: "涨停: \(limitUpText)") {
            let nsRange = NSRange(range, in: fullText)
            attributedText.addAttribute(.foregroundColor, value: UIColor.red, range: nsRange)
        }
        
        limitUpDownLabel.attributedText = attributedText
    }
    
    // MARK: - Bottom Buttons
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupBottomButtons()
        
        // 在 view 出现后，处理当前可见标签页的数量行控件
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if self.selectedIndex == 0 {
                // 处理买入的数量行控件
                self.processBuyQuantityControlsIfNeeded()
            } else {
                // 处理卖出的数量行控件
                self.processSellQuantityControlsIfNeeded()
            }
            // 更新数量行控件的显示状态
            self.ensureQuantityControlsOnTop()
        }
    }
    
    private func setupBottomButtons() {
        buyConfirmButton.setTitle("买入下单", for: .normal)
        buyConfirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        buyConfirmButton.setTitleColor(.white, for: .normal)
        buyConfirmButton.backgroundColor = navBlue
        buyConfirmButton.layer.cornerRadius = 8
        buyConfirmButton.addTarget(self, action: #selector(buyConfirmTapped), for: .touchUpInside)
        view.addSubview(buyConfirmButton)
        buyConfirmButton.translatesAutoresizingMaskIntoConstraints = false
        
        sellConfirmButton.setTitle("确认卖出", for: .normal)
        sellConfirmButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        sellConfirmButton.setTitleColor(.white, for: .normal)
        sellConfirmButton.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        sellConfirmButton.layer.cornerRadius = 8
        sellConfirmButton.addTarget(self, action: #selector(sellConfirmTapped), for: .touchUpInside)
        view.addSubview(sellConfirmButton)
        sellConfirmButton.translatesAutoresizingMaskIntoConstraints = false
        
        updateBottomButtons()
        
        NSLayoutConstraint.activate([
            buyConfirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buyConfirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buyConfirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buyConfirmButton.heightAnchor.constraint(equalToConstant: 50),
            
            sellConfirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sellConfirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sellConfirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            sellConfirmButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func updateBottomButtons() {
        buyConfirmButton.isHidden = selectedIndex != 0
        sellConfirmButton.isHidden = selectedIndex != 1
    }
    
    @objc private func buyConfirmTapped() {
        guard let p = Double(currentPrice), p > 0 else {
            Toast.show("买入价格无效")
            return
        }
        guard buyQuantity > 0 else {
            Toast.show("请输入买入数量")
            return
        }
        buyConfirmButton.isEnabled = false
        SecureNetworkManager.shared.request(
            api: "/api/deal/addStrategy",
            method: .post,
            params: [
                "allcode": stockCode,
                "buyprice": "\(p)",
                "canBuy": buyQuantity
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.buyConfirmButton.isEnabled = true
                switch result {
                case .success(let res):
                    if let dict = res.decrypted, let retCode = dict["code"] as? Int, retCode == 1 {
                        Toast.show("买入委托已提交")
                        self?.loadStockData() // 刷新可买
                        self?.buyQuantity = 0
                        self?.buyQuantityTextField?.text = "0"
                        self?.calculateBuyAmount()
                    } else {
                        let msg = res.decrypted?["msg"] as? String ?? "提交失败"
                        Toast.show(msg)
                    }
                case .failure(let err):
                    Toast.show("买入失败: \(err.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func sellConfirmTapped() {
        guard let p = Double(currentPrice), p > 0 else {
            Toast.show("卖出价格无效")
            return
        }
        guard sellQuantity > 0 else {
            Toast.show("请输入卖出数量")
            return
        }
        sellConfirmButton.isEnabled = false
        SecureNetworkManager.shared.request(
            api: "/api/deal/sell", // 接口文档未明示卖出接口，凭经验猜使用卖出/sell
            method: .get,
            params: [
                "id": "",
                "canBuy": sellQuantity
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.sellConfirmButton.isEnabled = true
                switch result {
                case .success(let res):
                    if let dict = res.decrypted, let retCode = dict["code"] as? Int, retCode == 1 {
                        Toast.show("卖出委托已提交")
                        self?.loadStockData() // 刷新可卖
                        self?.sellQuantity = 0
                        self?.sellQuantityTextField?.text = "0"
                        self?.calculateSellAmount()
                    } else {
                        let msg = res.decrypted?["msg"] as? String ?? "提交失败"
                        Toast.show(msg)
                    }
                case .failure(let err):
                    Toast.show("卖出失败: \(err.localizedDescription)")
                }
            }
        }
    }
}
