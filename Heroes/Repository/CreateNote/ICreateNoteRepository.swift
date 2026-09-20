//
//  ICreateNoteRepository.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol ICreateNoteRepository: AnyObject {
    func createNote(title: String, content: String) async throws -> Note
}
