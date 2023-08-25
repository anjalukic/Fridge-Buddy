//
//  ContentFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation
import ComposableArchitecture

public struct AppFeature: ReducerProtocol {
  public struct State: Equatable {
    var selectedTab: Tab = .fridge
    
    var fridgeTabState: FridgeTabFeature.State = .init()
    var recipesTabState: RecipesTabFeature.State = .init()
    var shoppingListTabState: ShoppingListTabFeature.State = .init()
    var mealPlannerTabState: MealPlannerTabFeature.State = .init()
    var profileTabState: ProfileTabFeature.State = .init()
  }
  
  public enum Tab: Equatable {
    case fridge
    case recipes
    case shoppingList
    case mealPlanner
    case profile
    
    var title: String {
      switch self {
      case .fridge: return "Fridge"
      case .recipes: return "Recipes"
      case .shoppingList: return "Shopping List"
      case .mealPlanner: return "Meal Planner"
      case .profile: return "Profile"
      }
    }
  }
  
  public enum Action: Equatable {
    case onAppear
    case didTapTab(Tab)
    case handleRefreshDatabase
    case fridgeTabAction(FridgeTabFeature.Action)
    case recipesTabAction(RecipesTabFeature.Action)
    case shoppingListTabAction(ShoppingListTabFeature.Action)
    case mealPlannerTabAction(MealPlannerTabFeature.Action)
    case profileTabAction(ProfileTabFeature.Action)
    case dependencyAction(DependencyAction)
    
    public enum DependencyAction: Equatable {
      case handleDatabaseRefreshed(Result<Bool, FridgeSharingClient.FridgeSharingError>)
    }
  }
  
  @Dependency(\.userInfoClient) var userInfoClient
  @Dependency(\.fridgeSharingClient) var sharingClient
  @Dependency(\.continuousClock) var clock
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          await send(.handleRefreshDatabase)
          for await _ in clock.timer(interval: .seconds(60)) {
            await send(.handleRefreshDatabase)
          }
        }
      case .handleRefreshDatabase:
        return self.refreshDatabase()
      case .didTapTab(let tab):
        state.selectedTab = tab
        return .none
      case .fridgeTabAction:
        // handled in the lower level reducer
        return .none
      case .recipesTabAction:
        // handled in the lower level reducer
        return .none
      case .shoppingListTabAction:
        // handled in the lower level reducer
        return .none
      case .mealPlannerTabAction:
        // handled in the lower level reducer
        return .none
      case .profileTabAction:
        // handled in the lower level reducer
        return .none
      case .dependencyAction(.handleDatabaseRefreshed(let result)):
        switch result {
        case .success(let isRefreshed):
          print(isRefreshed ? "database refreshed and updated" : "database refreshed without need to update")
          return .none
        case .failure:
          print("database failed to refresh")
          return .none
        }
      }
    }
    
    Scope(
      state: \.fridgeTabState,
      action: /Action.fridgeTabAction
    ) {
      FridgeTabFeature()
    }
    
    Scope(
      state: \.recipesTabState,
      action: /Action.recipesTabAction
    ) {
      RecipesTabFeature()
    }
    
    Scope(
      state: \.shoppingListTabState,
      action: /Action.shoppingListTabAction
    ) {
      ShoppingListTabFeature()
    }
    
    Scope(
      state: \.mealPlannerTabState,
      action: /Action.mealPlannerTabAction
    ) {
      MealPlannerTabFeature()
    }
    
    Scope(
      state: \.profileTabState,
      action: /Action.profileTabAction
    ) {
      ProfileTabFeature()
    }
  }
}

extension AppFeature {
  fileprivate func refreshDatabase() -> EffectTask<Action> {
    return .run { send in
      let user = self.userInfoClient.getUserInfo()
      guard case .loggedIn = user else { return }
      let connectionResult = await self.sharingClient.getConnection()
      guard case .success(let connectionId) = connectionResult else {
        await send(.dependencyAction(.handleDatabaseRefreshed(.failure(.readingError))))
        return
      }
      guard connectionId != nil else {
        await send(.dependencyAction(.handleDatabaseRefreshed(.success(false))))
        return
      }
      let checkForUpdatesResult = await self.sharingClient.checkIfUpdateNeeded()
      guard case .success(let url) = checkForUpdatesResult else {
        await send(.dependencyAction(.handleDatabaseRefreshed(.failure(.readingError))))
        return
      }
      if let url {
        let result = await self.sharingClient.downloadFridge(url)
        await send(.dependencyAction(.handleDatabaseRefreshed(result)))
        return
      }
      await send(.dependencyAction(.handleDatabaseRefreshed(.success(false))))
    }
  }
}
