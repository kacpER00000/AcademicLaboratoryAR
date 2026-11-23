import RealityKit
import ARKit
import UIKit

class BoardEntity: Entity, HasCollision, PlaceableEntity {
    var allowedAlignment: ARPlaneAnchor.Alignment {
        return .vertical
    }

    required init() {
        super.init()
    }

    init(uiImage: String, scale: Float = 1.0) {
        super.init()

        let loadedImage = loadUIImage(named: uiImage)
        let framedImage = loadedImage.flatMap { renderFramedBoardImage(from: $0) }

        // Prostokątne proporcje dopasowane do obrazu planu (np. A4 poziomo ~1.41:1)
        let aspectRatio: Float
        if let image = framedImage ?? loadedImage, image.size.height > 0 {
            aspectRatio = Float(image.size.width / image.size.height)
        } else {
            aspectRatio = 1.414
        }

        let frontHeight: Float = 0.22
        let frontWidth: Float = frontHeight * aspectRatio
        let borderMargin: Float = 0.014
        let backingDepth: Float = 0.012

        let container = Entity()
        // Obrót o -90° wokół osi X, aby tablica przylegała płasko do pionowej płaszczyzny ARKit
        container.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        container.scale = SIMD3<Float>(repeating: scale)

        // 1. Ciemnoniebieskie, zaokrąglone tło / ramka tablicy 3D
        let backingMesh = MeshResource.generateBox(
            size: SIMD3<Float>(
                frontWidth + borderMargin * 2,
                frontHeight + borderMargin * 2,
                backingDepth
            ),
            cornerRadius: 0.005
        )
        var backingMaterial = SimpleMaterial()
        backingMaterial.color = .init(tint: UIColor(red: 0.05, green: 0.13, blue: 0.30, alpha: 1.0))
        backingMaterial.roughness = .float(0.35)
        backingMaterial.metallic = .float(0.1)

        let backingEntity = ModelEntity(mesh: backingMesh, materials: [backingMaterial])
        container.addChild(backingEntity)

        // 2. Prostokątny front z planem zajęć na ciemnoniebieskim tle
        do {
            let texture: TextureResource
            if let cgImage = framedImage?.cgImage {
                if #available(iOS 18.0, *) {
                    texture = try TextureResource(image: cgImage, options: .init(semantic: .color))
                } else {
                    texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
                }
            } else {
                texture = try (try? TextureResource.load(named: uiImage))
                    ?? TextureResource.load(named: "\(uiImage).jpg")
            }

            let frontMesh = MeshResource.generateBox(
                width: frontWidth,
                height: frontHeight,
                depth: 0.001
            )
            var frontMaterial = SimpleMaterial()
            frontMaterial.color = .init(tint: .white, texture: .init(texture))
            frontMaterial.roughness = .float(0.85)
            frontMaterial.metallic = .float(0.0)

            let frontEntity = ModelEntity(mesh: frontMesh, materials: [frontMaterial])
            frontEntity.position = SIMD3<Float>(0, 0, backingDepth / 2 + 0.0006)
            container.addChild(frontEntity)
        } catch {
            print("❌ Nie udało się załadować tekstury '\(uiImage)': \(error)")
        }

        self.addChild(container)

        let bounds = self.visualBounds(relativeTo: self)
        let hitSize = SIMD3<Float>(
            max(bounds.extents.x, 0.04),
            max(bounds.extents.y, 0.04),
            max(bounds.extents.z, 0.04)
        )
        let shape = ShapeResource
            .generateBox(size: hitSize)
            .offsetBy(translation: bounds.center)
        self.collision = CollisionComponent(shapes: [shape])
    }

    private func loadUIImage(named name: String) -> UIImage? {
        if let image = UIImage(named: name) ?? UIImage(named: "\(name).jpg") {
            return image
        }
        for ext in ["jpg", "jpeg", "png"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        return nil
    }

    private func renderFramedBoardImage(from scheduleImage: UIImage) -> UIImage? {
        guard scheduleImage.size.width > 0, scheduleImage.size.height > 0 else { return nil }

        let scheduleAspect = scheduleImage.size.width / scheduleImage.size.height
        let contentWidth: CGFloat = 1800
        let contentHeight: CGFloat = contentWidth / scheduleAspect

        let sidePadding: CGFloat = 68
        let headerHeight: CGFloat = 110
        let footerHeight: CGFloat = 78

        let canvasSize = CGSize(
            width: contentWidth + sidePadding * 2,
            height: headerHeight + contentHeight + footerHeight
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
        return renderer.image { context in
            let cgContext = context.cgContext
            let fullRect = CGRect(origin: .zero, size: canvasSize)

            // Ciemnoniebieski gradient tła
            let colors = [
                UIColor(red: 0.04, green: 0.11, blue: 0.27, alpha: 1.0).cgColor,
                UIColor(red: 0.09, green: 0.21, blue: 0.45, alpha: 1.0).cgColor
            ] as CFArray
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0.0, 1.0]
            ) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: canvasSize.width, y: canvasSize.height),
                    options: []
                )
            }

            // Subtelna obwódka wewnętrzna
            let insetRect = fullRect.insetBy(dx: 16, dy: 16)
            let borderPath = UIBezierPath(roundedRect: insetRect, cornerRadius: 28)
            UIColor(red: 0.55, green: 0.78, blue: 1.0, alpha: 0.28).setStroke()
            borderPath.lineWidth = 3
            borderPath.stroke()

            // Nagłówek
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 42, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let titleText = "Sala Apple • Akademia Tarnowska"
            titleText.draw(at: CGPoint(x: sidePadding, y: 32), withAttributes: titleAttributes)

            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 34, weight: .semibold),
                .foregroundColor: UIColor(red: 0.68, green: 0.84, blue: 1.0, alpha: 1.0)
            ]
            let subtitleText = "Plan zajęć"
            let subtitleSize = subtitleText.size(withAttributes: subtitleAttributes)
            subtitleText.draw(
                at: CGPoint(x: canvasSize.width - sidePadding - subtitleSize.width, y: 37),
                withAttributes: subtitleAttributes
            )

            // Karta z planem zajęć (zachowane prostokątne proporcje)
            let scheduleRect = CGRect(
                x: sidePadding,
                y: headerHeight,
                width: contentWidth,
                height: contentHeight
            )

            cgContext.saveGState()
            cgContext.setShadow(
                offset: CGSize(width: 0, height: 10),
                blur: 24,
                color: UIColor.black.withAlphaComponent(0.35).cgColor
            )
            let cardPath = UIBezierPath(roundedRect: scheduleRect, cornerRadius: 20)
            UIColor.white.setFill()
            cardPath.fill()
            cgContext.restoreGState()

            cgContext.saveGState()
            cardPath.addClip()
            scheduleImage.draw(in: scheduleRect)
            cgContext.restoreGState()

            // Stopka z podpowiedzią
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30, weight: .medium),
                .foregroundColor: UIColor(red: 0.78, green: 0.89, blue: 1.0, alpha: 0.95)
            ]
            let footerText = "Dotknij plan, aby zobaczyć wyposażenie sali Apple"
            let footerSize = footerText.size(withAttributes: footerAttributes)
            footerText.draw(
                at: CGPoint(
                    x: (canvasSize.width - footerSize.width) / 2,
                    y: headerHeight + contentHeight + (footerHeight - footerSize.height) / 2
                ),
                withAttributes: footerAttributes
            )
        }
    }
}
