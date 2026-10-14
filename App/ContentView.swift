import SwiftUI
import Charts

// MARK: - Models
struct Habit: Identifiable, Codable {
    var id = UUID()
    var title: String
    var subtitle: String
    var icon: String
    var colorHex: String
    var completedDates: Set<String> = []
}

// MARK: - ViewModel (Saves automatically to iPhone Storage)
class HabitStore: ObservableObject {
    @Published var habits: [Habit] = [] {
        didSet { save() }
    }
    
    private let storageKey = "WinterArcHabitsData_90Day"
    
    init() {
        load()
    }
    
    func toggle(habit: Habit, dateKey: String) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        if habits[index].completedDates.contains(dateKey) {
            habits[index].completedDates.remove(dateKey)
        } else {
            habits[index].completedDates.insert(dateKey)
        }
    }
    
    func addHabit(title: String, subtitle: String, icon: String, colorHex: String) {
        let newHabit = Habit(title: title, subtitle: subtitle, icon: icon, colorHex: colorHex)
        habits.append(newHabit)
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        } else {
            let today = Self.dateKey(for: Date())
            habits = [
                Habit(title: "Cold Plunge or Shower", subtitle: "Building mental resilience", icon: "snowflake", colorHex: "#00D2FF", completedDates: [today]),
                Habit(title: "Hit Hard Training", subtitle: "60 mins physical push", icon: "dumbbell.fill", colorHex: "#5E5CE6", completedDates: [today]),
                Habit(title: "Clean Eating & Water", subtitle: "Zero cheat meals, stay hydrated", icon: "flame.fill", colorHex: "#0A84FF", completedDates: [today]),
                Habit(title: "10 Pages Focus Reading", subtitle: "Develop key intellect", icon: "book.fill", colorHex: "#64D2FF", completedDates: []),
                Habit(title: "Recover Before 10:30 PM", subtitle: "Prioritize sleep & recovery", icon: "moon.stars.fill", colorHex: "#30D158", completedDates: [today])
            ]
        }
    }
    
    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Main Dashboard View
struct ContentView: View {
    @StateObject private var store = HabitStore()
    @State private var selectedDate: Date = Date()
    @State private var showingAddSheet = false
    
    // Config: Winter Arc 2026 starts Oct 1, 2026 for 90 Days
    private let arcStartDate: Date = {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 10
        comps.day = 1
        comps.hour = 0
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    
    private var arcProgress: (daysPassed: Int, totalDays: Int, percent: Double) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: arcStartDate)
        
        let diff = calendar.dateComponents([.day], from: start, to: today)
        let daysPassed = max(0, (diff.day ?? 0) + 1) // Count starts from 1 on Oct 1st
        
