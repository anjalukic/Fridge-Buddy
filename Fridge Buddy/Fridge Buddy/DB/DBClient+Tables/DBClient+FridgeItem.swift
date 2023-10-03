//
//  DBClient+GroceryItem.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation
import SQLite3

extension DBClient {
  func createFridgeItemTable() throws {
    let tableName = "FridgeItem"
    let createTableString =
    "CREATE TABLE IF NOT EXISTS \(tableName)(id TEXT PRIMARY KEY, groceryItemId TEXT, expDate TEXT, amount DOUBLE, unit TEXT);"
    try self.createTable(statement: createTableString, tableName: tableName)
  }
  
  func initFridgeItemTable() throws {
    try FridgeItem.startingItems.forEach { try self.insertFridgeItem($0) }
  }
}

extension DBClient {
  func insertFridgeItem(_ fridgeItem: FridgeItem) throws {
    let fridgeItems = try self.readFridgeItem()
    try fridgeItems.forEach { if $0.id == fridgeItem.id { throw DBError.duplicateIdInsertError } }
    let insertStatementString =
    "INSERT INTO FridgeItem (id, groceryItemId, expDate, amount, unit) VALUES (?, ?, DATETIME(?), ?, ?);"
    var insertStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(insertStatement) }
    
    if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(insertStatement, 1, fridgeItem.id.uuidString.utf8, -1, nil)
      sqlite3_bind_text(insertStatement, 2, fridgeItem.groceryItemId.uuidString.utf8, -1, nil)
      sqlite3_bind_text(insertStatement, 3, fridgeItem.expirationDate.toString().utf8, -1, nil)
      sqlite3_bind_double(insertStatement, 4, fridgeItem.amount)
      sqlite3_bind_text(insertStatement, 5, fridgeItem.unit.utf8, -1, nil)

      if sqlite3_step(insertStatement) == SQLITE_DONE {
        print("Successfully inserted row to FridgeItem.")
      } else {
        throw DBError.insertionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func updateFridgeItem(_ fridgeItem: FridgeItem) throws {
    let fridgeItems = try self.readFridgeItem()
    guard fridgeItems.contains(where: { $0.id == fridgeItem.id}) else { throw DBError.updatingError }
    let updateStatementString =
    "UPDATE FridgeItem SET groceryItemId = ?, expDate = DATETIME(?), amount = ?, unit = ? WHERE id = ?;"
    var updateStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(updateStatement) }
    
    if sqlite3_prepare_v2(self.db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(updateStatement, 1, fridgeItem.groceryItemId.uuidString.utf8, -1, nil)
      sqlite3_bind_text(updateStatement, 2, fridgeItem.expirationDate.toString().utf8, -1, nil)
      sqlite3_bind_double(updateStatement, 3, fridgeItem.amount)
      sqlite3_bind_text(updateStatement, 4, fridgeItem.unit.utf8, -1, nil)
      sqlite3_bind_text(updateStatement, 5, fridgeItem.id.uuidString.utf8, -1, nil)

      if sqlite3_step(updateStatement) == SQLITE_DONE {
        print("Successfully updated row in FridgeItem.")
      } else {
        throw DBError.updatingError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func readFridgeItem(withDebugPrintOn: Bool = false) throws -> [FridgeItem] {
    let queryStatementString = """
    SELECT fi.id, fi.groceryItemId, fi.expDate, fi.amount, fi.unit, gi.name, gi.imageName, gi.type FROM FridgeItem fi
    LEFT JOIN GroceryItem gi ON fi.groceryItemId = gi.id
    ;
    """
    var queryStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(queryStatement) }
    
    if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      var items : [FridgeItem] = []
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
        let groceryItemId = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
        let expDate = String(describing: String(cString: sqlite3_column_text(queryStatement, 2))).toDate()!
        let amount = sqlite3_column_double(queryStatement, 3)
        let unit = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
        let itemName = String(describing: String(cString: sqlite3_column_text(queryStatement, 5)))
        let imageName = String(describing: String(cString: sqlite3_column_text(queryStatement, 6)))
        let type = String(describing: String(cString: sqlite3_column_text(queryStatement, 7)))
        
        let fridgeItem = FridgeItem(
          id: UUID(uuidString: id)!,
          groceryItemId: UUID(uuidString: groceryItemId)!,
          expirationDate: expDate,
          amount: amount,
          unit: unit,
          name: itemName,
          imageName: imageName,
          groceryType: type
        )
        items.append(fridgeItem)
        
        if withDebugPrintOn {
          print("Fridge item: \(fridgeItem.debugDescription)")
        }
      }
      return items
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteFridgeItem(id: FridgeItem.ID) throws {
    let deleteStatementStirng = "DELETE FROM FridgeItem WHERE id = ?;"
    var deleteStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(deleteStatement) }
    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        print("Successfully deleted row from FridgeItem.")
      } else {
        throw DBError.deletionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func insertFridgeItems(_ fridgeItems: [FridgeItem]) throws {
    let existingFridgeItems = try self.readFridgeItem()
    let newIds = fridgeItems.map { $0.id }
    try existingFridgeItems.forEach { if newIds.contains($0.id) { throw DBError.duplicateIdInsertError } }
    var insertStatementString =
    "INSERT INTO FridgeItem (id, groceryItemId, expDate, amount, unit) VALUES "
    var values = Array.init(repeating: "(?, ?, DATETIME(?), ?, ?)", count: fridgeItems.count).joined(separator: ", ")
    values.append(";")
    insertStatementString.append(values)
    var insertStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(insertStatement) }
    
    if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      
      for (i, item) in fridgeItems.enumerated() {
        sqlite3_bind_text(insertStatement, Int32(i * 5 + 1), item.id.uuidString.utf8, -1, nil)
        sqlite3_bind_text(insertStatement, Int32(i * 5 + 2), item.groceryItemId.uuidString.utf8, -1, nil)
        sqlite3_bind_text(insertStatement, Int32(i * 5 + 3), item.expirationDate.toString().utf8, -1, nil)
        sqlite3_bind_double(insertStatement, Int32(i * 5 + 4), item.amount)
        sqlite3_bind_text(insertStatement, Int32(i * 5 + 5), item.unit.utf8, -1, nil)
      }
      print(insertStatementString)
      let result = sqlite3_step(insertStatement)
      if result == SQLITE_DONE {
        print("Successfully inserted \(fridgeItems.count) rows to FridgeItem.")
      } else {
        throw DBError.insertionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
}
