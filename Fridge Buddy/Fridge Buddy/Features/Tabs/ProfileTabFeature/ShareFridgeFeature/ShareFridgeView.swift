//
//  ShareFridgeView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 20.8.23..
//

import SwiftUI
import ComposableArchitecture

public struct ShareFridgeView: View {
  private let store: StoreOf<ShareFridgeFeature>
  
  public init(store: StoreOf<ShareFridgeFeature>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ZStack {
        VStack {
          TitleWithBackButtonView(title: "Connect your fridge", didTapBack: { viewStore.send(.didTapBack) })
          Group {
            self.emailField
            Spacer()
            self.description
            self.continueButton
          }
          .padding(.horizontal, 16)
        }
        .disabled(viewStore.isSharingInProgress)
        if viewStore.isSharingInProgress {
          ProgressView("Loading")
            .frame(width: 200, height: 200)
            .cornerRadius(12)
        }
      }
      .alert(self.store.scope(state: \.alert?.alertState, action: { .alert($0) }), dismiss: .didDismiss)
    }
  }
  
  private var emailField: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      HStack {
        Text("Email: ")
        TextField("email", text: viewStore.binding(get: { $0.sharingEmail }, send: { .didChangeEmail($0) }))
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled(true)
      }
      .padding(.vertical, 16)
    }
  }
  
  private var description: some View {
    Text("By tapping continue, you will share the contents of your fridge, your recipes and your shopping list with the email specified above.")
      .font(.footnote)
      .fontWeight(.light)
      .multilineTextAlignment(.center)
  }
  
  private var continueButton: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Button { viewStore.send(.didTapContinue) } label: {
        Text("Continue")
          .fontWeight(.bold)
          .frame(maxWidth: .infinity)
      }
      .disabled(!viewStore.isContinueEnabled)
      .buttonStyle(.borderedProminent)
    }
  }
}

extension ShareFridgeFeature.State.Alert {
  fileprivate var alertState: AlertState<ShareFridgeFeature.Action.AlertAction> {
    switch self {
    case .serverErrorFailed:
      return .init(
        title: .init("Internal error"),
        message: .init("Please try again later."),
        dismissButton: .cancel(.init("OK"), action: .send(.didDismiss))
      )
    case .fridgeShared:
      return .init(
        title: .init("Fridge shared!"),
        dismissButton: .cancel(.init("OK"), action: .send(.didDismissFridgeShared))
      )
    }
  }
}
