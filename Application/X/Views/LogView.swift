//
//  ExperimentalView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import SwiftUI

struct LogView: View {
    @ObservedObject var logStore: LogStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(logStore.messages, id: \.self) { message in
                    Text(message)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .toolbar {
            Button("清除") {
                logStore.clear()
            }
        }
    }
}