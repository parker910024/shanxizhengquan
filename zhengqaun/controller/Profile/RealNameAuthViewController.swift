//
//  RealNameAuthViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit
import PhotosUI

class RealNameAuthViewController: ZQViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 信息区
    private let nationalityLabel = UILabel()  // 国籍，点击选择
    private let nameTextField = UITextField() // 真实姓名
    private let idTypeLabel = UILabel()       // 证件类型，显示「身份证」
    private let idCardTextField = UITextField()
    
    // 图片上传
    private let frontImageContainer = UIView()
    private let frontImageView = UIImageView()
    private let frontCameraIcon = UIImageView()
    private let frontLabel = UILabel()
    
    private let backImageContainer = UIView()
    private let backImageView = UIImageView()
    private let backCameraIcon = UIImageView()
    private let backLabel = UILabel()
    
    // 按钮
    private let submitButton = UIButton(type: .system)
    
    // 注意事项
    private let noticeLabel = UILabel()
    
    // 选中的图片
    private var frontImage: UIImage?
    private var backImage: UIImage?
    
    // 选中国籍
    private var selectedCountry: CountryCode = .defaultCountry
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "实名认证"
        gk_navLineHidden = true
        gk_backStyle = .black
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupCertificateInfo()
        setupImageUpload()
        setupSubmitButton()
        setupNotice()
    }
    
    // 信息区容器（用于约束）
    private var infoSectionContainer: UIView!
    
    // MARK: - 证件信息（国籍 / 真实姓名 / 证件类型 / 身份证号码，表格式+分隔线）
    private func setupCertificateInfo() {
        let card = UIView()
        card.backgroundColor = .white
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let rowH: CGFloat = 50
        let margin: CGFloat = 16
        let sepColor = Constants.Color.separator
        
        // 国籍
        nationalityLabel.text = selectedCountry.name
        nationalityLabel.font = UIFont.systemFont(ofSize: 15)
        nationalityLabel.textColor = Constants.Color.textPrimary
        let nationalityRow = addInfoRow(to: card, label: "国籍", rightView: nationalityLabel, top: 0, height: rowH, showSeparator: true, sepColor: sepColor)
        nationalityLabel.text = "请输入"
        nationalityLabel.textColor = Constants.Color.textTertiary
        let nationalityTap = UITapGestureRecognizer(target: self, action: #selector(showCountryPicker))
        nationalityRow.addGestureRecognizer(nationalityTap)
        nationalityRow.isUserInteractionEnabled = true
        
        // 真实姓名
        nameTextField.placeholder = "请输入真实姓名"
        nameTextField.font = UIFont.systemFont(ofSize: 15)
        nameTextField.textColor = Constants.Color.textPrimary
        nameTextField.borderStyle = .none
        let nameRow = addInfoRow(to: card, label: "真实姓名", rightView: nameTextField, top: rowH, height: rowH, showSeparator: true, sepColor: sepColor)
        
        // 证件类型
        idTypeLabel.text = "身份证"
        idTypeLabel.font = UIFont.systemFont(ofSize: 15)
        idTypeLabel.textColor = Constants.Color.textPrimary
        let idTypeRow = addInfoRow(to: card, label: "证件类型", rightView: idTypeLabel, top: rowH * 2, height: rowH, showSeparator: true, sepColor: sepColor)
        
        // 身份证号码
        idCardTextField.placeholder = "请输入身份证号码"
        idCardTextField.font = UIFont.systemFont(ofSize: 15)
        idCardTextField.textColor = Constants.Color.textPrimary
        idCardTextField.borderStyle = .none
        idCardTextField.keyboardType = .numberPad
        let _ = addInfoRow(to: card, label: "身份证号码", rightView: idCardTextField, top: rowH * 3, height: rowH, showSeparator: false, sepColor: sepColor)
        
        infoSectionContainer = card
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            card.heightAnchor.constraint(equalToConstant: rowH * 4)
        ])
    }
    
    private func addInfoRow(to container: UIView, label: String, rightView: UIView, top: CGFloat, height: CGFloat, showSeparator: Bool, sepColor: UIColor) -> UIView {
        let row = UIView()
        row.backgroundColor = .white
        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        
        let leftLabel = UILabel()
        leftLabel.text = label
        leftLabel.font = UIFont.systemFont(ofSize: 15)
        leftLabel.textColor = Constants.Color.textPrimary
        row.addSubview(leftLabel)
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        
        row.addSubview(rightView)
        rightView.translatesAutoresizingMaskIntoConstraints = false
        
        var constraints: [NSLayoutConstraint] = [
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: top),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.heightAnchor.constraint(equalToConstant: height),
            leftLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            leftLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            leftLabel.widthAnchor.constraint(equalToConstant: 80),
            rightView.leadingAnchor.constraint(equalTo: leftLabel.trailingAnchor, constant: 12),
            rightView.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            rightView.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ]
        
        if showSeparator {
            let sep = UIView()
            sep.backgroundColor = sepColor
            row.addSubview(sep)
            sep.translatesAutoresizingMaskIntoConstraints = false
            constraints += [
                sep.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
                sep.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
                sep.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                sep.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
            ]
        }
        
        NSLayoutConstraint.activate(constraints)
        return row
    }
    
    @objc private func showCountryPicker() {
        let picker = CountryCodePickerViewController()
        picker.selectedCountry = selectedCountry
        picker.onCountrySelected = { [weak self] country in
            self?.selectedCountry = country
            self?.nationalityLabel.text = country.name
            self?.nationalityLabel.textColor = Constants.Color.textPrimary
            self?.presentedViewController?.dismiss(animated: true)
        }
        let nav = UINavigationController(rootViewController: picker)
        present(nav, animated: true)
    }
    
    // MARK: - 图片上传
    private func setupImageUpload() {
        // 证件正面上传（头像面）：左右结构，右侧图片 touxiangmian
        setupImageUploadContainer(
            container: frontImageContainer,
            imageView: frontImageView,
            cameraIcon: frontCameraIcon,
            label: frontLabel,
            title: "头像面",
            text: "上传身份证头像面",
            placeholderImageName: "touxiangmian",
            topAnchor: infoSectionContainer.bottomAnchor,
            topConstant: 24
        )
        
        // 证件反面上传（国徽面）：左右结构，右侧图片 guohuimian
        setupImageUploadContainer(
            container: backImageContainer,
            imageView: backImageView,
            cameraIcon: backCameraIcon,
            label: backLabel,
            title: "国徽面",
            text: "上传身份证国徽面",
            placeholderImageName: "guohuimian",
            topAnchor: frontImageContainer.bottomAnchor,
            topConstant: 16
        )
    }
    
    private func setupImageUploadContainer(
        container: UIView,
        imageView: UIImageView,
        cameraIcon: UIImageView,
        label: UILabel,
        title: String,
        text: String,
        placeholderImageName: String,
        topAnchor: NSLayoutYAxisAnchor,
        topConstant: CGFloat
    ) {
        // 整行卡片：左文字 + 右图片，圆角浅灰底
        container.backgroundColor = Constants.Color.backgroundMain
        container.layer.cornerRadius = 12
        container.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: container == frontImageContainer ? #selector(frontImageTapped) : #selector(backImageTapped))
        container.addGestureRecognizer(tapGesture)
        contentView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // 左侧：标题 + 说明
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = Constants.Color.textPrimary
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        label.text = text
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = Constants.Color.textSecondary
        label.numberOfLines = 2
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // 右侧：占位图（touxiangmian / guohuimian），点击可上传替换
        imageView.image = UIImage(named: placeholderImageName)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .clear
        container.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        cameraIcon.isHidden = true
        container.addSubview(cameraIcon)
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let rightImageW: CGFloat = 120
        let rightImageH: CGFloat = 90
        let padding: CGFloat = 16
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: topConstant),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.heightAnchor.constraint(equalToConstant: rightImageH + padding * 2),
            
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            titleLabel.heightAnchor.constraint(equalToConstant: 20),
            
            label.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            label.trailingAnchor.constraint(lessThanOrEqualTo: imageView.leadingAnchor, constant: -12),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 18),
            
            imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding),
            imageView.widthAnchor.constraint(equalToConstant: rightImageW),
            imageView.heightAnchor.constraint(equalToConstant: rightImageH)
        ])
    }
    
    // MARK: - 提交按钮
    private func setupSubmitButton() {
        submitButton.setTitle("确定", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        submitButton.backgroundColor = Constants.Color.stockRise
        submitButton.layer.cornerRadius = 8
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        contentView.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            submitButton.topAnchor.constraint(equalTo: backImageContainer.bottomAnchor, constant: 24),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - 注意事项
    private func setupNotice() {
        noticeLabel.text = "注意事项:\n务必使用真实的本人姓名、身份证号码信息进行填写。系统会校验信息的真实性,如果信息有误将直接会影响到山西证券为您提供的服务的正常使用。"
        noticeLabel.font = UIFont.systemFont(ofSize: 12)
        noticeLabel.textColor = Constants.Color.stockRise // 红色
        noticeLabel.numberOfLines = 0
        contentView.addSubview(noticeLabel)
        noticeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            noticeLabel.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 20),
            noticeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            noticeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            noticeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    @objc private func frontImageTapped() {
        showImagePicker(isFront: true)
    }
    
    @objc private func backImageTapped() {
        showImagePicker(isFront: false)
    }
    
    private func showImagePicker(isFront: Bool) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        
        // 使用tag来区分正反面
        picker.view.tag = isFront ? 1 : 2
        
        present(picker, animated: true)
    }
    
    @objc private func submitTapped() {
        // 验证输入
//        guard let name = nameTextField.text, !name.isEmpty else {
//            Toast.showInfo("请输入姓名")
//            return
//        }
//        
//        guard let idCard = idCardTextField.text, !idCard.isEmpty else {
//            Toast.showInfo("请输入证件号")
//            return
//        }
//        
//        guard frontImage != nil else {
//            Toast.showInfo("请上传证件正面")
//            return
//        }
//        
//        guard backImage != nil else {
//            Toast.showInfo("请上传证件反面")
//            return
//        }
        
        // 跳转到结果页面（等待审核状态）
        let resultVC = RealNameAuthResultViewController()
        resultVC.name = "222"
        resultVC.idCard = "22222222"
        resultVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(resultVC, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension RealNameAuthViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self = self,
                  let image = object as? UIImage else {
                return
            }
            
            DispatchQueue.main.async {
                let isFront = picker.view.tag == 1
                
                if isFront {
                    self.frontImage = image
                    self.frontImageView.image = image
                    self.frontCameraIcon.isHidden = true
                } else {
                    self.backImage = image
                    self.backImageView.image = image
                    self.backCameraIcon.isHidden = true
                }
            }
        }
    }
}

