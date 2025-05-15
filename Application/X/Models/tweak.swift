//
//  ExperimentalView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import SwiftUI

enum TweakActionType {
    case zeroOutFiles(paths: [String])
}

struct Tweak: Identifiable {
    let id = UUID()
    var name: String
    var description: String?
    var action: TweakActionType
    var category: String
    var status: String = ""
    var isProcessing: Bool = false
}
