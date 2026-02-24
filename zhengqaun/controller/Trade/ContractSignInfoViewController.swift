//
//  ContractSignInfoViewController.swift
//  zhengqaun
//
//  点击签订时弹出的「合同信息」弹框：真实姓名、身份证号、居住地址 + 返回/确认
//

import UIKit

class ContractSignInfoViewController: UIViewController {

    var contract: ContractModel?
    var onConfirm: ((String, String, String) -> Void)?

    private let container = UIView()
    private let titleLabel = UILabel()
    private let nameField = UITextField()
    private let idCardField = UITextField()
    private let addressField = UITextField()
    private let backButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupContainer()
    }

    private func setupContainer() {
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "合同信息"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = Constants.Color.textPrimary
        titleLabel.textAlignment = .center
        container.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        nameField.placeholder = "请输入真实姓名"
        idCardField.placeholder = "请输入身份证号"
        addressField.placeholder = "请输入居住地址"
        idCardField.keyboardType = .numberPad

        backButton.setTitle("返回", for: .normal)
        backButton.setTitleColor(Constants.Color.textSecondary, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        backButton.backgroundColor = Constants.Color.backgroundMain
        backButton.layer.cornerRadius = 8
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        container.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        confirmButton.setTitle("确认", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        confirmButton.backgroundColor = Constants.Color.stockRise
        confirmButton.layer.cornerRadius = 8
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        container.addSubview(confirmButton)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTap))
        view.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false

        let margin: CGFloat = 20
        let rowH: CGFloat = 50
        let rowSpacing: CGFloat = 16
        let nameRow = makeInputRow(label: "真实姓名", textField: nameField)
        let idRow = makeInputRow(label: "身份证号", textField: idCardField)
        let addrRow = makeInputRow(label: "居住地址", textField: addressField)
        container.addSubview(nameRow)
        container.addSubview(idRow)
        container.addSubview(addrRow)
        nameRow.translatesAutoresizingMaskIntoConstraints = false
        idRow.translatesAutoresizingMaskIntoConstraints = false
        addrRow.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: margin),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: margin),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -margin),
            titleLabel.heightAnchor.constraint(equalToConstant: 24),

            nameRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            nameRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: margin),
            nameRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -margin),
            nameRow.heightAnchor.constraint(equalToConstant: rowH),

            idRow.topAnchor.constraint(equalTo: nameRow.bottomAnchor, constant: rowSpacing),
            idRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: margin),
            idRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -margin),
            idRow.heightAnchor.constraint(equalToConstant: rowH),

            addrRow.topAnchor.constraint(equalTo: idRow.bottomAnchor, constant: rowSpacing),
            addrRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: margin),
            addrRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -margin),
            addrRow.heightAnchor.constraint(equalToConstant: rowH),

            backButton.topAnchor.constraint(equalTo: addrRow.bottomAnchor, constant: 24),
            backButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: margin),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.trailingAnchor.constraint(equalTo: container.centerXAnchor, constant: -6),

            confirmButton.topAnchor.constraint(equalTo: addrRow.bottomAnchor, constant: 24),
            confirmButton.leadingAnchor.constraint(equalTo: container.centerXAnchor, constant: 6),
            confirmButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -margin),
            confirmButton.heightAnchor.constraint(equalToConstant: 44),
            confirmButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -margin)
        ])
    }

    private func makeInputRow(label: String, textField: UITextField) -> UIView {
        let row = UIView()
        row.backgroundColor = .white
        row.layer.cornerRadius = 8
        row.layer.borderWidth = 1
        row.layer.borderColor = Constants.Color.separator.cgColor

        let lbl = UILabel()
        lbl.text = label
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.textColor = Constants.Color.textPrimary
        row.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false

        textField.font = UIFont.systemFont(ofSize: 15)
        textField.textColor = Constants.Color.textPrimary
        textField.borderStyle = .none
        row.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            lbl.widthAnchor.constraint(equalToConstant: 80),
            textField.leadingAnchor.constraint(equalTo: lbl.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            textField.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    @objc private func dismissTap(_ g: UITapGestureRecognizer) {
        guard g.state == .ended else { return }
        let loc = g.location(in: view)
        if !container.frame.contains(loc) {
            dismiss(animated: true)
        }
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }

    @objc private func confirmTapped() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let idCard = idCardField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let address = addressField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if name.isEmpty {
            Toast.showInfo("请输入真实姓名")
            return
        }
        if idCard.isEmpty {
            Toast.showInfo("请输入身份证号")
            return
        }
        if address.isEmpty {
            Toast.showInfo("请输入居住地址")
            return
        }
        dismiss(animated: true) { [weak self] in
            self?.onConfirm?(name, idCard, address)
        }
    }
}
