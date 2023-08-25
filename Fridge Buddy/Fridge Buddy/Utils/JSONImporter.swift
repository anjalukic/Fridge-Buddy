//
//  JSONImporter.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.8.23..
//

import Foundation

enum JSONImporter {
  static func load(fileName: String) -> [String: Any]? {
    do {
      let fileManager = FileManager.default
      
      if let bundlePath = Bundle.main.path(forResource: fileName, ofType: "json"),
         let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
        if let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any] {
          return dictionary
        } else {
          print("Given JSON is not a valid dictionary object.")
          return nil
        }
      }
    } catch {
      print(error)
      return nil
    }
    return nil
  }
  
  static let groceryItems: [String: [String: Any]]? = JSONImporter.load(fileName: "groceryItems") as? [String: [String: Any]]
  static let groceryItemsSr: [String: String]? = JSONImporter.load(fileName: "groceryItemsSr") as? [String: String]
}
