//
//  CancelOrderViewController.swift
//  zhengqaun
//
//  Created by antigravity on 2026/02/27.
//

import UIKit

class CancelOrderViewController: ZQViewController {

    private let idTextField = UITextField()
    private let submitBtn = UIButton(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 248/255, green: 249/255, blue: 254/255, alpha: 1.0)
        
        gk_navTitle = "撤单"
        gk_navBackgroundColor = .white
        gk_navTintColor = .black
        gk_navTitleColor = UIColor(red: 43/255, green: 44/255, blue: 49/255, alpha: 1.0)
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 15)
        gk_statusBarStyle = .default
        gk_backStyle = .black
        gk_navLineHidden = false

        // Card Container
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 8
        view.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "委托编号"
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0)
        
        idTextField.placeholder = "请输入委托编号"
        idTextField.font = UIFont.systemFont(ofSize: 15)
        idTextField.textColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0)
        idTextField.keyboardType = .numberPad
        idTextField.clearButtonMode = .whileEditing
        
        let divider = UIView()
        divider.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)

        submitBtn.setTitle("撤单", for: .normal)
        submitBtn.setTitleColor(.white, for: .normal)
        submitBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        // 使用 APP 主体红
        submitBtn.backgroundColor = UIColor(red: 0xF4/255, green: 0x43/255, blue: 0x36/255, alpha: 1.0)
        submitBtn.layer.cornerRadius = 24
        submitBtn.addTarget(self, action: #selector(submitAction), for: .touchUpInside)

        card.addSubview(titleLabel)
        card.addSubview(idTextField)
        card.addSubview(divider)
        view.addSubview(submitBtn)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        idTextField.translatesAutoresizingMaskIntoConstraints = false
        divider.translatesAutoresizingMaskIntoConstraints = false
        submitBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: gk_navigationBar.bottomAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            card.heightAnchor.constraint(equalToConstant: 56),

            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 70),

            idTextField.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            idTextField.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            idTextField.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            idTextField.heightAnchor.constraint(equalToConstant: 40),

            divider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            divider.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            submitBtn.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 40),
            submitBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            submitBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            submitBtn.heightAnchor.constraint(equalToConstant: 48)
        ])

        // Tap to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func submitAction() {
        let idStr = idTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if idStr.isEmpty {
            Toast.show("请输入委托编号")
            return
        }
        guard let idVal = Int(idStr), idVal > 0 else {
            Toast.show("请输入有效委托编号")
            return
        }

        submitBtn.isEnabled = false
        dismissKeyboard()

        SecureNetworkManager.shared.request(
            api: "/api/deal/cheAll",
            method: .get,
            params: ["id": idVal]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.submitBtn.isEnabled = true
                switch result {
                case .success(let res):
                    if let dict = res.decrypted,
                       let code = dict["code"] as? Int, code == 1 {
                        Toast.show("撤单成功")
                        self?.navigationController?.popViewController(animated: true)
                    } else {
                        let msg = res.decrypted?["msg"] as? String ?? "撤单失败"
                        Toast.show(msg)
                    }
                case .failure(let err):
                    Toast.show(err.localizedDescription)
                }
            }
        }
    }
}
