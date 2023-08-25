//
//  SlideableListItemView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 9.8.23..
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct ItemActionsView: View {
  private var actions: IdentifiedArrayOf<Action>
  
  public init(actions: IdentifiedArrayOf<Action>) {
    self.actions = actions
  }
  
  public var body: some View {
    HStack(spacing: 0) {
      ForEach(self.actions) { action in
        Button(action: {
          action.callback()
        }, label: {
          ZStack {
            action.type.background
            action.type.icon
              .foregroundColor(.white)
              .padding(.horizontal, 16)
          }
        })
      }
    }
    .fixedSize(horizontal: true, vertical: false)
    .transition(.move(edge: .trailing))
  }
}

public extension ItemActionsView {
  struct Action: Identifiable {
    var type: ActionType
    var callback: () -> Void
    
    public init(_ type: ActionType, callback: @escaping () -> Void) {
      self.type = type
      self.callback = callback
    }
    
    public var id: ActionType { return self.type }
    
    public enum ActionType {
      case delete
      case edit
      
      var icon: Image {
        switch self {
        case .delete: return Image(systemName: "trash").renderingMode(.template)
        case .edit: return Image(systemName: "pencil").renderingMode(.template)
        }
      }
      
      var background: Color {
        switch self {
        case .delete: return .red
        case .edit: return .gray
        }
      }
    }
  }
}
