//
//  ShoppingListTabView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import SwiftUI
import ComposableArchitecture

public struct ShoppingListTabView: View {
  private let store: StoreOf<ShoppingListTabFeature>
  @State private var searchText: String = ""

  public init(store: StoreOf<ShoppingListTabFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ZStack(alignment: .bottom) {
        self.shoppingList
          .navigationBarItems(
            leading: self.leadingButton,
            trailing: self.trailingButton
          )
        
        self.removeAllItemsButton
      }
      .animation(.default, value: viewStore.isEditing)
      .alert(self.store.scope(state: \.alert?.alertState, action: { .alert($0) }), dismiss: .didDismiss)
      .navigationDestination(
        store: self.store.scope(state: \.$editItem, action: { .editItem($0) })
      ) { store in
        ShoppingListItemFormView(store: store)
      }
      .navigationDestination(
        store: self.store.scope(state: \.$addItem, action: { .addItem($0) })
      ) { store in
        ShoppingListItemFormView(store: store)
      }
      .onAppear {
        viewStore.send(.onAppear)
      }
    }
  }

  private var shoppingList: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        SearchBar(text: $searchText)
        List {
          ForEach(viewStore.state.items.filter({ searchText.isEmpty ? true : $0.name.contains(searchText) })) { item in
            HStack {
              Button(action: {
                viewStore.send(.didTapItem(item.id))
              }, label: {
                ItemView(name: item.name, amount: item.amount, unitName: item.unit)
              })
              Spacer()
              if viewStore.isEditing {
                ItemActionsView(
                  actions: [
                    .init(.delete, callback: { viewStore.send(.didTapDeleteItem(item.id)) }),
                    .init(.edit, callback: { viewStore.send(.didTapEditItem(item.id)) })
                  ]
                )
              }
            }
            .listRowInsets(EdgeInsets())
            .buttonStyle(PlainButtonStyle())
          }
        }
        .listStyle(.sidebar)
      }
    }
  }

  private var leadingButton: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Button(action: { viewStore.send(.didTapAddNewItem) }) {
        Image(systemName: "plus")
      }
      .opacity(viewStore.isEditing ? 0 : 1)
    }
  }

  private var trailingButton: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      if viewStore.isEditing {
        Button(action: { viewStore.send(.didTapDoneEditing) }) {
          Text("Done")
        }
      } else {
        Button(action: { viewStore.send(.didTapEdit) }) {
          Text("Edit")
        }
      }
    }
  }
  
  private var removeAllItemsButton: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      if !viewStore.isEditing && !viewStore.items.isEmpty {
        Button(action: { viewStore.send(.didTapRemoveAllItems) }) {
          Text("Clear the list")
            .bold()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .accentColor(.green)
        .padding(18)
      }
    }
  }
}

extension ShoppingListTabFeature.State.Alert {
  fileprivate var alertState: AlertState<ShoppingListTabFeature.Action.AlertAction> {
    switch self {
    case .confirmDeletion(let item):
      return .init(
        title: .init("Do you really want to delete?"),
        message: .init("\(item.name)"),
        primaryButton: .destructive(.init("Delete"), action: .send(.didTapConfirmDeletion)),
        secondaryButton: .cancel(.init("Cancel"), action: .send(.didTapCancelDeletion))
      )
      
    case .confirmClearingShoppingList:
      return .init(
        title: .init("Removing all items from the shopping list"),
        message: .init("Do you want to just delete all the items or move them from the shopping list to the fridge?"),
        buttons: [
          .destructive(.init("Delete all the items"), action: .send(.didTapDeleteAllItems)),
          .default(.init("Move items to fridge"), action: .send(.didTapMoveItemsToFridge)),
          .cancel(.init("Cancel"), action: .send(.didDismiss))
        ]
      )
    }
  }
}

