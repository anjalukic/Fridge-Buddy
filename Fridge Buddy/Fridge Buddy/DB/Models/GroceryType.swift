//
//  GroceryType.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//
//
//import Foundation
//
//public struct GroceryType: Equatable, Identifiable, Nameable {
//  public typealias ID = String
//  
//  public let name: String
//  public let imageName: String
//  
//  public var id: String { self.name }
//  
//  public init(name: String, imageName: String? = nil) {
//    self.name = name
//    self.imageName = imageName ?? "noImage"
//  }
//  
//  var debugDescription: String {
//    "\(self.id): \(self.name), imageName: \(self.imageName)"
//  }
//}
//
//extension GroceryType: Hashable {
//  public func hash(into hasher: inout Hasher) {
//    hasher.combine(self.id)
//  }
//}
