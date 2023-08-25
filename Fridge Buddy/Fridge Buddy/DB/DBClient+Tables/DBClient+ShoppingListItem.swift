//
//  DBClient+ShoppingListItem.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation
import SQLite3

extension DBClient {
  func createShoppingListItemTable() throws {
    let tableName = "ShoppingListItem"
    let createTableString =
    "CREATE TABLE IF NOT EXISTS \(tableName)(id TEXT PRIMARY KEY, groceryItemId TEXT, amount DOUBLE, unit TEXT);"
    try self.createTable(statement: createTableString, tableName: tableName)
  }
  
  func initShoppingListItemTable() throws {
    try ShoppingListItem.startingItems.forEach { try self.insertShoppingListItem($0) }
  }
}

extension DBClient {
  func insertShoppingListItem(_ item: ShoppingListItem) throws {
    let items = try self.readShoppingListItem()
    try items.forEach { if $0.id == item.id { throw DBError.duplicateIdInsertError } }
    let insertStatementString =
    "INSERT INTO ShoppingListItem (id, groceryItemId, amount, unit) VALUES (?, ?, ?, ?);"
    var insertStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(insertStatement) }
    
    if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(insertStatement, 1, item.id.uuidString.utf8, -1, nil)
      sqlite3_bind_text(insertStatement, 2, item.groceryItemId.uuidString.utf8, -1, nil)
      sqlite3_bind_double(insertStatement, 3, item.amount)
      sqlite3_bind_text(insertStatement, 4, item.unit.utf8, -1, nil)

      if sqlite3_step(insertStatement) == SQLITE_DONE {
        print("Successfully inserted row to ShoppingListItem.")
      } else {
        throw DBError.insertionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func updateShoppingListItem(_ item: ShoppingListItem) throws {
    let items = try self.readShoppingListItem()
    guard items.contains(where: { $0.id == item.id}) else { throw DBError.updatingError }
    let updateStatementString =
    "UPDATE ShoppingListItem SET groceryItemId = ?, amount = ?, unit = ? WHERE id = ?;"
    var updateStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(updateStatement) }
    
    if sqlite3_prepare_v2(self.db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(updateStatement, 1, item.groceryItemId.uuidString.utf8, -1, nil)
      sqlite3_bind_double(updateStatement, 2, item.amount)
      sqlite3_bind_text(updateStatement, 3, item.unit.utf8, -1, nil)
      sqlite3_bind_text(updateStatement, 4, item.id.uuidString.utf8, -1, nil)

      if sqlite3_step(updateStatement) == SQLITE_DONE {
        print("Successfully updated row in ShoppingListItem.")
      } else {
        throw DBError.updatingError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func readShoppingListItem(withDebugPrintOn: Bool = false) throws -> [ShoppingListItem] {
    let queryStatementString = """
    SELECT si.id, si.groceryItemId, si.amount, si.unit, gi.name FROM ShoppingListItem si
    LEFT JOIN GroceryItem gi ON si.groceryItemId = gi.id
    ;
    """
    var queryStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(queryStatement) }
    
    if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      var items : [ShoppingListItem] = []
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
        let groceryItemId = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
        let amount = sqlite3_column_double(queryStatement, 2)
        let unit = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
        let itemName = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
        
        var item = ShoppingListItem(
          id: UUID(uuidString: id)!,
          groceryItemId: UUID(uuidString: groceryItemId)!,
          amount: amount,
          unit: unit,
          name: itemName
        )
        items.append(item)
        
        if withDebugPrintOn {
          print("Shopping list item: \(item.debugDescription)")
        }
      }
      return items
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteShoppingListItem(id: ShoppingListItem.ID) throws {
    let deleteStatementStirng = "DELETE FROM ShoppingListItem WHERE id = ?;"
    var deleteStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(deleteStatement) }
    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        print("Successfully deleted row from ShoppingListItem.")
      } else {
        throw DBError.deletionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteAllShoppingListItems() throws {
    let deleteStatementStirng = "DELETE FROM ShoppingListItem;"
    var deleteStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(deleteStatement) }
    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        print("Successfully deleted all rows from ShoppingListItem.")
      } else {
        throw DBError.deletionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteAllShoppingListItems(for id: GroceryItem.ID) throws {
    let deleteStatementStirng = "DELETE FROM ShoppingListItem WHERE groceryItemId = ?;"
    var deleteStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(deleteStatement) }
    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        print("Successfully deleted row from ShoppingListItem.")
      } else {
        throw DBError.deletionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
}
