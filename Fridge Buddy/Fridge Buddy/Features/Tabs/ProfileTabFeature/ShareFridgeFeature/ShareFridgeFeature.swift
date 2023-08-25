//
//  ShareFridgeFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation
import ComposableArchitecture

public struct ShareFridgeFeature: ReducerProtocol {
  public struct State: Equatable {
    var sharingEmail: String = ""
    var user: User
    var alert: Alert?
    var isSharingInProgress = false
    
    public init(user: User) {
      self.user = user
    }
  }
  
  public enum Action: Equatable {
    case didChangeEmail(String)
    case didTapContinue
    case didTapBack
    case alert(AlertAction)
    case dependency(DependencyAction)
    
    public enum AlertAction: Equatable {
      case didDismiss
      case didDismissFridgeShared
    }
    
    public enum DependencyAction: Equatable {
      case handleSharing(Result<Bool, FridgeSharingClient.FridgeSharingError>)
    }
  }
  
  @Dependency(\.fridgeSharingClient) var sharingClient
  @Dependency(\.databaseClient) var dbClient
  @Dependency(\.dismiss) var dismiss
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .didChangeEmail(let email):
        state.sharingEmail = email
        return .none
        
      case .didTapContinue:
        state.isSharingInProgress = true
        return .run { [email = state.sharingEmail] send in
          let connectionResult = await self.sharingClient.createConnection(email)
          if case .failure(let error) = connectionResult {
            await send(.dependency(.handleSharing(.failure(error))))
            return
          }
          let result = await self.sharingClient.uploadFridge()
          await send(.dependency(.handleSharing(result)))
        }
        
      case .didTapBack:
        return .run { _ in await self.dismiss(animation: .default) }
        
      case .alert(let action):
        return self.handleAlertAction(action, state: &state)
        
      case .dependency(let action):
        return self.handleDependencyAction(action, state: &state)
      }
    }
  }
}

extension ShareFridgeFeature {
  private func handleAlertAction(_ action: Action.AlertAction, state: inout State) -> EffectTask<Action> {
    defer { state.alert = nil }
    switch action {
    case .didDismiss:
      return .none
      
    case .didDismissFridgeShared:
      return .run { _ in await self.dismiss(animation: .default) }
    }
  }
  
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    case .handleSharing(let result):
      state.isSharingInProgress = false
      switch result {
      case .success:
        state.alert = .fridgeShared
        return .none
      case .failure:
        state.alert = .serverErrorFailed
        return .none
      }
    }
  }
}

extension ShareFridgeFeature.State {
  var isContinueEnabled: Bool {
    !self.sharingEmail.isEmpty && !self.isSharingInProgress
  }
}

extension ShareFridgeFeature.State {
  public enum Alert: Equatable {
    case serverErrorFailed
    case fridgeShared
  }
}
