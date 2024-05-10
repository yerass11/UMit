//
//  SearchUserView.swift
//  UMit
//
//  Created by Yerasyl on 10.05.2024.
//

import SwiftUI
import FirebaseFirestore

struct SearchUserView: View {
    @State private var fetchedUsers: [User] = []
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
            List {
                ForEach(fetchedUsers) { user in
                    NavigationLink {
                        
                    } label: {
                        Text(user.email)
                            .font(.callout)
                        
                    }
                }
            }
            .listStyle(.plain)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Search User")
            .searchable(text: $searchText)
            .onSubmit(of: .search, {
                Task {
                    await searchUsers()
                }
            })
            .onChange(of: searchText, perform: { newValue in
                if newValue.isEmpty {
                    fetchedUsers = []
                }
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(.black)
                }
            
        }
    }
    
    func searchUsers() async {
        do {
            let queryLowerCased = searchText.lowercased()
            let queryUpperCased = searchText.uppercased()
            
            let documents = try await Firestore.firestore().collection("Users")
                .whereField("email", isGreaterThanOrEqualTo: queryUpperCased)
                .whereField("email", isLessThanOrEqualTo: "\(queryLowerCased)\u{f8ff}")
                .getDocuments()
            
            let users = try documents.documents.compactMap { doc -> User? in
                try doc.data(as: User.self)
            }
            
            await MainActor.run(body: {
                fetchedUsers = users
            })
            
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    SearchUserView()
}
