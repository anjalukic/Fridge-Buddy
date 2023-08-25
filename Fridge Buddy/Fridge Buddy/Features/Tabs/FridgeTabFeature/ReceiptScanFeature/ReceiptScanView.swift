//
//  ReceiptScanView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 22.8.23..
//

import Foundation
import SwiftUI
import ComposableArchitecture


struct ReceiptScanView: View {
  private let store: StoreOf<ReceiptScanFeature>
  
  public init(store: StoreOf<ReceiptScanFeature>) {
    self.store = store
  }
  
  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        QRScannerView { items in
          DispatchQueue.main.async {
            viewStore.send(.handleScanDone(items))
          }
        }
      }
      .navigationTitle("Scanning receipt QR")
      .navigationDestination(isPresented: .init(get: { viewStore.isScanningComplete }, set: { _ in })) {
        self.items
          .navigationTitle("Scanned items")
          .navigationBarItems(trailing: Button("Done", action: { viewStore.send(.didTapDone) }).disabled(!viewStore.state.isDoneEnabled))
      }
      .onAppear { viewStore.send(.onAppear) }
    }
  }
  
  private var items: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      if !viewStore.state.fridgeItems.isEmpty {
        List {
          ForEach(viewStore.state.fridgeItems) { item in
            HStack(alignment: .top) {
              SearchBarListView<GroceryItem>(
                listItems: .init(viewStore.groceryItems),
                placeholderText: "Grocery",
                onSelect: { viewStore.send(.didSelectNewGroceryItem($0.id, for: item.id)) },
                onCommit: { viewStore.send(.didEditItemName($0, for: item.id)) },
                selectedName: item.name
              )
              .padding(.top, 6)
              
              TextField("Amount", value: viewStore.binding(get: { $0.fridgeItems[id: item.id]!.amount }, send: { .didEditItemAmount(item.id, $0) }), format: .number)
                .keyboardType(.decimalPad)
                .frame(maxWidth: 36)
                .padding(.top, 6)
              
              Picker("", selection: viewStore.binding(get: { $0.fridgeItems[id: item.id]!.unit }, send: { .didEditItemUnit(item.id, $0) })) {
                ForEach(Unit.startingUnits) { unit in
                  Text(unit.name)
                    .tag(unit.id)
                }
              }
              .pickerStyle(.menu)
              .fixedSize()
              
              Button { viewStore.send(.didTapRemoveItem(item.id)) } label: {
                Image(systemName: "trash")
                  .foregroundColor(.red)
              }
              .buttonStyle(.plain)
              .padding(.top, 6)
            }
          }
        }
        .animation(.default, value: viewStore.state.fridgeItems)
      } else {
        Text("Loading...")
      }
    }
  }
}
