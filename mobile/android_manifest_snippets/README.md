# Android permissions — merge into android/app/src/main/AndroidManifest.xml

After running `flutter create . --platforms=android,ios` in `mobile/` (see
README "Flutter setup"), your `android/app/src/main/AndroidManifest.xml`
will be regenerated fresh. Add the permissions and metadata below.

## 1. Permissions (place as direct children of `<manifest>`, above `<application>`)

```xml
<!-- Location (section 24 of the product spec: only what each feature needs) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Camera, for AR navigation -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Internet, for optional background sync with the backend (app works
     fully offline without it — see README "Offline architecture") -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## 2. Camera feature flag (place inside `<manifest>`, alongside the permissions)

Declares the camera as optional so the app can still install on devices
without one (AR features degrade gracefully — see
`features/ar/services/ar_navigation_service.dart`).

```xml
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

## 3. minSdkVersion

`geolocator`, `camera`, and `flutter_compass` require API 21+. In
`android/app/build.gradle`, set:

```gradle
defaultConfig {
    minSdkVersion 21
    ...
}
```

## 4. Notes

- Do NOT request these permissions at app startup. `LocationService` and
  the AR navigation screen request them lazily, only when the relevant
  feature is opened (section 24: "Only request them when the feature
  requires them").
- If you rename the package (`applicationId`), keep it consistent between
  `android/app/build.gradle` and `pubspec.yaml`'s `name` field, per
  standard Flutter project conventions.
