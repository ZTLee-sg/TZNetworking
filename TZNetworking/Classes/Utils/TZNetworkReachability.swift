//
//  NetworkReachability.swift
//  Pods
//
//  Created by Leery TT on 2025/12/17.
//

import UIKit

final class TZNetworkReachability: NSObject {
    /// 单例
    static let shared = TZNetworkReachability()
    /// 网络监听管理器
    private let reachability = NetworkReachabilityManager()
    /// 是否有网络
    var isReachable: Bool { reachability?.isReachable ?? false }
    
    private init() {
        // 启动监听
        reachability?.startListening(onQueue: .global(), onUpdatePerforming: { status in
            switch status {
            case .reachable(.ethernetOrWiFi), .reachable(.cellular):
                print("📶 网络已连接")
            case .notReachable:
                print("📶 网络已断开")
            case .unknown:
                print("📶 网络状态未知")
            }
        })
    }
    
    deinit {
        reachability?.stopListening()
    }
}
