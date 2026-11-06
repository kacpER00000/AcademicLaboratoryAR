import RealityKit
import ARKit

protocol PlaceableEntity: Entity, HasCollision {
    var allowedAlignment: ARPlaneAnchor.Alignment { get }
}
