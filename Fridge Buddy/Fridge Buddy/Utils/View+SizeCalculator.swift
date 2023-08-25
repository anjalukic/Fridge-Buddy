//
//  View+SizeCalculator.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 2.6.23..
//

import Foundation
import SwiftUI

struct SizeCalculator: ViewModifier {
  @Binding var size: CGSize
  
  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { proxy in
          Color.clear // we just want the reader to get triggered, so let's use an empty color
            .onAppear {
              self.size = proxy.size
            }
        }
      )
  }
}

extension View {
  func saveSize(in size: Binding<CGSize>) -> some View {
    modifier(SizeCalculator(size: size))
  }
}
