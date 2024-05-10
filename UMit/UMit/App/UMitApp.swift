//
//  UMitApp.swift
//  UMit
//
//  Created by Yerasyl on 09.05.2024.
//

import SwiftUI
import Firebase

@main
struct UMitApp: App {
    @StateObject var viewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
