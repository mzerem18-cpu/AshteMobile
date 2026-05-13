import SwiftUI

struct AppsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                Text("Apps Section is Working!")
                    .font(.headline)
                    .padding()
            }
            .navigationTitle("Apps")
        }
    }
}
