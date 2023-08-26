//
//  RecipeFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 13.8.23..
//

import Foundation
import ComposableArchitecture

public struct RecipeFeature: ReducerProtocol {
  public struct State: Equatable {
    public let recipe: Recipe
    public var recipeItems: IdentifiedArrayOf<RecipeItem> = []
    public var recipeSteps: IdentifiedArrayOf<RecipeStep> = []
    public var missingRecipeItems: IdentifiedArrayOf<RecipeItem> = []
    public var fridgeItemsToRemoveOrUpdate: IdentifiedArrayOf<FridgeItem> = []
    var alert: Alert?
    
    @PresentationState var interactiveCooker: InteractiveCookingFeature.State?
    
    public init(recipe: Recipe) {
      self.recipe = recipe
    }
  }
  
  public enum Action: Equatable {
    case onAppear
    case didTapBack
    case didTapAddMissingIngredientsToShoppingList
    case didTapPrepareAndAddToFridge
    case didTapStartCooking
    case interactiveCooker(PresentationAction<InteractiveCookingFeature.Action>)
    case alert(AlertAction)
    case dependency(DependencyAction)
    case delegate(DelegateAction)
    
    public enum AlertAction: Equatable {
      case didTapAddMealToFridge
      case didSeeAddingItemsToList
      case didDismiss
    }
    
    public enum DependencyAction: Equatable {
      case handleItemsFetched(
        Result<IdentifiedArrayOf<RecipeItem>,DBClient.DBError>,
        Result<IdentifiedArrayOf<RecipeStep>,DBClient.DBError>,
        Result<IdentifiedArrayOf<RecipeItem>,DBClient.DBError>,
        Result<IdentifiedArrayOf<FridgeItem>,DBClient.DBError>
      )
      case handleItemsAddedToList(Result<Bool, DBClient.DBError>)
      case handleRemoveFridgeItemsAndAddToFridge(Result<Bool, DBClient.DBError>)
    }
    
    public enum DelegateAction: Equatable {
      case didTapAddMissingIngredientsToShoppingList
      case didTapPrepareAndAddToFridge
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  @Dependency(\.databaseClient) var dbClient
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return self.fetchItems(for: state.recipe.id)
        
      case .didTapBack:
        return .run { _ in await self.dismiss(animation: .default) }
        
      case .didTapAddMissingIngredientsToShoppingList:
        return .run { [missingRecipeItems = state.missingRecipeItems] send in
          for item in missingRecipeItems {
            let result = await self.dbClient.insertShoppingListItem(.init(
              id: .init(),
              groceryItemId: item.groceryItemId,
              amount: item.amount,
              unit: item.unit,
              name: item.name
            ))
            guard case .success = result else {
              await send(.dependency(.handleItemsAddedToList(.failure(.insertionError))))
              return
            }
          }
          await send(.dependency(.handleItemsAddedToList(.success(true))))
        }
        
      case .didTapPrepareAndAddToFridge:
        state.alert = .confirmAddingMealToFridge
        return .none
        
      case .didTapStartCooking:
        guard !state.recipeSteps.isEmpty else { return .none }
        state.interactiveCooker = .init(recipe: state.recipe, recipeSteps: state.recipeSteps)
        return .none
        
      case .interactiveCooker:
        // handled in the lower level reducer
        return .none
        
      case .alert(let action):
        return self.handleAlertAction(action, state: &state)
        
      case .dependency(let dependencyAction):
        return self.handleDependencyAction(dependencyAction, state: &state)
        
      case .delegate:
        // handled in the higher level reducer
        return .none
      }
    }
    .ifLet(\.$interactiveCooker, action: /Action.interactiveCooker) {
      InteractiveCookingFeature()
    }
  }
}

