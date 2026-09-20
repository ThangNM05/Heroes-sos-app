//
//  INoteListViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
protocol INoteListViewModel: IBaseViewModel {
    var notes: [Note] { get }
    
    func fetchNotes() async
    func deleteNote(at offsets: IndexSet) async
}
