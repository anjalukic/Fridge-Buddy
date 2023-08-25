//
//  FridgeItem.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation

public struct RecipeItem: Equatable, Identifiable, Nameable {
  public typealias ID = UUID
  
  public var id: ID
  public var recipeId: Recipe.ID
  public var groceryItemId: GroceryItem.ID
  public var amount: Double
  public var unit: Unit.ID
  
  // unwrapped properties
  public var name: String
  
  public init(
    id: ID,
    recipeId: Recipe.ID,
    groceryItemId: GroceryItem.ID,
    amount: Double,
    unit: Unit.ID,
    name: String
  ) {
    self.id = id
    self.recipeId = recipeId
    self.groceryItemId = groceryItemId
    self.amount = amount
    self.name = name
    self.unit = unit
  }
  
  public init(
    id: ID, recipe: Recipe, groceryItem: GroceryItem, amount: Double, unit: Unit) {
      self.init(
        id: id,
        recipeId: recipe.id,
        groceryItemId: groceryItem.id,
        amount: amount,
        unit: unit.id,
        name: groceryItem.name
      )
  }
  
  var debugDescription: String {
    "\(self.id): recipeId \(self.recipeId), groceryItemId \(self.groceryItemId), name \(self.name), amount \(self.amount), unitId: \(self.unit)"
  }
}

public extension RecipeItem {
  static let eggsCarbonara: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!, recipe: .carbonara, groceryItem: .egg, amount: 2, unit: .pcs)
  static let baconCarbonara: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000001")!, recipe: .carbonara, groceryItem: .bacon, amount: 200, unit: .g)
  static let eggsFried: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000002")!, recipe: .friedEggs, groceryItem: .egg, amount: 4, unit: .pcs)
  static let chickenCreamy: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000003")!, recipe: .creamyChicken, groceryItem: .chickenBreast, amount: 500, unit: .g)
  static let gaudaCreamyChicken: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000004")!, recipe: .creamyChicken, groceryItem: .gauda, amount: 200, unit: .g)
  
  static let startingItems: [RecipeItem] = [
    .eggsCarbonara, .baconCarbonara, .eggsFried, .chickenCreamy, .gaudaCreamyChicken
  ]
}
