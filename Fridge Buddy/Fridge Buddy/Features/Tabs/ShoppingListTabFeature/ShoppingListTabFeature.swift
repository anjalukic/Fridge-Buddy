//
//  ShoppingListTabFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation
import ComposableArchitecture

public struct ShoppingListTabFeature: ReducerProtocol {
  public struct State: Equatable {
    var isEditing: Bool = false
    var items: IdentifiedArrayOf<ShoppingListItem> = []
    var groceryItems: IdentifiedArrayOf<GroceryItem> = []
    var alert: Alert?
    
    @PresentationState var editItem: ShoppingListItemFormFeature.State?
    @PresentationState var addItem: ShoppingListItemFormFeature.State?
  }
  
  public enum Action: Equatable {
    case onAppear
    case didTapEdit
    case didTapDoneEditing
    case didTapAddNewItem
    case didTapItem(UUID)
    case didTapDeleteItem(UUID)
    case didTapEditItem(UUID)
    case didTapRemoveAllItems
    case alert(AlertAction)
    case dependency(DependencyAction)
    case editItem(PresentationAction<ShoppingListItemFormFeature.Action>)
    case addItem(PresentationAction<ShoppingListItemFormFeature.Action>)
    
    public enum AlertAction: Equatable {
      case didTapConfirmDeletion
      case didTapCancelDeletion
      case didTapDeleteAllItems
      case didTapMoveItemsToFridge
      case didDismiss
    }
    
    public enum DependencyAction: Equatable {
      case handleItemsFetched(
        Result<IdentifiedArrayOf<ShoppingListItem>, DBClient.DBError>,
        Result<IdentifiedArrayOf<GroceryItem>, DBClient.DBError>
      )
      case handleDeletionResult(Result<Bool, DBClient.DBError>)
      case handleDeletionOfAllResult(Result<Bool, DBClient.DBError>)
      case handleMovingToFridgeResult(Result<Bool, DBClient.DBError>)
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
        
      case .didTapAddNewItem:
        state.addItem = .init(
          shoppingListItem: .init(
            id: .init(),
            groceryItem: .apple,
            amount: 1,
            unit: .kg
          ),
          groceryItems: state.groceryItems,
          mode: .addingNewItem
        )
        return .none

      case .didTapItem(let id), .didTapEditItem(let id):
        guard let item = state.items[id: id] else { fatalError("Couldn't find the selected item") }
        state.editItem = .init(
          shoppingListItem: item,
          groceryItems: state.groceryItems,
          mode: .editingItem
        )
        state.isEditing = false
        return .none

      case .didTapDeleteItem(let id):
        guard let item = state.shoppingListItemForId(id) else { return .none }
        state.alert = .confirmDeletion(item)
        return .none
        
      case .didTapRemoveAllItems:
        state.alert = .confirmClearingShoppingList
        return .none
        
      case .alert(let action):
        return self.handleAlertAction(action, state: &state)
        
      case .dependency(let action):
        return self.handleDependencyAction(action, state: &state)
        
      case .editItem(let action):
        guard case .presented(let editAction) = action else { return .none }
        return self.handleEditItemAction(editAction, state: &state)


      case .addItem(let action):
        guard case .presented(let addAction) = action else { return .none }
        return self.handleAddItemAction(addAction, state: &state)
      }
    }
    .ifLet(\.$editItem, action: /Action.editItem) {
      ShoppingListItemFormFeature()
    }
    .ifLet(\.$addItem, action: /Action.addItem) {
      ShoppingListItemFormFeature()
    }
  }
}

extension ShoppingListTabFeature {
  private func handleAlertAction(_ action: Action.AlertAction, state: inout State) -> EffectTask<Action> {
    defer { state.alert = nil }
    switch action {
    case .didTapConfirmDeletion:
      guard case .confirmDeletion(let item) = state.alert else { fatalError("Delete alert in inconsistent state") }
      return .run { send in
        let result = await self.dbClient.deleteShoppingListItem(item.id)
        await send(.dependency(.handleDeletionResult(result)))
      }
      
    case .didTapCancelDeletion:
      return .none
      
    case .didTapDeleteAllItems:
      return .run { send in
        let result = await self.dbClient.deleteAllShoppingListItems()
        await send(.dependency(.handleDeletionOfAllResult(result)))
      }
      
    case .didTapMoveItemsToFridge:
      return .run { [items = state.items, groceryItems = state.groceryItems] send in
        for item in items {
          guard let groceryItem = groceryItems[id: item.groceryItemId] else {
            await send(.dependency(.handleMovingToFridgeResult(.failure(.generalError))))
            return
          }
          var result = await self.dbClient.insertFridgeItem(.init(
            id: .init(),
            groceryItemId: groceryItem.id,
            expirationDate: Date() + groceryItem.defaultExpirationInterval,
            amount: item.amount,
            unit: item.unit,
            name: groceryItem.name,
            imageName: groceryItem.imageName,
            groceryType: groceryItem.type
          ))
          guard case .success = result else {
            await send(.dependency(.handleMovingToFridgeResult(.failure(.generalError))))
            return
          }
          result = await self.dbClient.deleteShoppingListItem(item.id)
          guard case .success = result else {
            await send(.dependency(.handleMovingToFridgeResult(.failure(.generalError))))
            return
          }
        }
        await send(.dependency(.handleMovingToFridgeResult(.success(true))))
      }
      return .none
      
    case .didDismiss:
      return .none
    }
  }
  
  private func handleEditItemAction(_ action: ShoppingListItemFormFeature.Action, state: inout State) -> EffectTask<Action> {
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

  private func handleAddItemAction(_ action: ShoppingListItemFormFeature.Action, state: inout State) -> EffectTask<Action> {
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
  
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    case .handleItemsFetched(let shoppingItemResult, let groceryItemResult):
      switch (shoppingItemResult, groceryItemResult) {
      case (.success(let shoppingItems), .success(let groceryItems)):
        state.items = shoppingItems
        state.groceryItems = groceryItems
        return .none
      default:
        return .none
      }
      
    case .handleDeletionResult(let result), .handleDeletionOfAllResult(let result), .handleMovingToFridgeResult(let result):
      switch result {
      case .success:
        return self.fetchItems()
      case .failure:
        return .none
      }
    }
  }
  
  private func fetchItems() -> EffectTask<Action> {
    return .task {
      let items = await self.dbClient.readShoppingListItem()
      let groceryItems = await self.dbClient.readGroceryItem()
      return .dependency(.handleItemsFetched(items, groceryItems))
    }
  }
}

extension ShoppingListTabFeature.State {
  func shoppingListItemForId(_ id: ShoppingListItem.ID) -> ShoppingListItem? {
    return self.items[id: id]
  }
}

extension ShoppingListTabFeature.State {
  public enum Alert: Equatable {
    case confirmDeletion(ShoppingListItem)
    case confirmClearingShoppingList
  }
}
