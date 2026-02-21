//
//  CountryCodePicker.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

/// 国家代码数据模型
struct CountryCode {
    let name: String
    let code: String
    let dialCode: String
    
    static let defaultCountry = CountryCode(name: "中国", code: "CN", dialCode: "+86")
    
    static let countries: [CountryCode] = [
        CountryCode(name: "中国", code: "CN", dialCode: "+86"),
        CountryCode(name: "美国", code: "US", dialCode: "+1"),
        CountryCode(name: "英国", code: "GB", dialCode: "+44"),
        CountryCode(name: "日本", code: "JP", dialCode: "+81"),
        CountryCode(name: "韩国", code: "KR", dialCode: "+82"),
        CountryCode(name: "新加坡", code: "SG", dialCode: "+65"),
        CountryCode(name: "澳大利亚", code: "AU", dialCode: "+61"),
        CountryCode(name: "加拿大", code: "CA", dialCode: "+1"),
        CountryCode(name: "德国", code: "DE", dialCode: "+49"),
        CountryCode(name: "法国", code: "FR", dialCode: "+33"),
        CountryCode(name: "意大利", code: "IT", dialCode: "+39"),
        CountryCode(name: "西班牙", code: "ES", dialCode: "+34"),
        CountryCode(name: "俄罗斯", code: "RU", dialCode: "+7"),
        CountryCode(name: "印度", code: "IN", dialCode: "+91"),
        CountryCode(name: "巴西", code: "BR", dialCode: "+55"),
        CountryCode(name: "墨西哥", code: "MX", dialCode: "+52"),
        CountryCode(name: "阿根廷", code: "AR", dialCode: "+54"),
        CountryCode(name: "南非", code: "ZA", dialCode: "+27"),
        CountryCode(name: "泰国", code: "TH", dialCode: "+66"),
        CountryCode(name: "马来西亚", code: "MY", dialCode: "+60"),
        CountryCode(name: "印度尼西亚", code: "ID", dialCode: "+62"),
        CountryCode(name: "菲律宾", code: "PH", dialCode: "+63"),
        CountryCode(name: "越南", code: "VN", dialCode: "+84"),
        CountryCode(name: "台湾", code: "TW", dialCode: "+886"),
        CountryCode(name: "香港", code: "HK", dialCode: "+852"),
        CountryCode(name: "澳门", code: "MO", dialCode: "+853")
    ]
}

/// 国家代码选择器
class CountryCodePickerViewController: UIViewController {
    
    var selectedCountry: CountryCode = CountryCode.defaultCountry
    var onCountrySelected: ((CountryCode) -> Void)?
    
    private let tableView = UITableView()
    private let countries = CountryCode.countries
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "选择国家/地区"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension CountryCodePickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let country = countries[indexPath.row]
        cell.textLabel?.text = "\(country.name) \(country.dialCode)"
        
        if country.code == selectedCountry.code {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedCountry = countries[indexPath.row]
        onCountrySelected?(selectedCountry)
        navigationController?.popViewController(animated: true)
    }
}


