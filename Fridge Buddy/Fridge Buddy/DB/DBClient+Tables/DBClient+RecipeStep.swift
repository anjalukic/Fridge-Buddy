//
//  DBClient+Unit.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation
import SQLite3

extension DBClient {
  func createRecipeStepTable() throws {
    let tableName = "RecipeStep"
    let createTableString =
    "CREATE TABLE IF NOT EXISTS \(tableName)(id TEXT PRIMARY KEY, recipeId TEXT, description TEXT, stepIndex INT, timerDurationSeconds INT);"
    try self.createTable(statement: createTableString, tableName: tableName)
  }
  
  func initRecipeStepTable() throws {
    try RecipeStep.startingItems.forEach { try self.insertRecipeStep($0) }
  }
}

extension DBClient {
  func insertRecipeStep(_ recipeStep: RecipeStep) throws {
    let recipeSteps = try self.readRecipeStep()
    try recipeSteps.forEach { if recipeStep.id == $0.id { throw DBError.duplicateIdInsertError} }
    let insertStatementString =
    "INSERT INTO RecipeStep (id, recipeId, description, stepIndex, timerDurationSeconds) VALUES (?, ?, ?, ?, ?);"
    var insertStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(insertStatement) }
    
    if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(insertStatement, 1, recipeStep.id.uuidString.utf8, -1, nil)
      sqlite3_bind_text(insertStatement, 2, recipeStep.recipeId.uuidString.utf8, -1, nil)
      sqlite3_bind_text(insertStatement, 3, recipeStep.description.utf8, -1, nil)
      sqlite3_bind_int(insertStatement, 4, Int32(recipeStep.index))
      if let seconds = recipeStep.timerDuration?.seconds {
        sqlite3_bind_int(insertStatement, 5, Int32(seconds))
      } else {
        sqlite3_bind_null(insertStatement, 5)
      }
      
      if sqlite3_step(insertStatement) == SQLITE_DONE {
        print("Successfully inserted row to RecipeStep.")
      } else {
        throw DBError.insertionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func readRecipeStep(withDebugPrintOn: Bool = false) throws -> [RecipeStep] {
    let queryStatementString = "SELECT id, recipeId, description, stepIndex, timerDurationSeconds FROM RecipeStep;"
    var queryStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(queryStatement) }
    
    if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      var recipeSteps : [RecipeStep] = []
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
        let recipeId = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
        let description = String(cString: sqlite3_column_text(queryStatement, 2))
        let index = Int(sqlite3_column_int(queryStatement, 3))
        let seconds: TimeInterval?
        if sqlite3_column_type(queryStatement, 4) == 1 {
          seconds = TimeInterval(sqlite3_column_int(queryStatement, 4))
        } else {
          seconds = nil
        }
        let recipeStep = RecipeStep(
          id: UUID(uuidString: id)!,
          recipeId: UUID(uuidString: recipeId)!,
          description: description,
          index: index,
          timerDuration: seconds
        )
        recipeSteps.append(recipeStep)
        if withDebugPrintOn {
          print("RecipeStep: \(recipeStep.debugDescription)")
        }
      }
      return recipeSteps
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteRecipeStep(id: RecipeStep.ID) throws {
    let deleteStatementStirng = "DELETE FROM RecipeStep WHERE id = ?;"
    var deleteStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(deleteStatement) }
    
    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        print("Successfully deleted row from RecipeStep.")
      } else {
        throw DBError.deletionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteAllRecipeStepsFor(id: Recipe.ID) throws {
    let deleteStatementStirng = "DELETE FROM RecipeStep WHERE recipeId = ?;"
    var deleteStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(deleteStatement) }
    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        print("Successfully deleted row(s) from RecipeItem.")
      } else {
        throw DBError.deletionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
}
