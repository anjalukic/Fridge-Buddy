////
////  DBClient+Unit.swift
////  Fridge Buddy
////
////  Created by Anja Lukic on 24.5.23..
////
//
//import Foundation
//import SQLite3
//
//extension DBClient {
//  func createUnitTable() throws {
//    let tableName = "Unit"
//    let createTableString =
//    "CREATE TABLE IF NOT EXISTS \(tableName)(id TEXT PRIMARY KEY, name TEXT);"
//    try self.createTable(statement: createTableString, tableName: tableName)
//  }
//  
//  func initUnitTable() throws {
//    try Unit.startingUnits.forEach { try self.insertUnit($0) }
//  }
//}
//
//extension DBClient {
//  func insertUnit(_ unit: Unit) throws {
//    let units = try self.readUnit()
//    try units.forEach { if unit.id == $0.id { throw DBError.duplicateIdInsertError} }
//    let insertStatementString =
//    "INSERT INTO Unit (id, name) VALUES (?, ?);"
//    var insertStatement: OpaquePointer? = nil
//    defer { sqlite3_finalize(insertStatement) }
//    
//    if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
//      sqlite3_bind_text(insertStatement, 1, unit.id.uuidString.utf8, -1, nil)
//      sqlite3_bind_text(insertStatement, 2, unit.name.utf8, -1, nil)
//      
//      if sqlite3_step(insertStatement) == SQLITE_DONE {
//        print("Successfully inserted row to Unit.")
//      } else {
//        throw DBError.insertionError
//      }
//    } else {
//      throw DBError.statementPreparationError
//    }
//  }
//  
//  func readUnit(withDebugPrintOn: Bool = false) throws -> [Unit] {
//    let queryStatementString = "SELECT id, name FROM Unit;"
//    var queryStatement: OpaquePointer? = nil
//    defer { sqlite3_finalize(queryStatement) }
//    
//    if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
//      var units : [Unit] = []
//      while sqlite3_step(queryStatement) == SQLITE_ROW {
//        let id = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
//        let name = String(cString: sqlite3_column_text(queryStatement, 1))
//        let unit = Unit(id: UUID(uuidString: id)!, name: name)
//        units.append(unit)
//        if withDebugPrintOn {
//          print("Unit: \(unit.debugDescription)")
//        }
//      }
//      return units
//    } else {
//      throw DBError.statementPreparationError
//    }
//  }
//  
//  func deleteUnit(id: Unit.ID) throws {
//    let deleteStatementStirng = "DELETE FROM Unit WHERE id = ?;"
//    var deleteStatement: OpaquePointer? = nil
//    defer { sqlite3_finalize(deleteStatement) }
//    
//    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
//      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
//      if sqlite3_step(deleteStatement) == SQLITE_DONE {
//        print("Successfully deleted row from Unit.")
//      } else {
//        throw DBError.deletionError
//      }
//    } else {
//      throw DBError.statementPreparationError
//    }
//  }
//}
