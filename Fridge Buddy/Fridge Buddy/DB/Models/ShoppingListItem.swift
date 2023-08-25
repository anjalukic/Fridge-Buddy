//
//  ShoppingListItem.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation

public struct ShoppingListItem: Equatable, Identifiable, Nameable {
  public typealias ID = UUID
  
  public var id: ID
  public var groceryItemId: GroceryItem.ID
  public var amount: Double
  public var unit: Unit.ID
  
  // unwrapped properties
  public var name: String
  
  public init(
    id: ID,
    groceryItemId: GroceryItem.ID,
    amount: Double,
    unit: Unit.ID,
    name: String
  ) {
    self.id = id
    self.groceryItemId = groceryItemId
    self.amount = amount
    self.unit = unit
    self.name = name
  }
  
  public init(
    id: ID, groceryItem: GroceryItem, amount: Double, unit: Unit) {
      self.init(
        id: id,
        groceryItemId: groceryItem.id,
        amount: amount,
        unit: unit.id,
        name: groceryItem.name
      )
  }
  
  var debugDescription: String {
    "\(self.id): groceryItemId \(self.groceryItemId), name \(self.name), amount \(self.amount), unit: \(self.unit)"
  }
}

public extension ShoppingListItem {
  static let eggs: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!, groceryItem: .egg, amount: 2, unit: .pcs)
  
  static let startingItems: [ShoppingListItem] = [
    .eggs
  ]
}
