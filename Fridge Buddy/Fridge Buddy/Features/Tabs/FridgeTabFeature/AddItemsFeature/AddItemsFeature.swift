//
//  AddItemsFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.8.23..
//

import Foundation
import ComposableArchitecture

public struct AddItemsFeature: ReducerProtocol {
  public struct State: Equatable {
    @PresentationState var addItem: FridgeItemFormFeature.State?
    @PresentationState var scanItems: ReceiptScanFeature.State?
  }
  
  public enum Action: Equatable {
    case didTapScanItems
    case didTapAddSingleItem
    case addItem(PresentationAction<FridgeItemFormFeature.Action>)
    case scanItems(PresentationAction<ReceiptScanFeature.Action>)
    case delegate(DelegateAction)
    
    public enum DelegateAction: Equatable {
      case handleAddItems([FridgeItem])
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .didTapScanItems:
        state.scanItems = .init()
        return .none
        
      case .didTapAddSingleItem:
        state.addItem = .init(
          fridgeItem: .init(
            id: .init(),
            groceryItem: .apple,
            expirationDate: Date() + GroceryItem.apple.defaultExpirationInterval,
            amount: 1,
            unit: .pcs
          ),
          mode: .addingNewItem
        )
        return .none
      
      case .addItem(let action):
        guard case .presented(let addAction) = action else { return .none }
        return self.handleAddItemAction(addAction, state: &state)
        
      case .scanItems(let action):
        guard case .presented(let scanAction) = action else { return .none }
        return self.handleScanItemsAction(scanAction, state: &state)
        
      case .delegate:
        // handled in the higher level reducer
        return .none
      }
    }
    .ifLet(\.$addItem, action: /Action.addItem) {
      FridgeItemFormFeature()
    }
    .ifLet(\.$scanItems, action: /Action.scanItems) {
      ReceiptScanFeature()
    }
  }
}

extension AddItemsFeature {
  private func handleAddItemAction(_ action: FridgeItemFormFeature.Action, state: inout State) -> EffectTask<Action> {
    switch action {
    case .delegate(let action):
      switch action {
      case .didTapDone(let fridgeItem):
        return .merge(
          .send(.delegate(.handleAddItems([fridgeItem]))),
          .run { _ in await self.dismiss(animation: .default) }
        )
      }
    default:
      return .none
    }
  }
  
  private func handleScanItemsAction(_ action: ReceiptScanFeature.Action, state: inout State) -> EffectTask<Action> {
    switch action {
    case .delegate(let action):
      switch action {
      case .didTapDone(let fridgeItems):
        return .merge(
          .send(.delegate(.handleAddItems(fridgeItems))),
          .run { _ in await self.dismiss(animation: .default) }
        )
      }
      
    default:
      return .none
    }
  }
}
