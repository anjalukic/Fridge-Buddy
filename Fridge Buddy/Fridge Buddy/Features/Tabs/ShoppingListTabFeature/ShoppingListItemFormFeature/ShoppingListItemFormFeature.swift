//
//  ShoppingListItemFormFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 25.5.23..
//

import Foundation
import ComposableArchitecture

public struct ShoppingListItemFormFeature: ReducerProtocol {
  public struct State: Equatable {
    public let mode: Mode
    @BindingState public var shoppingListItem: ShoppingListItem
    public var groceryItems: IdentifiedArrayOf<GroceryItem>
    public var isDoneButtonEnabled: Bool = false
    
    public init(
      shoppingListItem: ShoppingListItem,
      groceryItems: IdentifiedArrayOf<GroceryItem>,
      mode: Mode
    ) {
      self.shoppingListItem = shoppingListItem
      self.groceryItems = groceryItems
      self.mode = mode
      if mode == .editingItem { self.isDoneButtonEnabled = true }
    }
  }
  
  public enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case didTapDone
    case didChangeGroceryItem(GroceryItem)
    case didChangeGroceryItemName(String)
    case delegate(DelegateAction)
    case dependency(DependencyAction)
    
    public enum DelegateAction: Equatable {
      case didTapDone(ShoppingListItem)
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
        if state.isEditing {
          // update the existing shoppingListItem
          return .run { [item = state.shoppingListItem] send in
            let result = await self.dbClient.updateShoppingListItem(item)
            await send(.dependency(.handleUpdatingResult(result, shouldDismiss: true)))
          }
        } else {
          // add a new shoppingListItem
          return .run { [item = state.shoppingListItem] send in
            let result = await self.dbClient.insertShoppingListItem(item)
            await send(.dependency(.handleUpdatingResult(result, shouldDismiss: true)))
          }
        }
        
      case .didChangeGroceryItem(let item):
        state.shoppingListItem.groceryItemId = item.id
        state.isDoneButtonEnabled = true
        return .none
        
      case .didChangeGroceryItemName(let groceryItemName):
        if let groceryItem = state.groceryItems.first(where: { $0.name == groceryItemName }) {
          return .send(.didChangeGroceryItem(groceryItem))
        } else {
          state.isDoneButtonEnabled = false
          return .none
        }
        
      case .dependency(let dependencyAction):
        switch dependencyAction {
        case .handleUpdatingResult(let result, let shouldDismiss):
          switch result {
          case .success:
            return shouldDismiss ?
              .merge(
                .send(.delegate(.didTapDone(state.shoppingListItem))),
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
              .send(.delegate(.didTapDone(state.shoppingListItem))),
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

extension ShoppingListItemFormFeature.State {
  var isEditing: Bool {
    switch self.mode {
    case .editingItem: return true
    case .addingNewItem: return false
    }
  }
}

extension ShoppingListItemFormFeature.State {
  public enum Mode {
    case editingItem
    case addingNewItem
  }
}
