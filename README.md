# Runtime
[![ios-version](https://img.shields.io/badge/iOS-18.2+-blue.svg)](https://developer.apple.com/ios/)
[![xcode-version](https://img.shields.io/badge/Xcode-16.2+-blue.svg)](https://developer.apple.com/xcode/)

Runtime is a personal offline app that lists your HealthKit running workouts with per-split detail, pace metrics, and small charts for quick context.

## How It Works
`HealthKitManager` asks for read-only permissions, pulls running workouts, and rebuilds splits kilometre by kilometre while keeping pause time out of the numbers for maximum accuracy. The results are cached by `HealthKitStorage`, which keeps the latest snapshot in `UserDefaults`.

## Requirements
- iOS 18.2 or later
- Xcode 16.2 or later
- A physical device with HealthKit data; the app reads from your running workouts and cannot pull real data in the simulator

## Getting Started
1. Clone the repository and open `Runtime.xcodeproj`.
2. Update the bundle identifier if you plan to install alongside other builds.
3. Ensure the `HealthKit` capability is enabled (already configured in the project).
4. Run on an iPhone with Health data and grant the read permissions when prompted.

## Credits
- Wave separator inspired by [Paul Hudson’s tutorial on Hacking with Swift](https://www.hackingwithswift.com/plus/custom-swiftui-components/creating-a-waveview-to-draw-smooth-waveforms).
