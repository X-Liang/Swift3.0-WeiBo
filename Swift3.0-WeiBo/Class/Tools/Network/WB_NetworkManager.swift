//
//  WB_NetworkManager.swift
//  Swift3.0-WeiBo
//
//  Created by X-Liang on 2016/10/28.
//  Copyright © 2016年 X-Liang. All rights reserved.
//

import UIKit
import AFNetworking

/// Swift枚举支持任意数据类型
enum WB_HTTPMethod {
    case GET
    case POST
}

/// 网络管理工具
class WB_NetworkManager: AFHTTPSessionManager {
    // 单例：1. 静态 2. 常量 3. 闭包
    // 在第一次访问时， 执行闭包， 并将结果存储在sharedManager静态常量中
    static let sharedManager: WB_NetworkManager = {
        // 实例化对象
        let instance = WB_NetworkManager()
        // 设置响应的反序列化支持的数据类型
        instance.responseSerializer.acceptableContentTypes?.insert("text/plain")
        return instance
    }()
    
    /// 访问令牌，所有的网络请求都基于此令牌
//    var accessToken: String? // = "2.00yyFj9D3UqMzDfca7866a25aFyA8D"
    
    /// 用户账户的懒加载属性
    lazy var userAccount = WB_UserAccount()
    
    var userLogon: Bool {
        return userAccount.access_token != nil
    }
    
    /// 专门用来拼接token的网络请求
    func tokenRequest(method: WB_HTTPMethod = .GET, URLString: String,
                     paramaters: [String: Any]?, complation: @escaping (Any?, Bool) -> (Void)) {
        // 处理token, 程序执行过程中一般token不会为nil
        guard let token = userAccount.access_token else {
            // FIXME: 发送通知，提示用户登录
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: WB_UserShouldLoginNotification),
                                            object: nil)
            complation(nil, false)
            return
        }
        
        // 默认参数是不可变的， 这几赋值到一个局部变量进行修改
        var paramaters = paramaters
        if paramaters == nil {
            paramaters = [String: Any]()
        }
        // 此时parameters一定有值
        paramaters!["access_token"] = token
        
        // 调用request发起网络请求
        request(method: method, URLString: URLString, paramaters: paramaters, complation: complation)
    }
    
    /// 使用一个函数封装AFN的GET/POST 请求
    func request(method: WB_HTTPMethod = .GET, URLString: String,
                 paramaters: [String: Any]?, complation: @escaping (Any?, Bool) -> (Void)) {
        let success = { (task: URLSessionTask, json: Any?) -> () in
            complation(json, true)
        }
        
        let failure = { (task: URLSessionTask?, error: Error) -> () in
            // 针对403，处理用户token过期
            if (task?.response as? HTTPURLResponse)?.statusCode == 403 {
                print("token out time")
                
                // 发送通知，提示用户登录
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: WB_UserShouldLoginNotification),
                                                object: "Bad Token")
            }
            // error不需要传递到外部
            complation(nil, false)
        }
        
        if method == .GET {
            get(URLString, parameters: paramaters, progress: nil, success: success, failure: failure)
        } else {
            post(URLString, parameters: paramaters, progress: nil, success: success, failure: failure)
        }
    }
}
