//
//  CameraPermissionManager.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import AVFoundation
import UIKit

class CameraPermissionManager {
    static let shared = CameraPermissionManager()

    private init() {}

    enum CameraPermissionStatus {
        case authorized
        case denied
        case notDetermined
        case restricted
    }

    func checkCameraPermission() -> CameraPermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func handleCameraPermission(
        from viewController: UIViewController,
        completion: @escaping (Bool) -> Void
    ) {
        switch checkCameraPermission() {
        case .authorized:
            completion(true)

        case .notDetermined:
            requestCameraPermission { granted in
                completion(granted)
            }

        case .denied, .restricted:
            showPermissionDeniedAlert(from: viewController) {
                completion(false)
            }
        }
    }

    private func showPermissionDeniedAlert(
        from viewController: UIViewController,
        completion: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: String(localized: .cameraPermissionTitle),
            message: String(localized: .cameraPermissionMessage),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .cameraPermissionGoToSettings), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
            completion()
        })

        alert.addAction(UIAlertAction(title: String(localized: .actionCancel), style: .cancel) { _ in
            completion()
        })

        viewController.present(alert, animated: true)
    }
}
