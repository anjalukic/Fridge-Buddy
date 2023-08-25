//
//  DBClient.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import Foundation
import SQLite3

var isInitialiedOverride = true

public class DBClient {
  var db: OpaquePointer?
  
  init() {
    self.openDBAndInit()
  }
  
  private func openDBAndInit() {
    self.db = self.openDatabase()
    if !self.isInitialized {
      self.initDB()
      self.isInitialized = true
    }
  }
  
  func openDatabase() -> OpaquePointer? {
    let filePath = Self.dbFilePath(fileName: self.dbFileName)
    var db: OpaquePointer? = nil
    if sqlite3_open(filePath.path, &db) != SQLITE_OK {
      debugPrint("Can't open database")
      return nil
    }
    else {
      print("Successfully created connection to database at \(filePath.path)")
      return db
    }
  }
  
  func initDB() {
    try? self.createGroceryItemTable()
//    try? self.createGroceryTypeTable()
    try? self.createFridgeItemTable()
//    try? self.createUnitTable()
    try? self.createRecipeTable()
    try? self.createRecipeItemTable()
    try? self.createRecipeStepTable()
    try? self.createShoppingListItemTable()
    try? self.createPlannedMealTable()

//    try? self.initGroceryTypeTable()
//    try? self.initUnitTable()
    try? self.initGroceryItemTable()
    try? self.initFridgeItemTable()
    try? self.initRecipeTable()
    try? self.initRecipeItemTable()
    try? self.initRecipeStepTable()
    try? self.initPlannedMealTable()
  }
  
  func createTable(statement createStatementString: String, tableName: String) throws {
    var createTableStatement: OpaquePointer? = nil
    defer { sqlite3_finalize(createTableStatement) }
    
    if sqlite3_prepare_v2(self.db, createStatementString, -1, &createTableStatement, nil) == SQLITE_OK {
      if sqlite3_step(createTableStatement) == SQLITE_DONE {
        print("\(tableName) table created.")
      } else {
        throw DBError.tableCreationError
      }
    } else {
      throw DBError.statementPreparationError
    }
  }
  
  func deleteAllDatabaseData() throws {
    try FileManager.removeItem(FileManager.default)(at: self.dbFilePath)
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: "connection")
    defaults.removeObject(forKey: "dbLastUpdated")
    self.isInitialized = false
    self.openDBAndInit()
  }
  
  func loadNewDatabase(from url: URL) {
    let newName = url.lastPathComponent
    self.dbFileName = newName
    self.isInitialized = false
    self.openDBAndInit()
  }
  
  static func dbFilePath(fileName: String) -> URL {
    try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      .appendingPathComponent(fileName)
  }
  
  var dbFilePath: URL {
    Self.dbFilePath(fileName: self.dbFileName)
  }
  
  var dbFileName: String {
    get {
      let defaults = UserDefaults.standard
      if let name = defaults.string(forKey: "dbFileName") {
        return name
      }
      let name = "fridgeBuddyDB_\(UUID.init()).sqlite"
      defaults.set(name, forKey: "dbFileName")
      return name
    }
    set {
      let defaults = UserDefaults.standard
      defaults.set(newValue, forKey: "dbFileName")
    }
  }
  
  var isInitialized: Bool {
    get {
      if isInitialiedOverride {
        isInitialiedOverride = false
        return false
      }
      let defaults = UserDefaults.standard
      return defaults.bool(forKey: "isDbInitialized")
    }
    set {
      let defaults = UserDefaults.standard
      defaults.set(newValue, forKey: "isDbInitialized")
    }
  }
}

extension DBClient {
  public enum DBError: Error {
    case tableCreationError
    case duplicateIdInsertError
    case insertionError
    case statementPreparationError
    case deletionError
    case readingError
    case updatingError
    case generalError
    case dbDeletionError
  }
}

extension Date {
  func toString() -> String {
    // Setup date (yyyy-MM-dd HH:mm:ss)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateString = formatter.string(from: self)
    
    return dateString
  }
}

extension String {
  func toDate() -> Date? {
    // Setup date (yyyy-MM-dd HH:mm:ss)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let date = formatter.date(from: self)
    
    return date
  }
  
  var utf8: UnsafePointer<CChar>? {
    (self as NSString).utf8String
  }
}
