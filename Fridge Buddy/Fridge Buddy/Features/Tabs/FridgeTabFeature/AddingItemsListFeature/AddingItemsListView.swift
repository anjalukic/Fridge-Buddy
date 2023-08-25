//
//  AddingItemsListView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.8.23..
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct AddingItemsListView: View {
  private let store: StoreOf<AddingItemsListFeature>
  
  public init(store: StoreOf<AddingItemsListFeature>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        self.addedItems
        Spacer()
        self.toggleRemoveFromShoppingList
      }
        .animation(.default, value: viewStore.items)
        .navigationTitle("Add items")
        .navigationBarItems(trailing: Button("Done", action: { viewStore.send(.didTapDone) }))
        .navigationDestination(
          store: self.store.scope(state: \.$addItems, action: { .addItems($0) })
        ) { store in
          AddItemsView(store: store)
        }
    }
  }
  
  private var addedItems: some View {
    WithViewStore(self.store, observe: { $0.items }) { viewStore in
      List {
        ForEach(viewStore.state) { item in
          HStack {
            ItemView(name: item.name, amount: item.amount, unitName: item.unit)
            Button { viewStore.send(.didTapRemoveItem(item.id)) } label: {
              Image(systemName: "trash")
                .foregroundColor(.red)
            }
            .buttonStyle(.plain)
          }
        }
        
        self.addMoreButton
      }
    }
  }
  
  private var addMoreButton: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Button {
        viewStore.send(.didTapAdd)
      } label: {
        Image(systemName: "plus")
      }
      .buttonStyle(.borderedProminent)
    }
  }
  
  private var toggleRemoveFromShoppingList: some View {
    WithViewStore(self.store, observe: { $0.shouldRemoveFromShoppingList }) { viewStore in
      VStack(spacing: 0) {
        Divider()
        Toggle("Remove from shopping list", isOn: viewStore.binding(get: { $0 }, send: { .didToggleShouldRemoveFromShoppingList($0) }))
          .padding(20)
      }
    }
  }
}
