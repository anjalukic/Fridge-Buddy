//
//  AddFridgeItemFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 25.5.23..
//

import Foundation
import ComposableArchitecture

public struct FridgeItemFormFeature: ReducerProtocol {
  public struct State: Equatable {
    public let mode: Mode
    @BindingState public var fridgeItem: FridgeItem
    public var groceryItems: IdentifiedArrayOf<GroceryItem> = []
    public var isDoneButtonEnabled: Bool = false
    
    public init(
      fridgeItem: FridgeItem,
      mode: Mode
    ) {
      self.fridgeItem = fridgeItem
      self.mode = mode
      if mode == .editingItem { self.isDoneButtonEnabled = true }
    }
  }
  
  public enum Action: BindableAction, Equatable {
    case onAppear
    case binding(BindingAction<State>)
    case didTapDone
    case didChangeGroceryItem(GroceryItem)
    case didChangeGroceryItemName(String)
    case didChangeGroceryType(String)
    case delegate(DelegateAction)
    case dependency(DependencyAction)
    
    public enum DelegateAction: Equatable {
      case didTapDone(FridgeItem)
    }
    
    public enum DependencyAction: Equatable {
      case handleFetchingResult(Result<IdentifiedArrayOf<GroceryItem>, DBClient.DBError>)
      case handleUpdatingResult(Result<Bool, DBClient.DBError>)
      case handleAddingGroceryItemResult(Result<Bool, DBClient.DBError>)
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  @Dependency(\.databaseClient) var dbClient
  
  public var body: some ReducerProtocolOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          let result = await self.dbClient.readGroceryItem()
          await send(.dependency(.handleFetchingResult(result)))
        }
        
      case .didTapDone:
        if state.isEditing {
          // update the existing fridgeItem
          return .run { [fridgeItem = state.fridgeItem] send in
            let result = await self.dbClient.updateFridgeItem(fridgeItem)
            await send(.dependency(.handleUpdatingResult(result)))
          }
        }
        else {
          // add a new GroceryItem if needed
          if !state.groceryItems.map({ $0.id }).contains(state.fridgeItem.groceryItemId) {
            guard let groceryType = GroceryItem.groceryTypes.first(where: { $0 == state.fridgeItem.groceryType})
            else { fatalError("Invalid grocery type") }
            let newGroceryItem = GroceryItem.init(
              id: state.fridgeItem.groceryItemId,
              name: state.fridgeItem.name,
              defaultExpirationInterval: state.fridgeItem.expirationDate.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate,
              type: groceryType
            )
            return .run { send in
              let result = await self.dbClient.insertGroceryItem(newGroceryItem)
              await send(.dependency(.handleAddingGroceryItemResult(result)))
            }
          } else {
            return .send(.delegate(.didTapDone(state.fridgeItem)))
          }
        }
        
      case .didChangeGroceryItem(let item):
        state.fridgeItem.groceryItemId = item.id
        state.fridgeItem.name = item.name
        state.fridgeItem.groceryType = item.type
        state.fridgeItem.expirationDate = Date() + item.defaultExpirationInterval
        state.isDoneButtonEnabled = true
        return .none
        
      case .didChangeGroceryItemName(let groceryItemName):
        if let groceryItem = state.groceryItems.first(where: { $0.name == groceryItemName }) {
          return .send(.didChangeGroceryItem(groceryItem))
        } else {
          if groceryItemName.isEmpty {
            state.isDoneButtonEnabled = false
            return .none
          }
          state.fridgeItem.name = groceryItemName
          state.fridgeItem.groceryItemId = .init()
          state.isDoneButtonEnabled = true
        }
        return .none
        
      case .didChangeGroceryType(let groceryType):
        state.fridgeItem.groceryType = groceryType
        return .none
        
      case .dependency(let dependencyAction):
        return self.handleDependencyAction(dependencyAction, state: &state)
        
      case .binding:
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}

extension FridgeItemFormFeature {
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    case .handleFetchingResult(let result):
      switch result {
      case .success(let groceryItems):
        state.groceryItems = groceryItems
        return .none
      case .failure:
        return .none
      }
      
    case .handleUpdatingResult(let result):
      switch result {
      case .success:
        return .merge(
          .send(.delegate(.didTapDone(state.fridgeItem))),
          .run { _ in await self.dismiss(animation: .default) }
        )
      case .failure:
        return .none
      }
    case .handleAddingGroceryItemResult(let result):
      switch result {
      case .success:
        return .merge(
          .run { _ in await self.dismiss(animation: .default) },
          .send(.delegate(.didTapDone(state.fridgeItem)))
        )
      case .failure:
        return .none
      }
    }
  }
}

extension FridgeItemFormFeature.State {
  var isEditing: Bool {
    switch self.mode {
    case .editingItem: return true
    case .addingNewItem: return false
    }
  }
}

extension FridgeItemFormFeature.State {
  public enum Mode {
    case editingItem
    case addingNewItem
  }
}
