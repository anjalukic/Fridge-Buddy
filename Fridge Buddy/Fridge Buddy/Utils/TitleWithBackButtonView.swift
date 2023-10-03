//
//  TitleWithBackButtonView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 13.8.23..
//

import Foundation
import SwiftUI

public struct TitleWithBackButtonView: View {
  public let didTapBack: () -> Void
  public let title: String
  
  public init(title: String, didTapBack: @escaping () -> Void) {
    self.title = title
    self.didTapBack = didTapBack
  }
  
  public var body: some View {
    HStack {
      Button(action: {
        self.didTapBack()
      }, label: {
        Image(systemName: "chevron.backward")
          .renderingMode(.template)
          .foregroundColor(Color.init("AppetiteRed"))
      })
      
      Spacer()
      
      Text(self.title)
        .font(.system(size: 20, weight: .bold))
        .padding(.vertical, 8)
      
      Spacer()
    }
    .padding(12)
  }
}
