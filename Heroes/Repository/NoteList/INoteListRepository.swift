//
//  INoteListRepository.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol INoteListRepository: AnyObject {
    func fetchNotes() async throws -> [Note]
    func deleteNote(id: UUID) async throws
}
