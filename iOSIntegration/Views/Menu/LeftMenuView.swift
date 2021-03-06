
// Adapted from https://github.com/BLCKBIRDS/Side-Menu--Hamburger-Menu--in-SwiftUI

import SwiftUI

struct LeftMenuView: View {
    @Environment(\.sideMenuLeftPanelKey) var sideMenuLeftPanel
    @Environment(\.sideMenuCenterViewKey) var sideMenuCenterView
    @ObservedObject var viewModel:ViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            MenuButtonView(viewModel: viewModel, menuItemName: "Files", imageSystemName: "person", topPadding: 30, menuChoice: Screens.fileAccess)
            MenuButtonView(viewModel: viewModel, menuItemName: "Logs", imageSystemName: "pencil.circle", topPadding: 30, menuChoice: Screens.logger, canDisable: false)
            MenuButtonView(viewModel: viewModel, menuItemName: "Mail", imageSystemName: "envelope", topPadding: 30, menuChoice: Screens.mail)
            MenuButtonView(viewModel: viewModel, menuItemName: "SignIn", imageSystemName: "gear", topPadding: 30, menuChoice: Screens.signIn, canDisable: false)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 32/255, green: 32/255, blue: 32/255))
        .edgesIgnoringSafeArea(.all)
    }
}

struct MenuButtonView: View {
    @Environment(\.sideMenuLeftPanelKey) var sideMenuLeftPanel
    @Environment(\.sideMenuCenterViewKey) var sideMenuCenterView
    @ObservedObject var viewModel:ViewModel
    let menuItemName: String
    let imageSystemName: String
    let topPadding: CGFloat
    let canDisable: Bool
    let menuChoice: AnyView
    
    init(viewModel:ViewModel, menuItemName: String, imageSystemName: String, topPadding: CGFloat, menuChoice: AnyView, canDisable: Bool = true) {
        self.viewModel = viewModel
        self.menuItemName = menuItemName
        self.imageSystemName = imageSystemName
        self.topPadding = topPadding
        self.canDisable = canDisable
        self.menuChoice = menuChoice
    }
    
    var body: some View {
        Button(action: {
            withAnimation {
                self.sideMenuCenterView.wrappedValue = menuChoice
                self.sideMenuLeftPanel.wrappedValue = false
            }
        }) {
            Image(systemName: imageSystemName)
                .imageScale(.large)
            Text(menuItemName)
        }
        .foregroundColor(.gray)
        .font(.headline)
        .padding(.top, topPadding)
        .disabled(disable())
        .opacity(disable() ? 0.5 : 1)
    }
    
    func disable() -> Bool {
        guard canDisable else {
            return false
        }
        
        return !viewModel.userSignedIn
    }
}

