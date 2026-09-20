//
//  NoteListView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct NoteListView: View {
    @StateObject private var viewModel: NoteListViewModel
    @State private var showingCreateNote = false

    init(viewModel: NoteListViewModel? = nil) {
        let vm = viewModel ?? NoteListViewModel(noteListService: AppDIContainer.shared.resolve())
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.notes.isEmpty {
                    ProgressView("Loading notes...")
                } else if viewModel.notes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Notes Available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("Create Your First Note") {
                            showingCreateNote = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(viewModel.notes) { note in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(note.title)
                                    .font(.headline)
                                Text(note.content)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { offsets in
                            Task {
                                await viewModel.deleteNote(at: offsets)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateNote = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateNote, onDismiss: {
                Task {
                    await viewModel.fetchNotes()
                }
            }) {
                CreateNoteView()
            }
            .task {
                await viewModel.fetchNotes()
            }
        }
    }
}

#Preview {
    NoteListView(
        viewModel: NoteListViewModel(
            noteListService: NoteListService(
                repository: NoteListRepository(networkClient: NetworkClient())
            )
        )
    )
}
