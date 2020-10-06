//
//  ViewModel.swift
//  SharingExtensionUI
//
//  Created by Christopher G Prince on 10/4/20.
//

import Foundation
import SwiftUI
import iOSSignIn
import ServerShared

struct SharingGroupData: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    
    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

enum Preview {
    case image(UIImage, URL)
}

class ViewModel: ObservableObject {
    @Published var width: CGFloat = 0
    @Published var height: CGFloat = 0
    @Published var sharingGroups = [SharingGroupData]()
    @Published var userSignedIn: Bool = true
    @Published var preview: Preview?
    @Published var selectedSharingGroupUUID: UUID?
    var cancel:(()->())?
    var post:((Preview, _ sharingGroupUUID: UUID)->())!
}
