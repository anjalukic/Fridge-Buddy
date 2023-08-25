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
          Text("Add a single item")
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        Button { viewStore.send(.didTapScanItems) } label: {
          Text("Scan a receipt QR code")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
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
}
