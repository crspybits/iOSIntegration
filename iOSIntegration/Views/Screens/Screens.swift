//
//  Screens.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 9/29/20.
//

import Foundation
import SwiftUI

enum Screens {
    static let signIn = AnyView(LandingView())
    static let fileAccess = AnyView(FilesView())
    static let mail = AnyView(SendMailView())
    static let logger = AnyView(LoggerView())
}
