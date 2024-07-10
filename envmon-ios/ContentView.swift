//
//  ContentView.swift
//  envmon-ios
//
//  Created by Jimmy Hough Jr on 6/28/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var servers: [Server]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(servers) { server in
                    NavigationLink("\(server.address)",
                                   destination: EnvView(server: server)
                                                        .modelContext(modelContext))
                }
            }
            NavigationLink(destination: {ServerView(role: .create)},
                           label: {Text("New Server")})
        } detail: {
            Text("Select a Server.")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Server.self, inMemory: true)
}
