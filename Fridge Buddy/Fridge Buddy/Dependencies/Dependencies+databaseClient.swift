//
//  Dependencies.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 2.6.23..
//

import Foundation
import ComposableArchitecture

enum DatabaseClientKey: DependencyKey {
  static let defaultValue: DatabaseClient = .init(
    deleteFridgeItem: { _ in .success(true) },
    deleteRecipe: { _ in .success(true) },
    deleteRecipeItemsFor: { _ in .success(true) },
    deleteRecipeStepsFor: { _ in .success(true) },
    deleteShoppingListItem: { _ in .success(true) },
    deleteAllShoppingListItems: { return .success(true) },
    deleteAllShoppingListItemsFor: { _ in .success(true) },
    deletePlannedMeal: { _ in .success(true) },
    readFridgeItem: { return .success([]) },
    readGroceryItem: { return .success([]) },
    readRecipe: { return .success([]) },
    readRecipeItem: { return .success([]) },
    readRecipeStep: { return .success([]) },
    readShoppingListItem: { return .success([]) },
    readPlannedMeal: { return .success([]) },
    updateFridgeItem: { _ in return .success(true) },
    updateRecipe: { _ in return .success(true) },
    updateShoppingListItem: { _ in return .success(true) },
    insertFridgeItem: { _ in return .success(true) },
    insertGroceryItem: { _ in return .success(true) },
    insertRecipe: { _ in return .success(true) },
    insertRecipeItem: { _ in return .success(true) },
    insertRecipeStep: { _ in return .success(true) },
    insertShoppingListItem: { _ in return .success(true) },
    insertPlannedMeal: { _ in return .success(true) },
    deleteAllData: { return .success(true) },
    getDatabaseURL: { return URL(string: "google.com")! },
    loadNewDatabase: { _ in return .success(true) }
  )
  
