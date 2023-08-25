//
//  FridgeItemView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import SwiftUI
import ComposableArchitecture

public struct ItemView: View {
  private let name: String
  private let amount: Double
  private let unitName: String

  public init(name: String, amount: Double, unitName: String) {
    self.name = name
    self.amount = amount
    self.unitName = unitName
  }
  
  public var body: some View {
    HStack {
      Image(systemName: "carrot")
      Spacer().frame(maxWidth: 12)
      // TODO: handle fonts better
      Text(self.name).fontWeight(.semibold)
      Spacer()
      Text("\(self.amount.formatted())")
      Text("\(self.unitName)")
    }
  }
}
