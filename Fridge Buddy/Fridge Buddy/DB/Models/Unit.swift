//
//  Unit.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation

public struct Unit: Identifiable, Nameable, Equatable {
  public typealias ID = String
  
  public let name: String
  
  public var id: ID { self.name }
  
  public init(name: String) {
    self.name = name
  }
  
  var debugDescription: String {
    "\(self.name)"
  }
  
  func isComparable(with unit: String) -> Bool {
    return self.comparables.contains(unit)
  }
  
  var comparables: [String] {
    switch self.name {
    case "g", "kg": return ["g", "kg"]
    case "l", "ml": return ["l", "ml"]
    case "portions": return ["portions"]
    case "pcs": return ["pcs"]
    default: return []
    }
  }
}

public extension Unit {
  static let pcs: Self = .init(name: "pcs")
  static let g: Self = .init(name: "g")
  static let portions: Self = .init(name: "portions")
  static let kg: Self = .init(name: "kg")
  static let ml: Self = .init(name: "ml")
  static let l: Self = .init(name: "l")
  
  static let startingUnits: [Unit] = [.pcs, .portions, .g, .kg, .ml, .l]
}

// Helper struct
struct AmountWithUnit: Equatable {
  var amount: Double
  var unit: String
  
  init(amount: Double, unit: String) {
    self.amount = amount
    self.unit = unit
    convertToBasicUnit()
  }
  
  mutating func convertToBasicUnit() {
    switch self.unit {
    case "portions", "pcs", "g", "ml": return
    case "kg":
      self.amount = self.amount * 1000
      self.unit = "g"
    case "l":
      self.amount = self.amount * 1000
      self.unit = "ml"
    default: return
    }
  }
}
