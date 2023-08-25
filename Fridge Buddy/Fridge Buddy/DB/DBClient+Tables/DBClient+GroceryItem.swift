//
//  DBClient+GroceryItem.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation
import SQLite3

extension DBClient {
  func createGroceryItemTable() throws {
    let tableName = "GroceryItem"
    let createTableString =
    "CREATE TABLE IF NOT EXISTS \(tableName)(id TEXT PRIMARY KEY, name TEXT, defaultExpInterval INTEGER, imageName TEXT, type TEXT);"
    try self.createTable(statement: createTableString, tableName: tableName)
  }
  
  func initGroceryItemTable() throws {
    // TODO: Remove this
    try GroceryItem.startingGroceryItems.forEach { try self.insertGroceryItem($0) }
    
    guard let rawGroceryItems = JSONImporter.groceryItems else { throw DBClient.DBError.insertionError }
    
    let groceryItems: [GroceryItem] = rawGroceryItems.map { (itemId, itemInfo) in
      guard let name = itemInfo["name"] as? String,
            let defaultExpirationInterval = itemInfo["defaultExpInterval"] as? Int,
            let type = itemInfo["type"] as? String,
            let imageName = itemInfo["imageName"] as? String
      else { return nil }
      return GroceryItem(
        id: UUID(uuidString: itemId)!,
        name: name,
        defaultExpirationInterval: TimeInterval(defaultExpirationInterval),
        type: type,
        imageName: imageName
      )
    }.compactMap { $0 }
    try groceryItems.forEach { try self.insertGroceryItem($0) }
  }
}

extension DBClient {
  func insertGroceryItem(_ groceryItem: GroceryItem) throws {
    let groceryItems = try self.readGroceryItem()
    try groceryItems.forEach { if $0.id == groceryItem.id { throw DBError.duplicateIdInsertError } }
    let insertStatementString =
    "INSERT INTO GroceryItem (id, name, defaultExpInterval, imageName, type) VALUES (?, ?, ?, ?, ?);"
    var insertStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(insertStatement) }
    
    if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(insertStatement, 1, groceryItem.id.uuidString.utf8, -1, nil)
      sqlite3_bind_text(insertStatement, 2, groceryItem.name.utf8, -1, nil)
      sqlite3_bind_int(insertStatement, 3, Int32(groceryItem.defaultExpirationInterval))
      sqlite3_bind_text(insertStatement, 4, groceryItem.imageName.utf8, -1, nil)
      sqlite3_bind_text(insertStatement, 5, groceryItem.type.utf8, -1, nil)
      
      if sqlite3_step(insertStatement) == SQLITE_DONE {
        print("Successfully inserted row to GroceryItem.")
      } else {
        throw DBError.insertionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func readGroceryItem(withDebugPrintOn: Bool = false) throws -> [GroceryItem] {
    let queryStatementString = """
    SELECT i.id, i.name, i.defaultExpInterval, i.imageName, i.type FROM groceryItem i
    ;
    """
    var queryStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(queryStatement) }
    
    if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      var items : [GroceryItem] = []
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
        let name = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
        let defaultExpInt = sqlite3_column_int(queryStatement, 2)
        let imageName = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
        let type = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
        var groceryItem = GroceryItem(
          id: UUID(uuidString: id)!,
          name: name,
          defaultExpirationInterval: .init(defaultExpInt),
          type: type,
          imageName: imageName
        )
        items.append(groceryItem)
        if withDebugPrintOn {
          print("Grocery item: \(groceryItem.debugDescription)")
        }
      }
      return items
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func updateGroceryItem(_ item: GroceryItem) throws {
    let items = try self.readGroceryItem()
    guard items.contains(where: { $0.id == item.id}) else { throw DBError.updatingError }
    let updateStatementString =
    "UPDATE GroceryItem SET name = ?, defaultExpInterval = ?, imageName = ?, type = ? WHERE id = ?;"
    var updateStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(updateStatement) }
    
    if sqlite3_prepare_v2(self.db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(updateStatement, 1, item.name.utf8, -1, nil)
      sqlite3_bind_int(updateStatement, 2, Int32(item.defaultExpirationInterval))
      sqlite3_bind_text(updateStatement, 3, item.imageName.utf8, -1, nil)
      sqlite3_bind_text(updateStatement, 4, item.type.utf8, -1, nil)
      sqlite3_bind_text(updateStatement, 5, item.id.uuidString.utf8, -1, nil)

      if sqlite3_step(updateStatement) == SQLITE_DONE {
        print("Successfully updated row in GroceryItem.")
      } else {
        throw DBError.updatingError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteGroceryItem(id: GroceryItem.ID) throws {
    let deleteStatementStirng = "DELETE FROM groceryItem WHERE id = ?;"
    var deleteStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(deleteStatement) }
    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        print("Successfully deleted row from GroceryItem.")
      } else {
        throw DBError.deletionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
}
