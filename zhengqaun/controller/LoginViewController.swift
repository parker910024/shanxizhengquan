//
//  LoginViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit
import SafariServices

class LoginViewController: UIViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    
    // Tab切换
    private let loginTabButton = UIButton(type: .system)
    private let registerTabButton = UIButton(type: .system)
    private let tabIndicator = UIView()
    private var currentTab: TabType = .login
    
    enum TabType {
        case login
        case register
    }
    
    // 登录表单
    private let loginAccountLabel = UILabel()
    private let loginAccountTextField = UITextField()
    private let loginPasswordLabel = UILabel()
    private let loginPasswordTextField = UITextField()
    
    // 注册表单 - 用户名模式
    private let registerUsernameLabel = UILabel()
    private let registerUsernameTextField = UITextField()
    
    // 注册表单 - 手机号模式
    private let registerPhoneLabel = UILabel()
    private let registerCountryCodeButton = UIButton(type: .system)
    private let registerPhoneTextField = UITextField()
    private let registerVerificationCodeLabel = UILabel()
    private let registerVerificationCodeTextField = UITextField()
    private let registerGetCodeButton = UIButton(type: .system)
    private var selectedCountryCode: CountryCode = CountryCode.defaultCountry
    
    // 注册表单 - 通用
    private let registerPasswordLabel = UILabel()
    private let registerPasswordTextField = UITextField()
    private let registerConfirmPasswordLabel = UILabel()
    private let registerConfirmPasswordTextField = UITextField()
    private let registerPaymentPasswordLabel = UILabel()
    private let registerPaymentPasswordTextField = UITextField()
    private let registerInviteCodeLabel = UILabel()
    private let registerInviteCodeTextField = UITextField()
    
    // 协议
    private let agreementCheckbox = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    
    // 登录按钮
    private let loginButton = UIButton(type: .system)
    
    // 表单容器引用
    private var loginFormContainer: UIView!
    private var registerFormContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 设置滚动视图
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // 确保scrollView可以滚动
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        setupHeader()
        setupTabs()
        setupLoginForm()
        setupRegisterForm()
        setupAgreement()
        setupLoginButton()
        
        // 默认显示登录表单
        switchToTab(.login)
    }
    
    // MARK: - Header
    private func setupHeader() {
        contentView.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 渐变背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0).cgColor,
            UIColor(red: 0.15, green: 0.55, blue: 0.85, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        headerView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Logo
        let logoView = UIView()
        logoView.backgroundColor = UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0) // 橙色
        logoView.layer.cornerRadius = 20
        headerView.addSubview(logoView)
        logoView.translatesAutoresizingMaskIntoConstraints = false
        
        let logoLabel = UILabel()
        logoLabel.text = "W"
        logoLabel.font = UIFont.boldSystemFont(ofSize: 40)
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        logoView.addSubview(logoLabel)
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 应用名称
        let appNameLabel = UILabel()
        appNameLabel.text = "华泰证券"
        appNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        appNameLabel.textColor = .white
        appNameLabel.textAlignment = .center
        headerView.addSubview(appNameLabel)
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 280),
            
            logoView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            logoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            logoView.widthAnchor.constraint(equalToConstant: 80),
            logoView.heightAnchor.constraint(equalToConstant: 80),
            
            logoLabel.centerXAnchor.constraint(equalTo: logoView.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),
            
            appNameLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 16),
            appNameLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor)
        ])
        
        // 更新渐变层frame
        DispatchQueue.main.async {
            gradientLayer.frame = self.headerView.bounds
        }
    }
    
    // MARK: - Tabs
    private var tabContainer: UIView!
    
    private func setupTabs() {
        tabContainer = UIView()
        tabContainer.backgroundColor = .white // 白色背景，符合图片设计
        tabContainer.layer.cornerRadius = 12
        tabContainer.layer.masksToBounds = true
        contentView.addSubview(tabContainer)
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 登录按钮
        loginTabButton.setTitle("登录", for: .normal)
        loginTabButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        loginTabButton.setTitleColor(Constants.Color.themeBlue, for: .normal)
        loginTabButton.setTitleColor(Constants.Color.textSecondary, for: .normal)
        loginTabButton.addTarget(self, action: #selector(loginTabTapped), for: .touchUpInside)
        tabContainer.addSubview(loginTabButton)
        loginTabButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 注册按钮
        registerTabButton.setTitle("注册", for: .normal)
        registerTabButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        registerTabButton.setTitleColor(Constants.Color.textSecondary, for: .normal)
        registerTabButton.addTarget(self, action: #selector(registerTabTapped), for: .touchUpInside)
        tabContainer.addSubview(registerTabButton)
        registerTabButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 下划线指示器
        tabIndicator.backgroundColor = Constants.Color.themeBlue
        tabIndicator.layer.cornerRadius = 1
        tabContainer.addSubview(tabIndicator)
        tabIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tabContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            tabContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tabContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tabContainer.heightAnchor.constraint(equalToConstant: 44),
            
            loginTabButton.leadingAnchor.constraint(equalTo: tabContainer.leadingAnchor, constant: 4),
            loginTabButton.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            loginTabButton.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            loginTabButton.widthAnchor.constraint(equalTo: tabContainer.widthAnchor, multiplier: 0.5, constant: -4),
            
            registerTabButton.leadingAnchor.constraint(equalTo: loginTabButton.trailingAnchor),
            registerTabButton.topAnchor.constraint(equalTo: tabContainer.topAnchor),
            registerTabButton.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor),
            registerTabButton.trailingAnchor.constraint(equalTo: tabContainer.trailingAnchor, constant: -4),
            
            tabIndicator.bottomAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: -1),
            tabIndicator.heightAnchor.constraint(equalToConstant: 3),
            tabIndicator.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        tabIndicatorCenterXConstraint = tabIndicator.centerXAnchor.constraint(equalTo: loginTabButton.centerXAnchor)
        tabIndicatorCenterXConstraint.isActive = true
    }
    
    @objc private func loginTabTapped() {
        switchToTab(.login)
    }
    
    @objc private func registerTabTapped() {
        switchToTab(.register)
    }
    
    private var tabIndicatorCenterXConstraint: NSLayoutConstraint!
    
    private func switchToTab(_ tab: TabType) {
        currentTab = tab
        
        // 移除旧约束
        if tabIndicatorCenterXConstraint != nil {
            tabIndicatorCenterXConstraint.isActive = false
        }
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            if tab == .login {
                // 更新按钮文字颜色
                self.loginTabButton.setTitleColor(Constants.Color.themeBlue, for: .normal)
                self.registerTabButton.setTitleColor(Constants.Color.textSecondary, for: .normal)
                
                // 更新下划线位置
                self.tabIndicatorCenterXConstraint = self.tabIndicator.centerXAnchor.constraint(equalTo: self.loginTabButton.centerXAnchor)
                self.tabIndicatorCenterXConstraint.isActive = true
                
                // 切换表单显示
                self.loginFormContainer.isHidden = false
                self.loginFormContainer.alpha = 1.0
                self.registerFormContainer.isHidden = true
                self.registerFormContainer.alpha = 0.0
                
                // 更新登录表单标签
                self.updateLoginAccountLabel()
                self.updateLoginAccountPlaceholder()
                
                // 更新协议容器约束
                if self.agreementTopConstraint != nil {
                    self.agreementTopConstraint.isActive = false
                }
                self.agreementTopConstraint = self.agreementContainer.topAnchor.constraint(equalTo: self.loginFormContainer.bottomAnchor, constant: 20)
                self.agreementTopConstraint.isActive = true
            } else {
                // 更新按钮文字颜色
                self.loginTabButton.setTitleColor(Constants.Color.textSecondary, for: .normal)
                self.registerTabButton.setTitleColor(Constants.Color.themeBlue, for: .normal)
                
                // 更新下划线位置
                self.tabIndicatorCenterXConstraint = self.tabIndicator.centerXAnchor.constraint(equalTo: self.registerTabButton.centerXAnchor)
                self.tabIndicatorCenterXConstraint.isActive = true
                
                // 切换表单显示
                self.loginFormContainer.isHidden = true
                self.loginFormContainer.alpha = 0.0
                self.registerFormContainer.isHidden = false
                self.registerFormContainer.alpha = 1.0
                
                // 更新协议容器约束
                if self.agreementTopConstraint != nil {
                    self.agreementTopConstraint.isActive = false
                }
                self.agreementTopConstraint = self.agreementContainer.topAnchor.constraint(equalTo: self.registerFormContainer.bottomAnchor, constant: 20)
                self.agreementTopConstraint.isActive = true
            }
            
            self.updateLoginButtonTitle()
            self.updateAgreementText()
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Login Form
    private func setupLoginForm() {
        loginFormContainer = UIView()
        loginFormContainer.backgroundColor = .white
        loginFormContainer.alpha = 1.0
        contentView.addSubview(loginFormContainer)
        loginFormContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 账号/手机号
        updateLoginAccountLabel()
        loginAccountLabel.font = UIFont.systemFont(ofSize: 15)
        loginAccountLabel.textColor = Constants.Color.textPrimary
        loginFormContainer.addSubview(loginAccountLabel)
        loginAccountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        updateLoginAccountPlaceholder()
        loginAccountTextField.font = UIFont.systemFont(ofSize: 15)
        loginAccountTextField.textColor = Constants.Color.textPrimary
        loginAccountTextField.borderStyle = .none
        loginAccountTextField.clearButtonMode = .whileEditing
        loginAccountTextField.keyboardType = UserAuthManager.shared.phoneRegister ? .phonePad : .default
        loginFormContainer.addSubview(loginAccountTextField)
        loginAccountTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let accountLine = UIView()
        accountLine.backgroundColor = Constants.Color.separator
        loginFormContainer.addSubview(accountLine)
        accountLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 密码
        loginPasswordLabel.text = "密码"
        loginPasswordLabel.font = UIFont.systemFont(ofSize: 15)
        loginPasswordLabel.textColor = Constants.Color.textPrimary
        loginFormContainer.addSubview(loginPasswordLabel)
        loginPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        
        loginPasswordTextField.placeholder = "请输入密码"
        loginPasswordTextField.font = UIFont.systemFont(ofSize: 15)
        loginPasswordTextField.textColor = Constants.Color.textPrimary
        loginPasswordTextField.borderStyle = .none
        loginPasswordTextField.isSecureTextEntry = true
        loginPasswordTextField.clearButtonMode = .whileEditing
        loginFormContainer.addSubview(loginPasswordTextField)
        loginPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let passwordLine = UIView()
        passwordLine.backgroundColor = Constants.Color.separator
        loginFormContainer.addSubview(passwordLine)
        passwordLine.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loginFormContainer.topAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: 20),
            loginFormContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            loginFormContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            loginAccountLabel.topAnchor.constraint(equalTo: loginFormContainer.topAnchor, constant: 20),
            loginAccountLabel.leadingAnchor.constraint(equalTo: loginFormContainer.leadingAnchor),
            loginAccountLabel.widthAnchor.constraint(equalToConstant: 60),
            
            loginAccountTextField.centerYAnchor.constraint(equalTo: loginAccountLabel.centerYAnchor),
            loginAccountTextField.leadingAnchor.constraint(equalTo: loginAccountLabel.trailingAnchor, constant: 16),
            loginAccountTextField.trailingAnchor.constraint(equalTo: loginFormContainer.trailingAnchor),
            
            accountLine.topAnchor.constraint(equalTo: loginAccountLabel.bottomAnchor, constant: 12),
            accountLine.leadingAnchor.constraint(equalTo: loginFormContainer.leadingAnchor),
            accountLine.trailingAnchor.constraint(equalTo: loginFormContainer.trailingAnchor),
            accountLine.heightAnchor.constraint(equalToConstant: 1),
            
            loginPasswordLabel.topAnchor.constraint(equalTo: accountLine.bottomAnchor, constant: 20),
            loginPasswordLabel.leadingAnchor.constraint(equalTo: loginFormContainer.leadingAnchor),
            loginPasswordLabel.widthAnchor.constraint(equalToConstant: 60),
            
            loginPasswordTextField.centerYAnchor.constraint(equalTo: loginPasswordLabel.centerYAnchor),
            loginPasswordTextField.leadingAnchor.constraint(equalTo: loginPasswordLabel.trailingAnchor, constant: 16),
            loginPasswordTextField.trailingAnchor.constraint(equalTo: loginFormContainer.trailingAnchor),
            
            passwordLine.topAnchor.constraint(equalTo: loginPasswordLabel.bottomAnchor, constant: 12),
            passwordLine.leadingAnchor.constraint(equalTo: loginFormContainer.leadingAnchor),
            passwordLine.trailingAnchor.constraint(equalTo: loginFormContainer.trailingAnchor),
            passwordLine.heightAnchor.constraint(equalToConstant: 1),
            passwordLine.bottomAnchor.constraint(equalTo: loginFormContainer.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Helper Methods
    private func updateLoginAccountLabel() {
        loginAccountLabel.text = UserAuthManager.shared.phoneRegister ? "手机号" : "账号"
    }
    
    private func updateLoginAccountPlaceholder() {
        loginAccountTextField.placeholder = UserAuthManager.shared.phoneRegister ? "请输入手机号" : "请输入账号"
    }
    
    // MARK: - Register Form
    private func setupRegisterForm() {
        registerFormContainer = UIView()
        registerFormContainer.backgroundColor = .white
        registerFormContainer.isHidden = true
        registerFormContainer.alpha = 0.0
        contentView.addSubview(registerFormContainer)
        registerFormContainer.translatesAutoresizingMaskIntoConstraints = false
        
        if UserAuthManager.shared.phoneRegister {
            // 手机号注册模式
            setupPhoneRegisterForm(formContainer: registerFormContainer)
        } else {
            // 用户名注册模式
            setupUsernameRegisterForm(formContainer: registerFormContainer)
        }
    }
    
    private func setupPhoneRegisterForm(formContainer: UIView) {
        // 手机号行
        registerPhoneLabel.text = "手机号"
        registerPhoneLabel.font = UIFont.systemFont(ofSize: 15)
        registerPhoneLabel.textColor = Constants.Color.textPrimary
        formContainer.addSubview(registerPhoneLabel)
        registerPhoneLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 国家代码选择按钮
        registerCountryCodeButton.setTitle("\(selectedCountryCode.dialCode) ▼", for: .normal)
        registerCountryCodeButton.setTitleColor(Constants.Color.textPrimary, for: .normal)
        registerCountryCodeButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        registerCountryCodeButton.addTarget(self, action: #selector(countryCodeButtonTapped), for: .touchUpInside)
        formContainer.addSubview(registerCountryCodeButton)
        registerCountryCodeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 手机号输入框
        registerPhoneTextField.placeholder = "请输入手机号"
        registerPhoneTextField.font = UIFont.systemFont(ofSize: 15)
        registerPhoneTextField.textColor = Constants.Color.textPrimary
        registerPhoneTextField.borderStyle = .none
        registerPhoneTextField.keyboardType = .phonePad
        registerPhoneTextField.clearButtonMode = .whileEditing
        formContainer.addSubview(registerPhoneTextField)
        registerPhoneTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let phoneLine = createSeparatorLine()
        formContainer.addSubview(phoneLine)
        phoneLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 验证码行
        registerVerificationCodeLabel.text = "验证码"
        registerVerificationCodeLabel.font = UIFont.systemFont(ofSize: 15)
        registerVerificationCodeLabel.textColor = Constants.Color.textPrimary
        formContainer.addSubview(registerVerificationCodeLabel)
        registerVerificationCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 验证码输入框
        registerVerificationCodeTextField.placeholder = "请输入验证码"
        registerVerificationCodeTextField.font = UIFont.systemFont(ofSize: 15)
        registerVerificationCodeTextField.textColor = Constants.Color.textPrimary
        registerVerificationCodeTextField.borderStyle = .none
        registerVerificationCodeTextField.keyboardType = .numberPad
        registerVerificationCodeTextField.clearButtonMode = .whileEditing
        formContainer.addSubview(registerVerificationCodeTextField)
        registerVerificationCodeTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 获取验证码按钮
        registerGetCodeButton.setTitle("获取验证码", for: .normal)
        registerGetCodeButton.setTitleColor(Constants.Color.themeBlue, for: .normal)
        registerGetCodeButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        registerGetCodeButton.addTarget(self, action: #selector(getVerificationCodeTapped), for: .touchUpInside)
        formContainer.addSubview(registerGetCodeButton)
        registerGetCodeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let verificationCodeLine = createSeparatorLine()
        formContainer.addSubview(verificationCodeLine)
        verificationCodeLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 布局约束
        NSLayoutConstraint.activate([
            registerPhoneLabel.topAnchor.constraint(equalTo: formContainer.topAnchor, constant: 20),
            registerPhoneLabel.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            registerPhoneLabel.widthAnchor.constraint(equalToConstant: 60),
            
            registerCountryCodeButton.centerYAnchor.constraint(equalTo: registerPhoneLabel.centerYAnchor),
            registerCountryCodeButton.leadingAnchor.constraint(equalTo: registerPhoneLabel.trailingAnchor, constant: 16),
            registerCountryCodeButton.widthAnchor.constraint(equalToConstant: 70),
            
            registerPhoneTextField.centerYAnchor.constraint(equalTo: registerPhoneLabel.centerYAnchor),
            registerPhoneTextField.leadingAnchor.constraint(equalTo: registerCountryCodeButton.trailingAnchor, constant: 8),
            registerPhoneTextField.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            
            phoneLine.topAnchor.constraint(equalTo: registerPhoneLabel.bottomAnchor, constant: 12),
            phoneLine.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            phoneLine.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            phoneLine.heightAnchor.constraint(equalToConstant: 1),
            
            registerVerificationCodeLabel.topAnchor.constraint(equalTo: phoneLine.bottomAnchor, constant: 20),
            registerVerificationCodeLabel.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            registerVerificationCodeLabel.widthAnchor.constraint(equalToConstant: 60),
            
            registerVerificationCodeTextField.centerYAnchor.constraint(equalTo: registerVerificationCodeLabel.centerYAnchor),
            registerVerificationCodeTextField.leadingAnchor.constraint(equalTo: registerVerificationCodeLabel.trailingAnchor, constant: 16),
            registerVerificationCodeTextField.trailingAnchor.constraint(equalTo: registerGetCodeButton.leadingAnchor, constant: -12),
            
            registerGetCodeButton.centerYAnchor.constraint(equalTo: registerVerificationCodeLabel.centerYAnchor),
            registerGetCodeButton.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            registerGetCodeButton.widthAnchor.constraint(equalToConstant: 90),
            
            verificationCodeLine.topAnchor.constraint(equalTo: registerVerificationCodeLabel.bottomAnchor, constant: 12),
            verificationCodeLine.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            verificationCodeLine.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            verificationCodeLine.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // 继续添加其他字段（密码、确认密码、支付密码、邀请码）
        setupCommonRegisterFields(formContainer: formContainer, previousLine: verificationCodeLine)
    }
    
    private func setupUsernameRegisterForm(formContainer: UIView) {
        // 用户名
        registerUsernameLabel.text = "用户名"
        registerUsernameLabel.font = UIFont.systemFont(ofSize: 15)
        registerUsernameLabel.textColor = Constants.Color.textPrimary
        formContainer.addSubview(registerUsernameLabel)
        registerUsernameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        registerUsernameTextField.placeholder = "请输入用户名"
        registerUsernameTextField.font = UIFont.systemFont(ofSize: 15)
        registerUsernameTextField.textColor = Constants.Color.textPrimary
        registerUsernameTextField.borderStyle = .none
        registerUsernameTextField.clearButtonMode = .whileEditing
        formContainer.addSubview(registerUsernameTextField)
        registerUsernameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let usernameLine = createSeparatorLine()
        formContainer.addSubview(usernameLine)
        usernameLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 用户名行约束
        NSLayoutConstraint.activate([
            registerUsernameLabel.topAnchor.constraint(equalTo: formContainer.topAnchor, constant: 20),
            registerUsernameLabel.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            registerUsernameLabel.widthAnchor.constraint(equalToConstant: 80),
            
            registerUsernameTextField.centerYAnchor.constraint(equalTo: registerUsernameLabel.centerYAnchor),
            registerUsernameTextField.leadingAnchor.constraint(equalTo: registerUsernameLabel.trailingAnchor, constant: 16),
            registerUsernameTextField.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            
            usernameLine.topAnchor.constraint(equalTo: registerUsernameLabel.bottomAnchor, constant: 12),
            usernameLine.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            usernameLine.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            usernameLine.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // 继续添加其他字段
        setupCommonRegisterFields(formContainer: formContainer, previousLine: usernameLine)
    }
    
    private func setupCommonRegisterFields(formContainer: UIView, previousLine: UIView) {
        
        // 密码
        registerPasswordLabel.text = "密码"
        registerPasswordLabel.font = UIFont.systemFont(ofSize: 15)
        registerPasswordLabel.textColor = Constants.Color.textPrimary
        formContainer.addSubview(registerPasswordLabel)
        registerPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        
        registerPasswordTextField.placeholder = "请输入密码"
        registerPasswordTextField.font = UIFont.systemFont(ofSize: 15)
        registerPasswordTextField.textColor = Constants.Color.textPrimary
        registerPasswordTextField.borderStyle = .none
        registerPasswordTextField.isSecureTextEntry = true
        registerPasswordTextField.clearButtonMode = .whileEditing
        formContainer.addSubview(registerPasswordTextField)
        registerPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let passwordLine = createSeparatorLine()
        formContainer.addSubview(passwordLine)
        passwordLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 确认密码
        registerConfirmPasswordLabel.text = "确认密码"
        registerConfirmPasswordLabel.font = UIFont.systemFont(ofSize: 15)
        registerConfirmPasswordLabel.textColor = Constants.Color.textPrimary
        formContainer.addSubview(registerConfirmPasswordLabel)
        registerConfirmPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        
        registerConfirmPasswordTextField.placeholder = "请输入密码"
        registerConfirmPasswordTextField.font = UIFont.systemFont(ofSize: 15)
        registerConfirmPasswordTextField.textColor = Constants.Color.textPrimary
        registerConfirmPasswordTextField.borderStyle = .none
        registerConfirmPasswordTextField.isSecureTextEntry = true
        registerConfirmPasswordTextField.clearButtonMode = .whileEditing
        formContainer.addSubview(registerConfirmPasswordTextField)
        registerConfirmPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let confirmPasswordLine = createSeparatorLine()
        formContainer.addSubview(confirmPasswordLine)
        confirmPasswordLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 支付密码
        registerPaymentPasswordLabel.text = "支付密码"
        registerPaymentPasswordLabel.font = UIFont.systemFont(ofSize: 15)
        registerPaymentPasswordLabel.textColor = Constants.Color.textPrimary
        formContainer.addSubview(registerPaymentPasswordLabel)
        registerPaymentPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        
        registerPaymentPasswordTextField.placeholder = "请输入支付密码"
        registerPaymentPasswordTextField.font = UIFont.systemFont(ofSize: 15)
        registerPaymentPasswordTextField.textColor = Constants.Color.textPrimary
        registerPaymentPasswordTextField.borderStyle = .none
        registerPaymentPasswordTextField.isSecureTextEntry = true
        registerPaymentPasswordTextField.clearButtonMode = .whileEditing
        formContainer.addSubview(registerPaymentPasswordTextField)
        registerPaymentPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let paymentPasswordLine = createSeparatorLine()
        formContainer.addSubview(paymentPasswordLine)
        paymentPasswordLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 邀请码
        registerInviteCodeLabel.text = "邀请码"
        registerInviteCodeLabel.font = UIFont.systemFont(ofSize: 15)
        registerInviteCodeLabel.textColor = Constants.Color.textPrimary
        formContainer.addSubview(registerInviteCodeLabel)
        registerInviteCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        registerInviteCodeTextField.placeholder = "请输入邀请码"
        registerInviteCodeTextField.font = UIFont.systemFont(ofSize: 15)
        registerInviteCodeTextField.textColor = Constants.Color.textPrimary
        registerInviteCodeTextField.borderStyle = .none
        registerInviteCodeTextField.clearButtonMode = .whileEditing
        formContainer.addSubview(registerInviteCodeTextField)
        registerInviteCodeTextField.translatesAutoresizingMaskIntoConstraints = false
        
        let inviteCodeLine = createSeparatorLine()
        formContainer.addSubview(inviteCodeLine)
        inviteCodeLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 布局约束 - 通用字段
        NSLayoutConstraint.activate([
            registerPasswordLabel.topAnchor.constraint(equalTo: previousLine.bottomAnchor, constant: 20),
            registerPasswordLabel.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            registerPasswordLabel.widthAnchor.constraint(equalToConstant: 80),
            
            registerPasswordTextField.centerYAnchor.constraint(equalTo: registerPasswordLabel.centerYAnchor),
            registerPasswordTextField.leadingAnchor.constraint(equalTo: registerPasswordLabel.trailingAnchor, constant: 16),
            registerPasswordTextField.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            
            passwordLine.topAnchor.constraint(equalTo: registerPasswordLabel.bottomAnchor, constant: 12),
            passwordLine.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            passwordLine.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            passwordLine.heightAnchor.constraint(equalToConstant: 1),
            
            registerConfirmPasswordLabel.topAnchor.constraint(equalTo: passwordLine.bottomAnchor, constant: 20),
            registerConfirmPasswordLabel.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            registerConfirmPasswordLabel.widthAnchor.constraint(equalToConstant: 80),
            
            registerConfirmPasswordTextField.centerYAnchor.constraint(equalTo: registerConfirmPasswordLabel.centerYAnchor),
            registerConfirmPasswordTextField.leadingAnchor.constraint(equalTo: registerConfirmPasswordLabel.trailingAnchor, constant: 16),
            registerConfirmPasswordTextField.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            
            confirmPasswordLine.topAnchor.constraint(equalTo: registerConfirmPasswordLabel.bottomAnchor, constant: 12),
            confirmPasswordLine.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            confirmPasswordLine.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            confirmPasswordLine.heightAnchor.constraint(equalToConstant: 1),
            
            registerPaymentPasswordLabel.topAnchor.constraint(equalTo: confirmPasswordLine.bottomAnchor, constant: 20),
            registerPaymentPasswordLabel.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            registerPaymentPasswordLabel.widthAnchor.constraint(equalToConstant: 80),
            
            registerPaymentPasswordTextField.centerYAnchor.constraint(equalTo: registerPaymentPasswordLabel.centerYAnchor),
            registerPaymentPasswordTextField.leadingAnchor.constraint(equalTo: registerPaymentPasswordLabel.trailingAnchor, constant: 16),
            registerPaymentPasswordTextField.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            
            paymentPasswordLine.topAnchor.constraint(equalTo: registerPaymentPasswordLabel.bottomAnchor, constant: 12),
            paymentPasswordLine.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            paymentPasswordLine.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            paymentPasswordLine.heightAnchor.constraint(equalToConstant: 1),
            
            registerInviteCodeLabel.topAnchor.constraint(equalTo: paymentPasswordLine.bottomAnchor, constant: 20),
            registerInviteCodeLabel.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            registerInviteCodeLabel.widthAnchor.constraint(equalToConstant: 80),
            
            registerInviteCodeTextField.centerYAnchor.constraint(equalTo: registerInviteCodeLabel.centerYAnchor),
            registerInviteCodeTextField.leadingAnchor.constraint(equalTo: registerInviteCodeLabel.trailingAnchor, constant: 16),
            registerInviteCodeTextField.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            
            inviteCodeLine.topAnchor.constraint(equalTo: registerInviteCodeLabel.bottomAnchor, constant: 12),
            inviteCodeLine.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            inviteCodeLine.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            inviteCodeLine.heightAnchor.constraint(equalToConstant: 1),
            inviteCodeLine.bottomAnchor.constraint(equalTo: formContainer.bottomAnchor, constant: -20)
        ])
        
        NSLayoutConstraint.activate([
            formContainer.topAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: 20),
            formContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            formContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Event Handlers
    @objc private func countryCodeButtonTapped() {
        let pickerVC = CountryCodePickerViewController()
        pickerVC.selectedCountry = selectedCountryCode
        pickerVC.onCountrySelected = { [weak self] country in
            self?.selectedCountryCode = country
            self?.registerCountryCodeButton.setTitle("\(country.dialCode) ▼", for: .normal)
        }
        let navController = UINavigationController(rootViewController: pickerVC)
        present(navController, animated: true)
    }
    
    @objc private func getVerificationCodeTapped() {
        let phone = registerPhoneTextField.text ?? ""
        guard !phone.isEmpty else {
            Toast.show("请输入手机号")
            return
        }
        
        // TODO: 调用获取验证码接口
        Toast.showSuccess("验证码已发送")
        
        // 倒计时
        var countdown = 60
        registerGetCodeButton.isEnabled = false
        registerGetCodeButton.setTitle("\(countdown)秒", for: .normal)
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            countdown -= 1
            if countdown > 0 {
                self?.registerGetCodeButton.setTitle("\(countdown)秒", for: .normal)
            } else {
                timer.invalidate()
                self?.registerGetCodeButton.isEnabled = true
                self?.registerGetCodeButton.setTitle("获取验证码", for: .normal)
            }
        }
    }
    
    private func createSeparatorLine() -> UIView {
        let line = UIView()
        line.backgroundColor = Constants.Color.separator
        return line
    }
    
    // MARK: - Agreement
    private var agreementContainer: UIView!
    private var agreementTopConstraint: NSLayoutConstraint!
    
    private func setupAgreement() {
        agreementContainer = UIView()
        contentView.addSubview(agreementContainer)
        agreementContainer.translatesAutoresizingMaskIntoConstraints = false
        
        agreementCheckbox.setImage(UIImage(systemName: "circle"), for: .normal)
        agreementCheckbox.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        agreementCheckbox.tintColor = Constants.Color.themeBlue
        agreementCheckbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        agreementContainer.addSubview(agreementCheckbox)
        agreementCheckbox.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置协议文本（初始为登录状态）
        updateAgreementText()
        
        agreementLabel.font = UIFont.systemFont(ofSize: 12)
        agreementLabel.textColor = Constants.Color.textSecondary
        agreementLabel.numberOfLines = 0
        agreementLabel.isUserInteractionEnabled = true
        agreementContainer.addSubview(agreementLabel)
        agreementLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(agreementLabelTapped(_:)))
        agreementLabel.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            agreementContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            agreementContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            agreementCheckbox.leadingAnchor.constraint(equalTo: agreementContainer.leadingAnchor),
            agreementCheckbox.widthAnchor.constraint(equalToConstant: 24),
            agreementCheckbox.heightAnchor.constraint(equalToConstant: 24),
            
            agreementLabel.leadingAnchor.constraint(equalTo: agreementCheckbox.trailingAnchor, constant: 8),
            agreementLabel.trailingAnchor.constraint(equalTo: agreementContainer.trailingAnchor),
            agreementLabel.topAnchor.constraint(equalTo: agreementContainer.topAnchor),
            agreementLabel.bottomAnchor.constraint(equalTo: agreementContainer.bottomAnchor),
            
            // 复选框相对于协议文本垂直居中
            agreementCheckbox.centerYAnchor.constraint(equalTo: agreementLabel.centerYAnchor)
        ])
        
        // 初始约束：绑定到登录表单
        agreementTopConstraint = agreementContainer.topAnchor.constraint(equalTo: loginFormContainer.bottomAnchor, constant: 20)
        agreementTopConstraint.isActive = true
    }
    
    /// 更新协议文本（根据当前tab）
    private func updateAgreementText() {
        let agreementText: String
        let linkText: String
        
        if currentTab == .login {
            agreementText = "登录即同意《华泰证券账户免责条款、隐私协议》并使用本机号码登录、未注册华泰证券账户的手机号,登录时将自动注册"
            linkText = "《华泰证券账户免责条款、隐私协议》"
        } else {
            agreementText = "我已阅读并同意《用户协议》后可登录"
            linkText = "《用户协议》"
        }
        
        agreementLabel.text = agreementText
        
        // 设置协议文本中的链接颜色和点击区域
        let attributedString = NSMutableAttributedString(string: agreementText)
        let range = (agreementText as NSString).range(of: linkText)
        if range.location != NSNotFound {
            attributedString.addAttribute(.foregroundColor, value: Constants.Color.themeBlue, range: range)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
        agreementLabel.attributedText = attributedString
    }
    
    @objc private func checkboxTapped() {
        agreementCheckbox.isSelected.toggle()
    }
    
    @objc private func agreementLabelTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: agreementLabel)
        let text = agreementLabel.text ?? ""
        let linkText = currentTab == .login ? "《华泰证券账户免责条款、隐私协议》" : "《用户协议》"
        
        guard let attributedText = agreementLabel.attributedText else {
            return
        }
        
        let nsRange = (text as NSString).range(of: linkText)
        guard nsRange.location != NSNotFound else {
            return
        }
        
        // 使用NSLayoutManager检查点击位置
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: agreementLabel.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = agreementLabel.numberOfLines
        textContainer.lineBreakMode = agreementLabel.lineBreakMode
        layoutManager.addTextContainer(textContainer)
        
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if NSLocationInRange(characterIndex, nsRange) {
            // 打开Safari内部浏览器
            openAgreementInSafari()
        }
    }
    
    /// 在Safari内部浏览器中打开协议
    private func openAgreementInSafari() {
        // 这里使用示例URL，实际应该使用真实的协议URL
        let urlString = currentTab == .login 
            ? "https://www.htsc.com.cn/agreement" // 登录协议URL
            : "https://www.htsc.com.cn/user-agreement" // 用户协议URL
        
        guard let url = URL(string: urlString) else {
            Toast.showError("无法打开协议链接")
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = Constants.Color.themeBlue
        present(safariVC, animated: true)
    }
    
    // MARK: - Login Button
    private func setupLoginButton() {
        updateLoginButtonTitle()
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = Constants.Color.themeBlue
        loginButton.layer.cornerRadius = 8
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        contentView.addSubview(loginButton)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loginButton.topAnchor.constraint(equalTo: agreementContainer.bottomAnchor, constant: 30),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            loginButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -60)
        ])
    }
    
    private func updateLoginButtonTitle() {
        loginButton.setTitle(currentTab == .login ? "登录" : "注册", for: .normal)
    }
    
    @objc private func loginButtonTapped() {
        guard agreementCheckbox.isSelected else {
            Toast.show("请先同意协议")
            return
        }
        
        if currentTab == .login {
            // 登录逻辑
            if UserAuthManager.shared.phoneRegister {
                // 手机号登录
                let phone = loginAccountTextField.text ?? ""
                let password = loginPasswordTextField.text ?? ""
                
                guard !phone.isEmpty, !password.isEmpty else {
                    Toast.show("请输入手机号和密码")
                    return
                }
                
                // 模拟登录成功
                UserAuthManager.shared.login(username: phone, phone: phone)
                Toast.showSuccess("登录成功")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.switchToMainApp()
                }
            } else {
                // 用户名登录
                let account = loginAccountTextField.text ?? ""
                let password = loginPasswordTextField.text ?? ""
                
                guard !account.isEmpty, !password.isEmpty else {
                    Toast.show("请输入账号和密码")
                    return
                }
                
                SecureNetworkManager.shared.request(
                    api: "/api/user/login",
                    method: .post,
                    params: [
                        "account": account,
                        "password": password
                    ]
                ) { result in
                    switch result {
                    case .success(let res):
                        print("status =", res.statusCode)
                        print("raw =", res.raw)          // 原始响应
                        print("decrypted =", res.decrypted ?? "无法解密") // 解密后的明文（如果能解）
                        let dict = res.decrypted
                        if res.statusCode != 1 {
                        
                            DispatchQueue.main.async {
                                Toast.showInfo(dict?["msg"] as? String ?? "")
                            }
                            return
                        }
                        let dataDict = (dict?["data"] as? [String: Any] ?? [:]) ["userinfo"] as? [String: Any] ?? [:]
                        
                        // 登录成功
                        UserAuthManager.shared.login(username: dataDict["nickname"] as? String ?? "", phone:  dataDict["username"] as? String ?? "")
                        UserAuthManager.shared.token = dataDict["token"] as? String ?? ""
                        UserAuthManager.shared.userID = String(format: "%@", dataDict["user_id"] as! CVarArg)
                        Toast.showSuccess("登录成功")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.switchToMainApp()
                        }

                    case .failure(let error):
                        print("error =", error.localizedDescription)
                        Toast.showError(error.localizedDescription)
                    }
                }
                

            }
        } else {
            // 注册逻辑
            if UserAuthManager.shared.phoneRegister {
                // 手机号注册
                let phone = registerPhoneTextField.text ?? ""
                let verificationCode = registerVerificationCodeTextField.text ?? ""
                let password = registerPasswordTextField.text ?? ""
                let confirmPassword = registerConfirmPasswordTextField.text ?? ""
                let paymentPassword = registerPaymentPasswordTextField.text ?? ""
                let inviteCode = registerInviteCodeTextField.text ?? ""
                
                guard !phone.isEmpty, !verificationCode.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
                    Toast.show("请填写完整信息")
                    return
                }
                
                guard password == confirmPassword else {
                    Toast.showError("两次密码不一致")
                    return
                }
                
                guard !paymentPassword.isEmpty else {
                    Toast.show("请输入支付密码")
                    return
                }
                
                // 模拟注册成功
                let fullPhone = "\(selectedCountryCode.dialCode)\(phone)"
                UserAuthManager.shared.registerAndLogin(username: fullPhone, phone: fullPhone)
                Toast.showSuccess("注册成功")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.switchToMainApp()
                }
            } else {
                // 用户名注册
                let username = registerUsernameTextField.text ?? ""
                let password = registerPasswordTextField.text ?? ""
                let confirmPassword = registerConfirmPasswordTextField.text ?? ""
                let paymentPassword = registerPaymentPasswordTextField.text ?? ""
                let inviteCode = registerInviteCodeTextField.text ?? ""
                
                guard !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
                    Toast.show("请填写完整信息")
                    return
                }
                
                guard password == confirmPassword else {
                    Toast.showError("两次密码不一致")
                    return
                }
                
                guard !paymentPassword.isEmpty else {
                    Toast.show("请输入支付密码")
                    return
                }
      
                SecureNetworkManager.shared.request(
                    api: "/api/user/register",
                    method: .post,
                    params: [
                        "mobile": username,
                        "password": password,
                        "payment_code":paymentPassword,
                        "institution_number":inviteCode
                    ]
                ) { result in
                    switch result {
                    case .success(let res):
                        print("status =", res.statusCode)
                        print("raw =", res.raw)          // 原始响应
                        print("decrypted =", res.decrypted ?? "无法解密") // 解密后的明文（如果能解）
                        let dict = res.decrypted
                        if res.statusCode != 1 {
                        
                            DispatchQueue.main.async {
                                Toast.showInfo(dict?["msg"] as? String ?? "")
                            }
                            return
                        }

                        let dataDict = (dict?["data"] as? [String: Any] ?? [:]) ["userinfo"] as? [String: Any] ?? [:]
                        
                        UserAuthManager.shared.login(username: dataDict["nickname"] as? String ?? "", phone:  dataDict["username"] as? String ?? "")
                        UserAuthManager.shared.token = dataDict["token"] as? String ?? ""
                        UserAuthManager.shared.userID = String(format: "%@", dataDict["user_id"] as! CVarArg)
                        Toast.showSuccess("注册成功")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.switchToMainApp()
                        }

                    case .failure(let error):
                        print("error =", error.localizedDescription)
                        Toast.showError(error.localizedDescription)
                    }
                }
                
            }
        }
    }
    
    private func switchToMainApp() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        let tabBarController = MainTabBarController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = tabBarController
        }, completion: nil)
    }
}

