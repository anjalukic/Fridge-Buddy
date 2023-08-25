//
//  FridgeItem.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation

public struct RecipeStep: Equatable, Identifiable {
  public typealias ID = UUID
  
  public var id: ID
  public var recipeId: Recipe.ID
  public var description: String
  public var index: Int
  public var timerDuration: TimeInterval?
  
  public init(
    id: ID,
    recipeId: Recipe.ID,
    description: String,
    index: Int,
    timerDuration: TimeInterval? = nil
  ) {
    self.id = id
    self.recipeId = recipeId
    self.description = description
    self.index = index
    self.timerDuration = timerDuration
  }
  
  var debugDescription: String {
    "\(self.id): recipeId \(self.recipeId), index \(self.index), description \(self.description), duration \(String(describing: self.timerDuration))"
  }
}

public extension RecipeStep {
  static let carbonara1st: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!, recipeId: Recipe.carbonara.id, description: "Cook the pasta", index: 0, timerDuration: .init(fromMinutes: 7))
  static let carbonara2nd: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000001")!, recipeId: Recipe.carbonara.id, description: "Cut the bacon into cubes", index: 1)
  static let carbonara3rd: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000002")!, recipeId: Recipe.carbonara.id, description: "Fry the bacon in a pan", index: 2, timerDuration: .init(fromMinutes: 1))
  
  static let startingItems: [RecipeStep] = [
    .carbonara1st, .carbonara2nd, .carbonara3rd
  ]
}

extension TimeInterval {
  init(fromMinutes minutes: Int) {
    self.init(minutes * 60)
  }
  
  var seconds: Int {
    return Int(self.rounded())
  }
  
  var minutes: Int {
    return self.seconds / 60
  }
  
  var description: String {
    let formatter = DateComponentsFormatter()

    formatter.unitsStyle = .positional
    formatter.zeroFormattingBehavior = .pad
    formatter.allowedUnits = [.minute, .second]
    
    return formatter.string(from: self)!
  }
  
  static func createTimeInterval(fromMinutes minutes: Int?) -> TimeInterval? {
    if let minutes {
      return .init(fromMinutes: minutes)
    } else {
      return nil
    }
  }
}
