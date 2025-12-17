//
//  TZNetworking.swift
//  FBSnapshotTestCase
//
//  Created by Leery TT on 2025/12/16.
//

import UIKit

public class TZNetworking: NSObject {
    static let shared = TZNetworking()
    private init() {}
    
    // MARK: - 通用请求方法（解析基础模型）
    /// - Parameters:
    ///   - api: 遵循BaseAPI的请求实例
    ///   - modelType: 要解析的模型类型（Codable）
    ///   - completion: 回调（Result<模型, 网络错误>）
    /// - Returns: 可取消请求的Cancellable
    @discardableResult
    func request<T: BaseAPI, M: Decodable>(
        api: T,
        modelType: M.Type,
        completion: @escaping (Result<M, TZNetworkError>) -> Void
    ) -> Cancellable? {
        // 检查网络状态
        guard TZNetworkReachability.shared.isReachable else {
            completion(.failure(.noNetwork))
            return nil
        }
        
        let provider = NetworkProvider<T>()
        let cancellable = provider.request(api) { result in
            switch result {
            case .success(let response):
                do {
                    // 验证状态码（200-299）
                    let validatedResponse = try response.filterSuccessfulStatusCodes()
                    // 解析JSON到模型
                    let model = try validatedResponse.decode(to: modelType)
                    completion(.success(model))
                } catch let moyaError as MoyaError {
                    // 处理Moya错误
                    completion(.failure(self.handleMoyaError(moyaError)))
                } catch {
                    // 其他解析错误
                    completion(.failure(.jsonParseFailed(error)))
                }
            case .failure(let moyaError):
                // 请求失败
                completion(.failure(self.handleMoyaError(moyaError)))
            }
        }
        return cancellable
    }
    
    // MARK: - 业务请求方法（适配后端统一返回格式）
    /// 适配后端格式：{code: Int, msg: String, data: T}
    /// - Parameters:
    ///   - api: 遵循BaseAPI的请求实例
    ///   - dataType: 业务数据模型类型
    ///   - completion: 回调（Result<业务数据, 网络错误>）
    @discardableResult
    func requestBusiness<T: BaseAPI, M: Decodable>(
        api: T,
        dataType: M.Type,
        completion: @escaping (Result<M, TZNetworkError>) -> Void
    ) -> Cancellable? {
        // 通用业务响应模型
        struct BusinessResponse<D: Decodable>: Decodable {
            let code: Int
            let msg: String
            let data: D
        }
        
        return request(api: api, modelType: BusinessResponse<M>.self) { result in
            switch result {
            case .success(let resp):
                // 假设code=0为业务成功（根据后端调整）
                if resp.code == 0 {
                    completion(.success(resp.data))
                } else {
                    completion(.failure(.businessError(code: resp.code, msg: resp.msg)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - 文件上传（带进度）
    @discardableResult
    func requestUpload<T: BaseAPI, M: Decodable>(
        api: T,
        modelType: M.Type,
        progress: ((Progress) -> Void)? = nil,
        completion: @escaping (Result<M, TZNetworkError>) -> Void
    ) -> Cancellable? {
        // 1. 检查网络
        guard NetworkReachability.shared.isReachable else {
            completion(.failure(.noNetwork))
            return nil
        }
        
        // 2. 校验上传文件
        if let files = api.uploadFiles, !files.isEmpty {
            for file in files {
                // 空文件校验
                if file.data == nil && file.fileURL == nil {
                    completion(.failure(.fileNotFound(path: "空文件")))
                    return nil
                }
                // 本地文件存在性校验
                if let url = file.fileURL, !FileManager.default.fileExists(atPath: url.path) {
                    completion(.failure(.fileNotFound(path: url.path)))
                    return nil
                }
            }
        }
        
        // 3. 发起上传请求
        let provider = NetworkProvider<T>()
        let cancellable = provider.request(api, progress: { progressValue in
            DispatchQueue.main.async { progress?(progressValue) } // 主线程更新UI
        }) { result in
            switch result {
            case .success(let response):
                do {
                    let validatedResponse = try response.filterSuccessfulStatusCodes()
                    let model = try validatedResponse.decode(to: modelType)
                    completion(.success(model))
                } catch let moyaError as MoyaError {
                    completion(.failure(self.handleMoyaError(moyaError)))
                } catch {
                    completion(.failure(.jsonParseFailed(error)))
                }
            case .failure(let moyaError):
                completion(.failure(self.handleMoyaError(moyaError)))
            }
        }
        return cancellable
    }
    
    // MARK: - 文件下载（带进度+断点续传）
    @discardableResult
    func requestDownload<T: BaseAPI>(
        api: T,
        progress: ((Progress) -> Void)? = nil,
        completion: @escaping (Result<URL, TZNetworkError>) -> Void
    ) -> Cancellable? {
        // 1. 检查网络
        guard NetworkReachability.shared.isReachable else {
            completion(.failure(.noNetwork))
            return nil
        }
        
        // 2. 校验下载配置
        guard api.downloadDestination != nil else {
            let error = NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "下载路径未配置"])
            completion(.failure(.fileWriteFailed(path: "未配置下载路径", error: error)))
            return nil
        }
        
        // 3. 发起下载请求
        let provider = NetworkProvider<T>()
        let cancellable = provider.request(api, progress: { progressValue in
            DispatchQueue.main.async { progress?(progressValue) } // 主线程更新UI
        }) { result in
            switch result {
            case .success(let response):
                do {
                    let validatedResponse = try response.filterSuccessfulStatusCodes()
                    // 获取下载文件路径
                    guard let fileURL = validatedResponse.destinationURL else {
                        completion(.failure(.emptyDownloadFile))
                        return
                    }
                    // 校验文件大小（非空）
                    guard let fileSize = FileUtils.fileSize(for: fileURL), fileSize > 0 else {
                        completion(.failure(.emptyDownloadFile))
                        return
                    }
                    completion(.success(fileURL))
                } catch let moyaError as MoyaError {
                    completion(.failure(self.handleMoyaError(moyaError)))
                } catch {
                    completion(.failure(.fileWriteFailed(path: "下载文件校验失败", error: error)))
                }
            case .failure(let moyaError):
                // 处理断点续传错误
                if case .underlying(let error, _) = moyaError, error.isResumeDataError {
                    completion(.failure(.resumeDataError(error)))
                } else {
                    completion(.failure(self.handleMoyaError(moyaError)))
                }
            }
        }
        return cancellable
    }
    
    // MARK: - 私有方法：处理MoyaError转为NetworkError
    private func handleMoyaError(_ error: MoyaError) -> NetworkError {
        switch error {
        case .statusCode(let resp):
            return .responseCodeError(resp.statusCode)
        case .requestMapping:
            return .invalidURL
        case .jsonMapping, .objectMapping:
            return .jsonParseFailed(error)
        case .parameterEncoding(let underlyingError):
            return .requestFailed(error)
        case .underlying(let underlyingError, _):
            if underlyingError.isNetworkError {
                return .noNetwork
            }
            return .requestFailed(error)
        default:
            return .requestFailed(error)
        }
    }
}

// MARK: - 扩展：Response解析Codable模型
extension Response {
    func decode<T: Decodable>(to type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        // 适配后端日期格式（根据实际情况调整）
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
}
