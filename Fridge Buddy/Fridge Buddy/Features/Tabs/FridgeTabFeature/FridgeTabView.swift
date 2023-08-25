//
//  FridgeTabView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import SwiftUI
import ComposableArchitecture

public struct FridgeTabView: View {
  private let store: StoreOf<FridgeTabFeature>
  
  public init(store: StoreOf<FridgeTabFeature>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      self.fridgeContents
        .navigationBarItems(
          leading: self.leadingButton,
          trailing: self.trailingButton
        )
        .animation(.default, value: viewStore.isEditing)
        .animation(.default, value: viewStore.sectionedItems)
        .alert(self.store.scope(state: \.alert?.alertState, action: { .alert($0) }), dismiss: .didDismiss)
        .navigationDestination(
          store: self.store.scope(state: \.$editItem, action: { .editItem($0) })
        ) { store in
          FridgeItemFormView(store: store)
        }
        .navigationDestination(
          store: self.store.scope(state: \.$addItems, action: { .addItems($0) })
        ) { store in
          AddingItemsListView(store: store)
        }
        .onAppear {
          viewStore.send(.onAppear)
        }
    }
  }
  
  private var fridgeContents: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      List {
        ForEach(GroceryItem.groceryTypes) { section in
          if viewStore.state.shouldShowSection(section) {
            Section(header: Text(section)) {
              ForEach(viewStore.state.itemsForSection(section)) { item in
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
          }
        }
      }
      .listStyle(.sidebar)
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
}

extension FridgeTabFeature.State.Alert {
  fileprivate var alertState: AlertState<FridgeTabFeature.Action.AlertAction> {
    switch self {
    case .confirmDeletion(let item):
      return .init(
        title: .init("Do you really want to delete?"),
        message: .init("\(item.name) \(item.amount.formatted()) \(item.unit)"),
        primaryButton: .destructive(.init("Delete"), action: .send(.didTapConfirmDeletion)),
        secondaryButton: .cancel(.init("Cancel"), action: .send(.didTapCancelDeletion))
      )
    }
  }
}

