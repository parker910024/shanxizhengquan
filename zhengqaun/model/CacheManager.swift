//
//  CacheManager.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import Foundation
import UIKit

/// 缓存管理类
class CacheManager {
    
    static let shared = CacheManager()
    
    private init() {}
    
    /// 计算缓存大小（字节）
    func calculateCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        
        // 1. URLCache缓存大小
        let cache = URLCache.shared
        totalSize += Int64(cache.currentDiskUsage)
        totalSize += Int64(cache.currentMemoryUsage)
        
        // 2. Caches目录大小
        if let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            totalSize += directorySize(at: cachesPath)
        }
        
        // 3. Temporary目录大小
        let tempPath = NSTemporaryDirectory()
        totalSize += directorySize(at: tempPath)
        
        return totalSize
    }
    
    /// 计算目录大小
    private func directorySize(at path: String) -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = FileManager.default.enumerator(atPath: path) else {
            return 0
        }
        
        for file in enumerator {
            let filePath = (path as NSString).appendingPathComponent(file as! String)
            
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory) {
                if !isDirectory.boolValue {
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath),
                       let fileSize = attributes[.size] as? Int64 {
                        totalSize += fileSize
                    }
                }
            }
        }
        
        return totalSize
    }
    
    /// 格式化缓存大小显示
    func formatCacheSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    /// 清理所有缓存
    func clearCache(completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var success = true
            var errorMessage: String?
            
            // 1. 清理URLCache
            URLCache.shared.removeAllCachedResponses()
            
            // 2. 清理Caches目录
            if let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
                if let error = self?.clearDirectory(at: cachesPath) {
                    success = false
                    errorMessage = error
                }
            }
            
            // 3. 清理Temporary目录
            let tempPath = NSTemporaryDirectory()
            if let error = self?.clearDirectory(at: tempPath) {
                success = false
                errorMessage = error
            }
            
            DispatchQueue.main.async {
                if success {
                    completion(true, "缓存清理成功")
                } else {
                    completion(false, errorMessage ?? "缓存清理失败")
                }
            }
        }
    }
    
    /// 清理指定目录
    private func clearDirectory(at path: String) -> String? {
        guard let enumerator = FileManager.default.enumerator(atPath: path) else {
            return nil
        }
        
        var errors: [String] = []
        
        for file in enumerator {
            let filePath = (path as NSString).appendingPathComponent(file as! String)
            
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch {
                errors.append(error.localizedDescription)
            }
        }
        
        return errors.isEmpty ? nil : errors.joined(separator: "; ")
    }
}

