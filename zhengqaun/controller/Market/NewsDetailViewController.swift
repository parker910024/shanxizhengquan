//
//  NewsDetailViewController.swift
//  zhengqaun
//
//  新闻详情页面
//

import UIKit

class NewsDetailViewController: ZQViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentTextView = UITextView()
    
    var htmlContent: String? // HTML内容
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupScrollView()
        loadContent()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0)
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "新闻详情"
        gk_navLineHidden = true
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
    }
    
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    private func setupScrollView() {
        let navH = Constants.Navigation.totalNavigationHeight
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(contentTextView)
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        contentTextView.isEditable = false
        contentTextView.isScrollEnabled = false // 禁用内部滚动，使用外部scrollView
        contentTextView.backgroundColor = .clear
        contentTextView.textContainerInset = .zero
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.font = UIFont.systemFont(ofSize: 16)
        contentTextView.textColor = Constants.Color.textPrimary
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            contentTextView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            contentTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func loadContent() {
        guard let html = htmlContent else {
            contentTextView.text = "暂无内容"
            return
        }
        
        // 使用NSAttributedString渲染HTML，保留标签样式
        if let attributedString = htmlToAttributedString(html) {
            contentTextView.attributedText = attributedString
        } else {
            contentTextView.text = "内容加载失败"
        }
    }
    
    /// 将HTML转换为NSAttributedString，保留标签样式
    private func htmlToAttributedString(_ html: String) -> NSAttributedString? {
        // 清理HTML，移除script和style标签
        var cleanHTML = html
        cleanHTML = cleanHTML.replacingOccurrences(of: "<script[^>]*>.*?</script>", with: "", options: [.regularExpression, .caseInsensitive])
        cleanHTML = cleanHTML.replacingOccurrences(of: "<style[^>]*>.*?</style>", with: "", options: [.regularExpression, .caseInsensitive])
        
        // 添加基础CSS样式
        let cssStyle = """
        <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 16px;
            line-height: 1.6;
            color: #1C1C1C;
        }
        p {
            margin: 0 0 12px 0;
        }
        strong {
            font-weight: bold;
        }
        </style>
        """
        
        let htmlWithStyle = cssStyle + cleanHTML
        
        // 使用NSAttributedString的HTML初始化方法
        guard let data = htmlWithStyle.data(using: .utf8) else {
            return nil
        }
        
        do {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            let attributedString = try NSAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            )
            
            // 创建可变属性字符串，以便进一步自定义样式
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
            
            // 设置段落样式
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            paragraphStyle.paragraphSpacing = 8
            
            mutableAttributedString.addAttribute(
                .paragraphStyle,
                value: paragraphStyle,
                range: NSRange(location: 0, length: mutableAttributedString.length)
            )
            
            return mutableAttributedString
        } catch {
            print("HTML解析错误: \(error)")
            return nil
        }
    }
}
