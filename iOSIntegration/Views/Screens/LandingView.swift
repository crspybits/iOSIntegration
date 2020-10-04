
// Initial landing view, when the app first starts: Enable the user to sign in.
// Menu functionality adapted from https://github.com/Vidhyadharan24/SideMenu

import SwiftUI

struct LandingView: View {        
    var body: some View {
        MenuNavBar(title: "Sign In") {
            VStack {
                if Services.session.setupFailure {
                    Text("Setup Failure!")
                        .background(Color.red)
                }

                Services.session.signInServices.signInView
            }
        }
    }
}

#if DEBUG
struct PopularPhotosView_Previews : PreviewProvider {
    static var previews: some View {
        LandingView()
    }
}
#endif
