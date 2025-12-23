//
//  TZUserAPI.swift
//  Pods
//
//  Created by Leery TT on 2025/12/17.
//

import UIKit
import Moya

// MARK: - 请求错误状态
public enum TZNetworkError: Error, LocalizedError {
    /// 无效URL
    case invalidURL
    /// 请求失败（Moya底层错误）
    case requestFailed(MoyaError)
    /// 响应状态码错误（非200-299）
    case responseCodeError(Int)
    /// 响应数据为空
    case emptyResponseData
    /// JSON解析失败
    case jsonParseFailed(Error)
    /// 业务错误（后端自定义code/msg）
    case businessError(code: Int, msg: String)
    /// 无网络
    case noNetwork
    /// 文件不存在
    case fileNotFound(path: String)
    /// 文件读取失败
    case fileReadFailed(path: String, error: Error)
    /// 文件写入失败
    case fileWriteFailed(path: String, error: Error)
    /// 上传进度回调异常
    case uploadProgressError(Error)
    /// 下载进度回调异常
    case downloadProgressError(Error)
    /// 下载文件为空
    case emptyDownloadFile
    /// 断点续传信息获取失败
    case resumeDataError(Error)

    
    // 错误描述（适配LocalizedError）
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .requestFailed(let error):
            return "请求失败：\(error.localizedDescription)"
        case .responseCodeError(let code):
            return "服务器响应错误（状态码：\(code)）"
        case .emptyResponseData:
            return "服务器返回数据为空"
        case .jsonParseFailed(let error):
            return "数据解析失败：\(error.localizedDescription)"
        case .businessError(_, let msg):
            return msg
        case .noNetwork:
            return "当前网络不可用，请检查网络设置"
        case .fileNotFound(let path): 
            return "文件不存在：\(path)"
        case .fileReadFailed(let path, let error):
            return "文件读取失败：\(path) | 错误：\(error.localizedDescription)"
        case .fileWriteFailed(let path, let error): 
            return "文件写入失败：\(path) | 错误：\(error.localizedDescription)"
        case .uploadProgressError(let error): 
            return "上传进度回调异常：\(error.localizedDescription)"
        case .downloadProgressError(let error): 
            return "下载进度回调异常：\(error.localizedDescription)"
        case .emptyDownloadFile: 
            return "下载的文件为空"
        case .resumeDataError(let error):
            return "断点续传信息获取失败：\(error.localizedDescription)"
        }
    }
}
// 扩展Error：判断网络/断点续传错误
extension Error {
    /// 是否为网络错误
    var isNetworkError: Bool {
        let code = (self as NSError).code
        return code == NSURLErrorNotConnectedToInternet ||
               code == NSURLErrorTimedOut ||
               code == NSURLErrorNetworkConnectionLost
    }
    
    /// 是否为断点续传错误
    var isResumeDataError: Bool {
        let code = (self as NSError).code
        // 断点续传相关错误码原始值（通用兼容所有版本）
        return code == -3009    // NSURLErrorCannotResumeDownload
        || code == -3010    // NSURLErrorResumeDataCorrupted
    }
}
