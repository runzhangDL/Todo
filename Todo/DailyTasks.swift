//
//  DailyTasks.swift
//  Todo
//
//  Created by 张润 on 2024/10/19.
//

import Foundation
import SwiftData

@Model
final class DailyTasks {
    @Attribute(.unique) var day: String
    @Relationship(deleteRule: .cascade) var tasks: [Task]
    
    init(day: String, tasks: [Task]=[]) {
        self.day = day
        self.tasks = tasks
    }
}

@Model
final class Task {
    var startDate: Date
    var endDate: Date
    var taskDescription: String
    var isCompleted: Bool
    
    @Relationship(inverse: \DailyTasks.tasks) var dailyTasks: DailyTasks?
    
    init(startDate: Date = Date(), endDate: Date = Date(), taskDescription: String, isCompleted: Bool=false){
        self.startDate = startDate
        self.endDate = endDate
        self.taskDescription = taskDescription
        self.isCompleted = isCompleted
    }
}
