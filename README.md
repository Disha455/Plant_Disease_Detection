# Plant Disease Detector 🌿

*A cross-platform Flutter app for real-time plant disease identification using deep learning models (CNN, TensorFlow Lite).*  

---

## ✨ Features

- 📷 **Live Camera Scan:** Capture plant leaf images for immediate disease analysis.
- 🧠 **AI-Powered Detection:** On-device diagnosis using pre-trained CNN (`.tflite`) models.
- 📝 **Disease Details:** Get disease names, brief descriptions, and severity level.
- 📂 **Offline Functionality:** Works without internet, fully on-device!
- 📜 **History:** View past scans and results for tracked plants.

---

## 🏗️ Project Structure

assets/
models/ # CNN .tflite model files for disease prediction
images/ # Sample or UI images (if any)
lib/
screens/ # Main UI screens (home, scan, results, history)
models/ # Dart data classes
services/ # ML model loading/inference logic
utils/ # Helper functions
widgets/ # Reusable UI components
main.dart # App entry point
test/ # Unit and widget tests

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart SDK
- Android Studio or VS Code

### Installation

git clone https://github.com/yourusername/plant_disease_detector.git
cd plant_disease_detector
flutter pub get

### Run the App

- **Android/iOS:** Connect a device and run `flutter run`.
- **Web/Desktop:** Build for your target using `flutter run -d chrome` or `flutter run -d windows`.

---

## 🧠 Model Integration

- `.tflite` disease detection models are located in `assets/models/`.
- Included models are referenced in `pubspec.yaml` and loaded at runtime for image inference[web:94][web:100].

---

## 📝 Usage

1. Open the app and use the camera to scan a plant leaf.
2. The CNN model (TensorFlow Lite) analyzes the image and predicts disease and severity.
3. Review results and learn more about detected diseases.
4. View previous scan history for comparison.

---

## 🤖 Machine Learning Details

- **Model:** Convolutional Neural Network
- **Frameworks:** TensorFlow, TensorFlow Lite
- **Dataset:** Thousands of labeled leaf images ([reference](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4921827))[web:95].
- **Inference:** Works offline for real-time predictions.



## 📄 License

MIT




