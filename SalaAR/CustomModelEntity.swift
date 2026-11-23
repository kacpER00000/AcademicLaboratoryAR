import RealityKit
import ARKit

/// Encja ładująca model .usdz z paczki aplikacji.
/// HasCollision jest wymagane, żeby działały gesty (installGestures) oraz kliknięcia.
class CustomModelEntity: Entity, HasCollision, PlaceableEntity {
    var allowedAlignment: ARPlaneAnchor.Alignment {
        return .horizontal
    }

    let modelType: PlaceableModel?
    let isBeaconOwned: Bool

    /// Wymagany przez RealityKit
    required init() {
        self.modelType = nil
        self.isBeaconOwned = false
        super.init()
    }

    init(model: PlaceableModel, isBeaconOwned: Bool = false) {
        self.modelType = model
        self.isBeaconOwned = isBeaconOwned
        super.init()
        loadModel(named: model.rawValue, scale: model.scale)
    }

    /// - Parameters:
    ///   - modelName: nazwa pliku bez rozszerzenia (np. "nxp" dla nxp.usdz)
    ///   - scale: skala modelu (jeśli jest za duży/mały, zmień)
    init(modelName: String, scale: Float = 1.0, isBeaconOwned: Bool = false) {
        self.modelType = PlaceableModel(rawValue: modelName)
        self.isBeaconOwned = isBeaconOwned
        super.init()
        loadModel(named: modelName, scale: scale)
    }

    private func loadModel(named modelName: String, scale: Float) {
        do {
            let model = try Entity.load(named: modelName)
            model.scale = SIMD3<Float>(repeating: scale)
            self.addChild(model)

            // Pudełko kolizji dopasowane do rozmiaru modelu (z minimalną grubością dla łatwiejszego klikania)
            let bounds = self.visualBounds(relativeTo: self)
            let hitSize = SIMD3<Float>(
                max(bounds.extents.x, 0.03),
                max(bounds.extents.y, 0.03),
                max(bounds.extents.z, 0.03)
            )
            let shape = ShapeResource
                .generateBox(size: hitSize)
                .offsetBy(translation: bounds.center)
            self.collision = CollisionComponent(shapes: [shape])
        } catch {
            print("❌ Nie udało się załadować modelu '\(modelName)': \(error)")
        }
    }
}
