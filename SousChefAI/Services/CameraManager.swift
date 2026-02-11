//
//  CameraManager.swift
//  SousChefAI
//
//  Camera management using AVFoundation for real-time video streaming
//

@preconcurrency import AVFoundation
@preconcurrency import CoreVideo
import UIKit
import Combine

/// Manages camera capture and provides async stream of video frames
@MainActor
final class CameraManager: NSObject, ObservableObject {
    
    @Published var isAuthorized = false
    @Published var error: CameraError?
    @Published var isRunning = false
    
    nonisolated(unsafe) private let captureSession = AVCaptureSession()
    nonisolated(unsafe) private var videoOutput: AVCaptureVideoDataOutput?
    private let videoQueue = DispatchQueue(label: "com.souschef.video", qos: .userInitiated)
    
    nonisolated(unsafe) private var frameContinuation: AsyncStream<CVPixelBuffer>.Continuation?
    private let continuationQueue = DispatchQueue(label: "com.souschef.continuation")
    
    private var isConfigured = false
    
    nonisolated override init() {
        super.init()
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            
        case .denied, .restricted:
            isAuthorized = false
            error = .notAuthorized
            
        @unknown default:
            isAuthorized = false
        }
    }
    
    // MARK: - Session Setup
    
    func setupSession() async throws {
        // Only configure once
        guard !isConfigured else { return }
        
        // Ensure authorization is checked first
        await checkAuthorization()
        
        guard isAuthorized else {
            throw CameraError.notAuthorized
        }
        
        captureSession.beginConfiguration()
        
        // Set session preset
        captureSession.sessionPreset = .high
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            captureSession.commitConfiguration()
            throw CameraError.setupFailed
        }
        
        captureSession.addInput(videoInput)
        
        // Add video output
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: videoQueue)
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        guard captureSession.canAddOutput(output) else {
            captureSession.commitConfiguration()
            throw CameraError.setupFailed
        }
        
        captureSession.addOutput(output)
        self.videoOutput = output
        
        captureSession.commitConfiguration()
        isConfigured = true
    }
    
    // MARK: - Session Control
    
    func startSession() {
        guard !captureSession.isRunning else { return }
        
        let session = captureSession
        Task.detached { [weak self] in
            session.startRunning()
            
            await MainActor.run { [weak self] in
                self?.isRunning = true
            }
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        
        let session = captureSession
        Task.detached { [weak self] in
            session.stopRunning()
            
            await MainActor.run { [weak self] in
                self?.isRunning = false
            }
        }
    }
    
    // MARK: - Frame Stream
    
    func frameStream() -> AsyncStream<CVPixelBuffer> {
        AsyncStream { [weak self] continuation in
            guard let self = self else { return }
            
            self.continuationQueue.async {
                Task { @MainActor in
                    self.frameContinuation = continuation
                }
            }
            
            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                self.continuationQueue.async {
                    Task { @MainActor in
                        self.frameContinuation = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Preview Layer
    
    func previewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // CVPixelBuffer is thread-safe and immutable, safe to pass across isolation boundaries
        // Using nonisolated(unsafe) for continuation since we manage synchronization manually
        frameContinuation?.yield(pixelBuffer)
    }
}

// MARK: - Error Handling

enum CameraError: Error, LocalizedError {
    case notAuthorized
    case setupFailed
    case captureSessionFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access not authorized. Please enable camera access in Settings."
        case .setupFailed:
            return "Failed to setup camera session"
        case .captureSessionFailed:
            return "Camera capture session failed"
        }
    }
}
