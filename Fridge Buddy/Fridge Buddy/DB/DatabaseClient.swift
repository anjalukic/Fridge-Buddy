//
//  DatabaseClient.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 10.8.23..
//

import Foundation
import IdentifiedCollections

/// This is a wrapper client for DBClient which handles communication with the database
public struct DatabaseClient {
  public var deleteFridgeItem: (FridgeItem.ID) async -> Result<Bool, DBClient.DBError>
  public var deleteRecipe: (Recipe.ID) async -> Result<Bool, DBClient.DBError>
  public var deleteRecipeItemsFor: (Recipe.ID) async -> Result<Bool, DBClient.DBError>
  public var deleteRecipeStepsFor: (Recipe.ID) async -> Result<Bool, DBClient.DBError>
  public var deleteShoppingListItem: (ShoppingListItem.ID) async -> Result<Bool, DBClient.DBError>
  public var deleteAllShoppingListItems: () async -> Result<Bool, DBClient.DBError>
  public var deleteAllShoppingListItemsFor: (GroceryItem.ID) async -> Result<Bool, DBClient.DBError>
  public var deletePlannedMeal: (PlannedMeal.ID) async -> Result<Bool, DBClient.DBError>
  public var readFridgeItem: () async -> Result<IdentifiedArrayOf<FridgeItem>, DBClient.DBError>
  public var readGroceryItem: () async -> Result<IdentifiedArrayOf<GroceryItem>, DBClient.DBError>
  public var readRecipe: () async -> Result<IdentifiedArrayOf<Recipe>, DBClient.DBError>
  public var readRecipeItem: () async -> Result<IdentifiedArrayOf<RecipeItem>, DBClient.DBError>
  public var readRecipeStep: () async -> Result<IdentifiedArrayOf<RecipeStep>, DBClient.DBError>
  public var readShoppingListItem: () async -> Result<IdentifiedArrayOf<ShoppingListItem>, DBClient.DBError>
  public var readPlannedMeal: () async -> Result<IdentifiedArrayOf<PlannedMeal>, DBClient.DBError>
  public var updateFridgeItem: (FridgeItem) async -> Result<Bool, DBClient.DBError>
  public var updateRecipe: (Recipe) async -> Result<Bool, DBClient.DBError>
  public var updateShoppingListItem: (ShoppingListItem) async -> Result<Bool, DBClient.DBError>
  public var insertFridgeItem: (FridgeItem) async -> Result<Bool, DBClient.DBError>
  public var insertFridgeItems: ([FridgeItem]) async -> Result<Bool, DBClient.DBError>
  public var insertGroceryItem: (GroceryItem) async -> Result<Bool, DBClient.DBError>
  public var insertRecipe: (Recipe) async -> Result<Bool, DBClient.DBError>
  public var insertRecipeItem: (RecipeItem) async -> Result<Bool, DBClient.DBError>
  public var insertRecipeStep: (RecipeStep) async -> Result<Bool, DBClient.DBError>
  public var insertShoppingListItem: (ShoppingListItem) async -> Result<Bool, DBClient.DBError>
  public var insertPlannedMeal: (PlannedMeal) async -> Result<Bool, DBClient.DBError>
  public var deleteAllData: () async -> Result<Bool, DBClient.DBError>
  public var getDatabaseURL: () -> URL
  public var loadNewDatabase: (_ from: URL) async -> Result<Bool, DBClient.DBError>
}
