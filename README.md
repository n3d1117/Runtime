<img src="https://github.com/user-attachments/assets/149758e8-4221-4573-ad34-b9384ef19474" height=130>

# Runtime
[![ios-version](https://img.shields.io/badge/iOS-26.0+-blue.svg)](https://developer.apple.com/ios/)
[![xcode-version](https://img.shields.io/badge/Xcode-26.0+-blue.svg)](https://developer.apple.com/xcode/)

Personal SwiftUI toy project used to experiment with:
- Extracting and working with HealthKit running workouts data
- Displaying workout data with per-split detail, pace metrics, and small charts for quick context
- On‑device “Insights” card that summarizes your running history using Apple Intelligence (FoundationModels)
- iOS 26 design language (Liquid Glass)

## Screenshot
<img src="https://github.com/user-attachments/assets/d915d4f6-94f8-4503-9e9b-1543a5398a5a" width=400>

## How It Works
`HealthKitManager` asks for read-only permissions, pulls running workouts, and rebuilds splits (km) while keeping pause time out of the numbers for maximum accuracy. The results are cached by `HealthKitStorage`, which keeps the latest snapshot in `UserDefaults`.

Insights are computed from the currently displayed workouts and cached locally. On supported devices, the on‑device language model generates a short, friendly bullet list using only the computed facts. Insights run only on device and refresh when you tap Reload.

## Requirements
- iOS 26.0 or later
- Xcode 26.0 or later
- A physical iPhone with HealthKit data; the app reads from your running workouts and cannot pull real data in the simulator
- Apple Intelligence‑capable device for Insights (FoundationModels availability varies by device and settings)

## Getting Started
1. Clone the repository and open `Runtime.xcodeproj`.
2. Update the bundle identifier if you plan to install alongside other builds.
3. Ensure the `HealthKit` capability is enabled (already configured in the project).
4. Run on an iPhone with Health data and grant the read permissions when prompted.

## Credits
- Wave separator inspired by [Paul Hudson’s tutorial on Hacking with Swift](https://www.hackingwithswift.com/plus/custom-swiftui-components/creating-a-waveview-to-draw-smooth-waveforms).
