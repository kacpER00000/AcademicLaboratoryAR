import SwiftUI

struct RoomEquipmentItem: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let count: Int
    let iconName: String
}

enum RoomEquipmentData {
    static let appleDevices: [RoomEquipmentItem] = [
        RoomEquipmentItem(
            name: "iPhone",
            subtitle: "Testowanie i tworzenie aplikacji iOS, ARKit i iBeacon",
            count: 15,
            iconName: "iphone"
        ),
        RoomEquipmentItem(
            name: "iPad",
            subtitle: "Programowanie iPadOS, SwiftUI oraz wizualizacje 3D/AR",
            count: 15,
            iconName: "ipad"
        ),
        RoomEquipmentItem(
            name: "Apple Watch",
            subtitle: "Tworzenie aplikacji watchOS i obsługa czujników ruchu",
            count: 15,
            iconName: "applewatch"
        )
    ]

    static let embeddedDevices: [RoomEquipmentItem] = [
        RoomEquipmentItem(
            name: "NXP MCXN947",
            subtitle: "Dwurdzeniowy ARM Cortex-M33 z akceleratorem AI (NPU)",
            count: 15,
            iconName: "cpu"
        ),
        RoomEquipmentItem(
            name: "NXP MCXW71",
            subtitle: "Komunikacja bezprzewodowa Bluetooth LE, Thread i Matter",
            count: 15,
            iconName: "antenna.radiowaves.left.and.right"
        ),
        RoomEquipmentItem(
            name: "NXP MCXA153",
            subtitle: "Energooszczędny mikrokontroler ARM Cortex-M33",
            count: 15,
            iconName: "memorychip"
        ),
        RoomEquipmentItem(
            name: "ESP32-S3-Pico",
            subtitle: "Kompaktowy moduł Wi-Fi i Bluetooth LE dla projektów IoT",
            count: 15,
            iconName: "wifi"
        )
    ]

    static var totalUnits: Int {
        (appleDevices + embeddedDevices).reduce(0) { $0 + $1.count }
    }
}

struct RoomEquipmentSheet: View {
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Baner sali typowo Apple w ciemnoniebieskiej stylistyce tablicy
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.16))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Laboratorium Apple")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.white)

                                Text("Akademia Tarnowska • Sala typowo Apple")
                                    .font(.footnote.weight(.medium))
                                    .foregroundColor(Color(red: 0.72, green: 0.86, blue: 1.0))
                            }
                        }

                        Text("Specjalistyczna sala dydaktyczna skoncentrowana na ekosystemie Apple (iOS, iPadOS, watchOS, Swift, Xcode, ARKit) wraz z zapleczem mikrokontrolerów NXP i ESP32 do projektów IoT i komunikacji z urządzeniami Apple.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 10) {
                            summaryPill(title: "15 zestawów", icon: "desktopcomputer")
                            summaryPill(title: "\(RoomEquipmentData.totalUnits) urządzeń łącznie", icon: "shippingbox.fill")
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.04, green: 0.11, blue: 0.27),
                                Color(red: 0.09, green: 0.22, blue: 0.46)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    equipmentSection(
                        title: "Ekosystem Apple",
                        badgeText: "Główne wyposażenie sali",
                        accentColor: Color(red: 0.09, green: 0.24, blue: 0.52),
                        items: RoomEquipmentData.appleDevices
                    )

                    equipmentSection(
                        title: "Płytki rozwojowe i IoT",
                        badgeText: "Integracja BLE / Matter / Wi-Fi",
                        accentColor: Color.blue,
                        items: RoomEquipmentData.embeddedDevices
                    )
                }
                .padding(20)
            }
            .navigationTitle("Wyposażenie sali")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func summaryPill(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.16))
        .clipShape(Capsule())
    }

    private func equipmentSection(
        title: String,
        badgeText: String,
        accentColor: Color,
        items: [RoomEquipmentItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(badgeText)
                    .font(.caption.weight(.medium))
                    .foregroundColor(accentColor)
            }

            ForEach(items) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.iconName)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(accentColor)
                        .frame(width: 40, height: 40)
                        .background(accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))

                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Text("\(item.count) szt.")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}
