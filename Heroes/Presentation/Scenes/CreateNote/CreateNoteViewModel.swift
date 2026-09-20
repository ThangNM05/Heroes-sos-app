//
//  CreateNoteViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class CreateNoteViewModel: BaseViewModel, ICreateNoteViewModel {
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var isSuccess: Bool = false

    private let createNoteService: ICreateNoteService

    init(createNoteService: ICreateNoteService) {
        self.createNoteService = createNoteService
        super.init()
    }

    func saveNote() async {
        isLoading = true
        clearError()
        defer { isLoading = false }

        do {
            _ = try await createNoteService.execute(title: title, content: content)
            isSuccess = true
        } catch {
            handleError(error)
        }
    }
}
