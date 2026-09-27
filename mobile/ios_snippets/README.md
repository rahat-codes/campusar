# iOS permissions — merge into ios/Runner/Info.plist

After running `flutter create . --platforms=android,ios` in `mobile/`,
add these keys as direct children of the top-level `<dict>` in
`ios/Runner/Info.plist`.

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>CampusAR uses your location to show your position on the campus map and calculate walking directions to buildings.</string>

<key>NSCameraUsageDescription</key>
<string>CampusAR uses your camera for AR navigation, overlaying a directional indicator over the live camera view to help you find your destination.</string>
```

## Notes

- Only `When In Use` location access is requested — CampusAR never needs
  background location (section 24 of the product spec).
- If you later add background location (e.g. for a "how far did I walk"
  feature), you would also need `NSLocationAlwaysAndWhenInUseUsageDescription`
  and the `location` background mode in `UIBackgroundModes` — not needed
  for V1.
- iOS Simulator has no real camera; test the AR navigation screen on a
  physical device, or confirm it shows the "AR is not supported on this
  device" fallback gracefully on the simulator.
- Minimum iOS deployment target: 13.0 (required by `camera` and
  `flutter_compass`). Set this in `ios/Podfile` and in Xcode's
  Runner target's "Deployment Info" if `flutter create` doesn't already
  match.
