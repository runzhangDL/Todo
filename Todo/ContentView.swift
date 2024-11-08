//
//  ContentView.swift
//  Todo
//
//  Created by 张润 on 2024/10/19.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var context
    static var descriptor: FetchDescriptor<DailyTasks> {
        let today = Date().formatted(date: .abbreviated, time: .omitted)
        let descriptor = FetchDescriptor<DailyTasks> (predicate: #Predicate{dailyTasks in dailyTasks.day == today})
        return descriptor
    }
    @Query(descriptor) private var todayTasks: [DailyTasks]
    
    @State private var isShowingSheet = false
    
    var body: some View {
        NavigationView{
            VStack{
                if let todayTask = todayTasks.first {
                    TaskListView(todayTask: todayTask)
                } else {
                    Text("No tasks for today")
                }
            }
            .navigationTitle("Today's Tasks")
            .toolbar{
                Button(action: {isShowingSheet.toggle()}) {
//                    addNewTask()
                    Text("Add New Task")
                }
                .sheet(isPresented: $isShowingSheet, onDismiss: didDismiss){
                    AddTaskView()
                }
            }
        }
    }
    
    struct TaskListView: View {
        let todayTask: DailyTasks
        var body: some View {
            List {
                ForEach(todayTask.tasks.sorted(by: {$0.startDate < $1.startDate})) { task in
                    TaskView(task: task, todayTask: todayTask)
                }
            }
            .listStyle(PlainListStyle())
            .background(Color.clear)
        }
    }
    
    struct TaskView: View {
        let task: Task
        let todayTask: DailyTasks
        @Environment(\.modelContext) private var context
        
        var body: some View {
            HStack{
                HStack{
                    Text("\(task.startDate.formatted(date: .omitted, time: .shortened))-\(task.endDate.formatted(date: .omitted, time: .shortened))")
                        .font(.custom("ComicSansMS-Bold", size: UIFont.labelFontSize))
//                        .font(.system(size: UIFont.labelFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(task.taskDescription)
                        .font(.custom("ComicSansMS-Bold", size: UIFont.labelFontSize))
//                        .font(.system(size: UIFont.labelFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .overlay(
                    GeometryReader { geometry in
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                        }
                        .stroke(Color.gray, lineWidth:2)
                        .opacity(task.isCompleted ? 1 : 0)
                    }
                )
                Image(systemName: "checkmark")
                    .foregroundStyle(.gray)
                    .opacity(task.isCompleted ? 1 : 0)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 50, coordinateSpace: .local)
                    .onEnded{gesture in
                        if abs(gesture.translation.width) > abs(gesture.translation.height){
                            let translation = gesture.translation.width
                            if translation > 100 {
                                handleCompleteSwap()
                            }
                            else if translation < -100 {
                                handleIncompleteSwap()
                            }
                        }
                    }
            )
            .contextMenu{
                if task.isCompleted {
                    Button(action:{
                        handleIncompleteSwap()
                    }) {
                        Label("Mark as incomplete", systemImage: "arrowshape.turn.up.left")
                    }
                } else {
                    Button(action:{
                        handleCompleteSwap()
                    }) {
                        Label("Mark as complete", systemImage: "checkmark")
                    }
                }
                Button(action: {
                    handleDelete()
                }){
                    Label("Erase from list", systemImage: "eraser")
                }
            }
            
        }
        
        private func handleCompleteSwap(){
            if task.isCompleted {
                return
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                task.isCompleted = true
            }
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        
        private func handleIncompleteSwap(){
            if !task.isCompleted {
                return
            }
            withAnimation(.easeInOut(duration: 0.3)){
                task.isCompleted = false
            }
        }
        
        private func handleDelete(){
            todayTask.tasks.removeAll(where: {$0.id == task.id})
            context.delete(task)
            try? context.save()
        }
        
    }
    
    private func didDismiss(){
    }
    
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DailyTasks.self, Task.self, configurations: config)
    return ContentView().modelContainer(container)
}
