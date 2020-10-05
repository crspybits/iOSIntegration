//
//  ButtonBar.swift
//  SharingExtensionUI
//
//  Created by Christopher G Prince on 10/4/20.
//

import Foundation
import SwiftUI
import iOSSignIn

struct ButtonBar: View {
    @ObservedObject var viewModel:ViewModel
    
    var body: some View {
        HStack {
            Button("Cancel", action: {
            
            })
            Spacer()
            Button("Post", action: {
            
            })
        }
        .frame(height: 50)
    }
}

struct ButtonBar_Previews: PreviewProvider {
    static let viewModel = ViewModel()
    static var previews: some View {
        viewModel.width = 150
        viewModel.height = 300
        return ButtonBar(viewModel: viewModel)
    }
}

