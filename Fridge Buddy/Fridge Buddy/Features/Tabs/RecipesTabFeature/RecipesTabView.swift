//
//  FridgeTabView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import SwiftUI
import ComposableArchitecture

public struct RecipesTabView: View {
  private let store: StoreOf<RecipesTabFeature>
  @State private var searchText: String = ""

  public init(store: StoreOf<RecipesTabFeature>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      self.recipesList
        .navigationBarItems(
          leading: self.leadingButton,
          trailing: self.trailingButton
        )
        .animation(.default, value: viewStore.isEditing)
        .alert(self.store.scope(state: \.alert?.alertState, action: { .alert($0) }), dismiss: .didDismiss)
        .fullScreenCover(
          store: self.store.scope(state: \.$recipePreview, action: { .recipePreview($0) })
        ) { store in
          RecipeView(store: store)
        }
        .navigationDestination(
          store: self.store.scope(state: \.$editRecipe, action: { .editRecipe($0) })
        ) { store in
          RecipeFormView(store: store)
        }
        .navigationDestination(
          store: self.store.scope(state: \.$addRecipe, action: { .addRecipe($0) })
        ) { store in
          RecipeFormView(store: store)
        }
        .onAppear {
          viewStore.send(.onAppear)
        }
    }
  }

  private var recipesList: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        SearchBar(text: $searchText)
          .padding(.vertical, 6)
        List {
          ForEach(viewStore.sections) { section in
            Section(section) {
              if let recipesInSection = viewStore.sectionedRecipes[section] {
                ForEach(recipesInSection.filter({ searchText.isEmpty ? true : $0.name.contains(searchText) })) { recipe in
                  HStack {
                    Button(action: {
                      viewStore.send(.didTapRecipe(recipe.id))
                    }, label: {
                      Text(recipe.name)
                        .padding(.horizontal, 6)
                    })
                    Spacer()
                    if viewStore.isEditing {
                      ItemActionsView(
                        actions: [
                          .init(.delete, callback: { viewStore.send(.didTapDeleteRecipe(recipe.id)) }),
                          .init(.edit, callback: { viewStore.send(.didTapEditRecipe(recipe.id)) })
                        ]
                      )
                    }
                  }
                  .listRowInsets(EdgeInsets())
                  .buttonStyle(PlainButtonStyle())
                }
              }
            }
          }
        }
        .listStyle(.sidebar)
      }
    }
  }

  private var leadingButton: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Button(action: { viewStore.send(.didTapAddNewRecipe) }) {
        Image(systemName: "plus")
      }
      .opacity(viewStore.isEditing ? 0 : 1)
      .foregroundColor(.white)
    }
  }

  private var trailingButton: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      if viewStore.isEditing {
        Button(action: { viewStore.send(.didTapDoneEditing) }) {
          Text("Done")
        }
      } else {
        Button(action: { viewStore.send(.didTapEdit) }) {
          Text("Edit")
        }
      }
    }
    .foregroundColor(.white)
  }
}

extension RecipesTabFeature.State.Alert {
  fileprivate var alertState: AlertState<RecipesTabFeature.Action.AlertAction> {
    switch self {
    case .confirmDeletion(let recipe):
      return .init(
        title: .init("Do you really want to delete?"),
        message: .init("\(recipe.name)"),
        primaryButton: .destructive(.init("Delete"), action: .send(.didTapConfirmDeletion)),
        secondaryButton: .cancel(.init("Cancel"), action: .send(.didTapCancelDeletion))
      )
    }
  }
}

