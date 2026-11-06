import RealityKit
import ARKit

class BoardEntity: Entity, HasCollision, PlaceableEntity {
    var allowedAlignment: ARPlaneAnchor.Alignment {
        return .vertical
    }

    required init() {
        super.init()
    }

    init(uiImage: String, scale: Float = 1.0) {
        super.init()
        do {
            let mesh = MeshResource.generateBox(width: 0.2, height: 0.2, depth: 0.01)
            let texture = try (try? TextureResource.load(named: uiImage))
                ?? TextureResource.load(named: "\(uiImage).jpg")

            var material = SimpleMaterial()
            material.color = .init(tint: .white, texture: .init(texture))

            let modelEntity = ModelEntity(mesh: mesh, materials: [material])
            // Obrót o -90° wokół osi X, aby tablica przylegała płasko do pionowej płaszczyzny ARKit
            modelEntity.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            modelEntity.scale = SIMD3<Float>(repeating: scale)
            self.addChild(modelEntity)

            let bounds = self.visualBounds(relativeTo: self)
            let shape = ShapeResource
                .generateBox(size: bounds.extents)
                .offsetBy(translation: bounds.center)
            self.collision = CollisionComponent(shapes: [shape])
        } catch {
            print("❌ Nie udało się załadować tekstury '\(uiImage)': \(error)")
        }
    }
}
