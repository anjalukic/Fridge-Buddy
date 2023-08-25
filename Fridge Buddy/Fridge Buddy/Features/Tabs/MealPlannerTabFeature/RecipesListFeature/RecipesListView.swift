//
//  RecipesListView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import SwiftUI
import ComposableArchitecture

public struct RecipesListView: View {
  private let store: StoreOf<RecipesListFeature>
  @State private var searchText: String = ""

  public init(store: StoreOf<RecipesListFeature>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        SearchBar(text: $searchText)
        List {
          ForEach(viewStore.recipes.filter { searchText.isEmpty ? true : $0.name.contains(searchText) }) { recipe in
            Button(action: {
              viewStore.send(.didTapRecipe(recipe.id))
            }, label: {
              Text(recipe.name)
                .padding(.horizontal, 6)
            })
          }
        }
        .listStyle(.sidebar)
      }
      .padding(.vertical, 8)
      .onAppear {
        viewStore.send(.onAppear)
      }
    }
  }}

