import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    var body: some View {
        ARViewContainer()
            .ignoresSafeArea()
    }
}

struct ARViewContainer: UIViewRepresentable {

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)

        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.goal = .anyPlane
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coaching)

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        context.coordinator.arView = arView

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject {
        weak var arView: ARView?

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = recognizer.location(in: arView)

            if arView.entity(at: tapLocation) != nil { return }

            let results = arView.raycast(
                from: tapLocation,
                allowing: .estimatedPlane,
                alignment: .any
            )

            guard let firstResult = results.first,
                  let planeAlignment = alignment(for: firstResult) else { return }

            let entity: PlaceableEntity
            switch planeAlignment {
            case .horizontal:
                entity = CustomModelEntity(modelName: "nxp", scale: 1.5)
            case .vertical:
                entity = BoardEntity(uiImage: "rozklad", scale: 1.0)
            @unknown default:
                return
            }

            place(entity, at: firstResult, planeAlignment: planeAlignment, in: arView)
        }

        private func alignment(for result: ARRaycastResult) -> ARPlaneAnchor.Alignment? {
            if let planeAnchor = result.anchor as? ARPlaneAnchor {
                return planeAnchor.alignment
            }
            switch result.targetAlignment {
            case .horizontal:
                return .horizontal
            case .vertical:
                return .vertical
            default:
                return nil
            }
        }

        private func place(
            _ entity: PlaceableEntity,
            at result: ARRaycastResult,
            planeAlignment: ARPlaneAnchor.Alignment,
            in arView: ARView
        ) {
            guard entity.allowedAlignment == planeAlignment else { return }

            let anchor = AnchorEntity(world: result.worldTransform)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)

            // Obrót dwoma palcami, przesuwanie jednym, skalowanie "pinch"
            arView.installGestures([.rotation, .translation, .scale], for: entity)
        }
    }
}

#Preview {
    ContentView()
}
