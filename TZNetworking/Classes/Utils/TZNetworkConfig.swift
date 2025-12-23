//
//  TZBaseAPI.swift
//  Pods
//
//  Created by Leery TT on 2025/12/17.
//

import UIKit
import Alamofire
import Moya

let TOKEN = "token"

// MARK: - 上传文件模型
public struct UploadFile {
    /// 文件数据（Data/URL二选一）
    let data: Data?
    let fileURL: URL?
    /// 表单字段名（后端接收的key）
    let name: String
    /// 文件名（带后缀，如 avatar.png）
    let fileName: String
    /// 文件MIME类型（如 image/png、application/pdf）
    let mimeType: String
    
    // 便捷初始化：Data类型（如图片Data）
    init(data: Data, name: String, fileName: String, mimeType: String) {
        self.data = data
        self.fileURL = nil
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
    // 便捷初始化：本地文件URL
    init(fileURL: URL, name: String, fileName: String? = nil, mimeType: String) {
        self.fileURL = fileURL
        self.data = nil
        self.name = name
        self.fileName = fileName ?? fileURL.lastPathComponent
        self.mimeType = mimeType
    }
}

/// 基础API协议（遵循Moya.TargetType）
public protocol BaseAPI: TargetType {
    /// 基础URL（支持多环境切换）
    var baseURL: URL { get }
    /// 请求路径
    var path: String { get }
    /// 请求方法（GET/POST等）
    var method: Moya.Method { get }
    /// 请求参数
    var parameters: [String: Any]? { get }
    /// 请求头
    var headers: HTTPHeaders? { get }
    /// 请求任务类型（默认JSON参数）
    var task: Task { get }
    /// 上传文件列表（multipart/form-data）
    var uploadFiles: [UploadFile]? { get }
    /// 下载文件保存路径
    var downloadDestination: DownloadDestination? { get }
    /// 断点续传数据
    var resumeData: Data? { get }
}

// MARK: - BaseAPI 默认实现
extension BaseAPI {
    var headers: HTTPHeaders? {
        var headers = HTTPHeaders()
        headers.add(.contentType("application/json"))
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let sysVersion = UIDevice.current.systemVersion
        headers.add(.userAgent("iOS/\(sysVersion) App/\(appVersion)"))
        if let token = UserDefaults.standard.string(forKey: TOKEN) {
            headers.add(.authorization(bearerToken: token))
        }
        return headers
    }
    
    // 新增：默认上传/下载配置
    var uploadFiles: [UploadFile]? { nil }
    var downloadDestination: DownloadDestination? { nil }
    var resumeData: Data? { nil }
    
    var task: Task {
        // 1. 优先处理文件上传
        if let files = uploadFiles, !files.isEmpty {
            let result = files.map { file in
                if let data = file.data {
                    return MultipartFormData(provider: MultipartFormData.FormDataProvider.data(data), name: file.name,fileName: file.fileName,mimeType: file.mimeType)
                }else if let url = file.fileURL {
                    return MultipartFormData(provider: MultipartFormData.FormDataProvider.file(url), name: file.name,fileName: file.fileName,mimeType: file.mimeType)
                }
                return MultipartFormData(provider: MultipartFormData.FormDataProvider.data(Data()), name: file.name,fileName: file.fileName,mimeType: file.mimeType)
            }
            
            return .uploadMultipart(result)
        }
        
        // 2. 处理文件下载
        if let destination = downloadDestination {
            return .downloadDestination(destination) // 普通下载
        }
        
        // 3. 原有JSON参数请求
        guard let params = parameters else { return .requestPlain }
        return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    }
    
    var validationType: ValidationType { .successCodes }
}

// MARK: - 下载路径便捷构造器
/// 默认下载路径：Documents/Downloads
public func defaultDownloadDestination(fileName: String? = nil) -> DownloadDestination {
    return { temporaryURL, response in
        // 创建Downloads目录
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsURL = documentsURL.appendingPathComponent("Downloads")
        try? FileManager.default.createDirectory(at: downloadsURL, withIntermediateDirectories: true)
        
        // 确定文件名
        let finalFileName = fileName ?? response.suggestedFilename ?? UUID().uuidString
        let finalURL = downloadsURL.appendingPathComponent(finalFileName)
        
        // 删除旧文件（避免覆盖）
        if FileManager.default.fileExists(atPath: finalURL.path) {
            try? FileManager.default.removeItem(at: finalURL)
        }
        
        return (finalURL, [.removePreviousFile, .createIntermediateDirectories])
    }
}

// MARK: - Moya Provider 配置
final class NetworkProvider<T: TargetType>: MoyaProvider<T> {
    init(plugins: [PluginType] = [NetworkLoggerPlugin()]) {
        let configuration = URLSessionConfiguration.default
        // 超时时间（30秒）
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        // 复用Alamofire默认请求头
        configuration.httpAdditionalHeaders = HTTPHeaders.default.dictionary
        
        super.init(
            session: Session(configuration: configuration),
            plugins: plugins
        )
    }
}
