//
//  RecipesListFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation
import ComposableArchitecture

public struct RecipesListFeature: ReducerProtocol {
  public struct State: Equatable {
    var recipes: IdentifiedArrayOf<Recipe> = []
  }
  
  public enum Action: Equatable {
    case onAppear
    case didTapRecipe(UUID)
    case dependency(DependencyAction)
    case delegate(DelegateAction)
    
    public enum DependencyAction: Equatable {
      case handleItemsFetched(Result<IdentifiedArrayOf<Recipe>, DBClient.DBError>)
    }
    
    public enum DelegateAction: Equatable {
      case didTapRecipe(UUID)
    }
  }
  
  @Dependency(\.databaseClient) var dbClient
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return self.fetchItems()
        
      case .didTapRecipe(let id):
        return .send(.delegate(.didTapRecipe(id)))
        
      case .dependency(let action):
        return self.handleDependencyAction(action, state: &state)
        
      case .delegate:
        // handled in the higher level reducer
        return .none
      }
    }
  }
}

extension RecipesListFeature {
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    case .handleItemsFetched(let recipeResult):
      switch recipeResult {
      case .success(let recipes):
        state.recipes = recipes
        return .none
      case .failure:
        return .none
      }
    }
  }
  
  private func fetchItems() -> EffectTask<Action> {
    return .task {
      let recipes = await self.dbClient.readRecipe()
      return .dependency(.handleItemsFetched(recipes))
    }
  }
}
