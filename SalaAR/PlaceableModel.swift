import Foundation

struct TechnologyItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let iconName: String
}

enum PlaceableModel: String, CaseIterable, Identifiable {
    case ipad = "Ipad_Air_5"
    case iphone = "iphone_16e"
    case nxp = "nxp"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ipad: return "iPad"
        case .iphone: return "iPhone"
        case .nxp: return "NXP"
        }
    }

    var fullTitle: String {
        switch self {
        case .ipad: return "Apple iPad Air"
        case .iphone: return "Apple iPhone"
        case .nxp: return "Płytka rozwojowa NXP"
        }
    }

    var subtitle: String {
        switch self {
        case .ipad: return "Aplikacje iPadOS, AR i projektowanie interfejsów"
        case .iphone: return "Programowanie natywnych aplikacji mobilnych iOS"
        case .nxp: return "Systemy wbudowane, mikrokontrolery i IoT"
        }
    }

    var iconName: String {
        switch self {
        case .ipad: return "ipad"
        case .iphone: return "iphone"
        case .nxp: return "cpu"
        }
    }

    var scale: Float {
        switch self {
        case .ipad, .iphone: return 1.0
        case .nxp: return 1.5
        }
    }

    var descriptionText: String {
        switch self {
        case .nxp:
            return "Płytka uruchomieniowa z mikrokontrolerem firmy NXP (architektura ARM Cortex-M), wykorzystywana na zajęciach laboratoryjnych w Akademii Tarnowskiej do nauki programowania systemów wbudowanych, obsługi czujników oraz komunikacji sprzętowej."
        case .iphone:
            return "Smartfon Apple używany podczas zajęć w Akademii Tarnowskiej do budowania i testowania aplikacji na system iOS — w tym projektów wykorzystujących rozszerzoną rzeczywistość (AR), technologię iBeacon, Bluetooth oraz czujniki mobilne."
        case .ipad:
            return "Tablet Apple wykorzystywany w laboratoriach Akademii Tarnowskiej do tworzenia responsywnych aplikacji dla systemu iPadOS, wizualizacji modeli 3D w AR oraz nauki programowania w nowoczesnym ekosystemie Apple."
        }
    }

    var technologies: [TechnologyItem] {
        switch self {
        case .nxp:
            return [
                TechnologyItem(
                    name: "C / C++ (Embedded)",
                    detail: "Programowanie niskopoziomowe rejestrów, przerwań i sterowników",
                    iconName: "chevron.left.forwardslash.chevron.right"
                ),
                TechnologyItem(
                    name: "MCUXpresso IDE & SDK",
                    detail: "Środowisko programistyczne, debugowanie i konfiguracja pinów NXP",
                    iconName: "wrench.and.screwdriver"
                ),
                TechnologyItem(
                    name: "ARM Cortex-M",
                    detail: "Architektura mikrokontrolerów oraz układy czasowo-licznikowe (PWM, ADC)",
                    iconName: "cpu"
                ),
                TechnologyItem(
                    name: "Magistrale komunikacyjne",
                    detail: "Obsługa interfejsów GPIO, UART, I2C i SPI w projektach IoT",
                    iconName: "cable.connector"
                )
            ]
        case .iphone:
            return [
                TechnologyItem(
                    name: "Swift & SwiftUI / UIKit",
                    detail: "Tworzenie nowoczesnych, natywnych interfejsów dla systemu iOS",
                    iconName: "swift"
                ),
                TechnologyItem(
                    name: "ARKit & RealityKit",
                    detail: "Wykrywanie płaszczyzn i osadzanie obiektów 3D w rzeczywistości rozszerzonej",
                    iconName: "arkit"
                ),
                TechnologyItem(
                    name: "CoreLocation & iBeacon",
                    detail: "Wykrywanie beaconów Bluetooth i lokalizacja wewnątrz sal",
                    iconName: "dot.radiowaves.left.and.right"
                ),
                TechnologyItem(
                    name: "Xcode & Combine",
                    detail: "Programowanie reaktywne, debugowanie oraz testowanie na fizycznych urządzeniach",
                    iconName: "hammer"
                )
            ]
        case .ipad:
            return [
                TechnologyItem(
                    name: "Swift & iPadOS",
                    detail: "Projektowanie adaptacyjnych układów UI na większe ekrany dotykowe",
                    iconName: "rectangle.split.2x1"
                ),
                TechnologyItem(
                    name: "RealityKit & modele USDZ",
                    detail: "Prezentacja interaktywnych scen 3D i praca z rozszerzoną rzeczywistością",
                    iconName: "cube.transparent"
                ),
                TechnologyItem(
                    name: "CoreML & Vision",
                    detail: "Wykorzystanie uczenia maszynowego i analizy obrazu na urządzeniu",
                    iconName: "brain"
                ),
                TechnologyItem(
                    name: "Git & GitHub Actions",
                    detail: "Praca zespołowa z kontrolą wersji i automatyczne budowanie aplikacji",
                    iconName: "arrow.triangle.branch"
                )
            ]
        }
    }
}
