import SwiftUI

struct ModelInfoSheet: View {
    let model: PlaceableModel
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: model.iconName)
                                .font(.title)
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.fullTitle)
                                .font(.title3.weight(.bold))

                            Text(model.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "graduationcap.fill")
                            .foregroundColor(.blue)
                        Text("Akademia Tarnowska • Laboratorium")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())

                    VStack(alignment: .leading, spacing: 8) {
                        Text("O urządzeniu")
                            .font(.headline)

                        Text(model.descriptionText)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Technologie na zajęciach")
                            .font(.headline)

                        ForEach(model.technologies) { tech in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: tech.iconName)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.blue)
                                    .frame(width: 26, height: 26)
                                    .background(Color.blue.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tech.name)
                                        .font(.subheadline.weight(.semibold))

                                    Text(tech.detail)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(model.title)
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
}
