import SwiftData
import SwiftUI

struct MyCigarettesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PersistenceIssueCenter.self) private var persistenceIssues
    @Query private var profiles: [CigaretteProfile]
    @Query private var preferences: [CigarettePreferences]

    @State private var editingProfile: CigaretteProfile?
    @State private var isAdding = false
    @State private var showsArchived = false

    var body: some View {
        List {
            Section {
                if let preference = preferences.first {
                    Picker("Focus", selection: Binding(
                        get: { preference.goal },
                        set: {
                            preference.goal = $0
                            preference.updatedAt = .now
                            persistenceIssues.attempt("Saving cigarette goal") {
                                try modelContext.save()
                            }
                        }
                    )) {
                        ForEach(CigaretteGoal.allCases) { goal in
                            Label(goal.title, systemImage: goal.symbol).tag(goal)
                        }
                    }

                    LabeledContent("Optional daily target") {
                        TextField(
                            "None",
                            value: Binding(
                                get: { preference.optionalDailyTarget },
                                set: {
                                    preference.optionalDailyTarget = $0.map { max($0, 0) }
                                    preference.updatedAt = .now
                                    persistenceIssues.attempt("Saving the optional cigarette target") {
                                        try modelContext.save()
                                    }
                                }
                            ),
                            format: .number
                        )
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    }
                }
            } header: {
                Text("Responsible Goal")
            } footer: {
                Text("Targets are optional and never treated as a safe amount. CafeineX highlights patterns without judgment or medical claims.")
            }

            Section("Active Cigarettes") {
                ForEach(activeProfiles) { profile in
                    profileRow(profile)
                        .swipeActions(edge: .leading) {
                            Button {
                                toggleFavorite(profile)
                            } label: {
                                Label(profile.isFavorite ? "Unfavorite" : "Favorite", systemImage: "star.fill")
                            }
                            .tint(.yellow)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Archive") {
                                CigaretteLibrary.archive(profile)
                                persistenceIssues.attempt("Archiving the cigarette profile") {
                                    try modelContext.save()
                                }
                            }
                            .tint(.orange)
                        }
                }
            }

            if !archivedProfiles.isEmpty {
                Section {
                    DisclosureGroup("Archived (\(archivedProfiles.count))", isExpanded: $showsArchived) {
                        ForEach(archivedProfiles) { profile in
                            profileRow(profile)
                                .swipeActions {
                                    Button("Restore") {
                                        profile.isArchived = false
                                        profile.archivedAt = nil
                                        profile.updatedAt = .now
                                        persistenceIssues.attempt("Restoring the cigarette profile") {
                                            try modelContext.save()
                                        }
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                }
            }

            Section {
                Label(
                    "Manufacturer nicotine is label information, not an estimate of nicotine absorbed by your body.",
                    systemImage: "info.circle.fill"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("My Cigarettes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") { isAdding = true }
            }
        }
        .sheet(isPresented: $isAdding) {
            CigaretteProfileEditor()
        }
        .sheet(item: $editingProfile) { profile in
            CigaretteProfileEditor(profile: profile)
        }
        .task {
            persistenceIssues.attempt("Preparing the cigarette library") {
                try CigaretteLibrary.bootstrapIfNeeded(
                    profiles: profiles,
                    preferences: preferences,
                    context: modelContext
                )
            }
        }
    }

    private var activeProfiles: [CigaretteProfile] {
        profiles.filter { !$0.isArchived }.sorted(by: sortProfiles)
    }

    private var archivedProfiles: [CigaretteProfile] {
        profiles.filter(\.isArchived).sorted { $0.name < $1.name }
    }

    private func sortProfiles(_ lhs: CigaretteProfile, _ rhs: CigaretteProfile) -> Bool {
        if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
        if lhs.favoriteOrder != rhs.favoriteOrder {
            return (lhs.favoriteOrder ?? .max) < (rhs.favoriteOrder ?? .max)
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    private func profileRow(_ profile: CigaretteProfile) -> some View {
        Button { editingProfile = profile } label: {
            Label {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(profile.name).font(.headline)
                        if profile.isFavorite {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                        }
                    }
                    Text("\(profile.cigarettesPerPack) per pack • \(profile.useCount) logged")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "smoke.fill").foregroundStyle(CXTheme.nicotineAccent)
            }
        }
        .buttonStyle(.plain)
    }

    private func toggleFavorite(_ profile: CigaretteProfile) {
        profile.isFavorite.toggle()
        profile.favoriteOrder = profile.isFavorite
            ? (profiles.compactMap(\.favoriteOrder).max() ?? -1) + 1
            : nil
        profile.updatedAt = .now
        persistenceIssues.attempt("Updating the favorite cigarette") {
            try modelContext.save()
        }
    }
}

private struct CigaretteProfileEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PersistenceIssueCenter.self) private var persistenceIssues

    let profile: CigaretteProfile?
    @State private var name: String
    @State private var cigarettesPerPack: Int
    @State private var manufacturerNicotineMG: Double?
    @State private var isFavorite: Bool

    init(profile: CigaretteProfile? = nil) {
        self.profile = profile
        _name = State(initialValue: profile?.name ?? "")
        _cigarettesPerPack = State(initialValue: profile?.cigarettesPerPack ?? 20)
        _manufacturerNicotineMG = State(initialValue: profile?.manufacturerNicotineMG)
        _isFavorite = State(initialValue: profile?.isFavorite ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    TextField("Name or brand", text: $name)
                    Stepper("\(cigarettesPerPack) per pack", value: $cigarettesPerPack, in: 1...100)
                    TextField(
                        "Manufacturer nicotine (optional mg)",
                        value: $manufacturerNicotineMG,
                        format: .number.precision(.fractionLength(0...2))
                    )
                    .keyboardType(.decimalPad)
                    Toggle("Favorite", isOn: $isFavorite)
                }
            }
            .navigationTitle(profile == nil ? "New Cigarette" : "Edit Cigarette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        if let profile {
            profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.cigarettesPerPack = cigarettesPerPack
            profile.manufacturerNicotineMG = manufacturerNicotineMG
            profile.isFavorite = isFavorite
            profile.favoriteOrder = isFavorite ? (profile.favoriteOrder ?? 0) : nil
            profile.updatedAt = .now
        } else {
            modelContext.insert(CigaretteProfile(
                name: name,
                cigarettesPerPack: cigarettesPerPack,
                manufacturerNicotineMG: manufacturerNicotineMG,
                isFavorite: isFavorite,
                favoriteOrder: isFavorite ? 0 : nil
            ))
        }
        if persistenceIssues.attempt("Saving the cigarette profile", action: {
            try modelContext.save()
        }) {
            dismiss()
        }
    }
}
