//
//  Constants.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

struct Constants {
    
    // MARK: - 屏幕尺寸
    struct Screen {
        static let width = UIScreen.main.bounds.width
        static let height = UIScreen.main.bounds.height
        static let bounds = UIScreen.main.bounds
        static let scale = UIScreen.main.scale
    }
    
    // MARK: - 状态栏和导航栏
    struct Navigation {
        /// 状态栏高度
        static var statusBarHeight: CGFloat {
            if #available(iOS 13.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let statusBarManager = windowScene.statusBarManager {
                    return statusBarManager.statusBarFrame.height
                }
            }
            return UIApplication.shared.statusBarFrame.height
        }
        
        /// 导航栏高度
        static let navigationBarHeight: CGFloat = 44
        
        /// 导航栏总高度（状态栏 + 导航栏）
        static var totalNavigationHeight: CGFloat {
            return statusBarHeight + navigationBarHeight
        }

        /// 与 GKNavigationBarViewController 一致：内容应在此高度之下，避免被自定义导航栏遮挡（刘海屏为 safeAreaTop + 44）
        static var contentTopBelowGKNavBar: CGFloat {
            if safeAreaTop > 20 { return safeAreaTop + navigationBarHeight }
            return statusBarHeight + navigationBarHeight
        }

        /// 安全区域顶部高度
        static var safeAreaTop: CGFloat {
            if #available(iOS 11.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    return window.safeAreaInsets.top
                }
            }
            return statusBarHeight
        }
        
        /// 安全区域底部高度
        static var safeAreaBottom: CGFloat {
            if #available(iOS 11.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    return window.safeAreaInsets.bottom
                }
            }
            return 0
        }
    }
    
    // MARK: - TabBar
    struct TabBar {
        static let height: CGFloat = 49
        static let totalHeight: CGFloat = height + Navigation.safeAreaBottom
    }
    
    // MARK: - 颜色定义（十六进制）
    struct Color {
        // 主色调 - 蓝色
        static let primaryBlue = UIColor(hex: 0x007AFF) // RGB: 0, 122, 255
        static let primaryBlueLight = UIColor(hex: 0x3395FF) // RGB: 51, 149, 255
        static let primaryBlueDark = UIColor(hex: 0x0051D5) // RGB: 0, 81, 213
        
        // 应用主题蓝色（根据UI设计）
        static let themeBlue = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // RGB: 0, 122, 255
        
        // 文字颜色
        static let textPrimary = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // RGB: 51, 51, 51
        static let textSecondary = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0) // RGB: 102, 102, 102
        static let textTertiary = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0) // RGB: 153, 153, 153
        static let textWhite = UIColor.white
        static let textBlack = UIColor.black
        
        // 背景颜色
        static let backgroundMain = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // RGB: 245, 245, 245
        static let backgroundWhite = UIColor.white
        static let backgroundGray = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        static let backgroundDark = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        
        // 分割线颜色
        static let separator = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) // RGB: 230, 230, 230
        static let separatorLight = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        
        // 股票颜色
        static let stockRise = UIColor.systemRed // 上涨红色
        static let stockFall = UIColor.systemGreen // 下跌绿色
        
        // 状态颜色
        static let success = UIColor(hex: 0x34C759) // 绿色
        static let warning = UIColor(hex: 0xFF9500) // 橙色
        static let error = UIColor(hex: 0xFF3B30) // 红色
        static let info = UIColor(hex: 0x007AFF) // 蓝色
        
        // 其他常用颜色
        static let yellow = UIColor(hex: 0xFFCC00)
        static let orange = UIColor(hex: 0xFF9500)
        static let red = UIColor(hex: 0xFF3B30)
        static let green = UIColor(hex: 0x34C759)
        static let blue = UIColor(hex: 0x007AFF)
        static let purple = UIColor(hex: 0xAF52DE)
        static let pink = UIColor(hex: 0xFF2D55)
    }
    
    // MARK: - 字体大小
    struct Font {
        static let size10: CGFloat = 10
        static let size11: CGFloat = 11
        static let size12: CGFloat = 12
        static let size13: CGFloat = 13
        static let size14: CGFloat = 14
        static let size15: CGFloat = 15
        static let size16: CGFloat = 16
        static let size17: CGFloat = 17
        static let size18: CGFloat = 18
        static let size20: CGFloat = 20
        static let size24: CGFloat = 24
        static let size28: CGFloat = 28
        static let size32: CGFloat = 32
        static let size36: CGFloat = 36
        
        // 常用字体
        static func regular(_ size: CGFloat) -> UIFont {
            return UIFont.systemFont(ofSize: size)
        }
        
        static func medium(_ size: CGFloat) -> UIFont {
            return UIFont.systemFont(ofSize: size, weight: .medium)
        }
        
        static func bold(_ size: CGFloat) -> UIFont {
            return UIFont.boldSystemFont(ofSize: size)
        }
        
        static func semibold(_ size: CGFloat) -> UIFont {
            return UIFont.systemFont(ofSize: size, weight: .semibold)
        }
    }
    
    // MARK: - 间距
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        
        // 常用间距
        static let padding4 = xs
        static let padding8 = sm
        static let padding12 = md
        static let padding16 = lg
        static let padding20 = xl
        static let padding24 = xxl
        static let padding32 = xxxl
    }
    
    // MARK: - 圆角
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xlarge: CGFloat = 16
        static let xxlarge: CGFloat = 20
        static let round: CGFloat = 999 // 圆形
        
        // 常用圆角
        static let button: CGFloat = 8
        static let card: CGFloat = 12
        static let banner: CGFloat = 12
        static let searchBar: CGFloat = 20
        static let tab: CGFloat = 16
    }
    
    // MARK: - 高度
    struct Height {
        static let button: CGFloat = 44
        static let buttonSmall: CGFloat = 32
        static let buttonLarge: CGFloat = 50
        
        static let cell: CGFloat = 44
        static let cellSmall: CGFloat = 36
        static let cellLarge: CGFloat = 60
        
        static let searchBar: CGFloat = 40
        static let banner: CGFloat = 140
        static let bannerCity: CGFloat = 110
    }
    
    // MARK: - 动画时长
    struct Animation {
        static let fast: TimeInterval = 0.15
        static let normal: TimeInterval = 0.3
        static let slow: TimeInterval = 0.5
        
        // 常用动画
        static let duration = normal
        static let springDamping: CGFloat = 0.8
        static let springVelocity: CGFloat = 0.5
    }
    
    // MARK: - 网络相关
    struct Network {
        static let timeout: TimeInterval = 30
        static let retryCount = 3
    }
    
    // MARK: - 其他常量
    struct Other {
        // 自动滚动间隔
        static let autoScrollInterval: TimeInterval = 3.0
        
        // 分页大小
        static let pageSize = 20
        
        // 图片压缩质量
        static let imageCompressionQuality: CGFloat = 0.8
    }
}

// MARK: - UIColor 扩展（十六进制颜色支持）
extension UIColor {
    /// 通过十六进制创建颜色
    /// - Parameters:
    ///   - hex: 十六进制颜色值，例如 0xFF0000 表示红色
    ///   - alpha: 透明度，默认1.0
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// 通过十六进制字符串创建颜色
    /// - Parameters:
    ///   - hexString: 十六进制字符串，例如 "#FF0000" 或 "FF0000"
    ///   - alpha: 透明度，默认1.0
    convenience init?(hexString: String, alpha: CGFloat = 1.0) {
        var hex = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if hex.hasPrefix("#") {
            hex.remove(at: hex.startIndex)
        }
        
        guard hex.count == 6 else { return nil }
        
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        
        self.init(hex: UInt32(rgb), alpha: alpha)
    }
    
    /// 转换为十六进制字符串
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}

