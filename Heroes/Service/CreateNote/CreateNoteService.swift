//
//  CreateNoteService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

final class CreateNoteService: ICreateNoteService {
    private let repository: ICreateNoteRepository

    init(repository: ICreateNoteRepository) {
        self.repository = repository
    }

    func execute(title: String, content: String) async throws -> Note {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            throw NSError(domain: "CreateNoteService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Note title cannot be empty."])
        }

        return try await repository.createNote(title: trimmedTitle, content: trimmedContent)
    }
}
