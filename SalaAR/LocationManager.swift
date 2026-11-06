//
//  LocationManager.swift
//  BeaconGame
//
//  Created by Daniel Król on 18/09/2025.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var detectedBeacons: [CLBeacon] = []
    private var locationManager: CLLocationManager?
    private let beaconUUID = UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
    private let beaconIdentifier = "edu.tarnow.nocnaukowcow"
    private var distanceFilter: [String: Double] = [:]
    private let alpha: Double = 0.25
    private var isResetting = false

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        startScanning()
    }

    func startScanning() {
        let region = CLBeaconRegion(
            uuid: beaconUUID,
            identifier: beaconIdentifier
        )
        
        locationManager?.startMonitoring(for: region)
        locationManager?.startRangingBeacons(
            satisfying: CLBeaconIdentityConstraint(uuid: beaconUUID)
        )
    }

    private func key(for beacon: CLBeacon) -> String {
        "\(beacon.major.intValue)-\(beacon.minor.intValue)"
    }

    func locationManager(
        _ manager: CLLocationManager,
        didRange beacons: [CLBeacon],
        satisfying constraint: CLBeaconIdentityConstraint
    ) {
        
        if isResetting {
            isResetting = false
            return
        }
        
        var result: [CLBeacon] = []
        
        for beacon in beacons {
            
            let k = key(for: beacon)
            let raw = beacon.accuracy
            
            guard raw > 0 && raw < 50 else { continue }
            
            if let old = distanceFilter[k] {
                distanceFilter[k] = alpha * raw + (1 - alpha) * old
            } else {
                distanceFilter[k] = raw
            }
            
            result.append(beacon)
        }
        
        DispatchQueue.main.async {
            self.detectedBeacons = result
        }
    }

    func filteredDistance(for beacon: CLBeacon) -> Double? {
        let k = key(for: beacon)
        return distanceFilter[k]
    }
    
    func resetFilters() {
        distanceFilter.removeAll()
        
        isResetting = true
    }
}
