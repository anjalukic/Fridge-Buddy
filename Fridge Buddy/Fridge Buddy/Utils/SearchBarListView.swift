//
//  SearchBarListView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 25.5.23..
//

import SwiftUI
import Combine

public protocol Nameable {
  var name: String { get }
}

public struct SearchBarListView<Item: Equatable & Identifiable & Nameable>: View {
  private let numberOfRowsShown = 3
  
  @State private var isEditing: Bool = false
  @State private var inputText: String
  @State private var size: CGSize = .zero
  private let items: [Item]
  private let onSelect: (Item) -> Void
  private let onCommit: (String) -> Void
  private let placeholderText: String
  
  private var filteredItems: [Item] {
    return self.items.filter { $0.name.contains(self.inputText) && $0.name.prefix(1) == self.inputText.prefix(1) }
  }
  
  public init(
    listItems: [Item], placeholderText: String,
    onSelect: @escaping (Item) -> Void = { _ in }, onCommit: @escaping (String) -> Void = { _ in },
    selectedName: String = ""
  ) {
    self.items = listItems
    self.placeholderText = placeholderText
    self.onSelect = onSelect
    self.onCommit = onCommit
    self.inputText = selectedName
  }
  
  public var body: some View {
    VStack() {
      self.textField
      self.searchList
        .frame(maxHeight: self.isEditing ? .infinity : 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var textField: some View {
    TextField(
      self.placeholderText,
      text: self.$inputText,
      onEditingChanged: { isEditing in self.isEditing = isEditing },
      onCommit: { self.onCommit(self.inputText) }
    )
    .autocorrectionDisabled(true)
  }
  
  private var searchList: some View {
    ScrollView {
      VStack(spacing: 0) {
        ForEach(Array(zip(self.filteredItems.indices, self.filteredItems)), id: \.0) { index, item in
          VStack(spacing: 0) {
            Text(item.name)
              .foregroundColor(Color.init("AppetiteRed"))
              .padding(.vertical, 4)
              .frame(maxWidth: .infinity, alignment: .leading)
              .onTapGesture(perform: {
                self.inputText = item.name
                self.isEditing = false
                self.unfocus()
                self.onSelect(item)
              })
              .saveSize(in: self.$size)
            
            if index < self.filteredItems.count - 1 {
              Divider()
            }
          }
        }
      }
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: self.size.height * CGFloat(self.filteredItems.count > self.numberOfRowsShown ? self.numberOfRowsShown : self.filteredItems.count)
    )
  }
}

public extension View {
  func unfocus() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
