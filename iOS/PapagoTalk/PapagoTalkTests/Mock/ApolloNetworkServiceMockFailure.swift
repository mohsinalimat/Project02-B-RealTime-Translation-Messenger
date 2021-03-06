//
//  ApolloNetworkServiceMockFailure.swift
//  PapagoTalkTests
//
//  Created by 송민관 on 2020/12/08.
//

import Foundation
import RxSwift

struct ApolloNetworkServiceMockFailure: NetworkServiceProviding {
    func sendMessage(text: String) -> Maybe<SendMessageMutation.Data> {
        return Maybe.just(.init(createMessage: false))
    }
    
    func getMessage(roomId: Int,
                    language: Language) -> Observable<GetMessageSubscription.Data> {
        return Observable.just(.init(newMessage: .init(id: 1,
                                                       text: "안녕하세요",
                                                       source: "ko",
                                                       createdAt: "2020",
                                                       user: .init(id: 1,
                                                                   nickname: "testUser",
                                                                   avatar: "",
                                                                   lang: "ko"))))
    }
    
    func enterRoom(user: User,
                   code: String) -> Maybe<JoinChatResponse> {
        return Maybe.error(JoinChatError.networkError)
    }
    
    func createRoom(user: User) -> Maybe<CreateRoomResponse> {
        return Maybe.error(JoinChatError.networkError)
    }
    
    func getUserList(of roomID: Int) -> Maybe<FindRoomByIdQuery.Data> {
        return Maybe.just(.init(roomById: .init(code: "545305",
                                                users: [
                                                    .init(id: 1,
                                                          nickname: "test1",
                                                          avatar: "",
                                                          lang: "en"),
                                                    .init(id: 2,
                                                          nickname: "test2",
                                                          avatar: "",
                                                          lang: "ko"),
                                                    .init(id: 3,
                                                          nickname: "test3",
                                                          avatar: "",
                                                          lang: "fr")
                                                ])))
    }
    
    func subscribeLeavedUser(roomID: Int) -> Observable<LeavedUserSubscription.Data> {
        return Observable.error(NetworkError.invalidResponse(message: "error"))
    }
    
    func subscribeNewUser(roomID: Int) -> Observable<NewUserSubscription.Data> {
        return Observable.error(NetworkError.serverError(message: "400"))
    }
    
    func leaveRoom() {
        
    }
    
    func reconnect() {

    }
}
