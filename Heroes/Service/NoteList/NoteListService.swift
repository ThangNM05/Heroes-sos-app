//
//  NoteListService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

final class NoteListService: INoteListService {
    private let repository: INoteListRepository

    init(repository: INoteListRepository) {
        self.repository = repository
    }

    func getNotes() async throws -> [Note] {
        return try await repository.fetchNotes()
    }

    func deleteNote(id: UUID) async throws {
        try await repository.deleteNote(id: id)
    }
}
