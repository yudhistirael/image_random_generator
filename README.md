# 🎨 Immersive Random Image Viewer

A minimalist Flutter application that fetches random images and adapts the UI color scheme in real-time based on the image's dominant colors. Built with performance and user experience in mind. Implemented custom pixel-based color extraction algorithm using Isolates (compute) for performance, ensuring the UI thread never drops frames during calculation.

<p align="center">
  <img src="SS.gif" alt="App Demo" width="250" />
</p>

## ✨ Key Features

* **⚡ Instant Color Extraction:** Uses a custom `ResizeImage` algorithm to extract dominant colors from images in milliseconds without UI freeze (Non-blocking UI).
* **🖼️ Smart Caching:** Implements `CachedNetworkImage` with memory optimization (`memCacheWidth`) to keep the app lightweight and fast.
* **🔄 Auto-Retry Mechanism:** Automatically handles network errors (404/Timeout) by retrying with exponential backoff logic, ensuring a seamless experience.
* **📱 Adaptive UI:** The background color, text contrast, and button styles automatically adjust to match the image's palette (Dark/Light mode compliant).
* **🚀 Optimized Performance:** Reduces CPU usage by processing image thumbnails for color calculation instead of full-resolution images.

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **Networking:** `http` package with timeout handling.
* **Image Handling:** `cached_network_image` for aggressive caching and smooth transitions.
* **State Management:** Native `setState` with optimized rebuilds.

## 📲 Installation

1.  **Clone the repository**
    ```bash
    git clone [https://github.com/yudhistirael/image_random_generator](https://github.com/yudhistirael/image_random_generator)
    ```

2.  **Install dependencies**
    ```bash
    cd project-name
    flutter pub get
    ```

3.  **Run the app**
    ```bash
    flutter run
    ```

## 🧠 How It Works (Optimization Logic)

To achieve the "Instant Background Change" effect without lagging the device:

1.  **Thumbnail Processing:** The app requests a resized version of the image (via Unsplash API) and internally decodes a tiny 50x50px thumbnail.
2.  **Histogram Analysis:** Instead of averaging pixels (which results in muddy brown/grey colors), the app calculates a color histogram to find the *dominant* color.
3.  **Quantization:** Similar colors are grouped together to ensure the extracted color is distinct and vibrant.
4.  **HSL Adjustment:** The resulting color is slightly darkened (Lightness adjustment) to ensure white text remains readable and the background feels immersive.

---

Made with ❤️ using Flutter