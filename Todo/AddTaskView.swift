//
//  AddTaskView.swift
//  Todo
//
//  Created by 张润 on 2024/10/20.
//

import SwiftUI
import SwiftData

struct AddTaskView: View {
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight:CGFloat = 0
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var taskDescription:String = ""
    @State private var showDescLimitExceed:Bool = false
    @State private var showSuccessAdded:Bool = false
    @State private var showErrorAdded:Bool = false
    @State private var errorMessage:String = ""
    @State private var isProcessing:Bool = false
    
    let taskDescLimit = 50
        
    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2024, month: 1, day: 1)
        let endComponents = DateComponents(year: 2024, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        return calendar.date(from: startComponents)!
        ...
        calendar.date(from: endComponents)!
    }()
    
    var body: some View {
        ZStack {
            VStack(content: {
                DatePicker(
                    "Start Date:",
                    selection: $startDate,
                    in: dateRange,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.automatic)
                DatePicker(
                    "End Date:",
                    selection: $endDate,
                    in: startDate...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                TextField(
                    "Task Description",
                    text: $taskDescription,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .onChange(of: taskDescription) {_, newValue in
                    if newValue.count >= taskDescLimit {
                        taskDescription = String(newValue.prefix(taskDescLimit))
                        showDescLimitExceed = true
                    } else {
                        showDescLimitExceed = false
                    }
                }
                if showDescLimitExceed {
                    Text("Need a task description with less than \(taskDescLimit) characters")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                HStack(content: {
                    Button("Cancel"){
                        dismiss()
                    }
                    Spacer()
                    Button(action: doAdd, label: {
                        Text("Add")
                    })
                    .disabled(isProcessing)
                })
            })
            .padding()
            .background(
                GeometryReader { gemotry in
                    Color.clear.onAppear {
                        contentHeight = gemotry.size.height
                    }
                }
            )
            .presentationDetents([.height(contentHeight)])
            
            if showSuccessAdded {
                SuccessView()
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring, value: showSuccessAdded)
            }
            if showErrorAdded {
                ErrorView(errorMessage: errorMessage)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring, value: showErrorAdded)
            }
        }
    }
    
    private func doAdd(){
        
        guard !isProcessing else {return}
        
        isProcessing = true
        
        var processingRes = true
        
        if  startDate.formatted(date: .abbreviated, time: .omitted) != endDate.formatted(date: .abbreviated, time: .omitted){
            processingRes = false
            errorMessage = "Start and end date need to be in the same day"
        }
        
        if processingRes {
            let targetDay = startDate.formatted(date:.abbreviated, time: .omitted)
            var descriptor: FetchDescriptor<DailyTasks> {
                let descriptor = FetchDescriptor<DailyTasks> (predicate: #Predicate{dailyTasks in dailyTasks.day == targetDay})
                return descriptor
            }
            
            if (try? context.fetch(descriptor))?.first == nil {
                let newDailyTask = DailyTasks(day: targetDay, tasks: [])
                context.insert(newDailyTask)
                try? context.save()
            }
            
            let task = Task(startDate: startDate, endDate: endDate, taskDescription: taskDescription)

            if let targetTasks = (try? context.fetch(descriptor))?.first{
                targetTasks.tasks.append(task)
                try? context.save()
            }
            
            
//            let targetTasks: [DailyTasks] = try! context.fetch(descriptor)
                        
//            if let targetTask = targetTasks.first {
//                targetTask.tasks.append(task)
//                print("Got target's tasks")
//            } else {
//                print("No tasks for target's day")
//            }
//            do{
//                try context.save()
//            } catch {
//                processingRes = false
//                errorMessage = "Failed to save task \(error.localizedDescription)"
//            }
        }
        
        if processingRes {
            withAnimation{
                showSuccessAdded = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                withAnimation {
                    showSuccessAdded = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now()+0.3){
                    isProcessing = false
                }
            }
        } else {
            withAnimation{
                showErrorAdded = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                withAnimation {
                    showErrorAdded = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now()+0.3){
                    isProcessing = false
                }
            }
        }
        
    }
    
    private struct SuccessView: View {
        var body: some View {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
                .background(
                Circle()
                    .fill(.white)
                    .shadow(radius: 2)
                )
        }
    }
    
    private struct ErrorView: View {
        let errorMessage:String
        var body: some View {
            HStack(spacing:10) {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            .padding()
            .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white)
                .shadow(radius: 2)
            )
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DailyTasks.self, Task.self, configurations: config)
    return AddTaskView().modelContainer(container)
}
