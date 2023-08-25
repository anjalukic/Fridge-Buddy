//
//  FridgeTabFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation
import ComposableArchitecture

public struct RecipesTabFeature: ReducerProtocol {
  public struct State: Equatable {
    var isEditing: Bool = false
    var recipes: IdentifiedArrayOf<Recipe> = []
    var recipeItems: IdentifiedArrayOf<RecipeItem> = []
    var recipeSteps: IdentifiedArrayOf<RecipeStep> = []
    var fridgeItems: IdentifiedArrayOf<FridgeItem> = []
    var groceryItems: IdentifiedArrayOf<GroceryItem> = []
    var sectionedRecipes: [String: IdentifiedArrayOf<Recipe>] = [:]
    var alert: Alert?
    
    @PresentationState var recipePreview: RecipeFeature.State?
    @PresentationState var editRecipe: RecipeFormFeature.State?
    @PresentationState var addRecipe: RecipeFormFeature.State?
  }
  
  public enum Action: Equatable {
    case onAppear
    case didTapEdit
    case didTapDoneEditing
    case didTapAddNewRecipe
    case didTapRecipe(UUID)
    case didTapDeleteRecipe(UUID)
    case didTapEditRecipe(UUID)
    case alert(AlertAction)
    case dependency(DependencyAction)
    case recipePreview(PresentationAction<RecipeFeature.Action>)
    case editRecipe(PresentationAction<RecipeFormFeature.Action>)
    case addRecipe(PresentationAction<RecipeFormFeature.Action>)
    
    public enum AlertAction: Equatable {
      case didTapConfirmDeletion
      case didTapCancelDeletion
      case didDismiss
    }
    
    public enum DependencyAction: Equatable {
      case handleItemsFetched(
        Result<IdentifiedArrayOf<Recipe>, DBClient.DBError>,
        Result<IdentifiedArrayOf<RecipeItem>, DBClient.DBError>,
        Result<IdentifiedArrayOf<RecipeStep>, DBClient.DBError>,
        Result<IdentifiedArrayOf<FridgeItem>, DBClient.DBError>,
        Result<IdentifiedArrayOf<GroceryItem>, DBClient.DBError>
      )
      case handleDeletionResult(Result<Bool, DBClient.DBError>)
    }
  }
  
  @Dependency(\.databaseClient) var dbClient
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return self.fetchItems()
        
      case .didTapEdit:
        state.isEditing = true
        return .none
        
      case .didTapDoneEditing:
        state.isEditing = false
        return .none
        
      case .didTapAddNewRecipe:
        state.addRecipe = .init(
          recipe: .init(id: .init(), name: "My new recipe", yieldAmount: 1),
          recipeItems: [],
          recipeSteps: [],
          groceryItems: state.groceryItems,
          mode: .addingNewRecipe
        )
        return .none

      case .didTapRecipe(let id):
        guard let recipe = state.recipes[id: id] else { fatalError("Couldn't find the tapped item") }
        state.recipePreview = .init(recipe: recipe)
        return .none
          
      case .didTapEditRecipe(let id):
        guard let recipe = state.recipes[id: id] else { fatalError("Couldn't find the selected item") }
        let recipeItems = state.recipeItems.filter { $0.recipeId == recipe.id }
        let recipeSteps = state.recipeSteps.filter { $0.recipeId == recipe.id }
        state.isEditing = false
        state.editRecipe = .init(
          recipe: recipe,
          recipeItems: recipeItems,
          recipeSteps: recipeSteps,
          groceryItems: state.groceryItems,
          mode: .editingRecipe
        )
        return .none

      case .didTapDeleteRecipe(let id):
        guard let recipe = state.recipes[id: id] else { return .none }
        state.alert = .confirmDeletion(recipe)
        return .none
        
      case .recipePreview:
        // handled in the lower level reducer
        return .none
        
      case .editRecipe(let action):
        guard case .presented(let editAction) = action else { return .none }
        return self.handleEditRecipeAction(editAction, state: &state)
        
      case .addRecipe(let action):
        guard case .presented(let addAction) = action else { return .none }
        return self.handleAddRecipeAction(addAction, state: &state)
        
      case .alert(let action):
        return self.handleAlertAction(action, state: &state)
        
      case .dependency(let action):
        return self.handleDependencyAction(action, state: &state)
      }
    }
    .ifLet(\.$recipePreview, action: /Action.recipePreview) {
      RecipeFeature()
    }
    .ifLet(\.$editRecipe, action: /Action.editRecipe) {
      RecipeFormFeature()
    }
    .ifLet(\.$addRecipe, action: /Action.addRecipe) {
      RecipeFormFeature()
    }
  }
}

