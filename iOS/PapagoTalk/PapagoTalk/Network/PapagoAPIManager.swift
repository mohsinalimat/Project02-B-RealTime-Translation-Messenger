//
//  PapagoAPIManager.swift
//  PapagoTalk
//
//  Created by Byoung-Hwi Yoon on 2020/12/03.
//

import Foundation

final class PapagoAPIManager {
   
    private let service: URLSessionNetworkServiceProviding
    
    init(service: URLSessionNetworkServiceProviding = URLSessionNetworkService()) {
        self.service = service
    }
    
    func requestTranslation(request: TranslationRequest,
                            completionHandler: @escaping ((String?) -> Void)) {
        let body = request.encoded()
        let apiRequest = PapagoAPIRequest(body: body)
        
        service.request(request: apiRequest) { result in
            switch result {
            case .success(let data):
                guard let data: TranslationResponse = try? data.decoded() else {
                    completionHandler(nil)
                    return
                }
                completionHandler(data.message.result.translatedText)
            case .failure:
                completionHandler(nil)
            }
        }
    }
}

struct PapagoAPIRequest: HTTPRequest {
    var url: URL = APIEndPoint.naverPapagoOpenAPI
    var httpMethod: HTTPMethod = .post
    var headers: [String: String] = [
        "Content-Type": "Application/json",
        "X-Naver-Client-Id": APIEndPoint.naverPapagoOpenAPIclientID,
        "X-Naver-Client-Secret": APIEndPoint.naverPapagoOpenAPIclientSecret
    ]
    var body: Data?
    
    init(body: Data?) {
        self.body = body
    }
}
