# Liafon Cloud - Mobile App

## 📱 Flutter Smartwatch Companion App

A modern, feature-rich Flutter application that connects to your smartwatch via Bluetooth LE for comprehensive health monitoring and AI-powered insights.

### Features Implemented

#### ✅ Core Functionality
- **Bluetooth LE Connection**: Scan, connect, and communicate with smartwatches
- **Real-time Health Tracking**: Heart rate, SpO2, body temperature, steps, calories
- **Health Dashboard**: Beautiful visualizations with charts and metrics
- **Sleep Analysis**: Deep, light, REM sleep tracking with quality score
- **Fitness Tracking**: Steps, distance, calories burned
- **Emergency Alerts**: Fall detection and SOS triggers (ready for integration)
- **Settings & Profile**: User preferences, dark mode, data management

#### 🎨 UI/UX
- Modern Material Design 3 components
- Dark/Light theme support
- Responsive layouts for all screen sizes
- Smooth animations and transitions
- Intuitive onboarding flow
- Bottom navigation with 4 main sections

### Tech Stack

#### Dependencies (All Free/Open Source)
- **State Management**: Provider
- **Bluetooth**: flutter_blue_plus
- **Backend**: pocketbase
- **Charts**: fl_chart
- **Local Storage**: shared_preferences, hive
- **Health APIs**: health, fitness, pedometer
- **Notifications**: flutter_local_notifications
- **Camera/OCR**: camera, google_mlkit_text_recognition
- **PDF**: pdf, printing
- **Maps**: flutter_map
- **Audio**: just_audio, record, speech_to_text

### Project Structure

```
apps/mobile/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   ├── providers/                # State management
│   │   ├── app_provider.dart     # Global app state
│   │   ├── bluetooth_provider.dart # BLE connection
│   │   └── health_provider.dart  # Health data
│   ├── screens/                  # App screens
│   │   ├── home_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── health_dashboard_screen.dart
│   │   ├── fitness_screen.dart
│   │   ├── device_connect_screen.dart
│   │   └── settings_screen.dart
│   ├── services/                 # Backend services
│   ├── utils/                    # Utilities
│   │   └── theme.dart            # App theming
│   └── widgets/                  # Reusable widgets
├── test/                         # Unit tests
├── assets/                       # Images, fonts, etc.
└── pubspec.yaml                  # Dependencies
```

### Getting Started

#### Prerequisites
1. Install Flutter SDK (3.5.0 or higher)
2. Install Android Studio / Xcode
3. Enable Bluetooth on your device

#### Installation

```bash
cd apps/mobile

# Get dependencies
flutter pub get

# Run on Android
flutter run

# Run on iOS
flutter run

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

#### Development

```bash
# Run in debug mode with hot reload
flutter run --hot

# Run tests
flutter test

# Check code formatting
flutter format .

# Analyze code
flutter analyze

# Generate JSON serializers
flutter pub run build_runner build
```

### Key Components

#### 1. Bluetooth Provider (`bluetooth_provider.dart`)
Handles all Bluetooth LE operations:
- Device scanning and discovery
- Connection management
- Characteristic read/write
- Notification subscriptions
- Service discovery

#### 2. Health Provider (`health_provider.dart`)
Manages health data:
- Real-time vitals updates
- Historical data tracking
- Health score calculation (0-100)
- Sleep stage analysis
- Data export/clear functions

#### 3. App Provider (`app_provider.dart`)
Global application state:
- User authentication
- Onboarding status
- Theme preferences
- Settings management

### Permissions Required

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>We need Bluetooth to connect to your watch</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>We need Bluetooth to connect to your watch</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location for GPS tracking</string>
<key>NSCameraUsageDescription</key>
<string>We need camera for prescription scanning</string>
```

### Next Steps for Development

#### Phase 1 (Weeks 1-4): Core Features
- [x] Basic app structure
- [x] Bluetooth connection
- [x] Health dashboard
- [ ] Real watch integration
- [ ] Background sync

#### Phase 2 (Weeks 5-8): Advanced Features
- [ ] Prescription OCR scanning
- [ ] AI chat integration
- [ ] Emergency alerts
- [ ] Music control
- [ ] Notification mirroring

#### Phase 3 (Weeks 9-12): Polish & Launch
- [ ] Performance optimization
- [ ] Battery optimization
- [ ] Beta testing
- [ ] App store submission
- [ ] Marketing materials

### Testing

```bash
# Run unit tests
flutter test test/

# Run widget tests
flutter test test/widget_test.dart

# Integration tests
flutter test integration_test/

# Coverage report
flutter test --coverage
```

### Building for Production

#### Android
```bash
# Build release APK
flutter build apk --release --split-per-abi

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

#### iOS
```bash
# Build for App Store
flutter build ipa --release
```

### Troubleshooting

**Bluetooth not working?**
- Ensure location services are enabled (required for BLE scanning on Android)
- Check Bluetooth permissions in manifest
- Restart Bluetooth on device

**App crashes on startup?**
- Run `flutter clean` and `flutter pub get`
- Check console logs with `flutter logs`
- Ensure all native dependencies are properly configured

**Build errors?**
- Update Flutter: `flutter upgrade`
- Clear cache: `flutter clean`
- Check pubspec.yaml for dependency conflicts

### Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Submit a Pull Request

### License

This project is open source and available under the MIT License.

### Support

For issues and questions:
- GitHub Issues: https://github.com/your-repo/liafon-cloud/issues
- Documentation: https://liafon-cloud.github.dev/docs
- Email: support@liafon.cloud

---

**Built with ❤️ using Flutter and Open Source technologies**
