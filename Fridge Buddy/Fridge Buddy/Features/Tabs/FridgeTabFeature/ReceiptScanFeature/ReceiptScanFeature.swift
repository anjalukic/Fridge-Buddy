//
//  ReceiptScanFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 22.8.23..
//

import Foundation
import ComposableArchitecture

public struct ReceiptScanFeature: ReducerProtocol {
  public struct State: Equatable {
    var fridgeItems: IdentifiedArrayOf<FridgeItem> = []
    var groceryItems: IdentifiedArrayOf<GroceryItem> = []
    var isScanningComplete: Bool = false
    var isDoneEnabled: Bool = true
  }
  
  public enum Action: Equatable {
    case onAppear
    case handleScanDone([ScannedItem])
    case didTapRemoveItem(UUID)
    case didSelectNewGroceryItem(UUID, for: UUID)
    case didEditItemName(String, for: UUID)
    case didEditItemAmount(UUID, Double)
    case didEditItemUnit(UUID, String)
    case didTapDone
    case delegate(DelegateAction)
    case dependency(DependencyAction)
    
    public enum DelegateAction: Equatable {
      case didTapDone([FridgeItem])
    }
    
    public enum DependencyAction: Equatable {
      case handleItemsFetched(Result<IdentifiedArrayOf<GroceryItem>, DBClient.DBError>)
      case handleParsingFridgeItems(IdentifiedArrayOf<FridgeItem>)
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  @Dependency(\.databaseClient) var dbClient
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          let result = await self.dbClient.readGroceryItem()
          await send(.dependency(.handleItemsFetched(result)))
        }
        
      case .handleScanDone(let items):
        state.isScanningComplete = true
        return .run { send in
          let items = Self.parseFridgeItems(scannedItems: items)
          await send(.dependency(.handleParsingFridgeItems(.init(uniqueElements: items))))
        }
        
      case .didTapRemoveItem(let id):
        state.fridgeItems.remove(id: id)
        return .none
        
      case .didTapDone:
        return .send(.delegate(.didTapDone(state.fridgeItems.elements)))
        
      case .didEditItemName(let newName, let id):
        guard
          var item = state.fridgeItems[id: id],
          let groceryItem = state.groceryItems.first(where: { $0.name == newName })
        else {
          state.isDoneEnabled = false
          return .none
        }
        item.groceryItemId = groceryItem.id
        item.name = groceryItem.name
        state.fridgeItems[id: id] = item
        state.isDoneEnabled = true
        return .none
        
      case .didSelectNewGroceryItem(let groceryId, for: let itemId):
        guard
          var item = state.fridgeItems[id: itemId],
          let groceryItem = state.groceryItems[id: groceryId]
        else { return .none }
        item.groceryItemId = groceryId
        item.name = groceryItem.name
        state.fridgeItems[id: itemId] = item
        state.isDoneEnabled = true
        return .none
        
      case .didEditItemAmount(let id, let newAmount):
        guard var item = state.fridgeItems[id: id] else { return .none }
        item.amount = newAmount
        state.fridgeItems[id: id] = item
        return .none
        
      case .didEditItemUnit(let id, let newUnit):
        guard var item = state.fridgeItems[id: id] else { return .none }
        item.unit = newUnit
        state.fridgeItems[id: id] = item
        return .none
        
      case .dependency(.handleItemsFetched(let result)):
        switch result {
        case .success(let items):
          state.groceryItems = items
          return .none
        case .failure:
          return .none
        }
        
      case .dependency(.handleParsingFridgeItems(let items)):
        state.fridgeItems = items
        return .none
        
      case .delegate:
        // handled in the higher level reducer
        return .none
      }
    }
  }
}

extension ReceiptScanFeature {
  private static let threshold: Float = 0.2
  
  fileprivate static func parseFridgeItems(scannedItems: [ScannedItem]) -> [FridgeItem] {
    guard
      let groceryItemsSr = JSONImporter.groceryItemsSr,
      let groceryItems = JSONImporter.groceryItems
    else { return [] }
    let groceryKeys = Array(groceryItemsSr.keys)
    
    return scannedItems.map { scannedItem -> FridgeItem? in
      let scannedItemName = Self.preprocess(scannedItem: scannedItem.name)
      let match = Self.findBestMatch(groceryKeys, scannedItem: scannedItemName)
      guard
        let match,
        let id = groceryItemsSr[match],
        let item = groceryItems[id],
        let interval = item["defaultExpInterval"] as? Int,
        let name = item["name"] as? String,
        let imageName = item["imageName"] as? String,
        let groceryType = item["type"] as? String
      else { return nil }
      
      return FridgeItem(
        id: .init(),
        groceryItemId: UUID(uuidString: id)!,
        expirationDate: Date() + TimeInterval(interval),
        amount: round(Double(scannedItem.amount) * 100) / 100,
        unit: Unit.kg.id,
        name: name,
        imageName: imageName,
        groceryType: groceryType
      )
    }
    .compactMap { $0 }
  }
  
