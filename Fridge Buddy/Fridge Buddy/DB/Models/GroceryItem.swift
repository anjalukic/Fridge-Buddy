//
//  GroceryItem.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation

public struct GroceryItem: Equatable, Identifiable, Nameable {
  public typealias ID = UUID
  
  public let id: ID
  public let name: String
  public let defaultExpirationInterval: TimeInterval
  public let imageName: String
  public let type: String
  
  public init(
    id: UUID,
    name: String,
    defaultExpirationInterval: TimeInterval,
    type: String,
    imageName: String? = nil
  ) {
    self.id = id
    self.name = name
    self.defaultExpirationInterval = defaultExpirationInterval
    self.type = type
    self.imageName = imageName ?? "noImage"
  }
  
  var debugDescription: String {
    "\(self.id): \(self.name), defExpInterval: \(self.defaultExpirationInterval), imageName: \(self.imageName), type: \(self.type)"
  }
  
  static let groceryTypes: [String] = {
    guard
      let groceries = JSONImporter.groceryItems
    else { return [] }
    let groceriesInfos = Array(groceries.values)
    var groceryTypes = groceriesInfos.map { dict -> String? in
      guard let type = dict["type"] as? String else { return nil }
      return type
    }.compactMap { $0 }
    
    var deduplicated: Set<String> = .init(groceryTypes)
    deduplicated.insert("Dishes")
    
    return Array(deduplicated)
  }()
}

extension TimeInterval {
  init(fromDays days: Int) {
    self.init(days * 24 * 60 * 60)
  }
}

public extension GroceryItem {
  static let apple: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!, name: "Apple", defaultExpirationInterval: .init(fromDays: 7), type: "Fruits")
  static let chickenBreast: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Chicken breast", defaultExpirationInterval: .init(fromDays: 5), type: "Meat")
  static let gauda: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Gauda", defaultExpirationInterval: .init(fromDays: 5), type: "Dairy")
  static let milk: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Milk", defaultExpirationInterval: .init(fromDays: 5), type: "Dairy")
  static let tomato: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "Tomato", defaultExpirationInterval: .init(fromDays: 5), type: "Vegetables")
  static let cucumber: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000005")!, name: "Cucumber", defaultExpirationInterval: .init(fromDays: 5), type: "Vegetables")
  static let mayonnaise: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000006")!, name: "Mayonnaise", defaultExpirationInterval: .init(fromDays: 5), type: "Condiments")
  static let bread: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000007")!, name: "Bread", defaultExpirationInterval: .init(fromDays: 2), type: "Bakery")
  static let egg: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000008")!, name: "Egg", defaultExpirationInterval: .init(fromDays: 7), type: "Dairy")
  static let bacon: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000009")!, name: "Bacon", defaultExpirationInterval: .init(fromDays: 10), type: "Meat")
  
  static let startingGroceryItems: [GroceryItem] = [
    .apple, .chickenBreast, .gauda, .milk, .tomato, .cucumber, .mayonnaise, .bread, .egg, bacon
  ]
}