  static var liveValue: DatabaseClient = {
    let uploadActor = Semaphore()
    let dbClient = DBClient()
    let dbActor = Semaphore()
    
    @Sendable
    func uploadChangesIfConnected() async {
      await uploadActor.withSemaphoreLock {
        let connectionResult = await FridgeSharingClientKey.liveValue.getConnection()
        guard
          case .success(let status) = connectionResult,
          case .connected(id: let id) = status
        else { return }
        let _ = await FridgeSharingClientKey.liveValue.uploadFridge()
      }
    }
    
    func readItems<E>(_ readAction: (Bool) throws -> [E]) async -> Result<IdentifiedArrayOf<E>, DBClient.DBError> {
      await dbActor.withSemaphoreLock {
        do {
          let items = try readAction(false)
          return .success(.init(uniqueElements: items))
        } catch let error as DBClient.DBError {
          return .failure(error)
        } catch {
          return .failure(.readingError)
        }
      }
    }
    func deleteItem(_ deleteAction: (UUID) throws -> Void, id: UUID) async -> Result<Bool, DBClient.DBError> {
      await dbActor.withSemaphoreLock {
        do {
          try deleteAction(id)
          Task {
            await uploadChangesIfConnected()
          }
          return .success(true)
        } catch let error as DBClient.DBError {
          return .failure(error)
        } catch {
          return .failure(.deletionError)
        }
      }
    }
    func deleteAllItems(_ deleteAction: () throws -> Void) async -> Result<Bool, DBClient.DBError> {
      await dbActor.withSemaphoreLock {
        do {
          try deleteAction()
          Task {
            await uploadChangesIfConnected()
          }
          return .success(true)
        } catch let error as DBClient.DBError {
          return .failure(error)
        } catch {
          return .failure(.deletionError)
        }
      }
    }
    func updateItem<E>(_ updateAction: (E) throws -> Void, item: E) async -> Result<Bool, DBClient.DBError> {
      await dbActor.withSemaphoreLock {
        do {
          try updateAction(item)
          Task {
            await uploadChangesIfConnected()
          }
          return .success(true)
        } catch let error as DBClient.DBError {
          return .failure(error)
        } catch {
          return .failure(.updatingError)
        }
      }
    }
    func insertItem<E>(_ insertAction: (E) throws -> Void, item: E) async -> Result<Bool, DBClient.DBError> {
      await dbActor.withSemaphoreLock {
        do {
          try insertAction(item)
          Task {
            await uploadChangesIfConnected()
          }
          return .success(true)
        } catch let error as DBClient.DBError {
          return .failure(error)
        } catch {
          return .failure(.insertionError)
        }
      }
    }
    
    return .init(
      deleteFridgeItem: { id in
        return await deleteItem(dbClient.deleteFridgeItem(id:), id: id)
      },
      deleteRecipe: { id in
        return await deleteItem(dbClient.deleteRecipe(id:), id: id)
      },
      deleteRecipeItemsFor: { id in
        return await deleteItem(dbClient.deleteAllRecipeItemsFor(id:), id: id)
      },
      deleteRecipeStepsFor: { id in
        return await deleteItem(dbClient.deleteAllRecipeStepsFor(id:), id: id)
      },
      deleteShoppingListItem: { id in
        return await deleteItem(dbClient.deleteShoppingListItem(id:), id: id)
      },
      deleteAllShoppingListItems: {
        return await deleteAllItems(dbClient.deleteAllShoppingListItems)
      },
      deleteAllShoppingListItemsFor: { id in
        return await deleteItem(dbClient.deleteAllShoppingListItems(for:), id: id)
      },
      deletePlannedMeal: { id in
        return await deleteItem(dbClient.deletePlannedMeal(id:), id: id)
      },
      readFridgeItem: {
        return await readItems(dbClient.readFridgeItem)
      },
      readGroceryItem: {
        return await readItems(dbClient.readGroceryItem)
      },
      readRecipe: {
        return await readItems(dbClient.readRecipe)
      },
      readRecipeItem: {
        return await readItems(dbClient.readRecipeItem)
      },
      readRecipeStep: {
        return await readItems(dbClient.readRecipeStep)
      },
      readShoppingListItem: {
        return await readItems(dbClient.readShoppingListItem)
      },
      readPlannedMeal: {
        return await readItems(dbClient.readPlannedMeal)
      },
      updateFridgeItem: { item in
        return await updateItem(dbClient.updateFridgeItem, item: item)
      },
      updateRecipe: { item in
        return await updateItem(dbClient.updateRecipe, item: item)
      },
      updateShoppingListItem: { item in
        return await updateItem(dbClient.updateShoppingListItem, item: item)
      },
      insertFridgeItem: { item in
        return await insertItem(dbClient.insertFridgeItem, item: item)
      },
      insertGroceryItem: { item in
        return await insertItem(dbClient.insertGroceryItem, item: item)
      },
      insertRecipe: { item in
        return await insertItem(dbClient.insertRecipe, item: item)
      },
      insertRecipeItem: { item in
        return await insertItem(dbClient.insertRecipeItem, item: item)
      },
      insertRecipeStep: { item in
        return await insertItem(dbClient.insertRecipeStep, item: item)
      },
      insertShoppingListItem: { item in
        return await insertItem(dbClient.insertShoppingListItem, item: item)
      },
      insertPlannedMeal: { item in
        return await insertItem(dbClient.insertPlannedMeal, item: item)
      },
      deleteAllData: {
        do {
          try dbClient.deleteAllDatabaseData()
        } catch {
          return .failure(.dbDeletionError)
        }
        return .success(true)
      },
      getDatabaseURL: {
        dbClient.dbFilePath
      },
      loadNewDatabase: { url in
        dbClient.loadNewDatabase(from: url)
        return .success(true)
      }
    )
  }()
}

extension DependencyValues {
  var databaseClient: DatabaseClient {
    get { self[DatabaseClientKey.self] }
    set { self[DatabaseClientKey.self] = newValue }
  }
}
