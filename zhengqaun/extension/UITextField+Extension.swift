import UIKit

extension UITextField {
    /// 设置统一样式的占位符，解决在白色背景下深色模式 placeholder 颜色过浅的问题
    func setZqPlaceholder(_ text: String?, color: UIColor? = nil) {
        guard let text = text else {
            self.attributedPlaceholder = nil
            return
        }
        
        // 默认使用 Constants.Color.textTertiary (#999999)
        let placeholderColor = color ?? Constants.Color.textTertiary
        
        self.attributedPlaceholder = NSAttributedString(
            string: text,
            attributes: [.foregroundColor: placeholderColor]
        )
    }
}
