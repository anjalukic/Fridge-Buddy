//
//  DBClient+GroceryItem.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation
import SQLite3

extension DBClient {
  func createRecipeItemTable() throws {
    let tableName = "RecipeItem"
    let createTableString =
    "CREATE TABLE IF NOT EXISTS \(tableName)(id TEXT PRIMARY KEY, recipeId TEXT, groceryItemId TEXT, amount DOUBLE, unit TEXT);"
    try self.createTable(statement: createTableString, tableName: tableName)
  }
  
  func initRecipeItemTable() throws {
    try RecipeItem.startingItems.forEach { try self.insertRecipeItem($0) }
  }
}

extension DBClient {
  func insertRecipeItem(_ recipeItem: RecipeItem) throws {
    let recipeItems = try self.readRecipeItem()
    try recipeItems.forEach { if $0.id == recipeItem.id { throw DBError.duplicateIdInsertError } }
    let insertStatementString =
    "INSERT INTO RecipeItem (id, recipeId, groceryItemId, amount, unit) VALUES (?, ?, ?, ?, ?);"
    var insertStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(insertStatement) }
    
    if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(insertStatement, 1, recipeItem.id.uuidString.utf8, -1, nil)
      sqlite3_bind_text(insertStatement, 2, recipeItem.recipeId.uuidString.utf8, -1, nil)
      sqlite3_bind_text(insertStatement, 3, recipeItem.groceryItemId.uuidString.utf8, -1, nil)
      sqlite3_bind_double(insertStatement, 4, recipeItem.amount)
      sqlite3_bind_text(insertStatement, 5, recipeItem.unit.utf8, -1, nil)

      if sqlite3_step(insertStatement) == SQLITE_DONE {
        print("Successfully inserted row to RecipeItem.")
      } else {
        throw DBError.insertionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func updateRecipeItem(_ recipeItem: RecipeItem) throws {
    let recipeItems = try self.readRecipeItem()
    guard recipeItems.contains(where: { $0.id == recipeItem.id}) else { throw DBError.updatingError }
    let updateStatementString =
    "UPDATE RecipeItem SET recipeId = ?, groceryItemId = ?, amount = ?, unit = ? WHERE id = ?;"
    var updateStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(updateStatement) }
    
    if sqlite3_prepare_v2(self.db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(updateStatement, 1, recipeItem.recipeId.uuidString.utf8, -1, nil)
      sqlite3_bind_text(updateStatement, 2, recipeItem.groceryItemId.uuidString.utf8, -1, nil)
      sqlite3_bind_double(updateStatement, 3, recipeItem.amount)
      sqlite3_bind_text(updateStatement, 4, recipeItem.unit.utf8, -1, nil)
      sqlite3_bind_text(updateStatement, 5, recipeItem.id.uuidString.utf8, -1, nil)

      if sqlite3_step(updateStatement) == SQLITE_DONE {
        print("Successfully updated row in RecipeItem.")
      } else {
        throw DBError.updatingError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func readRecipeItem(withDebugPrintOn: Bool = false) throws -> [RecipeItem] {
    let queryStatementString = """
    SELECT ri.id, ri.recipeId, ri.groceryItemId, ri.amount, ri.unit, gi.name FROM RecipeItem ri
    LEFT JOIN GroceryItem gi ON ri.groceryItemId = gi.id
    ;
    """
    var queryStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(queryStatement) }
    
    if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      var items : [RecipeItem] = []
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
        let recipeId = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
        let groceryItemId = String(describing: String(cString: sqlite3_column_text(queryStatement, 2)))
        let amount = sqlite3_column_double(queryStatement, 3)
        let unit = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
        let itemName = String(describing: String(cString: sqlite3_column_text(queryStatement, 5)))
        
        var recipeItem = RecipeItem(
          id: UUID(uuidString: id)!,
          recipeId: UUID(uuidString: recipeId)!,
          groceryItemId: UUID(uuidString: groceryItemId)!,
          amount: amount,
          unit: unit,
          name: itemName
        )
        items.append(recipeItem)
        
        if withDebugPrintOn {
          print("Recipe item: \(recipeItem.debugDescription)")
        }
      }
      return items
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteRecipeItem(id: RecipeItem.ID) throws {
    let deleteStatementStirng = "DELETE FROM RecipeItem WHERE id = ?;"
    var deleteStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(deleteStatement) }
    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        print("Successfully deleted row from RecipeItem.")
      } else {
        throw DBError.deletionError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteAllRecipeItemsFor(id: Recipe.ID) throws {
    let deleteStatementStirng = "DELETE FROM RecipeItem WHERE recipeId = ?;"
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
