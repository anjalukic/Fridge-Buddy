//
//  LoginFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation
import ComposableArchitecture

public struct LoginFeature: ReducerProtocol {
  public struct State: Equatable {
    var username: String = ""
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var alert: Alert?
    var mode: Mode
    
    public init(mode: Mode) {
      self.mode = mode
    }
  }
  
  public enum Action: Equatable {
    case didChangeUsername(String)
    case didChangeEmail(String)
    case didChangePassword(String)
    case didChangeConfirmPassword(String)
    case didTapContinue
    case alert(AlertAction)
    case dependency(DependencyAction)
    
    public enum AlertAction: Equatable {
      case didDismiss
    }
    
    public enum DependencyAction: Equatable {
      case handleLogin(Result<Bool, UserInfoClient.UserInfoError>)
      case handleRegister(Result<Bool, UserInfoClient.UserInfoError>)
    }
  }
  
  @Dependency(\.userInfoClient) var userInfoClient
  @Dependency(\.dismiss) var dismiss
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .didChangeUsername(let username):
        state.username = username
        return .none
        
      case .didChangeEmail(let email):
        state.email = email
        return .none
        
      case .didChangePassword(let password):
        state.password = password
        return .none
        
      case .didChangeConfirmPassword(let confirmPassword):
        state.confirmPassword = confirmPassword
        return .none
        
      case .didTapContinue:
        switch state.mode {
        case .login:
          return .run { [username = state.username, password = state.password] send in
            let result = await self.userInfoClient.loginUser(username, password)
            await send(.dependency(.handleLogin(result)))
          }
          
        case .register:
          return .run { [username = state.username, email = state.email, password = state.password] send in
            let result = await self.userInfoClient.registerUser(username, email, password)
            await send(.dependency(.handleRegister(result)))
          }
        }
        
      case .alert(let action):
        return self.handleAlertAction(action, state: &state)
        
      case .dependency(let action):
        return self.handleDependencyAction(action, state: &state)
      }
    }
  }
}

extension LoginFeature {
  private func handleAlertAction(_ action: Action.AlertAction, state: inout State) -> EffectTask<Action> {
    defer { state.alert = nil }
    switch action {
    case .didDismiss:
      return .none
    }
  }
  
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    case .handleLogin(let result):
      switch result {
      case .success:
        return .run { _ in await self.dismiss(animation: .default) }
      case .failure(let error):
        switch error {
        case .wrongUsernameOrPasswordError:
          state.alert = .wrongUsernameOrPassword
          return .none
          
        default:
          state.alert = .serverErrorFailed
          return .none
        }
      }
      
    case .handleRegister(let result):
      switch result {
      case .success:
        return .run { _ in await self.dismiss(animation: .default) }
      case .failure(let error):
        switch error {
        case .usernameTakenError, .emailTakenError:
          state.alert = .takenUsernameOrEmail
          return .none
          
        default:
          state.alert = .serverErrorFailed
          return .none
        }
      }
    }
  }
}

extension LoginFeature.State {
  var isLoggingIn: Bool {
    switch self.mode {
    case .login: return true
    case .register: return false
    }
  }
  
  var isContinueEnabled: Bool {
    switch self.mode {
    case .login:
      return !self.username.isEmpty && !self.password.isEmpty
    case .register:
      return !self.username.isEmpty && !self.email.isEmpty && !self.password.isEmpty && !self.confirmPassword.isEmpty
      && self.password == self.confirmPassword
    }
  }
}

extension LoginFeature.State {
  public enum Alert: Equatable {
    case serverErrorFailed
    case takenUsernameOrEmail
    case wrongUsernameOrPassword
  }
  
  public enum Mode: Equatable {
    case login
    case register
  }
}
