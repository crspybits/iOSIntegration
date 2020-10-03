
import SwiftUI
import SFSafeSymbols
import SideMenu

struct MenuNavBar<Content: View>: View {
    @Environment(\.sideMenuLeftPanelKey) var sideMenuLeftPanel

    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                self.content
            }
            .navigationBarTitle("Sign In", displayMode: .inline)
                .navigationBarItems(
                    leading: Button(action: {
                        withAnimation {
                            self.sideMenuLeftPanel.wrappedValue = !self.sideMenuLeftPanel.wrappedValue
                        }
                    }, label: {
                        Image(systemName: SFSymbol.lineHorizontal3.rawValue)
                            .accentColor(.blue)
                            .imageScale(.large)
                    })
            )
        }
    }
}

