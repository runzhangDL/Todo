//
//  TodoApp.swift
//  Todo
//
//  Created by 张润 on 2024/10/19.
//

import SwiftUI
import SwiftData

@main
struct TodoApp: App {
    
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: DailyTasks.self, Task.self)
        } catch {
            fatalError("Failed to create container: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
