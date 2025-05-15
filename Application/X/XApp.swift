//
//  XApp.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//  GitHub: https://github.com/pxx917144686/X/tree/main
//

import SwiftUI

@main
struct XApp: App {
    @State private var showLaunchScreen = true
    // 添加作者信息
    let appAuthor = "pxx917144686"
    let githubURL = "https://github.com/pxx917144686/X/tree/main"
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                
                if showLaunchScreen {
                    LaunchScreen(isShowing: $showLaunchScreen)
                        .transition(.opacity)
                }
            }
            .onAppear {
                // 打印作者信息到控制台
                print("X App by \(appAuthor)")
                print("GitHub: \(githubURL)")
            }
        }
    }
}
