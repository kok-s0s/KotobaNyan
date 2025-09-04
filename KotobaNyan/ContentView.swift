//
//  ContentView.swift
//  KotobaNyan
//
//  Created by kok-s0s on 2025/9/2.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Hello, World!")
                NavigationLink("进入详情", destination: DetailView())
            }
        }
    }
}

struct DetailView: View {
    var body: some View {
        Text("这是详情页面")
    }
}

#Preview {
    ContentView()
}
