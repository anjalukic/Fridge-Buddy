//
//  AddingItemsListFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.8.23..
//

import Foundation
import ComposableArchitecture

public struct AddingItemsListFeature: ReducerProtocol {
  public struct State: Equatable {
    var items: IdentifiedArrayOf<FridgeItem> = []
    var shouldRemoveFromShoppingList: Bool = true
    @PresentationState var addItems: AddItemsFeature.State?
  }
  
  public enum Action: Equatable {
    case didTapDone
    case didTapAdd
    case didTapRemoveItem(UUID)
    case addItems(PresentationAction<AddItemsFeature.Action>)
    case didToggleShouldRemoveFromShoppingList(Bool)
    case dependency(DependencyAction)
    case delegate(DelegateAction)
    
    public enum DependencyAction: Equatable {
      case handleInsertingResult(Result<Bool, DBClient.DBError>)
      case handleDeletionResult(Result<Bool, DBClient.DBError>)
    }
    
    public enum DelegateAction: Equatable {
      case didAddItems([FridgeItem])
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  @Dependency(\.databaseClient) var dbClient
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .didTapDone:
        return .run { [items = state.items] send in
          for item in items {
            let result = await self.dbClient.insertFridgeItem(item)
            guard case .success = result else {
              await send(.dependency(.handleInsertingResult(.failure(.insertionError))))
              return
            }
          }
          await send(.dependency(.handleInsertingResult(.success(true))))
        }
        
      case .didTapAdd:
        state.addItems = .init()
        return .none
        
      case .didTapRemoveItem(let id):
        state.items.remove(id: id)
        return .none
        
      case .didToggleShouldRemoveFromShoppingList(let newValue):
        state.shouldRemoveFromShoppingList = newValue
        return .none
      
      case .addItems(let action):
        guard case .presented(let addAction) = action else { return .none }
        return self.handleAddItemsAction(addAction, state: &state)
        
      case .dependency(let action):
        return self.handleDependencyAction(action, state: &state)
        
      case .delegate:
        // handled in the higher level reducer
        return .none
      }
    }
    .ifLet(\.$addItems, action: /Action.addItems) {
      AddItemsFeature()
    }
  }
}

extension AddingItemsListFeature {
  private func handleAddItemsAction(_ action: AddItemsFeature.Action, state: inout State) -> EffectTask<Action> {
    switch action {
    case .delegate(let action):
      switch action {
      case .handleAddItems(let items):
        state.addItems = nil
        state.items.append(contentsOf: items)
        return .none
      }
    default:
      return .none
    }
  }
  
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    case .handleInsertingResult(let result):
      switch result {
      case .success:
        if !state.shouldRemoveFromShoppingList {
          return .merge(
            .run { _ in await self.dismiss(animation: .default) },
            .send(.delegate(.didAddItems(state.items.elements)))
          )
        }
        return .run { [items = state.items] send in
          for item in items {
            // TODO: this should ideally not remove, but substract from the shopping list
            let result = await self.dbClient.deleteAllShoppingListItemsFor(item.groceryItemId)
            guard case .success = result else {
              await send(.dependency(.handleDeletionResult(.failure(.deletionError))))
              return
            }
          }
          await send(.dependency(.handleDeletionResult(.success(true))))
        }
      case .failure:
        return .none
      }
      
    case .handleDeletionResult(let result):
      switch result {
      case .success:
        return .merge(
          .run { _ in await self.dismiss(animation: .default) },
          .send(.delegate(.didAddItems(state.items.elements)))
        )
      case .failure:
        return .none
      }
    }
  }
}