  fileprivate static func preprocess(scannedItem: String) -> String {
    let inputString = scannedItem.folding(options: .diacriticInsensitive, locale: nil)
    do {
      let specialCharPattern = "[^a-zA-Z0-9 ]+"
      let specialCharRegex = try NSRegularExpression(pattern: specialCharPattern, options: .caseInsensitive)
      let sanitizedStringStep1 = specialCharRegex.stringByReplacingMatches(in: inputString, options: [], range: NSRange(inputString.startIndex..<inputString.endIndex, in: inputString), withTemplate: " ")
      let whitespacePattern = "\\s+"
      let whitespaceRegex = try NSRegularExpression(pattern: whitespacePattern, options: .caseInsensitive)
      let sanitizedStringStep2 = whitespaceRegex.stringByReplacingMatches(in: sanitizedStringStep1, options: [], range: NSRange(sanitizedStringStep1.startIndex..<sanitizedStringStep1.endIndex, in: sanitizedStringStep1), withTemplate: " ")
      
      return sanitizedStringStep2
    } catch {
      print("Error creating regular expression: \(error)")
      return inputString // Return the original string in case of an error
    }
  }
  
  fileprivate static func findBestMatch(_ groceryItems: [String], scannedItem: String) -> String? {
    if let bestMatch = Self.findBestMatchNaively(groceryItems, scannedItem: scannedItem) {
      print("best match 1 \(scannedItem) \(bestMatch)")
      return bestMatch
    }
    if let bestMatch = Self.findBestMatchNgrams(groceryItems, scannedItem: scannedItem) {
      print("best match 2 \(scannedItem) \(bestMatch)")
      return bestMatch
    }
    return nil
  }
  
  fileprivate static func findBestMatchNaively(_ groceryItems: [String], scannedItem: String) -> String? {
    var longestFoundMatch: String = ""
    groceryItems.forEach { groceryItem in
      if scannedItem.range(of: "\\b\(groceryItem)\\b", options: .regularExpression, range: nil, locale: nil) != nil &&
          groceryItem.count > longestFoundMatch.count {
          longestFoundMatch = groceryItem
      }

    }
    return longestFoundMatch.isEmpty ? nil : longestFoundMatch
  }
  
  fileprivate static func findBestMatchNgrams(_ groceryItems: [String], scannedItem: String) -> String? {
    // TODO: move max number of words calculation to app init
    let maxNgram = groceryItems.reduce(1) { result, item in max(result, item.components(separatedBy: " ").count) }
    var ngrams: [Int: [String]] = [:]
    for i in 1...maxNgram {
      ngrams[i] = Self.ngram(from: scannedItem.lowercased(), n: i)
    }
    var bestMatch = ("", Float.infinity)
    groceryItems.forEach { groceryItem in
      let n = groceryItem.components(separatedBy: " ").count
      for ngram in ngrams[n]! {
        let distance = Float(Self.levenshtein(ngram, groceryItem.lowercased())) / Float(groceryItem.count)
        if distance < bestMatch.1  && distance < Self.threshold {
          bestMatch = (groceryItem, distance)
        }
      }
    }
    return bestMatch.0.isEmpty ? nil : bestMatch.0
  }
  
  fileprivate static func ngram(from string: String, n: Int) -> [String] {
    let words = string.components(separatedBy: " ")
    guard n > 0 else {
      fatalError("n must be a positive integer")
    }
    guard words.count >= n else {
      return []
    }
    var ngrams: [String] = []
    for i in 0...(words.count - n) {
      let ngram = words[i..<(i + n)].joined(separator: " ")
      ngrams.append(ngram)
    }
    return ngrams
  }
  
  fileprivate static func levenshtein(_ s1: String, _ s2: String) -> Int {
    let s1Array = Array(s1)
    let s2Array = Array(s2)
    
    var dp = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)
    
    for i in 0...s1.count {
      for j in 0...s2.count {
        if i == 0 {
          dp[i][j] = j
        } else if j == 0 {
          dp[i][j] = i
        } else {
          let insertion = dp[i][j - 1] + 1
          let deletion = dp[i - 1][j] + 1
          let substitution = dp[i - 1][j - 1] + (s1Array[i - 1] == s2Array[j - 1] ? 0 : 1)
          dp[i][j] = min(insertion, deletion, substitution)
        }
      }
    }
    
    return dp[s1.count][s2.count]
  }
}
