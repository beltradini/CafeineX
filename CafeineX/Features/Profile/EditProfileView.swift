import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let profile: UserProfile

    @State private var displayName: String
    @State private var goal: ProfileGoal
    @State private var avatarData: Data?
    @State private var selectedPhoto: PhotosPickerItem?

    init(profile: UserProfile) {
        self.profile = profile
        _displayName = State(initialValue: profile.displayName)
        _goal = State(initialValue: profile.goal)
        _avatarData = State(initialValue: profile.avatarData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        ProfileAvatarView(data: avatarData, size: 104)

                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images
                        ) {
                            Label("Choose Photo", systemImage: "photo.badge.plus")
                        }
                        .buttonStyle(.bordered)

                        if avatarData != nil {
                            Button("Remove Photo", role: .destructive) {
                                avatarData = nil
                                selectedPhoto = nil
                            }
                            .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Identity") {
                    TextField("Preferred name", text: $displayName)
                        .textInputAutocapitalization(.words)

                    Picker("Primary goal", selection: $goal) {
                        ForEach(ProfileGoal.allCases) { goal in
                            Label(goal.title, systemImage: goal.symbol)
                                .tag(goal)
                        }
                    }
                }

                Section("Future Sync") {
                    Label(
                        "This profile has a stable private identifier and is ready to link with Sign in with Apple in a future release.",
                        systemImage: "person.crop.circle.badge.checkmark"
                    )
                    .font(.subheadline)

                    Text("Your photo and name stay on this device today. Authentication credentials will be stored in Keychain when account sync is introduced.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                }
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto else { return }
                if let data = try? await selectedPhoto.loadTransferable(type: Data.self) {
                    avatarData = normalizedAvatarData(data)
                }
            }
        }
    }

    private func save() {
        do {
            try UserProfileStore.save(
                profile,
                displayName: displayName,
                avatarData: avatarData,
                goal: goal,
                in: modelContext
            )
            dismiss()
        } catch {
            assertionFailure("Unable to save profile: \(error)")
        }
    }

    private func normalizedAvatarData(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let target = CGSize(width: 512, height: 512)
        let thumbnail = image.preparingThumbnail(of: target) ?? image
        return thumbnail.jpegData(compressionQuality: 0.82)
    }
}
