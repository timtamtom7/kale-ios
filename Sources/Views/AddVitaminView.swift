import SwiftUI
import AVFoundation

struct AddVitaminView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var databaseService: DatabaseService
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var vitaminName = ""
    @State private var dosage = ""
    @State private var pillEmoji = "💊"
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var scannedBarcode: String?
    @State private var showingScanner = true
    @State private var showingManualEntry = false
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var scanFailed = false
    @State private var scanAttempts = 0
    @State private var stockCountText = ""
    @State private var dailyDoseText = "1"
    @State private var currentVitaminCount = 0
    @State private var showingLimitReached = false
    @State private var showingUpgradePrompt = false

    var onSave: ((Vitamin) -> Void)?

    private var canAddVitamin: Bool {
        subscriptionManager.canAccess(.unlimitedVitamins) || currentVitaminCount < 3
    }

    private var canUseBarcode: Bool {
        subscriptionManager.canAccess(.barcodeScanning)
    }

    private let pillEmojis = ["💊", "🫙", "💉", "🥤", "🍬", "🧪", "💧", "🌿", "🥛", "🍀", "🥜", "🐟"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundLight.ignoresSafeArea()

                if showingScanner && !showingManualEntry {
                    Group {
                        if cameraPermissionStatus == .denied || cameraPermissionStatus == .restricted {
                            CameraPermissionDeniedView()
                        } else if scanFailed {
                            BarcodeScanFailedView(
                                onRetry: {
                                    scanFailed = false
                                    scanAttempts += 1
                                },
                                onEnterManually: {
                                    showingManualEntry = true
                                    showingScanner = false
                                }
                            )
                        } else {
                            BarcodeScannerWithOverlay(
                                onBarcodeFound: handleBarcode,
                                onError: {
                                    scanFailed = true
                                },
                                scanAttempts: scanAttempts
                            )
                        }
                    }
                } else {
                    manualEntryForm
                }
            }
            .navigationTitle(scannedBarcode != nil ? "Add Vitamin" : "Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentGreen)
                }
            }
            .onAppear {
                checkCameraPermission()
                loadVitaminCount()
            }
            .alert("Vitamin Limit Reached", isPresented: $showingLimitReached) {
                Button("Cancel", role: .cancel) {}
                Button("Upgrade") {
                    showingUpgradePrompt = true
                }
            } message: {
                Text("Free plan supports up to 3 vitamins. Upgrade to Daily or Complete for unlimited vitamins.")
            }
        }
    }

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermissionStatus = status
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermissionStatus = granted ? .authorized : .denied
                }
            }
        }
    }

    private func loadVitaminCount() {
        do {
            let vitamins = try databaseService.fetchAllVitamins()
            currentVitaminCount = vitamins.count
        } catch {
            print("Load vitamin count error: \(error)")
        }
    }

    private var manualEntryForm: some View {
        ScrollView {
            VStack(spacing: 24) {
                emojiPicker
                formFields
                reminderSection
                saveButton
            }
            .padding()
        }
    }

    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(pillEmojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(pillEmoji == emoji ? Color.accentGreen.opacity(0.2) : Color.surfaceLight)
                            )
                            .overlay(
                                Circle()
                                    .stroke(pillEmoji == emoji ? Color.accentGreen : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                pillEmoji = emoji
                            }
                    }
                }
            }
        }
    }

    private var formFields: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
                TextField("Vitamin D3", text: $vitaminName)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Color.surfaceLight)
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Dosage")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
                TextField("2000 IU", text: $dosage)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Color.surfaceLight)
                    .cornerRadius(12)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Capsules in stock")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                    TextField("e.g. 60", text: $stockCountText)
                        .font(.system(size: 15))
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(Color.surfaceLight)
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Daily capsules")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                    TextField("1", text: $dailyDoseText)
                        .font(.system(size: 15))
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(Color.surfaceLight)
                        .cornerRadius(12)
                }
            }

            if let barcode = scannedBarcode {
                HStack {
                    Image(systemName: "barcode")
                        .foregroundColor(.accentGreen)
                    Text(barcode)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentGreen)
                }
                .padding(10)
                .background(Color.accentGreen.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Reminder")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textSecondary)

            DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .background(Color.surfaceLight)
                .cornerRadius(12)
        }
    }

    private var saveButton: some View {
        Button {
            if !canAddVitamin {
                showingLimitReached = true
            } else {
                saveVitamin()
            }
        } label: {
            VStack(spacing: 4) {
                Text("Save Vitamin")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                if !subscriptionManager.canAccess(.unlimitedVitamins) && currentVitaminCount >= 2 {
                    Text("\(3 - currentVitaminCount) slot left")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.accentGreen)
            )
        }
        .disabled(vitaminName.isEmpty || dosage.isEmpty)
        .opacity(vitaminName.isEmpty || dosage.isEmpty ? 0.5 : 1)
    }

    private func handleBarcode(_ code: String) {
        if !canAddVitamin {
            showingLimitReached = true
            return
        }

        if !canUseBarcode {
            showingUpgradePrompt = true
            return
        }

        scannedBarcode = code
        showingScanner = false

        if let entry = BarcodeService.shared.lookup(barcode: code) {
            vitaminName = entry.name
            dosage = entry.dosage
        }
        showingManualEntry = true
    }

    private func saveVitamin() {
        let vitamin = Vitamin(
            name: vitaminName,
            dosage: dosage,
            barcode: scannedBarcode,
            pillEmoji: pillEmoji,
            reminderTime: reminderTime,
            stockCount: Int(stockCountText),
            dailyDose: Int(dailyDoseText) ?? 1
        )

        do {
            let id = try databaseService.insertVitamin(vitamin)
            var savedVitamin = vitamin
            savedVitamin.id = id
            onSave?(savedVitamin)
            NotificationService.shared.scheduleMorningNotification()
            dismiss()
        } catch {
            print("Save error: \(error)")
        }
    }
}

// MARK: - Barcode Scanner with Overlay

struct BarcodeScannerWithOverlay: View {
    let onBarcodeFound: (String) -> Void
    let onError: () -> Void
    let scanAttempts: Int

    var body: some View {
        ZStack {
            CameraPreviewView(onBarcodeFound: { code in
                onBarcodeFound(code)
            }, onError: {
                onError()
            }, key: scanAttempts)

            ScanOverlayView {
                // Cancel handled by parent
            }
        }
    }
}

struct CameraPreviewView: UIViewControllerRepresentable {
    let onBarcodeFound: (String) -> Void
    let onError: () -> Void
    let key: Int

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onBarcodeFound = onBarcodeFound
        controller.onError = onError
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Restart scanning when key changes (retry)
        uiViewController.resetScanner()
    }
}

class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var onBarcodeFound: ((String) -> Void)?
    var onError: (() -> Void)?
    private var hasFound = false
    private var hasErrored = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasFound = false
        hasErrored = false
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }

    func resetScanner() {
        hasFound = false
        hasErrored = false
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              let session = captureSession,
              session.canAddInput(videoInput) else {
            DispatchQueue.main.async { [weak self] in
                self?.onError?()
            }
            return
        }

        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39, .code93]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasFound,
              let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }

        hasFound = true
        captureSession?.stopRunning()

        DispatchQueue.main.async { [weak self] in
            self?.onBarcodeFound?(stringValue)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}

#Preview {
    AddVitaminView()
        .environmentObject(DatabaseService.shared)
}
