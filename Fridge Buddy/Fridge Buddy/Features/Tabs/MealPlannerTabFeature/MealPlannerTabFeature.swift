//
//  MealPlannerTabFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation
import ComposableArchitecture

public struct MealPlannerTabFeature: ReducerProtocol {
  public struct State: Equatable {
    var meals: IdentifiedArrayOf<PlannedMeal> = []
    var recipes: IdentifiedArrayOf<Recipe> = []
    var alert: Alert?
    var selectedDate = Date()
    var modifyingMeal: ModifyingMeal?
    
    @PresentationState var recipesList: RecipesListFeature.State?
  }
  
  public enum Action: Equatable {
    case onAppear
    case handleCheckTodaysPlans
    case didChangeSelectedDate(Date)
    case didTapAddNewMeal(PlannedMeal.Meal)
    case didTapChangeMeal(PlannedMeal.Meal)
    case didTapDeleteMeal(PlannedMeal.Meal)
    case recipesList(PresentationAction<RecipesListFeature.Action>)
    case alert(AlertAction)
    case dependency(DependencyAction)
    case delegate(DelegateAction)
    
    public enum AlertAction: Equatable {
      case didTapConfirmDeletion
      case didTapCancelDeletion
      case didDismiss
    }
    
    public enum DependencyAction: Equatable {
      case handleItemsFetched(
        Result<IdentifiedArrayOf<PlannedMeal>, DBClient.DBError>,
        Result<IdentifiedArrayOf<Recipe>, DBClient.DBError>
      )
      case handleDeletionResult(Result<Bool, DBClient.DBError>)
      case handleEditingResult(Result<Bool, DBClient.DBError>)
      case handleAddingResult(Result<Bool, DBClient.DBError>)
      case handleTodaysMealsFetched(Result<String?, DBClient.DBError>)
    }
    
    public enum DelegateAction: Equatable {
      case presentPlannedMealAlert(message: String?)
    }
  }
  
  @Dependency(\.databaseClient) var dbClient
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return self.fetchItems()
        
      case .handleCheckTodaysPlans:
        return .run { send in
          let mealsResult = await self.dbClient.readPlannedMeal()
          let recipeItemsResult = await self.dbClient.readRecipeItem()
          let fridgeItemsResult = await self.dbClient.readFridgeItem()
          guard
            case .success(let meals) = mealsResult,
            case .success(let recipeItems) = recipeItemsResult,
            case .success(var fridgeItems) = fridgeItemsResult
          else {
            await send(.dependency(.handleTodaysMealsFetched(.failure(.readingError))))
            return
          }
          let todaysMeals = meals.filter { $0.date.isSameDate(as: Date()) }
          guard !todaysMeals.isEmpty else {
            await send(.dependency(.handleTodaysMealsFetched(.success(nil))))
            return
          }
          let todaysRecipeIds = todaysMeals.map { $0.recipeId }
          var startingFridgeItems = fridgeItems
          var missingItems: IdentifiedArrayOf<RecipeItem> = []
          todaysRecipeIds.forEach { recipeId in
            let (missing, updatedFridgeItems) = RecipeFeature.State.findMissingItems(
              recipeItems: recipeItems.filter { $0.recipeId == recipeId },
              fridgeItems: startingFridgeItems
            )
            missingItems.append(contentsOf: missing)
            updatedFridgeItems.filter { $0.amount == 0 }.map { $0.id }.forEach {
              startingFridgeItems.remove(id: $0)
            }
            updatedFridgeItems.filter { $0.amount != 0 }.forEach {
              startingFridgeItems[id: $0.id]?.amount = $0.amount
              startingFridgeItems[id: $0.id]?.unit = $0.unit
            }
          }
          
          let message: String
          if missingItems.isEmpty {
            let todaysMenu = todaysMeals.map { "\($0.name) for \($0.mealType.title.lowercased())" }.joined(separator: "\n")
            message = "Today's menu:\n\(todaysMenu)"
          } else {
            let missingList = missingItems.map { "\($0.name) \($0.amount)\($0.unit)" }.joined(separator: "\n")
            message = "You are missing the following ingredients for today's menu:\n\(missingList)"
          }
          await send(.dependency(.handleTodaysMealsFetched(.success(message))))
        }
        
      case .didChangeSelectedDate(let date):
        state.selectedDate = date
        return .none
        
      case .didTapAddNewMeal(let mealType):
        state.modifyingMeal = .adding(mealType)
        state.recipesList = .init()
        return .none
        
      case .didTapChangeMeal(let mealType):
        state.modifyingMeal = .editing(mealType)
        state.recipesList = .init()
        return .none
        
