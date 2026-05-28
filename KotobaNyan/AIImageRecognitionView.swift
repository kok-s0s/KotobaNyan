import SwiftUI
import Vision

struct AIImageRecognitionView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var recognitionResult: String? = nil
    @State private var japaneseResult: String? = nil
    @State private var isProcessing = false
    @State private var showImagePicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                imagePreview
                pickerButtons
                recognizeButton
                if isProcessing { ProgressView("识别中...") }
                resultCard
                Spacer()
            }
            .padding()
            .navigationTitle("AI 识图")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: pickerSource, image: $selectedImage)
            }
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let image = selectedImage {
            Image(uiImage: image)
                .resizable().scaledToFit()
                .frame(maxHeight: 240)
                .cornerRadius(14)
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray5))
                .frame(height: 200)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle").font(.system(size: 36)).foregroundColor(.gray)
                        Text("请拍照或从相册选择图片").foregroundColor(.gray)
                    }
                )
        }
    }

    private var pickerButtons: some View {
        HStack(spacing: 24) {
            Button {
                pickerSource = .camera
                showImagePicker = true
            } label: {
                Label("拍照", systemImage: "camera")
            }
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

            Button {
                pickerSource = .photoLibrary
                showImagePicker = true
            } label: {
                Label("相册", systemImage: "photo")
            }
        }
    }

    private var recognizeButton: some View {
        Button("识别图片") { recognizeImage() }
            .buttonStyle(.borderedProminent)
            .disabled(selectedImage == nil || isProcessing)
    }

    @ViewBuilder
    private var resultCard: some View {
        if let result = recognitionResult {
            VStack(alignment: .leading, spacing: 10) {
                Label("识别结果", systemImage: "eye.fill").font(.headline)
                Divider()
                HStack {
                    Text("英文：").foregroundColor(.secondary)
                    Text(result).font(.body)
                }
                HStack {
                    Text("日文：").foregroundColor(.secondary)
                    Text(japaneseResult ?? "未收录").font(.body)
                        .foregroundColor(japaneseResult != nil ? .primary : .secondary)
                }
                if let ja = japaneseResult {
                    Button {
                        SpeechManager.shared.speak(text: ja)
                    } label: {
                        Label("朗读日文", systemImage: "speaker.wave.2.fill")
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)))
        }
    }

    private func recognizeImage() {
        guard let image = selectedImage, let cgImage = image.cgImage else { return }
        isProcessing = true
        recognitionResult = nil
        japaneseResult = nil

        let request = VNClassifyImageRequest { req, _ in
            DispatchQueue.main.async {
                isProcessing = false
                if let top = (req.results as? [VNClassificationObservation])?.first {
                    recognitionResult = top.identifier
                    japaneseResult = localDict[top.identifier.lowercased()]
                } else {
                    recognitionResult = "未识别到物体"
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        }
    }

    private let localDict: [String: String] = [
        "cat": "猫（ねこ）",
        "dog": "犬（いぬ）",
        "person": "人（ひと）",
        "car": "車（くるま）",
        "bicycle": "自転車（じてんしゃ）",
        "bird": "鳥（とり）",
        "flower": "花（はな）",
        "tree": "木（き）",
        "book": "本（ほん）",
        "cup": "カップ",
        "phone": "電話（でんわ）",
        "computer": "パソコン",
        "table": "テーブル",
        "chair": "椅子（いす）",
        "window": "窓（まど）",
        "door": "ドア",
        "food": "食べ物（たべもの）",
        "water": "水（みず）"
    ]
}

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    AIImageRecognitionView()
}
