//
//  PlannedMeal.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation

public struct PlannedMeal: Equatable, Identifiable, Nameable {
  public typealias ID = UUID
  
  public var id: ID
  public var recipeId: Recipe.ID
  public var mealType: Meal
  public var date: Date
  
  // unwrapped properties
  public var recipeName: String
  
  public init(
    id: ID,
    recipeId: Recipe.ID,
    mealType: Meal,
    date: Date,
    recipeName: String
  ) {
    self.id = id
    self.recipeId = recipeId
    self.mealType = mealType
    self.date = date
    self.recipeName = recipeName
  }
  
  public init(
    id: ID, recipe: Recipe, mealType: Meal, date: Date) {
      self.init(
        id: id,
        recipeId: recipe.id,
        mealType: mealType,
        date: date,
        recipeName: recipe.name
      )
  }
  
  var debugDescription: String {
    "\(self.id): date \(self.date), recipeId \(self.recipeId), recipeName \(self.recipeName), meal \(self.mealType)"
  }
  
  public var name: String { self.recipeName }
}

public extension PlannedMeal {
  enum Meal: Int, CaseIterable, Identifiable {
    case breakfast = 0
    case lunch
    case dinner
    
    var title: String {
      switch self {
      case .breakfast: return "Breakfast"
      case .lunch: return "Lunch"
      case .dinner: return "Dinner"
      }
    }
    
    public var id: Self { return self }
  }
}

public extension PlannedMeal {
  static let plannedBreakfast: Self = .init(id: .init(uuidString: "00000000-0000-0000-0000-000000000000")!, recipe: .friedEggs, mealType: .breakfast, date: Date(timeIntervalSince1970: .init(1692284775)))
  
  static let startingItems: [PlannedMeal] = [.plannedBreakfast]
}
