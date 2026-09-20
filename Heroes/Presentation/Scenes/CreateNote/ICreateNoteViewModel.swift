//
//  ICreateNoteViewModel.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import Combine

@MainActor
protocol ICreateNoteViewModel: IBaseViewModel {
    var title: String { get set }
    var content: String { get set }
    var isSuccess: Bool { get set }
    
    func saveNote() async
}
