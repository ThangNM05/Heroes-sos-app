//
//  NoteListViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class NoteListViewModel: BaseViewModel, INoteListViewModel {
    @Published var notes: [Note] = []

    private let noteListService: INoteListService

    init(noteListService: INoteListService) {
        self.noteListService = noteListService
        super.init()
    }

    func fetchNotes() async {
        print("🔍 [NoteListViewModel] Fetching notes...")
        isLoading = true
        clearError()
        defer { isLoading = false }

        do {
            notes = try await noteListService.getNotes()
            print("✅ [NoteListViewModel] Fetched \(notes.count) notes successfully.")
        } catch {
            print("❌ [NoteListViewModel] Error fetching notes: \(error.localizedDescription)")
            handleError(error)
        }
    }

    func deleteNote(at offsets: IndexSet) async {
        for index in offsets {
            let note = notes[index]
            do {
                print("🗑️ [NoteListViewModel] Deleting note: \(note.title)")
                try await noteListService.deleteNote(id: note.id)
            } catch {
                print("❌ [NoteListViewModel] Error deleting note: \(error.localizedDescription)")
                handleError(error)
            }
        }
        await fetchNotes()
    }
}
