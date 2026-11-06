import RealityKit

/// Encja ładująca model .usdz z paczki aplikacji.
/// HasCollision jest wymagane, żeby działały gesty (installGestures).
class CustomModelEntity: Entity, HasCollision {

    /// Wymagany przez RealityKit
    required init() {
        super.init()
    }

    /// - Parameters:
    ///   - modelName: nazwa pliku bez rozszerzenia (np. "nxp" dla nxp.usdz)
    ///   - scale: skala modelu (jeśli jest za duży/mały, zmień)
    init(modelName: String, scale: Float = 1.0) {
        super.init()

        do {
            let model = try Entity.load(named: modelName)
            model.scale = SIMD3<Float>(repeating: scale)
            self.addChild(model)

            // Pudełko kolizji dopasowane do rozmiaru modelu
            let bounds = self.visualBounds(relativeTo: self)
            let shape = ShapeResource
                .generateBox(size: bounds.extents)
                .offsetBy(translation: bounds.center)
            self.collision = CollisionComponent(shapes: [shape])
        } catch {
            print("❌ Nie udało się załadować modelu '\(modelName)': \(error)")
        }
    }
}
