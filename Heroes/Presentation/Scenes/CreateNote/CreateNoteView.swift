//
//  CreateNoteView.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI

struct CreateNoteView: View {
    @StateObject private var viewModel: CreateNoteViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CreateNoteViewModel? = nil) {
        let vm = viewModel ?? CreateNoteViewModel(createNoteService: AppDIContainer.shared.resolve())
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Note Information")) {
                    TextField("Title", text: $viewModel.title)
                    TextEditor(text: $viewModel.content)
                        .frame(minHeight: 120)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .dismissKeyboardOnTapAndDrag()
            .navigationTitle("Create Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveNote()
                            if viewModel.isSuccess {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.title.isEmpty)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Saving...")
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(8)
                }
            }
        }
    }
}

#Preview {
    CreateNoteView(
        viewModel: CreateNoteViewModel(
            createNoteService: CreateNoteService(
                repository: CreateNoteRepository(networkClient: NetworkClient())
            )
        )
    )
}