extension RecipeFeature {
  private func fetchItems(for id: Recipe.ID) -> EffectTask<Action> {
    return .task {
      let recipeItemsResult = await self.dbClient.readRecipeItem()
      let recipeStepsResult = await self.dbClient.readRecipeStep()
      let fridgeItemsResult = await self.dbClient.readFridgeItem()
      guard
        case .success(var recipeItems) = recipeItemsResult,
        case .success(var recipeSteps) = recipeStepsResult,
        case .success(let fridgeItems) = fridgeItemsResult
      else {
        return .dependency(.handleItemsFetched(.failure(.readingError), .failure(.readingError), .failure(.readingError), .failure(.readingError)))
      }
      recipeItems = recipeItems.filter { $0.recipeId == id }
      recipeSteps = recipeSteps.filter { $0.recipeId == id }
      var missingRecipeItems: IdentifiedArrayOf<RecipeItem> = []
      var removedOrUpdatedFridgeItems: IdentifiedArrayOf<FridgeItem> = []
      
      for item in recipeItems {
        var amount = item.amount
        var unit = item.unit
        for fridgeItem in fridgeItems.filter({ $0.groceryItemId == item.groceryItemId }) {
          let itemAmount = AmountWithUnit(amount: amount, unit: unit)
          guard Unit(name: fridgeItem.unit).isComparable(with: itemAmount.unit) else { continue }
          let fridgeAmount = AmountWithUnit(amount: fridgeItem.amount, unit: fridgeItem.unit)
          // calculate missing amount
          amount = max(itemAmount.amount - fridgeAmount.amount, 0)
          unit = fridgeAmount.unit
          // calculate used amount
          var usedFridgeItem = fridgeItem
          usedFridgeItem.amount = max(fridgeAmount.amount - itemAmount.amount, 0)
          usedFridgeItem.unit = fridgeAmount.unit
          removedOrUpdatedFridgeItems.append(usedFridgeItem)
        }
        
        if amount > 0 {
          missingRecipeItems.append(.init(
            id: .init(),
            recipeId: item.recipeId,
            groceryItemId: item.groceryItemId,
            amount: amount,
            unit: unit,
            name: item.name
          ))
        }
      }
      return .dependency(.handleItemsFetched(.success(recipeItems), .success(recipeSteps), .success(missingRecipeItems), .success(removedOrUpdatedFridgeItems)))
    }
  }
  
  private func handleAlertAction(_ action: Action.AlertAction, state: inout State) -> EffectTask<Action> {
    defer { state.alert = nil }
    switch action {
    case .didTapAddMealToFridge:
      return .run { [removedFridgeItems = state.fridgeItemsToRemoveOrUpdate, recipe = state.recipe] send in
        for item in removedFridgeItems {
          let result: Result<Bool, DBClient.DBError>
          if item.amount == 0 {
            result = await self.dbClient.deleteFridgeItem(item.id)
          } else {
            result = await self.dbClient.updateFridgeItem(item)
          }
          guard case .success = result else {
            await send(.dependency(.handleRemoveFridgeItemsAndAddToFridge(.failure(.generalError))))
            return
          }
        }
        
        let result = await self.dbClient.insertFridgeItem(.init(
          id: .init(),
          groceryItemId: recipe.id,
          expirationDate: Date() + TimeInterval(fromDays: 4),
          amount: Double(recipe.yieldAmount),
          unit: Unit.portions.id,
          name: recipe.name,
          imageName: "noImage",
          groceryType: "Dishes"
        ))
        await send(.dependency(.handleRemoveFridgeItemsAndAddToFridge(result)))
      }
      
    case .didSeeAddingItemsToList:
      return .send(.delegate(.didTapAddMissingIngredientsToShoppingList))
      
    case .didDismiss:
      return .none
    }
  }
  
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    case .handleItemsFetched(let recipeItemResult, let recipeStepResult, let missingRecipeItemsResult, let fridgeItemsResult):
      switch (recipeItemResult, recipeStepResult, missingRecipeItemsResult, fridgeItemsResult) {
      case (.success(let recipeItems), .success(let recipeSteps), .success(let missingRecipeItems), .success(let fridgeItems)):
        state.recipeItems = recipeItems
        state.recipeSteps = recipeSteps
        state.missingRecipeItems = missingRecipeItems
        state.fridgeItemsToRemoveOrUpdate = fridgeItems
        return .none
      default:
        return .none
      }
      
    case .handleItemsAddedToList(let result):
      switch result {
      case .success:
        let message = state.missingRecipeItems
          .map { "\($0.name) \($0.amount.formatted())\($0.unit)" }
          .reduce("") { result, item in
            result + item + "\n"
          }
        state.alert = .missingIngredientsAddedToList(message)
        return .none
      case .failure:
        return .none
      }
      
    case .handleRemoveFridgeItemsAndAddToFridge(let result):
      switch result {
      case .success:
        return .merge(
          .send(.delegate(.didTapPrepareAndAddToFridge)),
          .run { _ in await self.dismiss(animation: .default) }
        )
          
      case .failure:
        return .none
      }
    }
  }
}

extension RecipeFeature.State {
  var hasMissingIngredients: Bool {
    return !self.missingRecipeItems.isEmpty
  }
}

extension RecipeFeature.State {
  public enum Alert: Equatable {
    case missingIngredientsAddedToList(String)
    case confirmAddingMealToFridge
  }
}
