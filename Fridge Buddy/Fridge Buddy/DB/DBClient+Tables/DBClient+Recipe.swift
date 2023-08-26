//
//  DBClient+Unit.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 24.5.23..
//

import Foundation
import SQLite3

extension DBClient {
  func createRecipeTable() throws {
    let tableName = "Recipe"
    let createTableString =
    "CREATE TABLE IF NOT EXISTS \(tableName)(id TEXT PRIMARY KEY, name TEXT, yieldAmount INT, image BLOB);"
    try self.createTable(statement: createTableString, tableName: tableName)
  }
  
  func initRecipeTable() throws {
    try Recipe.startingRecipes.forEach { try self.insertRecipe($0) }
  }
}

extension DBClient {
  func insertRecipe(_ recipe: Recipe) throws {
    let recipes = try self.readRecipe()
    try recipes.forEach { if recipe.id == $0.id { throw DBError.duplicateIdInsertError} }
    let insertStatementString =
    "INSERT INTO Recipe (id, name, yieldAmount, image) VALUES (?, ?, ?, ?);"
    var insertStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(insertStatement) }
    
    if sqlite3_prepare_v2(self.db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(insertStatement, 1, recipe.id.uuidString.utf8, -1, nil)
      sqlite3_bind_text(insertStatement, 2, recipe.name.utf8, -1, nil)
      sqlite3_bind_int(insertStatement, 3, Int32(recipe.yieldAmount))
      if let image = recipe.image {
        let nsData = NSData(data: image)
        sqlite3_bind_blob(insertStatement, 4, nsData.bytes, Int32(nsData.length), nil)
      } else {
        sqlite3_bind_null(insertStatement, 4)
      }
      
      if sqlite3_step(insertStatement) == SQLITE_DONE {
        print("Successfully inserted row to Recipe.")
      } else {
        throw DBError.insertionError
      }
    } else {
      throw DBError.statementPreparationError
    }
    
    // insert a grocery item for this recipe
    try self.insertGroceryItem(.init(
      id: recipe.id,
      name: recipe.name,
      defaultExpirationInterval: TimeInterval(fromDays: 4),
      type: "Dishes"
    ))
  }
  
  func updateRecipe(_ recipe: Recipe) throws {
    let recipes = try self.readRecipe()
    guard recipes.contains(where: { $0.id == recipe.id}) else { throw DBError.updatingError }
    let updateStatementString =
    "UPDATE Recipe SET name = ?, yieldAmount = ?, image = ? WHERE id = ?;"
    var updateStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(updateStatement) }
    
    if sqlite3_prepare_v2(self.db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(updateStatement, 1, recipe.name.utf8, -1, nil)
      sqlite3_bind_int(updateStatement, 2, Int32(recipe.yieldAmount))
      if let image = recipe.image {
        let nsData = NSData(data: image)
        sqlite3_bind_blob(updateStatement, 3, nsData.bytes, Int32(nsData.length), nil)
      } else {
        sqlite3_bind_null(updateStatement, 3)
      }
      sqlite3_bind_text(updateStatement, 4, recipe.id.uuidString.utf8, -1, nil)

      if sqlite3_step(updateStatement) == SQLITE_DONE {
        print("Successfully updated row in Recipe.")
      } else {
        throw DBError.updatingError
      }
    } else {
      throw DBError.statementPreparationError
    }
    
    // update the grocery item for this recipe
    try self.updateGroceryItem(.init(
      id: recipe.id,
      name: recipe.name,
      defaultExpirationInterval: TimeInterval(fromDays: 4),
      type: "Dishes"
    ))
  }
  
  func readRecipe(withDebugPrintOn: Bool = false) throws -> [Recipe] {
    let queryStatementString = "SELECT id, name, yieldAmount, image FROM Recipe;"
    var queryStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(queryStatement) }
    
    if sqlite3_prepare_v2(self.db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
      var recipes : [Recipe] = []
      while sqlite3_step(queryStatement) == SQLITE_ROW {
        let id = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
        let name = String(cString: sqlite3_column_text(queryStatement, 1))
        let yieldAmount = Int(sqlite3_column_int(queryStatement, 2))
        let image: Data?
        let imageType = sqlite3_column_type(queryStatement, 3)
        if imageType == SQLITE_NULL {
          image = nil
        } else {
          let imageData = sqlite3_column_blob(queryStatement, 3)
          let dataLength = Int(sqlite3_column_bytes(queryStatement, 3))
          image = Data(bytes: imageData!, count: dataLength)
        }
        let recipe = Recipe(id: UUID(uuidString: id)!, name: name, yieldAmount: yieldAmount, image: image)
        recipes.append(recipe)
        if withDebugPrintOn {
          print("Recipe: \(recipe.debugDescription)")
        }
      }
      return recipes
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteRecipe(id: Recipe.ID) throws {
    let deleteStatementStirng = "DELETE FROM Recipe WHERE id = ?;"
    var deleteStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(deleteStatement) }
    
    if sqlite3_prepare_v2(self.db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
      sqlite3_bind_text(deleteStatement, 1, id.uuidString.utf8, -1, nil)
      if sqlite3_step(deleteStatement) == SQLITE_DONE {
        print("Successfully deleted row from Recipe.")
      } else {
        throw DBError.deletionError
      }
    } else {
      throw DBError.statementPreparationError
    }
    try self.deleteAllRecipeItemsFor(id: id)
    try self.deleteAllRecipeStepsFor(id: id)
    try self.deleteAllPlannedMealsFor(id: id)
  }
}
