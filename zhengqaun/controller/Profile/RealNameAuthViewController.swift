//
//  RealNameAuthViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import SVProgressHUD
import PhotosUI
import UIKit

class RealNameAuthViewController: ZQViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 信息区
    private let nationalityTextField = UITextField() // 国籍，改为键盘输入
    private let nameTextField = UITextField() // 真实姓名
    private let idTypeLabel = UILabel() // 证件类型，显示「身份证」
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
    
    // 状态记录
    private var currentAuditStatus: String = ""
    private var currentRejectReason: String = ""
    private var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .black
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
    }
    
    // 信息区锚点（用于后续排列）
    private var lastInfoRowBottomAnchor: NSLayoutYAxisAnchor!
    
    // MARK: - 证件信息（国籍 / 真实姓名 / 证件类型 / 身份证号码，表格式+分隔线）

    private func setupCertificateInfo() {
        let rowH: CGFloat = 56
        let sepColor = UIColor(hexString: "E5E5E5") ?? Constants.Color.separator
        let labelColor = UIColor(hexString: "191919") ?? .black
        let hintColor = UIColor(hexString: "999999") ?? .gray
        
        // 国籍
        nationalityTextField.setZqPlaceholder("请输入")
        nationalityTextField.font = UIFont.systemFont(ofSize: 15)
        nationalityTextField.textColor = labelColor
        nationalityTextField.textAlignment = .right
        nationalityTextField.borderStyle = .none
        let _ = addInfoRow(to: contentView, label: "国籍", rightView: nationalityTextField, top: 0, height: rowH, showSeparator: true, sepColor: sepColor)
        
        // 真实姓名
        nameTextField.setZqPlaceholder("请输入真实姓名")
        nameTextField.font = UIFont.systemFont(ofSize: 15)
        nameTextField.textColor = labelColor
        nameTextField.textAlignment = .right
        nameTextField.borderStyle = .none
        let nameRow = addInfoRow(to: contentView, label: "真实姓名", rightView: nameTextField, top: rowH, height: rowH, showSeparator: true, sepColor: sepColor)
        
        // 证件类型
        idTypeLabel.text = "身份证"
        idTypeLabel.font = UIFont.systemFont(ofSize: 15)
        idTypeLabel.textColor = labelColor
        idTypeLabel.textAlignment = .right
        let idTypeRow = addInfoRow(to: contentView, label: "证件类型", rightView: idTypeLabel, top: rowH * 2, height: rowH, showSeparator: true, sepColor: sepColor)
        
        // 身份证号码
        idCardTextField.setZqPlaceholder("请输入身份证号码")
        idCardTextField.font = UIFont.systemFont(ofSize: 15)
        idCardTextField.textColor = labelColor
        idCardTextField.textAlignment = .right
        idCardTextField.borderStyle = .none
        idCardTextField.keyboardType = .asciiCapable
        let idCardRow = addInfoRow(to: contentView, label: "身份证号码", rightView: idCardTextField, top: rowH * 3, height: rowH, showSeparator: true, sepColor: sepColor)
        
        lastInfoRowBottomAnchor = idCardRow.bottomAnchor
    }
    
    private func addInfoRow(to container: UIView, label: String, rightView: UIView, top: CGFloat, height: CGFloat, showSeparator: Bool, sepColor: UIColor) -> UIView {
        let row = UIView()
        row.backgroundColor = .white
        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        
        let leftLabel = UILabel()
        leftLabel.text = label
        leftLabel.font = UIFont.systemFont(ofSize: 15)
        leftLabel.textColor = UIColor(hexString: "191919") ?? .black
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
            leftLabel.widthAnchor.constraint(equalToConstant: 100),
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
            topAnchor: lastInfoRowBottomAnchor,
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
            topConstant: 24
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
        // 整行样式：左文字 + 右图片
        container.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0) // 浅灰色底
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        container.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: container == frontImageContainer ? #selector(frontImageTapped) : #selector(backImageTapped))
        container.addGestureRecognizer(tapGesture)
        contentView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(hexString: "191919") ?? .black
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        label.text = text
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(hexString: "999999") ?? .gray
        label.numberOfLines = 0
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // 右侧上传框
        let uploadBox = UIView()
        uploadBox.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        uploadBox.layer.cornerRadius = 4
        uploadBox.clipsToBounds = true
        container.addSubview(uploadBox)
        uploadBox.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.image = UIImage(named: placeholderImageName)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        uploadBox.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        cameraIcon.image = UIImage(systemName: "camera.fill")
        cameraIcon.tintColor = .lightGray
        cameraIcon.isHidden = false // 默认显示相机图标在中间
        uploadBox.addSubview(cameraIcon)
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: topConstant),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            
            label.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: uploadBox.leadingAnchor, constant: -12),
            
            uploadBox.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            uploadBox.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            uploadBox.widthAnchor.constraint(equalToConstant: 120),
            uploadBox.heightAnchor.constraint(equalToConstant: 80),
            
            imageView.topAnchor.constraint(equalTo: uploadBox.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: uploadBox.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: uploadBox.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: uploadBox.bottomAnchor),
            
            cameraIcon.centerXAnchor.constraint(equalTo: uploadBox.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: uploadBox.centerYAnchor),
            cameraIcon.widthAnchor.constraint(equalToConstant: 32),
            cameraIcon.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    // MARK: - 提交按钮

    private func setupSubmitButton() {
        submitButton.setTitle("确定", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        submitButton.backgroundColor = UIColor(red: 0.9, green: 0.2, blue: 0.15, alpha: 1.0)
        submitButton.layer.cornerRadius = 4
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        contentView.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            submitButton.topAnchor.constraint(equalTo: backImageContainer.bottomAnchor, constant: 48),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            submitButton.heightAnchor.constraint(equalToConstant: 48),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    // MARK: - 注意事项

    // MARK: - API 交互
    
    private func loadData() {
        Task {
            do {
                let result = try await SecureNetworkManager.shared.request(api: Api.authenticationDetail_api, method: .get, params: [:])
                let dict = result.decrypted
                if let data = dict?["data"] as? [String: Any], let detail = data["detail"] as? [String: Any] {
                    DispatchQueue.main.async {
                        self.handleAuthenticationDetail(detail)
                    }
                }
            } catch {
                debugPrint("load authentication detail error =", error)
            }
        }
    }
    
    private func handleAuthenticationDetail(_ detail: [String: Any]) {
        let name = detail["name"] as? String ?? ""
        let idCard = detail["id_card"] as? String ?? ""
        let auditStatus = detail["is_audit"] as? String ?? ""
        let reject = detail["reject"] as? String ?? ""
        
        self.currentAuditStatus = auditStatus
        self.currentRejectReason = reject
        
        // 0=pending (未提交), 1=approved (通过), 2=rejected (驳回), 3=reviewing (正在审核)
        if auditStatus == "1" || auditStatus == "3" || auditStatus == "2" {
            // 跳转至结果页
            let resultVC = RealNameAuthResultViewController()
            resultVC.name = name
            resultVC.idCard = idCard
            if auditStatus == "1" {
                resultVC.authStatus = .approved
            } else if auditStatus == "3" {
                resultVC.authStatus = .pending
            } else {
                resultVC.authStatus = .rejected
                resultVC.rejectReason = reject
            }
            resultVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(resultVC, animated: false)
        }
        
        // 即使跳转了也回填一下，万一用户从结果页点“重新认证”回来可以看到
        nameTextField.text = name
        idCardTextField.text = idCard
    }
    
    // MARK: - Actions

    @objc private func frontImageTapped() {
        showImagePicker(isFront: true)
    }
    
    @objc private func backImageTapped() {
        showImagePicker(isFront: false)
    }
    
    private func showImagePicker(isFront: Bool) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "拍照", style: .default, handler: { _ in
            self.openCamera(isFront: isFront)
        }))
        alert.addAction(UIAlertAction(title: "从相册选择", style: .default, handler: { _ in
            self.openPhotoPicker(isFront: isFront)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func openCamera(isFront: Bool) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            Toast.showError("当前设备不支持相机")
            return
        }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.view.tag = isFront ? 1 : 2
        present(picker, animated: true)
    }
    
    private func openPhotoPicker(isFront: Bool) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        picker.view.tag = isFront ? 1 : 2
        present(picker, animated: true)
    }
    
    @objc private func submitTapped() {
        if isLoading { return }
        
        // 验证输入
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            Toast.showInfo("请输入真实姓名")
            return
        }

        guard let nationality = nationalityTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !nationality.isEmpty else {
            Toast.showInfo("请输入国籍")
            return
        }

        guard let idCard = idCardTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !idCard.isEmpty else {
            Toast.showInfo("请输入身份证号码")
            return
        }
        
        if idCard.count != 15 && idCard.count != 18 {
            Toast.showInfo("请输入正确的身份证号码")
            return
        }

        guard let _ = frontImage else {
            Toast.showInfo("请上传身份证人像面")
            return
        }

        guard let _ = backImage else {
            Toast.showInfo("请上传身份证国徽面")
            return
        }
        
        Task {
            do {
                setLoading(true, text: "上传照片中...")
                if let frontPath = await SecureNetworkManager.shared.upload(image: frontImage!),
                   let backPath = await SecureNetworkManager.shared.upload(image: backImage!)
                {
                    setLoading(true, text: "提交中...")
                    let result = try await SecureNetworkManager.shared.request(api: Api.authentication_api, method: .post, params: ["name": name, "id_card": idCard, "f": frontPath, "b": backPath])
                    let dict = result.decrypted
                    debugPrint(dict ?? "nil")
                    if dict?["code"] as? NSNumber != 1 && dict?["code"] as? String != "1" {
                        DispatchQueue.main.async {
                            Toast.showInfo(dict?["msg"] as? String ?? "")
                            self.setLoading(false)
                        }
                        return
                    }
                    SVProgressHUD.showSuccess(withStatus: "提交成功，等待审核")
                    try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    setLoading(false)
                    
                    // 跳转到结果页面
                    let resultVC = RealNameAuthResultViewController()
                    resultVC.name = name
                    resultVC.idCard = idCard
                    resultVC.authStatus = .pending
                    resultVC.hidesBottomBarWhenPushed = true
                    navigationController?.pushViewController(resultVC, animated: true)
                } else {
                    setLoading(false)
                    Toast.showError("图片上传失败")
                }
            } catch {
                setLoading(false)
                debugPrint("error =", error.localizedDescription)
                Toast.showError("提交失败，请稍后重试")
            }
        }
    }
    
    private func setLoading(_ loading: Bool, text: String = "加载中...") {
        isLoading = loading
        if loading {
            SVProgressHUD.show(withStatus: text)
        } else {
            SVProgressHUD.dismiss()
        }
        submitButton.isEnabled = !loading
        frontImageContainer.isUserInteractionEnabled = !loading
        backImageContainer.isUserInteractionEnabled = !loading
        nationalityTextField.isEnabled = !loading
    }
}

// MARK: - UIImagePickerControllerDelegate

extension RealNameAuthViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
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

// MARK: - PHPickerViewControllerDelegate

extension RealNameAuthViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self = self,
                  let image = object as? UIImage
            else {
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
