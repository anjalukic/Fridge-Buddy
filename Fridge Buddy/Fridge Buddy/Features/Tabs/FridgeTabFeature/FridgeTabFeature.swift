//
//  FridgeTabFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation
import ComposableArchitecture

public struct FridgeTabFeature: ReducerProtocol {
  public struct State: Equatable {
    var isEditing: Bool = false
    var items: IdentifiedArrayOf<FridgeItem> = []
    var groceryItems: IdentifiedArrayOf<GroceryItem> = []
    var sectionedItems: [String: IdentifiedArrayOf<FridgeItem>] = [:]
    var alert: Alert?
    
    @PresentationState var editItem: FridgeItemFormFeature.State?
    @PresentationState var addItems: AddingItemsListFeature.State?
  }
  
  public enum Action: Equatable {
    case onAppear
    case didTapEdit
    case didTapDoneEditing
    case didTapAddNewItem
    case didTapItem(UUID)
    case didTapDeleteItem(UUID)
    case didTapEditItem(UUID)
    case alert(AlertAction)
    case dependency(DependencyAction)
    case editItem(PresentationAction<FridgeItemFormFeature.Action>)
    case addItems(PresentationAction<AddingItemsListFeature.Action>)
    
    public enum AlertAction: Equatable {
      case didTapConfirmDeletion
      case didTapCancelDeletion
      case didDismiss
    }
    
    public enum DependencyAction: Equatable {
      case handleItemsFetched(
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
        
      case .didTapAddNewItem:
        state.addItems = .init()
        return .none

      case .didTapItem(let id), .didTapEditItem(let id):
        guard let item = state.items[id: id] else { fatalError("Couldn't find the selected item") }
        state.editItem = .init(fridgeItem: item, mode: .editingItem)
        state.isEditing = false
        return .none

      case .didTapDeleteItem(let id):
        guard let item = state.fridgeItemForId(id) else { return .none }
        state.alert = .confirmDeletion(item)
        return .none
        
      case .alert(let action):
        return self.handleAlertAction(action, state: &state)
        
      case .dependency(let action):
        return self.handleDependencyAction(action, state: &state)
        
      case .editItem(let action):
        guard case .presented(let editAction) = action else { return .none }
        return self.handleEditItemAction(editAction, state: &state)
        
      case .addItems(let action):
        guard case .presented(let addAction) = action else { return .none }
        return self.handleAddItemsAction(addAction, state: &state)
      }
    }
    .ifLet(\.$editItem, action: /Action.editItem) {
      FridgeItemFormFeature()
    }
    .ifLet(\.$addItems, action: /Action.addItems) {
      AddingItemsListFeature()
    }
  }
}

extension FridgeTabFeature {
  private func handleAlertAction(_ action: Action.AlertAction, state: inout State) -> EffectTask<Action> {
    defer { state.alert = nil }
    switch action {
    case .didTapConfirmDeletion:
      guard case .confirmDeletion(let item) = state.alert else { fatalError("Delete alert in inconsistent state") }
      return .run { send in
        let result = await self.dbClient.deleteFridgeItem(item.id)
        await send(.dependency(.handleDeletionResult(result)))
      }
      
    case .didTapCancelDeletion:
      return .none
      
    case .didDismiss:
      return .none
    }
  }
  
  private func handleEditItemAction(_ action: FridgeItemFormFeature.Action, state: inout State) -> EffectTask<Action> {
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
  
  private func handleAddItemsAction(_ action: AddingItemsListFeature.Action, state: inout State) -> EffectTask<Action> {
    switch action {
    case .delegate(let action):
      switch action {
      case .didAddItems:
        return self.fetchItems()
      }
      
    default:
      return .none
    }
  }
  
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    case .handleItemsFetched(let fridgeItemResult, let groceryItemResult):
      switch (fridgeItemResult, groceryItemResult) {
      case (.success(let fridgeItems), .success(let groceryItems)):
        state.items = fridgeItems
        state.groceryItems = groceryItems
        state.sectionedItems = state.getSectionedItems()
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
  
  private func fetchItems() -> EffectTask<Action> {
    return .task {
      let fridgeItems = await self.dbClient.readFridgeItem()
      let groceryItems = await self.dbClient.readGroceryItem()
      return .dependency(.handleItemsFetched(fridgeItems, groceryItems))
    }
  }
}

extension FridgeTabFeature.State {
  func getSectionedItems() -> [String: IdentifiedArrayOf<FridgeItem>] {
    var sectionedItems: [String: IdentifiedArrayOf<FridgeItem>] = [:]

    self.items.forEach { item in
      if var itemsForType = sectionedItems[item.groceryType] {
        itemsForType.append(item)
        sectionedItems[item.groceryType] = itemsForType
      } else {
        sectionedItems[item.groceryType] = [item]
      }
    }
    return sectionedItems
  }
  
  func itemsForSection(_ section: String) -> IdentifiedArrayOf<FridgeItem> {
    guard let items = self.sectionedItems[section] else { return [] }
    return items
  }
  
  func shouldShowSection(_ section: String) -> Bool {
    if self.sectionedItems[section] == nil { return false }
    return true
  }
  
  func fridgeItemForId(_ id: FridgeItem.ID) -> FridgeItem? {
    return self.items[id: id]
  }
}

extension FridgeTabFeature.State {
  public enum Alert: Equatable {
    case confirmDeletion(FridgeItem)
  }
}
