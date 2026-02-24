//
//  MessageDetailViewController.swift
//  zhengqaun
//
//  消息详情：导航栏「消息详情」+ 居中标题 + 正文左对齐 + 时间右对齐
//

import UIKit

class MessageDetailViewController: ZQViewController {

    /// 传入的消息，用于展示
    var message: Message?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let mainTitleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let timeLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        
        mainTitleLabel.text = message?.content
        timeLabel.text = "时间:" + (message?.date ?? "")
        
        loadDetailData()
    }

    private func setupNavigationBar() {
        gk_navTitle = "消息详情"
        gk_navBackgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        gk_navTintColor = .black
        gk_navTitleColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_statusBarStyle = .default
        gk_navLineHidden = false
        gk_backStyle = .black
    }

    private func setupUI() {
        view.backgroundColor = .white

        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        mainTitleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        mainTitleLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        mainTitleLabel.textAlignment = .center
        mainTitleLabel.numberOfLines = 0
        mainTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainTitleLabel)

        bodyLabel.font = UIFont.systemFont(ofSize: 16)
        bodyLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        bodyLabel.textAlignment = .left
        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bodyLabel)

        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
        timeLabel.textAlignment = .right
        timeLabel.numberOfLines = 1
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)

        let pad: CGFloat = 20
        let mainTop: CGFloat = 24
        let mainToBody: CGFloat = 20
        let bodyToTime: CGFloat = 24
        let bottomPad: CGFloat = 24

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 80),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            mainTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: mainTop),
            mainTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            mainTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),

            bodyLabel.topAnchor.constraint(equalTo: mainTitleLabel.bottomAnchor, constant: mainToBody),
            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),

            timeLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: bodyToTime),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -bottomPad)
        ])
    }

    private func loadDetailData() {
        guard let msgId = message?.id else {
            bodyLabel.text = "暂无内容"
            return
        }
        
        let params = ["id": msgId]
        
        SecureNetworkManager.shared.request(api: Api.message_detail_api, method: .get, params: params) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                if response.statusCode == 200,
                   let dec = response.decrypted,
                   let code = dec["code"] as? Int, code == 1,
                   let dataObj = dec["data"] as? [String: Any],
                   let htmlString = dataObj["detail"] as? String {
                    
                    self.setHTMLContent(htmlString)
                } else {
                    self.bodyLabel.text = "获取详情失败"
                }
            case .failure(let error):
                self.bodyLabel.text = "加载失败: \(error.localizedDescription)"
            }
        }
    }
    
    private func setHTMLContent(_ htmlString: String) {
        guard let data = htmlString.data(using: .utf8) else {
            bodyLabel.text = htmlString
            return
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                // 修改字体和颜色统一适配 UI
                let mutableAttrStr = NSMutableAttributedString(attributedString: attributedString)
                let fullRange = NSRange(location: 0, length: mutableAttrStr.length)
                mutableAttrStr.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: fullRange)
                mutableAttrStr.addAttribute(.foregroundColor, value: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0), range: fullRange)
                
                DispatchQueue.main.async {
                    self.bodyLabel.attributedText = mutableAttrStr
                }
            } else {
                DispatchQueue.main.async {
                    self.bodyLabel.text = htmlString.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                }
            }
        }
    }
}
