//
//  AddItemsView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.8.23..
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct AddItemsView: View {
  private let store: StoreOf<AddItemsFeature>
  
  public init(store: StoreOf<AddItemsFeature>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack(spacing: 36) {
        Button { viewStore.send(.didTapAddSingleItem) } label: {
          self.styledText("Add a single item")
        }
        Button { viewStore.send(.didTapScanItems) } label: {
          self.styledText("Scan a receipt QR code")
        }
        Button { viewStore.send(.didTapAddFromShoppingList) } label: {
          self.styledText("Add items from shopping list")
        }
      }
      .padding(.horizontal, 16)
      .buttonStyle(.borderedProminent)
        .navigationTitle("Add items")
        .navigationDestination(
          store: self.store.scope(state: \.$addItem, action: { .addItem($0) })
        ) { store in
          FridgeItemFormView(store: store)
        }
        .navigationDestination(
          store: self.store.scope(state: \.$scanItems, action: { .scanItems($0) })
        ) { store in
          ReceiptScanView(store: store)
        }
    }
  }
  
  private func styledText(_ text: String) -> some View {
    Text(text)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 24)
  }
}
