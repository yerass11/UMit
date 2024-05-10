//
//  MainView.swift
//  UMit
//
//  Created by Yerasyl on 10.05.2024.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage

struct CreateNewPost: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var onPost: (Post)->()
    @State private var postText: String = ""
    @State private var postImageData: Data?
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var showKeyboard: Bool
    
    var body: some View {
        let user = viewModel.currentUser
        VStack {
            HStack {
                Menu {
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Button(action: createPost) {
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(.black, in: Capsule())
                }
                .opacity(postText.isEmpty ? 0.5 : 1.0) // Устанавливаем непрозрачность в зависимости от условия
                .disabled(postText.isEmpty) // Отключаем кнопку в зависимости от условия
            }
            .padding()
            .background(
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
            )
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    TextField("What is happening?", text: $postText, axis: .vertical)
                        .focused($showKeyboard )
                    
                    if let postImageData, let image = UIImage(data: postImageData) {
                        GeometryReader {
                            let size = $0.size
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                /// Delete button
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            self.postImageData = nil
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .fontWeight(.bold)
                                            .tint(.red)
                                    }.padding(10)
                                }
                        }
                        .clipped()
                        .frame(height: 220)
                    }
                }
                .padding()
            }
            
            Divider()
            
            HStack {
                Button {
                    showImagePicker.toggle()
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                }
                
                Spacer()
                
                Button("Done") {
                    showKeyboard = false
                }
            }
            .padding()
            .foregroundColor(.black)
        }
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { newValue in
            if let newValue {
                Task {
if let rawImageData = try? await newValue.loadTransferable(type: Data.self), let image = UIImage(data: rawImageData), let compressedImageData = image.jpegData(compressionQuality: 0.5) {
                        await MainActor.run(body: {
                            postImageData = compressedImageData
                            photoItem = nil
                        })
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
//        .overlay {
//            LoadingView(show: $isLoading)
//        }
    }
    
    // MARK: Post Content to Firebase
    
    func createPost() {
        isLoading = true
        showKeyboard = false
        Task {
            do {
                guard let userFullname = viewModel.currentUser?.fullname else { return }
                let imageReferenceID = "\(viewModel.currentUser?.id ?? "")\(Date())"
                let storageRef = Storage.storage().reference().child("Post_Images").child(imageReferenceID)
                
                if let postImageData {
                    let _ = try await storageRef.putDataAsync(postImageData)
                    let downloadURL = try await storageRef.downloadURL()
                    let post = Post(text: postText, imageURL: downloadURL, imageReferenceID: imageReferenceID, userFullname: viewModel.currentUser?.fullname ?? "", userUID: viewModel.currentUser?.id ?? "")
                    try await createDocumentAtFirebase(post)
                } else {
                    let post = Post(text: postText, userFullname: viewModel.currentUser?.fullname ?? "", userUID: viewModel.currentUser?.id ?? "")
                    try await createDocumentAtFirebase(post)
                }
            } catch {
                await setError(error)
            }
        }
    }
    
    func createDocumentAtFirebase(_ post: Post) async throws {
        let doc = Firestore.firestore().collection("Posts").document()
        let _ = try doc.setData(from: post, completion: { error in
            if error == nil {
                isLoading = false
                var updatedPost = post
                updatedPost.id = doc.documentID
                onPost(updatedPost)
                dismiss()
            }})
    }
    
    //MARK: Displaying errors as Alert
    func setError(_ error: Error) async {
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

#Preview {
    CreateNewPost {_ in }
}
