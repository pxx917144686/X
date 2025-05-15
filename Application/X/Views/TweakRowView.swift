//
//  ExperimentalView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import SwiftUI

struct TweakRowView: View {
    @Binding var tweak: Tweak
    @Binding var isGloballyProcessing: Bool

    let action: () -> Void
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "程序坞": return "menubar.dock.rectangle.badge.record"
        case "UI元素": return "photo.on.rectangle.angled"
        case "锁屏": return "lock.display"
        case "声音": return "speaker.wave.2.fill"
        case "控制中心": return "switch.2"
        default: return "gearshape.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForCategory(tweak.category))
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(tweak.name)
                    .font(.headline)
                    .fontWeight(.medium)

                if let description = tweak.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                if !tweak.status.isEmpty {
                    HStack(spacing: 4) {
                        Text("状态:")
                        Text(tweak.status)
                            .fontWeight(.medium)
                            .foregroundColor(tweak.status.contains("成功") || tweak.status.contains("成功") ? .green : (tweak.status.contains("失败") ? .red : .orange))
                    }
                    .font(.caption)
                }
            }

            Spacer()

            Button(action: action) {
                if tweak.isProcessing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 44, height: 30) // 保持与按钮一致的大小
                } else {
                    Image(systemName: "hammer.circle.fill") // "wand.and.stars" 或 "gearshape.fill"
                        .imageScale(.large)
                }
            }
            .frame(width: 44, height: 30) // 给按钮一个确定的可点击区域
            .disabled(tweak.isProcessing || isGloballyProcessing)
            .buttonStyle(.borderless) // 在列表中为图标按钮使用无边框样式
            .contentShape(Rectangle()) // 确保整个区域可点击
        }
        .padding(.vertical, 8)
    }
}