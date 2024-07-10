//
//  envmon_iosApp.swift
//  envmon-ios
//
//  Created by Jimmy Hough Jr on 6/28/24.
//

import SwiftUI
import SwiftData

@main
struct envmon_iosApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Server.self,
            EnvReading.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema,
                                                    isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema,
                                      configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
