//
//  FridgeItem.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation

public struct FridgeItem: Equatable, Identifiable, Nameable {
  public typealias ID = UUID
  
  public var id: ID
  public var groceryItemId: GroceryItem.ID
  public var expirationDate: Date
  public var amount: Double
  public var unit: Unit.ID
  
  // unwrapped properties
  public var name: String
  public var imageName: String
  public var groceryType: String
  
  public init(
    id: ID,
    groceryItemId: GroceryItem.ID,
    expirationDate: Date,
    amount: Double,
    unit: Unit.ID,
    name: String,
    imageName: String,
    groceryType: String
  ) {
    self.id = id
    self.groceryItemId = groceryItemId
    self.expirationDate = expirationDate
    self.amount = amount
    self.unit = unit
    self.name = name
    self.imageName = imageName
    self.groceryType = groceryType
  }
  
  public init(
    id: ID, groceryItem: GroceryItem, expirationDate: Date, amount: Double, unit: Unit) {
      self.init(
        id: id,
        groceryItemId: groceryItem.id,
        expirationDate: expirationDate,
        amount: amount,
        unit: unit.id,
        name: groceryItem.name,
        imageName: groceryItem.imageName,
        groceryType: groceryItem.type
      )
  }
  
  var debugDescription: String {
    "\(self.id): groceryItemId \(self.groceryItemId), name \(self.name), amount \(self.amount), unit: \(self.unit), expirationDate: \(self.expirationDate)"
  }
}

public extension FridgeItem {
  static let apples: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!, groceryItem: .apple, expirationDate: Date(), amount: 5, unit: .pcs)
  static let milk: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000001")!, groceryItem: .milk, expirationDate: Date(), amount: 1, unit: .l)
  static let tomatoes: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000002")!, groceryItem: .tomato, expirationDate: Date(), amount: 3, unit: .pcs)
  
  static let startingItems: [FridgeItem] = [
    .apples, .milk, .tomatoes
  ]
}
