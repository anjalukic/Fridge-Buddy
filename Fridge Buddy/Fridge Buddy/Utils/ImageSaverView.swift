//
//  ImageSaverView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 25.8.23..
//

import SwiftUI
import UIKit

struct ImageSaverView: View {
  @State private var selectedImageData: Data?
  @State private var isImagePickerPresented = false
  private var onSelectImage: (Data) -> Void
  
  public init(onSelectImage: @escaping (Data) -> Void) {
    self.onSelectImage = onSelectImage
  }
  
  var body: some View {
    HStack {
      if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFit()
          .frame(width: 46, height: 46)
      }
      Button("Select an image") {
        isImagePickerPresented.toggle()
      }
    }
    .sheet(isPresented: $isImagePickerPresented) {
      ImagePicker(selectedImageData: $selectedImageData) { imageData in
        // Handle the selected image data here.
        // You can pass it to a function or save it as needed.
        print("Received \(imageData.count) bytes of image data.")
      }
    }
  }
}

struct ImagePicker: UIViewControllerRepresentable {
  @Binding var selectedImageData: Data?
  var completionHandler: ((Data) -> Void)
  
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .photoLibrary
    imagePicker.delegate = context.coordinator
    return imagePicker
  }
  
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var parent: ImagePicker
    
    init(_ parent: ImagePicker) {
      self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let uiImage = info[.originalImage] as? UIImage {
        if let imageData = uiImage.jpegData(compressionQuality: 1.0) {
          parent.selectedImageData = imageData
          
          // Call the completion handler with the image data
          parent.completionHandler(imageData)
        }
      }
      
      picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true)
    }
  }
}
