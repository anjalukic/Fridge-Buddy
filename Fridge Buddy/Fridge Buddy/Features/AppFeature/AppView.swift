//
//  ContentView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
  private let store: StoreOf<AppFeature>
  
  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }
  
  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      SwiftUI.TabView(
        selection: viewStore.binding(
          get: { $0.selectedTab },
          send: AppFeature.Action.didTapTab
        )
      ) {
        NavigationStack {
          FridgeTabView(store: self.store.scope(
            state: \.fridgeTabState,
            action: AppFeature.Action.fridgeTabAction
          ))
          .navigationTitle(AppFeature.Tab.fridge.title)
          .navigationBarTitleDisplayMode(.inline)
        }
          .tabItem {
            Label(AppFeature.Tab.fridge.title, systemImage: "refrigerator.fill")
          }
          .tag(AppFeature.Tab.fridge)
        
        NavigationStack {
          RecipesTabView(store: self.store.scope(
            state: \.recipesTabState,
            action: AppFeature.Action.recipesTabAction
          ))
          .navigationTitle(AppFeature.Tab.recipes.title)
          .navigationBarTitleDisplayMode(.inline)
        }
          .tabItem {
            Label(AppFeature.Tab.recipes.title, systemImage: "book")
          }
          .tag(AppFeature.Tab.recipes)
        
        NavigationStack {
          ShoppingListTabView(store: self.store.scope(
            state: \.shoppingListTabState,
            action: AppFeature.Action.shoppingListTabAction
          ))
          .navigationTitle(AppFeature.Tab.shoppingList.title)
          .navigationBarTitleDisplayMode(.inline)
        }
          .tabItem {
            Label(AppFeature.Tab.shoppingList.title, systemImage: "list.bullet.clipboard")
          }
          .tag(AppFeature.Tab.shoppingList)
        
        NavigationStack {
          MealPlannerTabView(store: self.store.scope(
            state: \.mealPlannerTabState,
            action: AppFeature.Action.mealPlannerTabAction
          ))
          .navigationTitle(AppFeature.Tab.mealPlanner.title)
          .navigationBarTitleDisplayMode(.inline)
        }
          .tabItem {
            Label(AppFeature.Tab.mealPlanner.title, systemImage: "calendar")
          }
          .tag(AppFeature.Tab.mealPlanner)
        
        NavigationStack {
          ProfileTabView(store: self.store.scope(
            state: \.profileTabState,
            action: AppFeature.Action.profileTabAction
          ))
          .navigationTitle(AppFeature.Tab.profile.title)
          .navigationBarTitleDisplayMode(.inline)
        }
          .tabItem {
            Label(AppFeature.Tab.profile.title, systemImage: "person")
          }
          .tag(AppFeature.Tab.profile)
      }
      .onAppear {
        let appearance = UITabBarAppearance()
        appearance.shadowColor = .white
        appearance.shadowImage = UIImage(named: "tab-shadow")?.withRenderingMode(.alwaysTemplate)
        UITabBar.appearance().scrollEdgeAppearance = appearance
        viewStore.send(.onAppear)
      }
      .alert(self.store.scope(state: \.alert?.alertState, action: { .alert($0) }), dismiss: .didDismiss)
    }
  }
}

extension AppFeature.State.Alert {
  fileprivate var alertState: AlertState<AppFeature.Action.AlertAction> {
    switch self {
    case .newConnectionReceived(emails: let emails):
      return .init(
        title: .init("New connection received!"),
        message: .init("The following emails want to connect their fridges with you: \n\(emails.joined(separator: "\n"))"),
        primaryButton: .default(.init("Accept"), action: .send(.didDismiss)),
        secondaryButton: .default(.init("Decline"), action: .send(.didDeclineConnection))
      )
    case .todaysMenu(message: let message):
      return .init(
        title: .init("Meal planner"),
        message: .init(message),
        dismissButton: .default(.init("OK"), action: .send(.didDismiss))
      )
    }
  }
}

struct TabView_Previews: PreviewProvider {
  static var previews: some View {
    AppView(store: .init(
      initialState: .init(
        selectedTab: .fridge,
        fridgeTabState: .init()
      ),
      reducer: AppFeature())
    )
  }
}
