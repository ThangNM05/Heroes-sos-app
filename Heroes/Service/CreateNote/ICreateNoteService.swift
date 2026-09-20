//
//  ICreateNoteService.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation

protocol ICreateNoteService: AnyObject {
    func execute(title: String, content: String) async throws -> Note
}
