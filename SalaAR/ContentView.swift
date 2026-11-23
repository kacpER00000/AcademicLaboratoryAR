import SwiftUI
import RealityKit
import ARKit
import CoreLocation
import Combine

enum BeaconConfig {
    static let doorMajor: Int = 1
    static let doorMinor: Int = 100

    static let maxDistance: Double = 12.0
    static let far: Double = 8.0
    static let boardTriggerDistance: Double = 5.0
    static let stationTriggerDistance: Double = 4.0
    static let stationHideDistance: Double = 5.5
    static let lostTimeout: TimeInterval = 3.0
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
    var lastSeen: Date? = nil

    var key: String {
        "\(major)-\(minor)"
    }

    var isDoor: Bool {
        major == BeaconConfig.doorMajor && minor == BeaconConfig.doorMinor
    }
}

private enum ActiveSheet: Identifiable {
    case modelInfo(PlaceableModel)
    case roomEquipment

    var id: String {
        switch self {
        case .modelInfo(let model): return "model-\(model.id)"
        case .roomEquipment: return "room-equipment"
        }
    }
}

struct ContentView: View {

    @StateObject private var locationManager = LocationManager()

    @State private var points: [BeaconPoint] = [
        BeaconPoint(name: "Door", major: BeaconConfig.doorMajor, minor: BeaconConfig.doorMinor)
    ]

    @State private var selectedModel: PlaceableModel = .nxp
    @State private var isModelPickerPresented: Bool = false
    @State private var activeSheet: ActiveSheet? = nil
    @State private var activeSheetFromStationBeacon: Bool = false

    private var isNearDoorBeacon: Bool {
        points.first(where: { $0.isDoor })?.found ?? false
    }

