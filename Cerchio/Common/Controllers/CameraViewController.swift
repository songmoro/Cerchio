//
//  CameraViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import UIKit
import AVFoundation

protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCapturePhoto image: UIImage)
    func cameraViewControllerDidCancel(_ controller: CameraViewController)
}

final class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?

    // MARK: - UI Components
    private let previewView = UIView()
    private let captureButton = UIButton()
    private let cancelButton = UIButton()
    private let flashButton = UIButton()

    // MARK: - Camera Components
    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCapturePhotoOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var currentDevice: AVCaptureDevice!

    // MARK: - Properties
    private var isFlashOn = false

    // MARK: - Lifecycle
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

    // MARK: - Setup
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
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)


        setupConstraints()
    }

    private func setupConstraints() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),

            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),

            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor)
        ])
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print(" Unable to access back camera")
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

    // MARK: - Camera Control
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

    // MARK: - Actions
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])

        if currentDevice.hasTorch && currentDevice.hasFlash {
            settings.flashMode = isFlashOn ? .on : .off
        }

        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func cancelTapped() {
        delegate?.cameraViewControllerDidCancel(self)
    }

    @objc private func flashTapped() {
        guard currentDevice.hasTorch && currentDevice.hasFlash else { return }

        isFlashOn.toggle()
        let imageName = isFlashOn ? "bolt" : "bolt.slash"
        flashButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print(" Photo capture error: \(error!.localizedDescription)")
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            print(" Unable to generate image data")
            return
        }

        guard let image = UIImage(data: imageData) else {
            print(" Unable to generate image from data")
            return
        }

        // 이미지 방향 수정
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
