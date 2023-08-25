////
////  DBClient+GroceryItem.swift
////  Fridge Buddy
////
////  Created by Anja Lukic on 24.5.23..
////
//
//import Foundation
//import SQLite3
//
//extension DBClient {
//  func createGroceryTypeTable() throws {
//    let tableName = "GroceryType"
//    let createTableString =
//    "CREATE TABLE IF NOT EXISTS \(tableName)(name TEXT PRIMARY KEY, imageName TEXT);"
//    try self.createTable(statement: createTableString, tableName: tableName)
//  }
//  
//  func initGroceryTypeTable() throws {
//    try GroceryType.startingGroceryTypes.forEach { try self.insertGroceryType($0) }
//  }
//}
//
//extension DBClient {
//  func insertGroceryType(_ groceryType: GroceryType) throws {
//    let groceryTypes = try self.readGroceryType()
//    try groceryTypes.forEach { if $0.id == groceryType.id { throw DBClient.DBError.duplicateIdInsertError } }
//    
//    let insertStatementString =
//    "INSERT INTO GroceryType (id, name, imageName) VALUES (?, ?, ?);"
//    var insertStatement: OpaquePointer? = nil
//    defer { sqlite3_finalize(insertStatement) }
//    
//    if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
//      sqlite3_bind_text(insertStatement, 1, groceryType.id.uuidString.utf8, -1, nil)
//      sqlite3_bind_text(insertStatement, 2, groceryType.name.utf8, -1, nil)
//      sqlite3_bind_text(insertStatement, 3, groceryType.imageName.utf8, -1, nil)
//      
//      if sqlite3_step(insertStatement) == SQLITE_DONE {
//        print("Successfully inserted row to GroceryType.")
//      } else {
//        throw DBError.insertionError
//      }
//    } else {
//      throw DBError.statementPreparationError
//    }
//  }
//  
//  func readGroceryType(withDebugPrintOn: Bool = false) throws -> [GroceryType] {
//    let queryStatementString = "SELECT id, name, imageName FROM GroceryType;"
//    var queryStatement: OpaquePointer? = nil
//    defer { sqlite3_finalize(queryStatement) }
//    
//    if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
//      var groceryTypes: [GroceryType] = []
//      while sqlite3_step(queryStatement) == SQLITE_ROW {
//        let id = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
//        let name = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
//        let imageName = String(describing: String(cString: sqlite3_column_text(queryStatement, 2)))
//        let groceryType = GroceryType(id: UUID(uuidString: id)!, name: name, imageName: imageName)
//        groceryTypes.append(groceryType)
//        if withDebugPrintOn {
//          print("Grocery type: \(groceryType.debugDescription)")
//        }
//      }
//      return groceryTypes
//    } else {
//      throw DBError.statementPreparationError
//    }
//  }
//  
//  func deleteGroceryType(id: GroceryType.ID) throws {
//    let deleteStatementStirng = "DELETE FROM GroceryType WHERE id = ?;"
//    var deleteStatement: OpaquePointer? = nil
//    defer { sqlite3_finalize(deleteStatement) }
//    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
//      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
//      if sqlite3_step(deleteStatement) == SQLITE_DONE {
//        print("Successfully deleted row from GroceryType.")
//      } else {
//        throw DBError.deletionError
//      }
//    } else {
//      throw DBError.statementPreparationError
//    }
//  }
//}
