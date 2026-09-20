//
//  CreateNoteRepository.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

final class CreateNoteRepository: ICreateNoteRepository {
    private let networkClient: INetworkClient
    private let userDefaults: UserDefaults
    private let storageKey = "base_project_notes_list"

    init(networkClient: INetworkClient, userDefaults: UserDefaults = .standard) {
        self.networkClient = networkClient
        self.userDefaults = userDefaults
    }

    func createNote(title: String, content: String) async throws -> Note {
        let newNote = Note(title: title, content: content)

        // Logic 1: Save locally in UserDefaults
        var existingNotes = fetchLocalNotes()
        existingNotes.insert(newNote, at: 0)
        saveLocalNotes(existingNotes)

        // Logic 2: Optional Remote API Sync via networkClient
        // For example:
        // let response: NoteDTO = try await networkClient.request(
        //     path: "/notes",
        //     method: .post,
        //     jsonBody: ["title": title, "content": content]
        // )

        return newNote
    }

    private func fetchLocalNotes() -> [Note] {
        guard let data = userDefaults.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([Note].self, from: data)) ?? []
    }

    private func saveLocalNotes(_ notes: [Note]) {
        if let encoded = try? JSONEncoder().encode(notes) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
}
