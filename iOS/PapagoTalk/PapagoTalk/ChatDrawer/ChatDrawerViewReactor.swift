//
//  ChatDrawerViewReactor.swift
//  PapagoTalk
//
//  Created by 송민관 on 2020/11/30.
//

import Foundation
import ReactorKit

final class ChatDrawerViewReactor: Reactor {
    
    typealias UserList = [User]
    
    enum Action {
        case fetchUsers
        case chatRoomCodeButtonTapped
        case leaveChatRoomButtonTapped
    }
    
    enum Mutation {
        case setUsers(UserList)
        case copyRoomCode
        case setToastMessage(String)
        case setLeaveChatRoom(Bool)
    }
    
    struct State {
        var users: UserList
        var roomCode: RevisionedData<String>
        var toastMessage: RevisionedData<String>
        var leaveChatRoom: Bool
    }
    
    private let networkService: NetworkServiceProviding
    private let userData: UserDataProviding
    private let roomID: Int
    let initialState: State
    
    init(networkService: NetworkServiceProviding, userData: UserDataProviding, roomID: Int, roomCode: String) {
        self.networkService = networkService
        self.userData = userData
        self.roomID = roomID
        initialState = State(users: UserList(),
                             roomCode: RevisionedData(data: roomCode),
                             toastMessage: RevisionedData(data: ""),
                             leaveChatRoom: false)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetchUsers:
            return requestGetUserList(by: roomID)
        case .chatRoomCodeButtonTapped:
            return .concat ([
                .just(Mutation.copyRoomCode),
                .just(Mutation.setToastMessage(Strings.ChatDrawer.chatCodeDidCopyMessage))
            ])
        case .leaveChatRoomButtonTapped:
            networkService.leaveRoom()
            return .just(Mutation.setLeaveChatRoom(true))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case .setUsers(let users):
            state.users = users
        case .copyRoomCode:
            state.roomCode = state.roomCode.update()
        case .setToastMessage(let toast):
            state.toastMessage = state.toastMessage.update(toast)
        case .setLeaveChatRoom(let leaveChatRoom):
            state.leaveChatRoom = leaveChatRoom
        }
        return state
    }
    
    private func requestGetUserList(by roomID: Int) -> Observable<Mutation> {
        return networkService.getUserList(of: roomID)
            .asObservable()
            .compactMap { $0.roomById?.users }
            .map { [weak self] in
                $0.filter { !$0.isDeleted }
                    .map { User(data: $0, userID: self?.userData.id ?? 0) }
            }
            .map { Mutation.setUsers($0) }
    }
}
