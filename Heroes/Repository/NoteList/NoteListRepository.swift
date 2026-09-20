//
//  NoteListRepository.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

final class NoteListRepository: INoteListRepository {
    private let networkClient: INetworkClient
    private let userDefaults: UserDefaults
    private let storageKey = "base_project_notes_list"

    init(networkClient: INetworkClient, userDefaults: UserDefaults = .standard) {
        self.networkClient = networkClient
        self.userDefaults = userDefaults
    }

    func fetchNotes() async throws -> [Note] {
        // Local logic: Read from UserDefaults
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }
        return (try? JSONDecoder().decode([Note].self, from: data)) ?? []
    }

    func deleteNote(id: UUID) async throws {
        var currentNotes = try await fetchNotes()
        currentNotes.removeAll { $0.id == id }
        if let encoded = try? JSONEncoder().encode(currentNotes) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }
}