        let totalDays = 90
        let percent = min(1.0, max(0.0, Double(daysPassed) / Double(totalDays)))
        return (daysPassed, totalDays, percent)
    }
    
    private var currentWeekDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (-6...0).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
    
    private var selectedDateKey: String {
        HabitStore.dateKey(for: selectedDate)
    }
    
    private var completionProgress: Double {
        guard !store.habits.isEmpty else { return 0 }
        let completed = store.habits.filter { $0.completedDates.contains(selectedDateKey) }.count
        return Double(completed) / Double(store.habits.count)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Winter Arc Progress Card (October 1st Milestone Timer)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("WINTER ARC TIMELINE")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.cyan)
                                
                                Text("Day \(arcProgress.daysPassed) / \(arcProgress.totalDays)")
                                    .font(.title2.weight(.heavy))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            Text("\(Int(arcProgress.percent * 100))%")
                                .font(.title.bold())
                                .foregroundStyle(.cyan)
                        }
                        
                        // Custom Ice Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(height: 10)
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.cyan, Color.blue, Color.indigo],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(arcProgress.percent), height: 10)
                                    .shadow(color: Color.cyan.opacity(0.4), radius: 4, x: 0, y: 0)
                            }
                        }
                        .frame(height: 10)
                        
                        HStack {
                            Text("Started Oct 1, 2026")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            let daysLeft = max(0, arcProgress.totalDays - arcProgress.daysPassed)
                            Text("\(daysLeft) Days Remaining")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(18)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                    )
                    
                    // Date picker Strip
                    HStack(spacing: 8) {
                        ForEach(currentWeekDates, id: \.self) { date in
                            let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDate = date
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Text(date.formatted(.dateTime.weekday(.narrow)))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(isSelected ? .black : .secondary)
                                    
                                    Text(date.formatted(.dateTime.day()))
                                        .font(.callout.weight(.bold))
                                        .foregroundStyle(isSelected ? .black : .primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSelected ? Color.cyan : Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                    
                    // Daily metrics & weekly charts
                    HStack(spacing: 16) {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .stroke(Color.cyan.opacity(0.18), lineWidth: 12)
                                Circle()
                                    .trim(from: 0, to: completionProgress)
                                    .stroke(
                                        AngularGradient(colors: [.cyan, .blue, .indigo, .cyan], center: .center),
                                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .animation(.spring(duration: 0.6), value: completionProgress)
                                
                                VStack(spacing: 2) {
                                    Text("\(Int(completionProgress * 100))%")
                                        .font(.title3.bold())
                                    Text("LOCKED")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 90, height: 90)
                            
                            Text("Protocol Completed")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Consistency")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            Chart {
                                ForEach(currentWeekDates, id: \.self) { date in
                                    let key = HabitStore.dateKey(for: date)
                                    let count = store.habits.filter { $0.completedDates.contains(key) }.count
                                    BarMark(
                                        x: .value("Day", date.formatted(.dateTime.weekday(.narrow))),
                                        y: .value("Completed", count)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(colors: [.cyan, .indigo], startPoint: .top, endPoint: .bottom)
                                    )
                                    .cornerRadius(5)
                                }
                            }
                            .chartYScale(domain: 0...max(store.habits.count, 1))
                            .frame(height: 95)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    
                    // Active habits list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Protocol Tasks")
                            .font(.headline)
                            .padding(.horizontal, 4)
                        
                        ForEach(store.habits) { habit in
                            let isDone = habit.completedDates.contains(selectedDateKey)
                            let accent = Color(hex: habit.colorHex)
                            
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.25)) {
                                    store.toggle(habit: habit, dateKey: selectedDateKey)
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: habit.icon)
                                        .font(.title3)
                                        .foregroundStyle(accent)
                                        .frame(width: 44, height: 44)
                                        .background(accent.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(habit.title)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(habit.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(isDone ? accent : Color.secondary.opacity(0.35))
                                }
                                .padding(14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Winter Arc ❄️")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.cyan)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddHabitSheet(store: store)
                    .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - New Habit Modal Sheet
struct AddHabitSheet: View {
    @ObservedObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var subtitle = ""
    @State private var selectedIcon = "snowflake"
    @State private var selectedColor = "#00D2FF"
    
    let icons = ["snowflake", "dumbbell.fill", "flame.fill", "brain.head.profile", "moon.stars.fill", "figure.run"]
    let colors = ["#00D2FF", "#0A84FF", "#5E5CE6", "#30D158", "#FF2D55"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Protocol Details") {
                    TextField("Goal Title (e.g. Cold Plunge)", text: $title)
                    TextField("Daily Target (e.g. 3 mins)", text: $subtitle)
                }
                
                Section("Icon & Accent") {
                    HStack(spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 38, height: 38)
                                .background(selectedIcon == icon ? Color.primary.opacity(0.15) : Color.clear)
                                .clipShape(Circle())
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == hex ? 2.5 : 0)
                                )
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                }
            }
            .navigationTitle("New Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addHabit(
                            title: title.isEmpty ? "New Protocol" : title,
                            subtitle: subtitle.isEmpty ? "Daily non-negotiable" : subtitle,
                            icon: selectedIcon,
                            colorHex: selectedColor
                        )
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Hex Color Helper
extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}