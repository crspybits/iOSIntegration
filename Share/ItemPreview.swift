//
//  ItemPreview.swift
//  SharingExtensionUI
//
//  Created by Christopher G Prince on 10/4/20.
//

import SwiftUI

struct ItemPreview: View {
    @ObservedObject var viewModel:ViewModel

    var body: some View {
        if let preview = viewModel.preview {
            switch preview {
            case .image(let image, _):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        else {
            Rectangle()
                .background(Color(UIColor.systemFill))
        }
    }
}

struct ItemPreview_Previews: PreviewProvider {
    static let viewModel = ViewModel()
    static var previews: some View {
        ItemPreview(viewModel: viewModel)
    }
}
