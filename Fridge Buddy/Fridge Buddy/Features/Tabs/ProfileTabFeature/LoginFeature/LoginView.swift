//
//  LoginView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import SwiftUI
import ComposableArchitecture

public struct LoginView: View {
  private let store: StoreOf<LoginFeature>

  public init(store: StoreOf<LoginFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        Text(viewStore.isLoggingIn ? "Log in" : "Register")
          .font(.system(size: 32, weight: .bold))
          .padding(.vertical, 32)
        self.form
        Spacer()
        self.continueButton
      }
        .padding(16)
        .alert(self.store.scope(state: \.alert?.alertState, action: { .alert($0) }), dismiss: .didDismiss)
    }
  }
  
  private var form: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack(spacing: 20) {
        HStack {
          Text("Username: ")
          TextField("username", text: viewStore.binding(get: { $0.username }, send: { .didChangeUsername($0) }))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
        }
        if !viewStore.isLoggingIn {
          HStack {
            Text("Email: ")
            TextField("email", text: viewStore.binding(get: { $0.email }, send: { .didChangeEmail($0) }))
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled(true)
          }
        }
        HStack {
          Text("Password: ")
          SecureField("password", text: viewStore.binding(get: { $0.password }, send: { .didChangePassword($0) }))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
        }
        if !viewStore.isLoggingIn {
          HStack {
            Text("Confirm password: ")
            SecureField("password", text: viewStore.binding(get: { $0.confirmPassword }, send: { .didChangeConfirmPassword($0) }))
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled(true)
          }
        }
      }
      .padding(16)
    }
  }
  
  private var continueButton: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Button { viewStore.send(.didTapContinue) } label: {
        Text(viewStore.isLoggingIn ? "Log in" : "Register")
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity)
      }
      .disabled(!viewStore.isContinueEnabled)
      .buttonStyle(.borderedProminent)
      .accentColor(Color.init("AppetiteRed"))
    }
  }
}

extension LoginFeature.State.Alert {
  fileprivate var alertState: AlertState<LoginFeature.Action.AlertAction> {
    switch self {
    case .serverErrorFailed:
      return .init(
        title: .init("Internal error"),
        message: .init("Please try again later."),
        dismissButton: .cancel(.init("OK"), action: .send(.didDismiss))
      )
    case .takenUsernameOrEmail:
      return .init(
        title: .init("Username or email already taken"),
        message: .init("Try a different username or email."),
        dismissButton: .cancel(.init("OK"), action: .send(.didDismiss))
      )
    case .wrongUsernameOrPassword:
      return .init(
        title: .init("Wrong username or password"),
        dismissButton: .cancel(.init("OK"), action: .send(.didDismiss))
      )
    }
  }
}

