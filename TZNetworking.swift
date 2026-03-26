import Foundation
import Moya

public class TZNetworking {
    public static let shared = TZNetworking()
    
    private var providers: [String: MoyaProvider<MultiTarget>] = [:]
    
    private init() {}
    
    private func getProvider(for baseURL: String) -> MoyaProvider<MultiTarget> {
        if let provider = providers[baseURL] {
            return provider
        }
        
        let provider = MoyaProvider<MultiTarget>(plugins: [])
        providers[baseURL] = provider
        return provider
    }
    
    public func request<T: TargetType>(_ target: T, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        let provider = getProvider(for: target.baseURL.absoluteString)
        provider.request(MultiTarget(target), completion: completion)
    }
    
    public func uploadFile<T: TargetType>(_ target: T, fileURL: URL, name: String, fileName: String, mimeType: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        let provider = getProvider(for: target.baseURL.absoluteString)
        provider.upload(MultiTarget(target)) {progress in
            // 可以在这里处理上传进度
        } fileURL: {
            return fileURL
        } completion: {result in
            completion(result)
        }
    }
    
    public func uploadMultipleFiles<T: TargetType>(_ target: T, files: [(url: URL, name: String, fileName: String, mimeType: String)], completion: @escaping (Result<Response, MoyaError>) -> Void) {
        let provider = getProvider(for: target.baseURL.absoluteString)
        
        provider.upload(MultiTarget(target)) {progress in
            // 可以在这里处理上传进度
        } multipartFormData: {multipartFormData in
            for file in files {
                multipartFormData.append(file.url, withName: file.name, fileName: file.fileName, mimeType: file.mimeType)
            }
        } completion: {result in
            completion(result)
        }
    }
}

public extension TZNetworking {
    func request<T: Decodable>(_ target: some TargetType, as type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        request(target) { result in
            switch result {
            case .success(let response):
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: response.data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}