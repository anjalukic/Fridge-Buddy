//
//  RecipeView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 13.8.23..
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct RecipeView: View {
  private let store: StoreOf<RecipeFeature>
  private let titlesPadding: CGFloat = 8
  private let titlesSize: CGFloat = 20
  private let horizontalPadding: CGFloat = 16
  
  public init(store: StoreOf<RecipeFeature>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        ScrollView {
          ZStack(alignment: .top) {
            self.image
            TitleWithBackButtonView(title: viewStore.recipe.name, didTapBack: { viewStore.send(.didTapBack) })
          }
          
          Group {
            self.ingredients
            self.instructions
            self.yieldAmount
            Spacer()
            
          }
          .padding(.horizontal, self.horizontalPadding)
        }
        
        self.CTAs
      }
      .onAppear {
        viewStore.send(.onAppear)
      }
      .alert(self.store.scope(state: \.alert?.alertState, action: { .alert($0) }), dismiss: .didDismiss)
      .fullScreenCover(
        store: self.store.scope(state: \.$interactiveCooker, action: { .interactiveCooker($0) })
      ) { store in
        InteractiveCookingView(store: store)
      }
    }
  }
  
  private var image: some View {
    WithViewStore(self.store, observe: { $0.recipe.image }) { viewStore in
      if let image = viewStore.state, let uiImage = UIImage(data: image) {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
      }
    }
  }
  
  private var ingredients: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      if !viewStore.recipeItems.isEmpty {
        VStack(alignment: .leading) {
          self.title("Ingredients")
            .frame(maxWidth: .infinity, alignment: .leading)
          ForEach(viewStore.recipeItems) { recipeItem in
            ItemView(name: recipeItem.name, amount: recipeItem.amount, unitName: recipeItem.unit)
          }
        }
      }
    }
  }
  
  private var instructions: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      if !viewStore.recipeSteps.isEmpty {
        VStack(alignment: .leading) {
          self.title("Instructions")
            .frame(maxWidth: .infinity, alignment: .leading)
          ForEach(viewStore.recipeSteps) { recipeStep in
            HStack {
              Text("\(recipeStep.index + 1)")
                .font(.system(size: 16, weight: .bold))
                .frame(width: 20)
              Text(recipeStep.description)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
  }
  
  private var yieldAmount: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        self.title("Yields")
          .frame(maxWidth: .infinity, alignment: .leading)
        Text("\(viewStore.recipe.yieldAmount) servings")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
  
  private var CTAs: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        if viewStore.hasMissingIngredients {
          Button { viewStore.send(.didTapAddMissingIngredientsToShoppingList) } label: {
            Text("Add missing ingredients to shopping list")
              .padding(.vertical, 8)
              .frame(maxWidth: .infinity)
          }
        }
        Button { viewStore.send(.didTapPrepareAndAddToFridge) } label: {
          Text("Mark as prepared")
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        if !viewStore.recipeSteps.isEmpty {
          Button { viewStore.send(.didTapStartCooking)} label: {
            Text("Start cooking")
              .padding(.vertical, 8)
              .frame(maxWidth: .infinity)
          }
        }
      }
      .buttonStyle(.borderedProminent)
      .accentColor(Color.init("AppetiteRed"))
      .padding(.horizontal, self.horizontalPadding)
    }
  }
  
  private func title(_ title: String) -> some View {
    Text(title)
      .font(.system(size: self.titlesSize, weight: .bold))
      .padding(.vertical, self.titlesPadding)
  }
}

extension RecipeFeature.State.Alert {
  fileprivate var alertState: AlertState<RecipeFeature.Action.AlertAction> {
    switch self {
    case .missingIngredientsAddedToList(let ingredients):
      return .init(
        title: .init("Missing ingredients added to list"),
        message: .init(ingredients),
        dismissButton: .cancel(.init("OK"), action: .send(.didSeeAddingItemsToList))
      )
    case .confirmAddingMealToFridge:
      return .init(
        title: .init("Adding prepared meal to fridge"),
        message: .init("Are you sure you want to remove the needed ingredients from fridge and add a prepared meal?"),
        primaryButton: .default(.init("Confirm"), action: .send(.didTapAddMealToFridge)),
        secondaryButton: .cancel(.init("Cancel"), action: .send(.didDismiss))
      )
    }
  }
}
