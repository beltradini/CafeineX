import SwiftData
import SwiftUI

struct ExposureDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PersistenceIssueCenter.self) private var persistenceIssues

    let item: ExposureItem

    @Query private var cigaretteDetailsValues: [CigaretteEventDetails]
    @Query private var cigaretteProfiles: [CigaretteProfile]

    @State private var isEditing = false
    @State private var isConfirmingDeletion = false

    var body: some View {
        ZStack {
            CXBackgroundView()

            List {
                Section {
                    CXGlassCard {
                        VStack(spacing: 16) {
                            Image(systemName: item.symbol)
                                .font(.largeTitle)
                                .foregroundStyle(tint)
                                .accessibilityHidden(true)

                            Text(item.title)
                                .font(.title2.bold())

                            Text(item.amountText)
                                .font(.largeTitle.bold())
                                .foregroundStyle(tint)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section("Event") {
                    LabeledContent("Substance", value: item.kind.title)
                    LabeledContent("Date") {
                        Text(item.date, format: .dateTime.day().month().year())
                    }
                    LabeledContent("Time") {
                        Text(item.date, style: .time)
                    }
                    LabeledContent("Source", value: item.sourceTitle)

                    if let note = item.note {
                        LabeledContent("Note", value: note)
                    }
                }

                if let cigaretteDetails {
                    Section("Cigarette Context") {
                        if let profile = cigaretteProfile(for: cigaretteDetails) {
                            LabeledContent("Product", value: profile.name)
                        }
                        if let context = cigaretteDetails.context {
                            LabeledContent("Context") {
                                Label(context.title, systemImage: context.symbol)
                            }
                        } else {
                            LabeledContent("Context", value: "Not recorded")
                        }
                        Text("Patterns describe timing in your records. They do not estimate absorbed nicotine or prove health effects.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if item.isHealthLinked {
                    Section {
                        Label(
                            "This record is linked to Apple Health and is read-only in CafeineX. Manage the Health copy from the Health app.",
                            systemImage: "heart.text.square"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                if item.canModify {
                    Section {
                        Button("Delete Event", role: .destructive) {
                            isConfirmingDeletion = true
                        }
                    } footer: {
                        Text("Deleting removes this event from CafeineX and updates local exposure guidance.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if item.canModify {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            ExposureEditorView(item: item)
        }
        .confirmationDialog(
            "Delete this event?",
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Delete Event", role: .destructive) {
                delete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var tint: Color {
        item.kind == .caffeine ? CXTheme.caffeineAccent : CXTheme.nicotineAccent
    }

    private var cigaretteDetails: CigaretteEventDetails? {
        guard case .nicotine(let entry) = item, entry.product == .cigarette else { return nil }
        return cigaretteDetailsValues.first { $0.nicotineEntryID == entry.id }
    }

    private func cigaretteProfile(for details: CigaretteEventDetails) -> CigaretteProfile? {
        guard let identifier = details.cigaretteProfileID else { return nil }
        return cigaretteProfiles.first { $0.id == identifier }
    }

    private func delete() {
        switch item {
        case .caffeine(let entry):
            modelContext.delete(entry)
        case .nicotine(let entry):
            let identifier = entry.id
            if let details = cigaretteDetailsValues.first(where: { $0.nicotineEntryID == identifier }) {
                modelContext.delete(details)
            }
            modelContext.delete(entry)
        }
        if persistenceIssues.attempt("Deleting the exposure event", action: {
            try modelContext.save()
        }) {
            dismiss()
        }
    }
}
