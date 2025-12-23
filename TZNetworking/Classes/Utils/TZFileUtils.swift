//
//  TZFileUtils.swift
//  Pods
//
//  Created by Leery TT on 2025/12/17.
//

import UIKit
import MobileCoreServices

public class TZFileUtils {
    /// 获取文件MIME类型
    static func mimeType(for fileURL: URL) -> String {
        let pathExtension = fileURL.pathExtension
        guard let uti = UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension,
            pathExtension as CFString,
            nil
        )?.takeRetainedValue() else {
            return "application/octet-stream"
        }
        
        guard let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() else {
            return "application/octet-stream"
        }
        return mimeType as String
    }
    
    /// 获取文件大小（字节）
    static func fileSize(for fileURL: URL) -> Int64? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try! FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64
    }
    
    /// 格式化文件大小（如 1.2MB、500KB）
    static func formattedFileSize(for bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// 删除文件
    static func deleteFile(at fileURL: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return true }
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            print("删除文件失败：\(error.localizedDescription)")
            return false
        }
    }
}
