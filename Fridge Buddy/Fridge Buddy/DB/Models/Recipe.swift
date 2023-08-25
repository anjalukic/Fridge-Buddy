//
//  GroceryItem.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation

public struct Recipe: Equatable, Identifiable, Nameable, Hashable {
  public typealias ID = UUID
  
  public let id: ID
  public var name: String
  public var yieldAmount: Int
  public var imageName: String
  
  public init(
    id: UUID,
    name: String,
    yieldAmount: Int,
    imageName: String? = nil
  ) {
    self.id = id
    self.name = name
    self.yieldAmount = yieldAmount
    self.imageName = imageName ?? "noImage"
  }
  
  var debugDescription: String {
    "\(self.id): \(self.name), imageName: \(self.imageName)"
  }
}

public extension Recipe {
  static let carbonara: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000020")!, name: "Carbonara", yieldAmount: 2, imageName: "Carbonara")
  static let friedEggs: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000021")!, name: "Fried eggs", yieldAmount: 1)
  static let creamyChicken: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000022")!, name: "Creamy chicken", yieldAmount: 4)
  
  static let startingRecipes: [Recipe] = [
    .carbonara, .friedEggs, .creamyChicken
  ]
}


