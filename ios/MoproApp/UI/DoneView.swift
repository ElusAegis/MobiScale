import SwiftUI

struct DoneView: View {
    @ObservedObject var flow: AppFlowViewModel
    var body: some View {
        ScrollView {
            Text("🎉 All proofs complete!")
                .font(.title2)
                .padding(.bottom)

            Text(flow.log)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