extension RecipesTabFeature {
  private func handleAlertAction(_ action: Action.AlertAction, state: inout State) -> EffectTask<Action> {
    defer { state.alert = nil }
    switch action {
    case .didTapConfirmDeletion:
      guard case .confirmDeletion(let recipe) = state.alert else { fatalError("Delete alert in inconsistent state") }
      return .run { send in
        let result = await self.dbClient.deleteRecipe(recipe.id)
        await send(.dependency(.handleDeletionResult(result)))
      }
      
    case .didTapCancelDeletion:
      return .none
      
    case .didDismiss:
      return .none
    }
  }
  
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    case .handleItemsFetched(let recipeResult, let recipeItemResult, let recipeStepResult, let fridgeItemResult, let groceryItemResult):
      switch (recipeResult, recipeItemResult, recipeStepResult, fridgeItemResult, groceryItemResult) {
      case (.success(let recipes), .success(let recipeItems), .success(let recipeSteps), .success(let fridgeItems), .success(let groceryItems)):
        state.recipes = recipes
        state.recipeItems = recipeItems
        state.recipeSteps = recipeSteps
        state.fridgeItems = fridgeItems
        state.groceryItems = groceryItems
        state.sectionedRecipes = state.splitRecipes
        return .none
      default:
        return .none
      }
      
    case .handleDeletionResult(let result):
      switch result {
      case .success:
        return self.fetchItems()
      case .failure:
        return .none
      }
    }
  }
  
  private func handleEditRecipeAction(_ action: RecipeFormFeature.Action, state: inout State) -> EffectTask<Action> {
    switch action {
    case .delegate(let delegateAction):
      switch delegateAction {
      case .didTapDone:
        return self.fetchItems()
      }
      
    default:
      return .none
    }
  }
  
  private func handleAddRecipeAction(_ action: RecipeFormFeature.Action, state: inout State) -> EffectTask<Action> {
    switch action {
    case .delegate(let delegateAction):
      switch delegateAction {
      case .didTapDone:
        return self.fetchItems()
      }
      
    default:
      return .none
    }
  }
  
  private func fetchItems() -> EffectTask<Action> {
    return .task {
      let recipes = await self.dbClient.readRecipe()
      let recipeItems = await self.dbClient.readRecipeItem()
      let fridgeItems = await self.dbClient.readFridgeItem()
      let recipeSteps = await self.dbClient.readRecipeStep()
      let groceryItems = await self.dbClient.readGroceryItem()
      return .dependency(.handleItemsFetched(recipes, recipeItems, recipeSteps, fridgeItems, groceryItems))
    }
  }
}

extension RecipesTabFeature.State {
  fileprivate var splitRecipes: [String: IdentifiedArrayOf<Recipe>] {
    let makeableSection = "Recipes I can make"
    let otherSection = "Other recipes"
    var splitRecipes: [String: IdentifiedArrayOf<Recipe>] = [
      makeableSection: [],
      otherSection: []
    ]
    
    self.recipes.forEach { recipe in
      let itemsForRecipe = self.recipeItems.filter { item in item.recipeId == recipe.id }
      var canMakeRecipe = true
      itemsForRecipe.forEach { recipeItem in
        if !self.fridgeItems.contains(where: { fridgeItem in
          return recipeItem.groceryItemId == fridgeItem.groceryItemId && self.checkEnoughAmount(of: recipeItem, in: fridgeItem)
        }) {
          canMakeRecipe = false
        }
      }
      if canMakeRecipe {
        splitRecipes[makeableSection]?.append(recipe)
      } else {
        splitRecipes[otherSection]?.append(recipe)
      }
    }
    
    return splitRecipes
  }
  
  fileprivate func checkEnoughAmount(of recipeItem: RecipeItem, in fridgeItem: FridgeItem) -> Bool {
    switch (recipeItem.unit, fridgeItem.unit) {
    case (let recipeUnit, let fridgeUnit) where recipeUnit == fridgeUnit:
      return fridgeItem.amount >= recipeItem.amount
    case (Unit.l.name, Unit.ml.name), (Unit.kg.name, Unit.g.name):
      return fridgeItem.amount >= recipeItem.amount * 1000
    case (Unit.ml.name, Unit.l.name), (Unit.g.name, Unit.kg.name):
      return fridgeItem.amount * 1000 >= recipeItem.amount
    default:
      return false
    }
  }
  
  var sections: IdentifiedArrayOf<String> {
    return .init(uniqueElements: self.sectionedRecipes.keys)
  }
}

extension RecipesTabFeature.State {
  public enum Alert: Equatable {
    case confirmDeletion(Recipe)
  }
}

extension String: Identifiable {
  public var id: Self { return self }
}
