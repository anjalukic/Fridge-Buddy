//
//  RecipeFormFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 25.5.23..
//

import Foundation
import ComposableArchitecture

public struct RecipeFormFeature: ReducerProtocol {
  public struct State: Equatable {
    public let mode: Mode
    @BindingState public var recipe: Recipe
    public var recipeItems: IdentifiedArrayOf<RecipeItem>
    public var recipeSteps: IdentifiedArrayOf<RecipeStep>
    public var groceryItems: IdentifiedArrayOf<GroceryItem>
    
    public init(
      recipe: Recipe,
      recipeItems: IdentifiedArrayOf<RecipeItem>,
      recipeSteps: IdentifiedArrayOf<RecipeStep>,
      groceryItems: IdentifiedArrayOf<GroceryItem>,
      mode: Mode
    ) {
      self.recipe = recipe
      self.recipeItems = recipeItems
      self.recipeSteps = recipeSteps
      self.groceryItems = groceryItems
      self.mode = mode
    }
  }
  
  public enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case didTapDone
    case didTapRemoveRecipeItem(RecipeItem.ID)
    case didTapRemoveRecipeStep(RecipeStep.ID)
    case didTapAddRecipeItem(GroceryItem, amount: Double, unitId: Unit.ID)
    case didTapAddRecipeStep(description: String, timeInMins: Int?)
    case didTapRemoveImage
    case delegate(DelegateAction)
    case dependency(DependencyAction)
    
    public enum DelegateAction: Equatable {
      case didTapDone(Recipe)
    }
    
    public enum DependencyAction: Equatable {
      case handleUpdatingResult(Result<Bool, DBClient.DBError>, shouldDismiss: Bool)
      case handleAddingResult(Result<Bool, DBClient.DBError>)
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  @Dependency(\.databaseClient) var dbClient
  
  public var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .didTapDone:
        return state.isEditing ? self.updateRecipe(state: &state) : self.saveRecipe(state: &state)
        
      case .didTapRemoveRecipeItem(let id):
        state.recipeItems.remove(id: id)
        return .none
        
      case .didTapRemoveRecipeStep(let id):
        state.recipeSteps.remove(id: id)
        return .none
        
      case .didTapAddRecipeItem(let item, let amount, let unitId):
        guard let unit = Unit.startingUnits.first(where: { $0.id == unitId }) else { return .none }
        state.recipeItems.append(.init(
          id: .init(),
          recipe: state.recipe,
          groceryItem: item,
          amount: amount,
          unit: unit
        ))
        return .none
        
      case .didTapAddRecipeStep(description: let description, timeInMins: let timeInMins):
        state.recipeSteps.append(.init(
          id: .init(),
          recipeId: state.recipe.id,
          description: description,
          index: state.recipeSteps.count,
          timerDuration: TimeInterval.createTimeInterval(fromMinutes: timeInMins)
        ))
        return .none
        
      case .didTapRemoveImage:
        state.recipe.image = nil
        return .none
        
      case .dependency(let dependencyAction):
        switch dependencyAction {
        case .handleUpdatingResult(let result, let shouldDismiss):
          switch result {
          case .success:
            return shouldDismiss ?
              .merge(
                .send(.delegate(.didTapDone(state.recipe))),
                .run { _ in await self.dismiss(animation: .default) }
              ) :
              .none
          case .failure:
            return .none
          }
        case .handleAddingResult(let result):
          switch result {
          case .success:
            return .merge(
              .send(.delegate(.didTapDone(state.recipe))),
              .run { _ in await self.dismiss(animation: .default) }
            )
          case .failure:
            return .none
          }
        }
        
      case .binding:
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}

extension RecipeFormFeature {
  private func updateRecipe(state: inout State) -> EffectTask<Action> {
    return .run { [recipe = state.recipe, recipeItems = state.recipeItems, recipeSteps = state.recipeSteps] send in
      let updateResult = await self.dbClient.updateRecipe(recipe)
      // update recipe items
      let recipeItemDeleteResult = await self.dbClient.deleteRecipeItemsFor(recipe.id)
      var recipeItemResult: Result<Bool, DBClient.DBError> = .success(true)
      for item in recipeItems {
        let result = await self.dbClient.insertRecipeItem(item)
        if case .failure = result {
          recipeItemResult = result
          break
        }
      }
      // update recipe steps
      let recipeStepDeleteResult = await self.dbClient.deleteRecipeStepsFor(recipe.id)
      var recipeStepResult: Result<Bool, DBClient.DBError> = .success(true)
      for step in recipeSteps {
        let result = await self.dbClient.insertRecipeStep(step)
        if case .failure = result {
          recipeStepResult = result
          break
        }
      }
      guard
        case .success = updateResult,
        case .success = recipeItemDeleteResult,
        case .success = recipeItemResult,
        case .success = recipeStepDeleteResult,
        case .success = recipeStepResult
      else {
        await send(.dependency(.handleUpdatingResult(.failure(.generalError), shouldDismiss: true)))
        return
      }
      await send(.dependency(.handleUpdatingResult(updateResult, shouldDismiss: true)))
    }
  }
  
  private func saveRecipe(state: inout State) -> EffectTask<Action> {
    return .run { [recipe = state.recipe, recipeItems = state.recipeItems, recipeSteps = state.recipeSteps] send in
      let insertionResult = await self.dbClient.insertRecipe(recipe)
      // insert recipe items
      var recipeItemResult: Result<Bool, DBClient.DBError> = .success(true)
      for item in recipeItems {
        let result = await self.dbClient.insertRecipeItem(item)
        if case .failure = result {
          recipeItemResult = result
          break
        }
      }
      // insert recipe steps
      var recipeStepResult: Result<Bool, DBClient.DBError> = .success(true)
      for step in recipeSteps {
        let result = await self.dbClient.insertRecipeStep(step)
        if case .failure = result {
          recipeStepResult = result
          break
        }
      }
      guard
        case .success = insertionResult, case .success = recipeItemResult, case .success = recipeStepResult else {
        await send(.dependency(.handleAddingResult(.failure(.generalError))))
        return
      }
      await send(.dependency(.handleAddingResult(insertionResult)))
    }
  }
}

extension RecipeFormFeature.State {
  var isEditing: Bool {
    switch self.mode {
    case .editingRecipe: return true
    case .addingNewRecipe: return false
    }
  }
}

extension RecipeFormFeature.State {
  public enum Mode {
    case editingRecipe
    case addingNewRecipe
  }
}