    private var activeStationBeacon: BeaconPoint? {
        points
            .filter { !$0.isDoor && $0.found }
            .min(by: { ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude) })
    }

    private var nearestBeaconPoint: BeaconPoint? {
        points
            .filter { $0.distance != nil }
            .min(by: { ($0.distance ?? .greatestFiniteMagnitude) < ($1.distance ?? .greatestFiniteMagnitude) })
    }

    var body: some View {
        ZStack {
            ARViewContainer(
                showBoard: isNearDoorBeacon,
                activeStationBeaconKey: activeStationBeacon?.key,
                selectedModel: selectedModel,
                onSelectModelInfo: { model, fromBeacon in
                    activeSheet = .modelInfo(model)
                    activeSheetFromStationBeacon = fromBeacon
                },
                onSelectBoardInfo: {
                    activeSheet = .roomEquipment
                    activeSheetFromStationBeacon = false
                }
            )
            .ignoresSafeArea()

            VStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
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

                        Spacer()
                    }

                    if isNearDoorBeacon {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap.fill")
                            Text("Kliknij na plan, aby zobaczyć wyposażenie sali Apple")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.08, green: 0.20, blue: 0.44).opacity(0.9))
                        .clipShape(Capsule())
                    }

                    if activeStationBeacon != nil {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap.fill")
                            Text("Kliknij na model, aby zobaczyć informacje")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.75))
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)

                Spacer()

                if isModelPickerPresented {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Wybierz model")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button {
                                withAnimation {
                                    isModelPickerPresented = false
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }

                        HStack(spacing: 12) {
                            ForEach(PlaceableModel.allCases) { model in
                                Button {
                                    selectedModel = model
                                    withAnimation {
                                        isModelPickerPresented = false
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: model.iconName)
                                            .font(.title2)
                                        Text(model.title)
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        selectedModel == model
                                            ? Color.blue.opacity(0.85)
                                            : Color.white.opacity(0.18)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.8))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button {
                        withAnimation {
                            isModelPickerPresented = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: selectedModel.iconName)
                            Text("Model: \(selectedModel.title)")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.75))
                        .clipShape(Capsule())
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .modelInfo(let model):
                    ModelInfoSheet(model: model) {
                        activeSheet = nil
                        activeSheetFromStationBeacon = false
                    }
                case .roomEquipment:
                    RoomEquipmentSheet {
                        activeSheet = nil
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: activeStationBeacon?.key) { _, newValue in
            // Gdy odejdziemy od beacona, zamknij również otwarte informacje o jego modelach
            if newValue == nil && activeSheetFromStationBeacon {
                activeSheet = nil
                activeSheetFromStationBeacon = false
            }
        }
        .onChange(of: isNearDoorBeacon) { _, isNear in
            // Gdy odejdziemy od drzwi, zamknij również otwarty podgląd wyposażenia sali
            if !isNear, case .roomEquipment = activeSheet {
                activeSheet = nil
            }
        }
        .onReceive(locationManager.$detectedBeacons) { beacons in
            update(beacons: beacons)
        }
    }

    private func update(beacons: [CLBeacon]) {
        DispatchQueue.main.async {
            let now = Date()

            // Dodaj automatycznie każdy wykryty beacon, który nie jest jeszcze na liście
            for beacon in beacons {
                let major = beacon.major.intValue
                let minor = beacon.minor.intValue
                if !self.points.contains(where: { $0.major == major && $0.minor == minor }) {
                    let isDoor = (major == BeaconConfig.doorMajor && minor == BeaconConfig.doorMinor)
                    let name = isDoor ? "Door" : "Stanowisko \(minor)"
                    self.points.append(BeaconPoint(name: name, major: major, minor: minor))
                }
            }

            for index in self.points.indices {
                let point = self.points[index]

                guard let beacon = beacons.first(where: {
                    $0.major.intValue == point.major &&
                    $0.minor.intValue == point.minor
                }) else {
                    if let lastSeen = point.lastSeen, now.timeIntervalSince(lastSeen) <= BeaconConfig.lostTimeout {
                        continue
                    }
                    self.points[index].distance = nil
                    self.points[index].found = false
                    continue
                }

                let rawDistance = self.locationManager.filteredDistance(for: beacon) ?? beacon.accuracy
                let distance = rawDistance > 0 ? rawDistance : nil
                self.points[index].distance = distance
                self.points[index].lastSeen = now

                guard let d = distance else {
                    self.points[index].found = false
                    continue
                }

                if point.isDoor {
                    self.points[index].found = d <= BeaconConfig.boardTriggerDistance
                } else {
                    // Histereza zapobiega migotaniu zestawu urządzeń na granicy zasięgu
                    if self.points[index].found {
                        self.points[index].found = d <= BeaconConfig.stationHideDistance
                    } else {
                        self.points[index].found = d <= BeaconConfig.stationTriggerDistance
                    }
                }
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    var showBoard: Bool
    var activeStationBeaconKey: String?
    var selectedModel: PlaceableModel
    var onSelectModelInfo: (PlaceableModel, Bool) -> Void
    var onSelectBoardInfo: () -> Void

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
        context.coordinator.selectedModel = selectedModel
        context.coordinator.onSelectModelInfo = onSelectModelInfo
        context.coordinator.onSelectBoardInfo = onSelectBoardInfo
        context.coordinator.updateBoardState(showBoard: showBoard)
        context.coordinator.updateStationState(activeBeaconKey: activeStationBeaconKey)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.selectedModel = selectedModel
        context.coordinator.onSelectModelInfo = onSelectModelInfo
        context.coordinator.onSelectBoardInfo = onSelectBoardInfo
        context.coordinator.updateBoardState(showBoard: showBoard)
        context.coordinator.updateStationState(activeBeaconKey: activeStationBeaconKey)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var selectedModel: PlaceableModel = .nxp
        var onSelectModelInfo: ((PlaceableModel, Bool) -> Void)?
        var onSelectBoardInfo: (() -> Void)?

        private var showBoard: Bool = false
        private var boardAnchor: AnchorEntity?
        private var boardGestures: [UIGestureRecognizer] = []

        private var activeStationBeaconKey: String? = nil
        private var placedStationBeaconKey: String? = nil
        private var stationAnchor: AnchorEntity?
        private var stationGestures: [UIGestureRecognizer] = []

        func updateBoardState(showBoard: Bool) {
            self.showBoard = showBoard
            if showBoard {
                tryPlaceBoardOnExistingVerticalPlane()
            } else {
                removeBoard()
            }
        }

        func updateStationState(activeBeaconKey: String?) {
            self.activeStationBeaconKey = activeBeaconKey

            guard let beaconKey = activeBeaconKey else {
                removeStationShowcase()
                return
            }

            // Jeśli podeszliśmy do innego beacona, usuń poprzedni zestaw i pokaż go przy nowym stanowisku
            if let placedKey = placedStationBeaconKey, placedKey != beaconKey {
                removeStationShowcase()
            }

            if stationAnchor == nil {
                tryPlaceStationShowcaseOnExistingHorizontalPlane()
            }
        }

        private func removeBoard() {
            if let arView = arView {
                for gesture in boardGestures {
                    arView.removeGestureRecognizer(gesture)
                }
            }
            boardGestures.removeAll()
            boardAnchor?.removeFromParent()
            boardAnchor = nil
        }

        private func removeStationShowcase() {
            if let arView = arView {
                for gesture in stationGestures {
                    arView.removeGestureRecognizer(gesture)
                }
            }
            stationGestures.removeAll()
            stationAnchor?.removeFromParent()
            stationAnchor = nil
            placedStationBeaconKey = nil
        }

        private func tryPlaceBoardOnExistingVerticalPlane() {
            guard showBoard, boardAnchor == nil, let arView = arView else { return }

            if let anchors = arView.session.currentFrame?.anchors {
                for anchor in anchors {
                    if let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical {
                        let board = BoardEntity(uiImage: "rozklad", scale: 2.0)
                        if let placed = place(
                            board,
                            transform: planeAnchor.transform,
                            planeAlignment: .vertical,
                            in: arView
                        ) {
                            boardAnchor = placed.anchor
                            boardGestures = placed.gestures
                            return
                        }
                    }
                }
            }
        }

        private func tryPlaceStationShowcaseOnExistingHorizontalPlane() {
            guard let beaconKey = activeStationBeaconKey,
                  stationAnchor == nil,
                  let arView = arView else { return }

            // 1. Preferuj płaszczyznę poziomą znajdującą się na środku ekranu (np. biurko przed użytkownikiem)
            if arView.bounds.width > 0 && arView.bounds.height > 0 {
                let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
                if let result = arView.raycast(from: center, allowing: .existingPlaneGeometry, alignment: .horizontal).first
                    ?? arView.raycast(from: center, allowing: .estimatedPlane, alignment: .horizontal).first {
                    placeStationShowcase(at: result.worldTransform, for: beaconKey, in: arView)
                    return
                }
            }

            // 2. W przeciwnym razie wybierz najbliższą kamerze wykrytą płaszczyznę poziomą
            guard let frame = arView.session.currentFrame else { return }
            let cameraPos = SIMD3<Float>(
                frame.camera.transform.columns.3.x,
                frame.camera.transform.columns.3.y,
                frame.camera.transform.columns.3.z
            )

            let nearestHorizontalPlane = frame.anchors
                .compactMap { $0 as? ARPlaneAnchor }
                .filter { $0.alignment == .horizontal }
                .min { lhs, rhs in
                    let lhsPos = SIMD3<Float>(lhs.transform.columns.3.x, lhs.transform.columns.3.y, lhs.transform.columns.3.z)
                    let rhsPos = SIMD3<Float>(rhs.transform.columns.3.x, rhs.transform.columns.3.y, rhs.transform.columns.3.z)
                    return simd_distance(cameraPos, lhsPos) < simd_distance(cameraPos, rhsPos)
                }

            if let plane = nearestHorizontalPlane {
                placeStationShowcase(at: plane.transform, for: beaconKey, in: arView)
            }
        }

        private func placeStationShowcase(
            at transform: simd_float4x4,
            for beaconKey: String,
            in arView: ARView
        ) {
            let planePosition = SIMD3<Float>(
                transform.columns.3.x,
                transform.columns.3.y,
                transform.columns.3.z
            )

            var anchorTransform = Transform(translation: planePosition)
            if let cameraTransform = arView.session.currentFrame?.camera.transform {
                let cameraPos = SIMD3<Float>(
                    cameraTransform.columns.3.x,
                    cameraTransform.columns.3.y,
                    cameraTransform.columns.3.z
                )
                let dx = cameraPos.x - planePosition.x
                let dz = cameraPos.z - planePosition.z
                if hypot(dx, dz) > 0.01 {
                    let yaw = atan2(dx, dz)
                    anchorTransform.rotation = simd_quatf(angle: yaw, axis: [0, 1, 0])
                }
            }

            let anchor = AnchorEntity(world: anchorTransform.matrix)

            let nxpEntity = CustomModelEntity(model: .nxp, isBeaconOwned: true)
            let iphoneEntity = CustomModelEntity(model: .iphone, isBeaconOwned: true)
            let ipadEntity = CustomModelEntity(model: .ipad, isBeaconOwned: true)

            let nxpBounds = nxpEntity.visualBounds(relativeTo: nxpEntity)
            let iphoneBounds = iphoneEntity.visualBounds(relativeTo: iphoneEntity)
            let ipadBounds = ipadEntity.visualBounds(relativeTo: ipadEntity)

            let nxpWidth = max(nxpBounds.extents.x, 0.08)
            let iphoneWidth = max(iphoneBounds.extents.x, 0.08)
            let ipadWidth = max(ipadBounds.extents.x, 0.08)

            let averageWidth = (nxpWidth + iphoneWidth + ipadWidth) / 3.0
            let spacing = max(0.05, min(0.12, averageWidth * 0.3))

            // Ustawienie koło siebie: płytka NXP (lewo), iPhone (środek), iPad (prawo)
            nxpEntity.position = SIMD3<Float>(
                -(iphoneWidth / 2 + spacing + nxpWidth / 2) - nxpBounds.center.x,
                0,
                -nxpBounds.center.z
            )
            iphoneEntity.position = SIMD3<Float>(
                -iphoneBounds.center.x,
                0,
                -iphoneBounds.center.z
            )
            ipadEntity.position = SIMD3<Float>(
                (iphoneWidth / 2 + spacing + ipadWidth / 2) - ipadBounds.center.x,
                0,
                -ipadBounds.center.z
            )

            var installedGestures: [UIGestureRecognizer] = []
            for entity in [nxpEntity, iphoneEntity, ipadEntity] {
                anchor.addChild(entity)
                let recognizers = arView.installGestures([.rotation, .translation], for: entity)
                for recognizer in recognizers {
                    installedGestures.append(recognizer)
                }
            }

            arView.scene.addAnchor(anchor)
            stationAnchor = anchor
            stationGestures = installedGestures
            placedStationBeaconKey = beaconKey
        }

        nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            handleDetectedAnchors(anchors)
        }

        nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            handleDetectedAnchors(anchors)
        }

        private nonisolated func handleDetectedAnchors(_ anchors: [ARAnchor]) {
            let planeAnchors = anchors.compactMap { $0 as? ARPlaneAnchor }
            let verticalTransform = planeAnchors
                .first(where: { $0.alignment == .vertical })?
                .transform
            let horizontalTransform = planeAnchors
                .first(where: { $0.alignment == .horizontal })?
                .transform

            guard verticalTransform != nil || horizontalTransform != nil else { return }

            Task { @MainActor in
                guard let arView = self.arView else { return }

                if let vTransform = verticalTransform, self.showBoard, self.boardAnchor == nil {
                    let board = BoardEntity(uiImage: "rozklad", scale: 2.0)
                    if let placed = self.place(
                        board,
                        transform: vTransform,
                        planeAlignment: .vertical,
                        in: arView
                    ) {
                        self.boardAnchor = placed.anchor
                        self.boardGestures = placed.gestures
                    }
                }

                if let hTransform = horizontalTransform,
                   let beaconKey = self.activeStationBeaconKey,
                   self.stationAnchor == nil {
                    self.placeStationShowcase(at: hTransform, for: beaconKey, in: arView)
                }
            }
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = recognizer.location(in: arView)

            // 1. Kliknięcie na istniejący model (NXP, iPhone lub iPad) -> pokaż informacje
            let hitEntities = arView.entities(at: tapLocation)
            if let tappedModel = hitEntities.compactMap({ findModelEntity(from: $0) }).first,
               let modelType = tappedModel.modelType {
                onSelectModelInfo?(modelType, tappedModel.isBeaconOwned)
                return
            }

            // 2. Kliknięcie na plan zajęć -> pokaż wyposażenie sali Apple
            if hitEntities.contains(where: { findBoardEntity(from: $0) != nil }) {
                onSelectBoardInfo?()
                return
            }

            if !hitEntities.isEmpty { return }

            // 2. Ręczne dodawanie wybranego modelu po kliknięciu w płaszczyznę
            let results = arView.raycast(
                from: tapLocation,
                allowing: .estimatedPlane,
                alignment: .any
            )

            guard let firstResult = results.first,
                  let planeAlignment = alignment(for: firstResult) else { return }

            switch planeAlignment {
            case .horizontal:
                let customEntity = CustomModelEntity(model: selectedModel, isBeaconOwned: false)
                place(
                    customEntity,
                    transform: firstResult.worldTransform,
                    planeAlignment: planeAlignment,
                    in: arView
                )
            case .vertical:
                guard showBoard, boardAnchor == nil else { return }
                let boardEntity = BoardEntity(uiImage: "rozklad", scale: 2.0)
                if let placed = place(
                    boardEntity,
                    transform: firstResult.worldTransform,
                    planeAlignment: planeAlignment,
                    in: arView
                ) {
                    boardAnchor = placed.anchor
                    boardGestures = placed.gestures
                }
            @unknown default:
                return
            }
        }

        private func findModelEntity(from entity: Entity?) -> CustomModelEntity? {
            var current = entity
            while let node = current {
                if let modelEntity = node as? CustomModelEntity {
                    return modelEntity
                }
                current = node.parent
            }
            return nil
        }

        private func findBoardEntity(from entity: Entity?) -> BoardEntity? {
            var current = entity
            while let node = current {
                if let boardEntity = node as? BoardEntity {
                    return boardEntity
                }
                current = node.parent
            }
            return nil
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
        ) -> (anchor: AnchorEntity, gestures: [UIGestureRecognizer])? {
            guard entity.allowedAlignment == planeAlignment else { return nil }

            let anchor = AnchorEntity(world: transform)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)

            // Obrót dwoma palcami i przesuwanie jednym (skalowanie usunięte)
            let recognizers = arView.installGestures([.rotation, .translation], for: entity)
            var gestures: [UIGestureRecognizer] = []
            for recognizer in recognizers {
                gestures.append(recognizer)
            }
            return (anchor, gestures)
        }
    }
}

#Preview {
    ContentView()
}
