import SwiftUI
import RealityKit
import ARKit
import CoreLocation
import Combine

enum BeaconConfig {
    static let maxDistance: Double = 12.0
    static let far: Double = 8.0
    static let boardTriggerDistance: Double = 5.0
    static let close: Double = 4.0
    static let veryClose: Double = 2.0
}

struct BeaconPoint: Identifiable {
    let id = UUID()
    let name: String
    let major: Int
    let minor: Int
    var found: Bool = false
    var distance: Double? = nil
}

struct ContentView: View {

    @StateObject private var locationManager = LocationManager()

    @State private var points: [BeaconPoint] = [
        BeaconPoint(name: "Door", major: 1, minor: 100)
    ]

    private var isNearDoorBeacon: Bool {
        points.first(where: { $0.major == 1 && $0.minor == 100 })?.found ?? false
    }

    private var nearestBeaconPoint: BeaconPoint? {
        points
            .filter { $0.distance != nil }
            .min(by: { ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude) })
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ARViewContainer(showBoard: isNearDoorBeacon)
                .ignoresSafeArea()

            Group {
                if let nearest = nearestBeaconPoint, let distance = nearest.distance {
                    Text(String(format: "Najbliższy beacon (%@): %.2f m", nearest.name, distance))
                } else {
                    Text("Najbliższy beacon: brak w zasięgu")
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.top, 16)
            .padding(.leading, 16)
        }
        .onReceive(locationManager.$detectedBeacons) { beacons in
            update(beacons: beacons)
        }
    }

    private func update(beacons: [CLBeacon]) {
        DispatchQueue.main.async {
            for index in self.points.indices {
                let point = self.points[index]

                guard let beacon = beacons.first(where: {
                    $0.major.intValue == point.major &&
                    $0.minor.intValue == point.minor
                }) else {
                    self.points[index].distance = nil
                    self.points[index].found = false
                    continue
                }

                let rawDistance = self.locationManager.filteredDistance(for: beacon) ?? beacon.accuracy
                let distance = rawDistance > 0 ? rawDistance : nil
                self.points[index].distance = distance

                guard let d = distance else {
                    self.points[index].found = false
                    continue
                }

                self.points[index].found = d <= BeaconConfig.boardTriggerDistance
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    var showBoard: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.delegate = context.coordinator
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
        context.coordinator.updateBoardState(showBoard: showBoard)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateBoardState(showBoard: showBoard)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        private var showBoard: Bool = false
        private var boardAnchor: AnchorEntity?

        func updateBoardState(showBoard: Bool) {
            self.showBoard = showBoard
            if showBoard {
                tryPlaceBoardOnExistingVerticalPlane()
            } else {
                removeBoard()
            }
        }

        private func removeBoard() {
            boardAnchor?.removeFromParent()
            boardAnchor = nil
        }

        private func tryPlaceBoardOnExistingVerticalPlane() {
            guard showBoard, boardAnchor == nil, let arView = arView else { return }

            if let anchors = arView.session.currentFrame?.anchors {
                for anchor in anchors {
                    if let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical {
                        let board = BoardEntity(uiImage: "rozklad", scale: 1.0)
                        boardAnchor = place(
                            board,
                            transform: planeAnchor.transform,
                            planeAlignment: .vertical,
                            in: arView
                        )
                        if boardAnchor != nil { return }
                    }
                }
            }
        }

        nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            handleDetectedAnchors(anchors)
        }

        nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            handleDetectedAnchors(anchors)
        }

        private nonisolated func handleDetectedAnchors(_ anchors: [ARAnchor]) {
            let verticalTransform = anchors
                .compactMap { $0 as? ARPlaneAnchor }
                .first(where: { $0.alignment == .vertical })?
                .transform

            guard let transform = verticalTransform else { return }

            Task { @MainActor in
                guard self.showBoard, self.boardAnchor == nil, let arView = self.arView else { return }
                let board = BoardEntity(uiImage: "rozklad", scale: 1.0)
                self.boardAnchor = self.place(
                    board,
                    transform: transform,
                    planeAlignment: .vertical,
                    in: arView
                )
            }
        }

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

            switch planeAlignment {
            case .horizontal:
                let customEntity = CustomModelEntity(modelName: "nxp", scale: 1.5)
                place(
                    customEntity,
                    transform: firstResult.worldTransform,
                    planeAlignment: planeAlignment,
                    in: arView
                )
            case .vertical:
                guard showBoard, boardAnchor == nil else { return }
                let boardEntity = BoardEntity(uiImage: "rozklad", scale: 1.0)
                boardAnchor = place(
                    boardEntity,
                    transform: firstResult.worldTransform,
                    planeAlignment: planeAlignment,
                    in: arView
                )
            @unknown default:
                return
            }
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

        @discardableResult
        private func place(
            _ entity: PlaceableEntity,
            transform: simd_float4x4,
            planeAlignment: ARPlaneAnchor.Alignment,
            in arView: ARView
        ) -> AnchorEntity? {
            guard entity.allowedAlignment == planeAlignment else { return nil }

            let anchor = AnchorEntity(world: transform)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)

            // Obrót dwoma palcami, przesuwanie jednym, skalowanie "pinch"
            arView.installGestures([.rotation, .translation, .scale], for: entity)
            return anchor
        }
    }
}

#Preview {
    ContentView()
}
