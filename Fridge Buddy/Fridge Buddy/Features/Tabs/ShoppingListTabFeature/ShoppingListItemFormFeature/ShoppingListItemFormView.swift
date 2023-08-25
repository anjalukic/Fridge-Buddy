//
//  ShoppingListItemFormView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 10.8.23..
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct ShoppingListItemFormView: View {
  private let store: StoreOf<ShoppingListItemFormFeature>
  @State private var searchString = ""
  @State private var listSelection: GroceryItem? = nil
  
  public init(store: StoreOf<ShoppingListItemFormFeature>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Form {
        if !viewStore.isEditing {
          Section {
            SearchBarListView<GroceryItem>(
              listItems: .init(viewStore.groceryItems),
              placeholderText: "Grocery",
              onSelect: { viewStore.send(.didChangeGroceryItem($0)) },
              onCommit: { viewStore.send(.didChangeGroceryItemName($0)) }
            )
          }
        }
        
        Section {
          HStack {
            TextField("Amount", value: viewStore.binding(\.$shoppingListItem.amount), format: .number)
              .keyboardType(.decimalPad)
            
            Picker("", selection: viewStore.binding(\.$shoppingListItem.unit)) {
              ForEach(Unit.startingUnits) { unit in
                Text(unit.name)
                  .tag(unit.id)
              }
            }
            .pickerStyle(.menu)
          }
        }
      }
      .navigationTitle(viewStore.isEditing ? "Editing \(viewStore.shoppingListItem.name)" : "Adding new item")
      .navigationBarItems(trailing: Button("Done", action: { viewStore.send(.didTapDone) }).disabled(!viewStore.isDoneButtonEnabled))
    }
  }
}
