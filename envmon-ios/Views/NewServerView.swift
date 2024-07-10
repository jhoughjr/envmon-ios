//
//  ServersView.swift
//  envmon-ios
//
//  Created by Jimmy Hough Jr on 7/7/24.
//

import SwiftUI
import SwiftData


struct ServerView: View {
    
    enum Role: UInt8 {
        case create
        case read
        case update
    }
    
    @Environment(\.modelContext) private var modelContext
    
    @State var role: Role
    var server: Server? = nil
    
    @State var serverName: String = ""
    @State var serverAddress: String = ""
    @State var errorReason: String = ""
    
    var body: some View {
        switch role {
        case .read:
            HStack {
                TextField("Name", text: $serverName)
                TextField("Address", text: $serverAddress)
            }
        case .update:
            VStack {
                HStack {
                    Spacer()
                    TextField("Name", text: $serverName)
                    TextField("Address", text: $serverAddress)
                    
                    Button {
                        Task {
                            try modelContext.save()
                        }
                    } label: {
                        Text("Save")
                    }
                }
            }
        case .create:
            VStack {
                TextField("Name", text: $serverName)
                TextField("Address", text: $serverAddress)
                Text(errorReason).foregroundStyle(.red)
                Button {
                    let new = Server(name: serverName,
                                     addr: serverAddress)
                    do {
                        modelContext.insert(new)
                        try new.modelContext?.save()
                    }
                    catch {
                        errorReason = error.localizedDescription
                    }
                } label: {
                    Text("Add")
                }.disabled(!errorReason.isEmpty)
            }
          
        }
     
    }
}