      case .didTapDeleteMeal(let mealType):
        guard let meal = state.mealForSelectedDate(mealType: mealType) else { return .none }
        state.alert = .confirmDeletion(meal)
        return .none
        
      case .recipesList(let action):
        return self.handleRecipesListAction(action, state: &state)
        
      case .alert(let action):
        return self.handleAlertAction(action, state: &state)
        
      case .dependency(let action):
        return self.handleDependencyAction(action, state: &state)
        
      case .delegate:
        // handled in the higher level reducer
        return .none
      }
    }
    .ifLet(\.$recipesList, action: /Action.recipesList) {
      RecipesListFeature()
    }
  }
}

extension MealPlannerTabFeature {
  private func handleAlertAction(_ action: Action.AlertAction, state: inout State) -> EffectTask<Action> {
    defer { state.alert = nil }
    switch action {
    case .didTapConfirmDeletion:
      guard case .confirmDeletion(let meal) = state.alert else { fatalError("Delete alert in inconsistent state") }
      return .run { send in
        let result = await self.dbClient.deletePlannedMeal(meal.id)
        await send(.dependency(.handleDeletionResult(result)))
      }
      
    case .didTapCancelDeletion:
      return .none
      
    case .didDismiss:
      return .none
    }
  }
  
  private func handleRecipesListAction(_ action: PresentationAction<RecipesListFeature.Action>, state: inout State) -> EffectTask<Action> {
    switch action {
    case .presented(.delegate(let delegateAction)):
      switch delegateAction {
      case .didTapRecipe(let recipeId):
        defer {
          state.modifyingMeal = nil
          state.recipesList = nil
        }
        
        switch state.modifyingMeal {
        case .editing(let mealType):
          guard let selectedMeal = state.mealForSelectedDate(mealType: mealType) else { return .none }
          return .run { [date = state.selectedDate] send in
            var result = await self.dbClient.deletePlannedMeal(selectedMeal.id)
            guard case .success = result else {
              await send(.dependency(.handleEditingResult(result)))
              return
            }
            result = await self.dbClient.insertPlannedMeal(.init(
              id: .init(),
              recipeId: recipeId,
              mealType: mealType,
              date: date,
              recipeName: ""
            ))
            await send(.dependency(.handleEditingResult(result)))
          }
          
        case .adding(let mealType):
          return .run { [date = state.selectedDate] send in
            let result = await self.dbClient.insertPlannedMeal(.init(
              id: .init(),
              recipeId: recipeId,
              mealType: mealType,
              date: date,
              recipeName: ""
            ))
            await send(.dependency(.handleAddingResult(result)))
          }
          
        case .none:
          return .none
        }
      }
      
    case .dismiss:
      state.modifyingMeal = nil
      return .none
      
    default:
      // handled in the lower level reducer
      return .none
    }
  }
  
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    case .handleItemsFetched(let mealResult, let recipeResult):
      switch (mealResult, recipeResult) {
      case (.success(let meals), .success(let recipes)):
        state.meals = meals
        state.recipes = recipes
        return .none
      default:
        return .none
      }
      
    case .handleDeletionResult(let result), .handleEditingResult(let result), .handleAddingResult(let result):
      switch result {
      case .success:
        return self.fetchItems()
      case .failure:
        return .none
      }
      
    case .handleTodaysMealsFetched(let result):
      switch result {
      case .success(let message):
        return .send(.delegate(.presentPlannedMealAlert(message: message)))
      case .failure:
        return .none
      }
    }
  }
  
  private func fetchItems() -> EffectTask<Action> {
    return .task {
      let meals = await self.dbClient.readPlannedMeal()
      let recipes = await self.dbClient.readRecipe()
      return .dependency(.handleItemsFetched(meals, recipes))
    }
  }
}

extension MealPlannerTabFeature.State {
  func mealForSelectedDate(mealType: PlannedMeal.Meal) -> PlannedMeal? {
    let filtered = self.meals.filter { $0.date.isSameDate(as: self.selectedDate) && $0.mealType == mealType }
    return filtered.first
  }
}

extension MealPlannerTabFeature.State {
  public enum Alert: Equatable {
    case confirmDeletion(PlannedMeal)
  }
  
  enum ModifyingMeal: Equatable {
    case editing(PlannedMeal.Meal)
    case adding(PlannedMeal.Meal)
  }
}

extension Date {
  func isSameDate(as date: Date) -> Bool {
    return Calendar.current.isDate(self, equalTo: date, toGranularity: .day)
  }
  
  var hasPassed: Bool {
    let today = Date()
    if self.isSameDate(as: today) {
      return false
    }
    return self < today
  }
  
  func formattedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let dateString = formatter.string(from: self)
    
    return dateString
  }
}
