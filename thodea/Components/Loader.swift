import SwiftUI
import WebKit

struct Loader: View {
    @State private var rotate = false
    @State private var rotationAngle: Double = 0.0
    // @State private var fadeIn = false // 1. Removed fadeIn state

    var body: some View {
        ZStack {
            Color(red: 17/255, green: 24/255, blue: 39/255)
                .ignoresSafeArea()

            VStack {
                Spacer().frame(height: 12)
                ZStack {
                    // 1. Center logo (stays stationary)
                    Image("logo")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())

                    // 2. Group for all rotating elements
                    ZStack {
                        // Spinning border ring
                        Circle()
                            .strokeBorder(Color(.systemBlue).opacity(0.8), lineWidth: 1)
                       
                        // Rotating blue dot
                        Circle()
                            .fill(Color(red: 23/255, green: 105/255, blue: 254/255))
                            .frame(width: 5, height: 5)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                            // 3. Offset to the top edge *before* rotation
                            .offset(y: -23.5)

                    }
                    .frame(width: 48, height: 48) // Set frame for the rotating group
                    // 4. Apply rotation and animation ONCE to the group
                    .rotationEffect(.degrees(rotationAngle))
                }
                // .frame(width: 48, height: 48) // No longer needed here
                .onAppear {
                    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                                        // Set the target angle (e.g., 360 degrees for one full rotation)
                                        // The animation repeats this change forever.
                                        rotationAngle = 360.0
                                    }
                    // fadeIn = true // 5. Removed fadeIn logic
                }
                
                // --- THIS IS THE FIX ---
                // Add a Spacer here to push the VStack content to the top
                Spacer()
                // -----------------------
            }
        }
    }
}

struct Loader_Previews: PreviewProvider {
    static var previews: some View {
        Loader()
    }
}
