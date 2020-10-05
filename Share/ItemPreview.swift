//
//  ItemPreview.swift
//  SharingExtensionUI
//
//  Created by Christopher G Prince on 10/4/20.
//

import SwiftUI

struct ItemPreview: View {
    var body: some View {
        Image("us")
            .resizable()
            .aspectRatio(1, contentMode: .fit)
    }
}

struct ItemPreview_Previews: PreviewProvider {
    static var previews: some View {
        ItemPreview()
    }
}
