//
//  INoteListService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol INoteListService: AnyObject {
    func getNotes() async throws -> [Note]
    func deleteNote(id: UUID) async throws
}
