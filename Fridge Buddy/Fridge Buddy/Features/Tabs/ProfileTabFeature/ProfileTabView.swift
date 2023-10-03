//
//  ProfileTabView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import SwiftUI
import ComposableArchitecture

public struct ProfileTabView: View {
  private let store: StoreOf<ProfileTabFeature>
  @AppStorage("isDarkModeEnabled") var isDarkModeEnabled = false

  public init(store: StoreOf<ProfileTabFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        self.userInfo
        self.CTAs
        Spacer()
      }
        .padding(16)
        .alert(self.store.scope(state: \.alert?.alertState, action: { .alert($0) }), dismiss: .didDismiss)
        .sheet(
          store: self.store.scope(state: \.$loginScreen, action: { .loginScreen($0) })
        ) { store in
          LoginView(store: store)
        }
        .fullScreenCover(
          store: self.store.scope(state: \.$shareFridge, action: { .shareFridge($0) })
        ) { store in
          ShareFridgeView(store: store)
        }
        .onAppear {
          viewStore.send(.onAppear)
        }
    }
  }
  
  private var userInfo: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Group {
        VStack(spacing: 8) {
          HStack {
            Image(systemName: "person.fill")
              .resizable()
              .frame(width: 26, height: 26)
            Group {
              if viewStore.isLoggedIn {
                HStack(spacing: 0) {
                  Text("Logged in as ")
                  Text(viewStore.username!)
                    .foregroundColor(Color.init("AppetiteRed"))
                }
              } else {
                Text("You are not logged in")
              }
            }
              .font(.system(size: 26, weight: .semibold))
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          if viewStore.email != nil {
            Text(viewStore.email ?? "")
              .fontWeight(.light)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          
          if !viewStore.connectedEmails.isEmpty {
            Text("Fridge sharing with: \(viewStore.connectedEmails.joined(separator: ", "))")
              .font(.system(size: 14, weight: .thin))
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 16)
      .overlay(
          RoundedRectangle(cornerRadius: 16)
              .stroke(Color.init("AppetiteRed"), lineWidth: 2)
      )
    }
  }
  
  private var CTAs: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack(spacing: 10) {
        if viewStore.isLoggedIn {
          Button { viewStore.send(.didTapLogOut) } label: {
            Text("Log out")
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        } else {
          Button { viewStore.send(.didTapLogIn) } label: {
            Text("Log in")
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          Divider()
          Button { viewStore.send(.didTapRegister) } label: {
            Text("Register")
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        Divider()
        Button { viewStore.send(.didTapDeleteAllData) } label: {
          Text("Delete all data")
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        Divider()
        if viewStore.isLoggedIn {
          Button { viewStore.send(.didTapConnectFridge) } label: {
            Text(viewStore.connectedEmails.isEmpty ? "Connect your fridge with roommates" : "Connect with another roommate")
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          Divider()
          if !viewStore.connectedEmails.isEmpty {
            Button { viewStore.send(.didTapRemoveConnection) } label: {
              Text("Disconnect from other fridges")
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
          }
        }
        Toggle("Dark mode", isOn: self.$isDarkModeEnabled)
      }
      .buttonStyle(.borderless)
      .padding(.vertical, 16)
    }
  }
}

extension ProfileTabFeature.State.Alert {
  fileprivate var alertState: AlertState<ProfileTabFeature.Action.AlertAction> {
    switch self {
    case .confirmDeletion:
      return .init(
        title: .init("Are you sure?"),
        message: .init(
          """
          By tapping confirm you will delete all your fridge inventory, recipes and shopping list items.
          The app will return to its default settings.
          """
        ),
        primaryButton: .destructive(.init("Confirm"), action: .send(.didConfirmDeletionOfAllData)),
        secondaryButton: .cancel(.init("Cancel"), action: .send(.didDismiss))
      )
    }
  }
}

