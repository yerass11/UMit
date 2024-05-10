//
//  PostCardView.swift
//  UMit
//
//  Created by Yerasyl on 10.05.2024.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct PostCardView: View {
    var post: Post
    // Callbacks
    var onUpdate: (Post)->()
    var onDelete: ()->()
    // View Properties
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var docListener: ListenerRegistration?
    
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(spacing: 6) {
                Text(post.userFullname)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical, 8)
                
//                 Post Image if Any
                if let postImageURL = post.imageURL {
                    GeometryReader {
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }.frame(height: 200)
                }
                
                Spacer()
                
                PostInteraction()
            }
            .padding()
            .overlay(alignment: .topTrailing, content:  {
                if post.userUID == viewModel.currentUser?.id {
                    Menu {
                        Button("Delete Post", role: .destructive, action: deletePost)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .rotationEffect(.init(degrees: -90))
                            .foregroundColor(.black)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                    .offset(x: 8)
                }
            })
            .onAppear {
                if docListener == nil {
                    guard let postID = post.id else { return }
                    docListener = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({ snapshot, error in
                        if let snapshot {
                            if snapshot.exists {
                                if let updatedPost = try? snapshot.data(as: Post.self) {
                                    onUpdate(updatedPost)
                                }
                            } else {
                                onDelete()
                                
                            }
                        }
                    })
                }
            }
        }
//        .onDisappear {
//            if docListener {
//                docListener?.remove()
//            }
//        }
    }
    
    // MARK: Like, Dislike Interaction
    @ViewBuilder
    func PostInteraction()->some View {
        HStack(spacing: 6) {
            Button(action: likePost) {
                Image(systemName: post.likedIDs.contains(viewModel.currentUser?.id ?? "") ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
           
            Spacer()
            
            Button(action: dislikePost) {
                Image(systemName: post.dislikedIDs.contains(viewModel.currentUser?.id ?? "") ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .foregroundColor(.black)
        .padding(.vertical, 8)
    }
    
    /// - Liking Post
    func likePost() {
        Task {
            guard let postID = post.id else { return }
            if post.likedIDs.contains(viewModel.currentUser?.id ?? "") {
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([viewModel.currentUser?.id])
                ])
            } else {
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayUnion([viewModel.currentUser?.id]),
                    "dislikedIDs": FieldValue.arrayRemove([viewModel.currentUser?.id])
                ])
            }
        }
    }
    
    /// - Disliking Post
    func dislikePost() {
        Task {
            guard let postID = post.id else { return }
            if post.dislikedIDs.contains(viewModel.currentUser?.id ?? "") {
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "dislikedIDs": FieldValue.arrayRemove([viewModel.currentUser?.id])
                ])
            } else {
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([viewModel.currentUser?.id]),
                    "dislikedIDs": FieldValue.arrayUnion([viewModel.currentUser?.id])
                ])
            }
        }
    }
    
    /// - Deleting Post
    func deletePost() {
        Task {
            do {
                if post.imageReferenceID != "" {
                    try await Storage.storage().reference().child("Post_Images").child(post.imageReferenceID).delete()
                    // Deleting Firestore Document
                }
                    guard let postID = post.id else { return }
                    try await Firestore.firestore().collection("Posts").document(postID).delete()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}


    

//#Preview {
//    PostCardView()
//}
