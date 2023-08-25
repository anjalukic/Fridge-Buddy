//
//  DBClient+PlannedMeal.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation
import SQLite3

extension DBClient {
  func createPlannedMealTable() throws {
    let tableName = "PlannedMeal"
    let createTableString =
    "CREATE TABLE IF NOT EXISTS \(tableName)(id TEXT PRIMARY KEY, recipeId TEXT, mealType Int, date TEXT);"
    try self.createTable(statement: createTableString, tableName: tableName)
  }
  
  func initPlannedMealTable() throws {
    try PlannedMeal.startingItems.forEach { try self.insertPlannedMeal($0) }
  }
}

extension DBClient {
  func insertPlannedMeal(_ item: PlannedMeal) throws {
    let items = try self.readPlannedMeal()
    try items.forEach { if $0.id == item.id { throw DBError.duplicateIdInsertError } }
    let insertStatementString =
    "INSERT INTO PlannedMeal (id, recipeId, mealType, date) VALUES (?, ?, ?, ?);"
    var insertStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(insertStatement) }
    
    if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(insertStatement, 1, item.id.uuidString.utf8, -1, nil)
      sqlite3_bind_text(insertStatement, 2, item.recipeId.uuidString.utf8, -1, nil)
      sqlite3_bind_int(insertStatement, 3, Int32(item.mealType.rawValue))
      sqlite3_bind_text(insertStatement, 4, item.date.toString().utf8, -1, nil)

      if sqlite3_step(insertStatement) == SQLITE_DONE {
        print("Successfully inserted row to PlannedMeal.")
      } else {
        throw DBError.insertionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func readPlannedMeal(withDebugPrintOn: Bool = false) throws -> [PlannedMeal] {
    let queryStatementString = """
    SELECT pm.id, pm.recipeId, pm.mealType, pm.date, r.name FROM PlannedMeal pm
    LEFT JOIN Recipe r ON pm.recipeId = r.id
    ;
    """
    var queryStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(queryStatement) }
    
    if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      var items : [PlannedMeal] = []
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
        let recipeId = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
        let mealType = PlannedMeal.Meal.init(rawValue: Int(sqlite3_column_int(queryStatement, 2)))!
        let date = String(describing: String(cString: sqlite3_column_text(queryStatement, 3))).toDate()!
        let recipeName = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
        
        let item = PlannedMeal(
          id: UUID(uuidString: id)!,
          recipeId: UUID(uuidString: recipeId)!,
          mealType: mealType,
          date: date,
          recipeName: recipeName
        )
        items.append(item)
        
        if withDebugPrintOn {
          print("Planned meal item: \(item.debugDescription)")
        }
      }
      return items
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deletePlannedMeal(id: PlannedMeal.ID) throws {
    let deleteStatementStirng = "DELETE FROM PlannedMeal WHERE id = ?;"
    var deleteStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(deleteStatement) }
    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        print("Successfully deleted row from PlannedMeal.")
      } else {
        throw DBError.deletionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteAllPlannedMealsFor(id: Recipe.ID) throws {
    let deleteStatementStirng = "DELETE FROM PlannedMeal WHERE recipeId = ?;"
    var deleteStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(deleteStatement) }
    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        print("Successfully deleted row(s) from PlannedMeal.")
      } else {
        throw DBError.deletionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
}
