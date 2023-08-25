//
//  ProfileTabFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation
import ComposableArchitecture

public struct ProfileTabFeature: ReducerProtocol {
  public struct State: Equatable {
    var user: User?
    var alert: Alert?
    var connectedEmails: IdentifiedArrayOf<String> = []
    
    @PresentationState var loginScreen: LoginFeature.State?
    @PresentationState var shareFridge: ShareFridgeFeature.State?
  }
  
  public enum Action: Equatable {
    case onAppear
    case didTapLogIn
    case didTapLogOut
    case didTapRegister
    case didTapDeleteAllData
    case didTapConnectFridge
    case didTapRemoveConnection
    case loginScreen(PresentationAction<LoginFeature.Action>)
    case shareFridge(PresentationAction<ShareFridgeFeature.Action>)
    case alert(AlertAction)
    case dependency(DependencyAction)
    
    public enum AlertAction: Equatable {
      case didDismiss
      case didConfirmDeletionOfAllData
    }
    
    public enum DependencyAction: Equatable {
      case handleDeletionOfAllData(Result<Bool, DBClient.DBError>)
      case handleRemovingConnection(Result<Bool, FridgeSharingClient.FridgeSharingError>)
      case handleFetchingConnectedEmails(Result<[String], FridgeSharingClient.FridgeSharingError>)
    }
  }
  
  @Dependency(\.databaseClient) var dbClient
  @Dependency(\.userInfoClient) var userInfoClient
  @Dependency(\.fridgeSharingClient) var sharingClient
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.user = self.userInfoClient.getUserInfo()
        return .run { send in
          let result = await self.sharingClient.getConnectedEmails()
          await send(.dependency(.handleFetchingConnectedEmails(result)))
        }
        
      case .didTapLogIn:
        state.loginScreen = .init(mode: .login)
        return .none
        
      case .didTapLogOut:
        self.userInfoClient.logoutUser()
        state.user = self.userInfoClient.getUserInfo()
        return .none
        
      case .didTapRegister:
        state.loginScreen = .init(mode: .register)
        return .none
        
      case .didTapDeleteAllData:
        state.alert = .confirmDeletion
        return .none
        
      case .didTapConnectFridge:
        guard let user = state.user else { return .none }
        state.shareFridge = .init(user: user)
        return .none
        
      case .didTapRemoveConnection:
        return .run { send in
          let result = await self.sharingClient.removeConnection()
          await send(.dependency(.handleRemovingConnection(result)))
        }
        
      case .loginScreen(let action):
        return self.handleLoginScreenAction(action, state: &state)
        
      case .shareFridge(let action):
        return self.handleShareFridgeAction(action, state: &state)
        
      case .alert(let action):
        return self.handleAlertAction(action, state: &state)
        
      case .dependency(let action):
        return self.handleDependencyAction(action, state: &state)
      }
    }
    .ifLet(\.$loginScreen, action: /Action.loginScreen) {
      LoginFeature()
    }
    .ifLet(\.$shareFridge, action: /Action.shareFridge) {
      ShareFridgeFeature()
    }
  }
}

extension ProfileTabFeature {
  private func handleAlertAction(_ action: Action.AlertAction, state: inout State) -> EffectTask<Action> {
    defer { state.alert = nil }
    switch action {
    case .didDismiss:
      return .none
      
    case .didConfirmDeletionOfAllData:
      return .run { send in
        let result = await self.dbClient.deleteAllData()
        await send(.dependency(.handleDeletionOfAllData(result)))
      }
    }
  }
  
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    case .handleDeletionOfAllData(let result):
      switch result {
      case .success:
        return .none
      case .failure:
        return .none
      }
      
    case .handleFetchingConnectedEmails(let result):
      switch result {
      case .success(let emails):
        state.connectedEmails = .init(uniqueElements: emails)
        return .none
      case .failure:
        return .none
      }
      
    case .handleRemovingConnection(let result):
      switch result {
      case .success:
        state.connectedEmails = .init()
        return .none
      case .failure:
        return .none
      }
    }
  }
  
  private func handleLoginScreenAction(_ action: PresentationAction<LoginFeature.Action>, state: inout State) -> EffectTask<Action> {
    switch action {
    case .dismiss:
      state.user = self.userInfoClient.getUserInfo()
      return .none
      
    case .presented:
      return .none
    }
  }
  
  private func handleShareFridgeAction(_ action: PresentationAction<ShareFridgeFeature.Action>, state: inout State) -> EffectTask<Action> {
    switch action {
    case .dismiss:
      return .run { send in
        let result = await self.sharingClient.getConnectedEmails()
        await send(.dependency(.handleFetchingConnectedEmails(result)))
      }
      
    case .presented:
      return .none
    }
  }
}

extension ProfileTabFeature.State {
  var username: String? {
    guard case .loggedIn(let username, _) = self.user else { return nil }
    return username
  }
  
  var email: String? {
    guard case .loggedIn(_, let email) = self.user else { return nil }
    return email
  }
  
  var isLoggedIn: Bool {
    switch self.user {
    case .guest: return false
    case .loggedIn: return true
    case .none: return false
    }
  }
}

extension ProfileTabFeature.State {
  public enum Alert: Equatable {
    case confirmDeletion
  }
}
