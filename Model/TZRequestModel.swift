//
//  TZRequestModel.swift
//  Alamofire
//
//  Created by Leery TT on 2025/12/16.
//

import Foundation
import Moya

struct TZRequestModel:Codable {
    let code:String?
    let data:String?
    let message:String?
    enum CodingKeys:String,CodingKey {
        case code = "code"
        case data = "data"
        case message = "message"
    }
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        code = try values.decode(String.self, forKey: .code)
        data = try values.decode(String.self, forKey: .data)
        message = try values.decode(String.self, forKey: .message)
    }
}

enum NetworkError: Error, LocalizedError {
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
    
    // 错误描述（适配LocalizedError）
    var errorDescription: String? {
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
        }
    }
}
