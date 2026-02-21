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
    
    // 输入框
    private let nameTextField = UITextField()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "实名认证"
        gk_navLineHidden = true
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
    
    // 容器引用
    private var idCardContainer: UIView!
    
    // MARK: - 证件信息
    private func setupCertificateInfo() {
        let sectionLabel = UILabel()
        sectionLabel.text = "证件信息"
        sectionLabel.font = UIFont.systemFont(ofSize: 15)
        sectionLabel.textColor = Constants.Color.textSecondary
        contentView.addSubview(sectionLabel)
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 姓名输入框
        let nameContainer = createTextFieldContainer(label: "姓名", textField: nameTextField, placeholder: "请输入")
        contentView.addSubview(nameContainer)
        nameContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 证件号输入框
        idCardContainer = createTextFieldContainer(label: "证件号", textField: idCardTextField, placeholder: "请输入")
        contentView.addSubview(idCardContainer)
        idCardContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            sectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            nameContainer.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 16),
            nameContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameContainer.heightAnchor.constraint(equalToConstant: 50),
            
            idCardContainer.topAnchor.constraint(equalTo: nameContainer.bottomAnchor, constant: 12),
            idCardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            idCardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            idCardContainer.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createTextFieldContainer(label: String, textField: UITextField, placeholder: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.borderWidth = 1
        container.layer.borderColor = Constants.Color.separator.cgColor
        container.layer.cornerRadius = 8
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 15)
        labelView.textColor = Constants.Color.textPrimary
        container.addSubview(labelView)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 15)
        textField.textColor = Constants.Color.textPrimary
        textField.borderStyle = .none
        container.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            labelView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            labelView.widthAnchor.constraint(equalToConstant: 60),
            
            textField.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    // MARK: - 图片上传
    private func setupImageUpload() {
        // 证件正面上传
        setupImageUploadContainer(
            container: frontImageContainer,
            imageView: frontImageView,
            cameraIcon: frontCameraIcon,
            label: frontLabel,
            text: "请上传证件正面",
            topAnchor: idCardContainer.bottomAnchor,
            topConstant: 30
        )
        
        // 证件反面上传
        setupImageUploadContainer(
            container: backImageContainer,
            imageView: backImageView,
            cameraIcon: backCameraIcon,
            label: backLabel,
            text: "请上传证件反面",
            topAnchor: frontLabel.bottomAnchor,
            topConstant: 20
        )
    }
    
    private func setupImageUploadContainer(
        container: UIView,
        imageView: UIImageView,
        cameraIcon: UIImageView,
        label: UILabel,
        text: String,
        topAnchor: NSLayoutYAxisAnchor,
        topConstant: CGFloat
    ) {
        container.backgroundColor = Constants.Color.backgroundMain
        container.layer.cornerRadius = 12
        container.isUserInteractionEnabled = true
        contentView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: container == frontImageContainer ? #selector(frontImageTapped) : #selector(backImageTapped))
        container.addGestureRecognizer(tapGesture)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .clear
        container.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 相机图标
        cameraIcon.image = UIImage(systemName: "camera.fill")
        cameraIcon.tintColor = .white
        cameraIcon.contentMode = .scaleAspectFit
        cameraIcon.backgroundColor = UIColor(white: 0, alpha: 0.3)
        cameraIcon.layer.cornerRadius = 30
        container.addSubview(cameraIcon)
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // 提示文字
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = Constants.Color.textSecondary
        label.textAlignment = .center
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: topConstant),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.heightAnchor.constraint(equalToConstant: 200),
            
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            cameraIcon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            cameraIcon.widthAnchor.constraint(equalToConstant: 60),
            cameraIcon.heightAnchor.constraint(equalToConstant: 60),
            
            label.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    // MARK: - 提交按钮
    private func setupSubmitButton() {
        submitButton.setTitle("提交", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        submitButton.backgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        submitButton.layer.cornerRadius = 8
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        contentView.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            submitButton.topAnchor.constraint(equalTo: backLabel.bottomAnchor, constant: 20),
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

