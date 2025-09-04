//
//  ContentView.swift
//  KotobaNyan
//
//  Created by kok-s0s on 2025/9/2.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject var viewModel = VocabularyViewModel()
    @State private var searchText: String = ""
    @State private var selectedItem: VocabularyItem? = nil
    @FocusState private var isSearchFocused: Bool
    @State private var selectedScene: String? = nil
    let gridColumns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索区
                VStack(spacing: 0) {
                    TextField("输入词条前缀...", text: $searchText)
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                        .padding([.horizontal, .top], 16)
                        .focused($isSearchFocused)
                        .submitLabel(.done)
                        .onChange(of: searchText) { newValue in
                            viewModel.search(prefix: newValue)
                            selectedItem = nil
                        }
                        .onSubmit {
                            isSearchFocused = false
                        }
                    if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        List(viewModel.filteredItems) { item in
                            Button(action: {
                                selectedItem = item
                                isSearchFocused = false
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.kanji.isEmpty ? item.kana : item.kanji)
                                            .font(.headline)
                                        Text(item.chinese)
                                            .font(.subheadline)
                                            .foregroundColor(.accentColor)
                                    }
                                    Spacer()
                                    Text(item.scene)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .frame(maxHeight: 300)
                        // 释义卡片
                        if let item = selectedItem {
                            VStack {
                                VocabularyCardView(item: item)
                                    .transition(.move(edge: .bottom))
                                    .padding(.bottom, 8)
                                Button("收起词卡") {
                                    selectedItem = nil
                                }
                                .padding(.bottom)
                            }
                        }
                    }
                }
                // 分类栅格区（仅在搜索框为空时显示）
                if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 14) {
                            ForEach(viewModel.scenes, id: \ .self) { scene in
                                NavigationLink(destination: SceneWordsView(scene: scene, viewModel: viewModel)) {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.accentColor.opacity(0.18))
                                        .frame(height: 120)
                                        .shadow(color: Color(.systemGray3), radius: 6, x: 0, y: 2)
                                        .overlay(
                                            GeometryReader { geometry in
                                                HStack {
                                                    Spacer(minLength: 0)
                                                    VStack {
                                                        Spacer(minLength: 0)
                                                        Text(scene)
                                                            .font(.title3)
                                                            .bold()
                                                            .foregroundColor(.accentColor)
                                                            .multilineTextAlignment(.center)
                                                            .padding(.horizontal, 12)
                                                            .padding(.top, 24) // 让文本整体向下偏移
                                                        Spacer(minLength: 0)
                                                    }
                                                    .frame(height: geometry.size.height)
                                                    Spacer(minLength: 0)
                                                }
                                            }
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                    }
                }
                Spacer()
            }
            .navigationTitle("场景分类与搜索")
        }
    }
}

#Preview {
    ContentView()
}
