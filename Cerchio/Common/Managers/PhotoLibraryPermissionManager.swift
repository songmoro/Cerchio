//
//  PhotoLibraryPermissionManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/2/25.
//

import Photos
import UIKit

class PhotoLibraryPermissionManager {
    static let shared = PhotoLibraryPermissionManager()

    private init() {}

    enum PhotoLibraryPermissionStatus {
        case authorized
        case denied
        case notDetermined
        case limited
        case restricted
    }

    func checkPhotoLibraryPermission() -> PhotoLibraryPermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .limited:
            return .limited
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                completion(status == .authorized || status == .limited)
            }
        }
    }

    func handlePhotoLibraryPermission(
        from viewController: UIViewController,
        completion: @escaping (Bool) -> Void
    ) {
        switch checkPhotoLibraryPermission() {
        case .authorized, .limited:
            completion(true)

        case .notDetermined:
            requestPhotoLibraryPermission { granted in
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
            title: String(localized: .photoLibraryPermissionTitle),
            message: String(localized: .photoLibraryPermissionMessage),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .photoLibraryPermissionGoToSettings), style: .default) { _ in
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
