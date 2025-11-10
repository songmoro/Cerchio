//
//  CameraViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import UIKit
import AVFoundation
import SnapKit

protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCapturePhoto image: UIImage)
    func cameraViewControllerDidCancel(_ controller: CameraViewController)
}

final class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?

    private let previewView = UIView()
    private let captureButton = UIButton()
    private let cancelButton = UIButton()
    private let flashButton = UIButton()

    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCapturePhotoOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var currentDevice: AVCaptureDevice!

    private var isFlashOn = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startRunning()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = previewView.bounds
    }

    private func setupUI() {
        view.backgroundColor = .black

        previewView.backgroundColor = .black
        view.addSubview(previewView)

        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.layer.borderWidth = 3
        captureButton.layer.borderColor = UIColor.lightGray.cgColor
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)

        cancelButton.setTitle(String(localized: .actionCancel), for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .custom(weight: .medium, size: 16)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)

        let flashImageName = isFlashOn ? "bolt.fill" : "bolt.slash.fill"
        flashButton.setImage(UIImage(systemName: flashImageName), for: .normal)
        flashButton.tintColor = .white
        flashButton.addTarget(self, action: #selector(flashTapped), for: .touchUpInside)
        view.addSubview(flashButton)

        setupConstraints()
    }

    private func setupConstraints() {
        previewView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-100)
        }

        captureButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.size.equalTo(70)
        }

        cancelButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalTo(captureButton)
        }

        flashButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalTo(captureButton)
            $0.size.equalTo(44)
        }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }

        currentDevice = backCamera

        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()

            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        } catch {
            print(" Error setting up camera: \(error.localizedDescription)")
        }
    }

    private func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(videoPreviewLayer)
    }

    private func startRunning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func stopRunning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    @objc private func capturePhoto() {
        HapticFeedbackManager.shared.impact()

        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])

        if currentDevice.hasTorch && currentDevice.hasFlash {
            settings.flashMode = isFlashOn ? .on : .off
        }

        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func cancelTapped() {
        HapticFeedbackManager.shared.impact()
        delegate?.cameraViewControllerDidCancel(self)
    }

    @objc private func flashTapped() {
        guard currentDevice.hasTorch && currentDevice.hasFlash else { return }

        HapticFeedbackManager.shared.selection()
        isFlashOn.toggle()

        let imageName = isFlashOn ? "bolt.fill" : "bolt.slash.fill"
        flashButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print(" Photo capture error: \(error!.localizedDescription)")
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            return
        }

        guard let image = UIImage(data: imageData) else {
            return
        }

        let fixedImage = fixImageOrientation(image)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.cameraViewController(self, didCapturePhoto: fixedImage)
        }
    }

    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? image
    }
}
