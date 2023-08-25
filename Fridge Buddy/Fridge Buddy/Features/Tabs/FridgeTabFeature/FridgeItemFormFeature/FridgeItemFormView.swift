//
//  EditFridgeItemView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 10.8.23..
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct FridgeItemFormView: View {
  private let store: StoreOf<FridgeItemFormFeature>
  @State private var searchString = ""
  @State private var listSelection: GroceryItem? = nil
  
  public init(store: StoreOf<FridgeItemFormFeature>) {
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

          Section {
            Picker("", selection: .init(get: { viewStore.fridgeItem.groceryType }, set: { typeId in viewStore.send(.didChangeGroceryType(typeId)) })) {
              ForEach(GroceryItem.groceryTypes) { type in
                Text(type)
                  .tag(type)
              }
            }
            .pickerStyle(.menu)
          }
        }
        
        Section {
          DatePicker("Expiration date", selection: viewStore.binding(\.$fridgeItem.expirationDate), displayedComponents: [.date])
            .datePickerStyle(.compact)
        }
        
        Section {
          HStack {
            TextField("Amount", value: viewStore.binding(\.$fridgeItem.amount), format: .number)
              .keyboardType(.decimalPad)
            
            Picker("", selection: viewStore.binding(\.$fridgeItem.unit)) {
              ForEach(Unit.startingUnits) { unit in
                Text(unit.name)
                  .tag(unit.id)
              }
            }
            .pickerStyle(.menu)
          }
        }
      }
      .onAppear { viewStore.send(.onAppear) }
      .navigationTitle(viewStore.isEditing ? "Editing \(viewStore.fridgeItem.name)" : "Adding new item")
      .navigationBarItems(trailing: Button("Done", action: { viewStore.send(.didTapDone) }).disabled(!viewStore.isDoneButtonEnabled))
    }
  }
}
