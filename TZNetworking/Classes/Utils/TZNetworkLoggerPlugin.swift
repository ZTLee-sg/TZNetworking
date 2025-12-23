//
//  TZNetworkLoggerPlugin.swift
//  Pods
//
//  Created by Leery TT on 2025/12/17.
//

import UIKit
import Alamofire
import Moya

final class NetworkLoggerPlugin: PluginType {
    /// 请求发送前
    func willSend(_ request: RequestType, target: BaseAPI) {
        let url = target.baseURL.absoluteString + target.path
        print("\n📡 开始请求：\(target.method.rawValue.uppercased()) \(url)")
        // 打印请求参数
        if let params = target.parameters {
            print("🔑 请求参数：\(params)")
        }
        // 打印请求头
        if let headers = target.headers {
            print("📄 请求头：\(headers)")
        }
        // 打印上传文件信息
        let baseAPI = target
        if let files = baseAPI.uploadFiles, !files.isEmpty {
            print("📤 上传文件列表：")
            for (index, file) in files.enumerated() {
                var fileInfo = "  第\(index+1)个文件：name=\(file.name) | fileName=\(file.fileName) | mimeType=\(file.mimeType)"
                if let data = file.data {
                    fileInfo += " | 大小：\(TZFileUtils.formattedFileSize(for: Int64(data.count)))"
                } else if let url = file.fileURL {
                    fileInfo += " | 路径：\(url.path)"
                    if let size = TZFileUtils.fileSize(for: url) {
                        fileInfo += " | 大小：\(TZFileUtils.formattedFileSize(for: size))"
                    }
                }
                print(fileInfo)
            }
        }
        
        // 打印下载配置
        if baseAPI.downloadDestination != nil {
            print("📥 下载配置：断点续传=\(baseAPI.resumeData != nil)")
        }
    }
    /// 进度回调（上传/下载）
    func didReceive(_ progress: Progress, target: TargetType) {
        let url = target.baseURL.absoluteString + target.path
        let progressStr = String(format: "%.2f%%", progress.fractionCompleted * 100)
        let baseAPI = target as! BaseAPI
        if baseAPI.uploadFiles != nil {
            print("📤 上传进度：\(url) | \(progressStr)")
        } else if baseAPI.downloadDestination != nil {
            print("📥 下载进度：\(url) | \(progressStr)")
        }
    }
    /// 收到响应后
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        let url = target.baseURL.absoluteString + target.path
        switch result {
        case .success(let response):
            print("✅ 请求成功：\(url) | 状态码：\(response.statusCode)")
            
            // 打印下载文件信息
            if let fileURL = response.request?.url {
                print("📥 下载文件路径：\(fileURL.path)")
                if let size = TZFileUtils.fileSize(for: fileURL) {
                    print("📥 下载文件大小：\(TZFileUtils.formattedFileSize(for: size))")
                }
            } else {
                // 打印普通响应数据
                if let json = try? response.mapJSON() {
                    print("📤 响应数据：\(json)")
                }
            }
        case .failure(let error):
            print("❌ 请求失败：\(url) | 错误：\(error.localizedDescription)")
        }
        print("----------------------------------------\n")
    }
}
// MARK: - Response扩展：获取下载文件路径
extension Response {
    var destinationURL: URL? {
        return response?.url
//        switch task {
//        case .downloadDestination:
//            return self.destinationURL
//        default:
//            return nil
//        }
    }
}
