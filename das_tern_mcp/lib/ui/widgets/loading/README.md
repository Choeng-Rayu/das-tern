# Health Loading Indicator System

A comprehensive, health-themed loading screen system for the DasTern medication management Flutter app.

## Features

- **Multiple Animation Variants**: Four beautiful health-themed animations
  - Heartbeat Pulse: ECG-style heartbeat with pulsing glow
  - Rotating Pills: Pills orbiting around medical icon
  - Medical Cross: Pulsing cross with shimmer particles
  - Progress Ring: Circular progress with medical bag icon

- **Flexible Sizing**: Four size options (small, medium, large, xlarge)
- **Customizable**: Custom colors, messages, and styles
- **Global Service**: Show/hide loading from anywhere in the app
- **Theme Support**: Automatic light/dark theme adaptation
- **Premium Design**: Smooth animations suitable for healthcare apps

## Components

### 1. HealthLoadingIndicator Widget

The main loading indicator widget with multiple variants.

#### Basic Usage

```dart
// Simple usage with defaults
HealthLoadingIndicator()

// Custom variant and size
HealthLoadingIndicator(
  variant: HealthLoadingVariant.pills,
  size: HealthLoadingSize.large,
  message: 'Loading medications...',
)

// Custom color
HealthLoadingIndicator(
  variant: HealthLoadingVariant.heartbeat,
  color: Colors.red,
)
```

#### Variants

```dart
// Fullscreen overlay
HealthLoadingIndicator.fullscreen(
  message: 'Processing...',
)

// Small inline indicator
HealthLoadingIndicator.inline(
  variant: HealthLoadingVariant.progressRing,
)
```

#### Parameters

- `variant`: The animation type (heartbeat, pills, medicalCross, progressRing)
- `size`: Size of the indicator (small, medium, large, xlarge)
- `color`: Primary color for the animation
- `message`: Optional message to display below the indicator
- `messageStyle`: Custom text style for the message
- `isFullscreen`: Whether to show as fullscreen overlay
- `overlayColor`: Background color for fullscreen mode

### 2. LoadingOverlayService

A singleton service for global loading overlay management.

#### Basic Usage

```dart
// Show loading overlay
LoadingOverlayService.show(
  context,
  message: 'Loading medications...',
  variant: HealthLoadingVariant.pills,
);

// Perform async operation
await fetchData();

// Hide loading overlay
LoadingOverlayService.hide();
```

#### Automatic Management

```dart
// Auto-hide after async operation completes
final result = await LoadingOverlayService.showWhile(
  context,
  future: fetchData(),
  message: 'Loading data...',
);
```

```dart
// Show for specific duration
await LoadingOverlayService.showForDuration(
  context,
  duration: Duration(seconds: 2),
  message: 'Processing...',
);
```

#### Advanced Options

```dart
LoadingOverlayService.show(
  context,
  variant: HealthLoadingVariant.medicalCross,
  message: 'Saving prescription...',
  barrierDismissible: true, // Allow tap to dismiss
  barrierColor: Colors.black.withOpacity(0.5),
);
```

## Animation Variants

### 1. Heartbeat Pulse
- ECG-style heartbeat wave animation
- Pulsing concentric rings
- Animated heart icon in center
- Best for: Health monitoring, vital signs, general loading

### 2. Rotating Pills
- Three colorful pills orbiting center
- Medical cross in center
- Smooth rotation animation
- Best for: Medication loading, prescription data

### 3. Medical Cross
- Pulsing medical cross with glow effect
- Particle shimmer effects around cross
- Breathing animation
- Best for: Medical operations, doctor actions

### 4. Progress Ring
- Circular progress indicator
- Medical bag icon in center
- Gradient trail effect
- Best for: Upload/download, data processing

## Size Options

| Size | Dimension | Use Case |
|------|-----------|----------|
| Small | 32px | Inline, buttons, list items |
| Medium | 64px | Cards, forms, default |
| Large | 96px | Fullscreen, important operations |
| XLarge | 128px | Splash, major processes |

## Localization

All loading messages support localization via the app's l10n system:

```dart
HealthLoadingIndicator(
  message: AppLocalizations.of(context).loadingMedications,
)
```

Available translations:
- `loadingMonitoringHealth`: "Monitoring your health..."
- `loadingMedications`: "Loading medications..."
- `loadingProcessing`: "Processing..."
- `loadingPleaseWait`: "Please wait..."

## Examples

### In a Button

```dart
PrimaryButton(
  text: 'Load Data',
  isLoading: _isLoading,
  onPressed: () async {
    setState(() => _isLoading = true);
    await LoadingOverlayService.showWhile(
      context,
      future: fetchData(),
      message: 'Loading...',
    );
    setState(() => _isLoading = false);
  },
)
```

### In a ListView

```dart
ListView.builder(
  itemBuilder: (context, index) {
    return ListTile(
      leading: HealthLoadingIndicator.inline(
        variant: HealthLoadingVariant.progressRing,
        size: HealthLoadingSize.small,
      ),
      title: Text('Loading...'),
    );
  },
)
```

### Custom Implementation

```dart
class MyScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: HealthLoadingIndicator(
              variant: HealthLoadingVariant.heartbeat,
              size: HealthLoadingSize.large,
              message: 'Loading your health data...',
            ),
          );
        }
        return YourContentWidget(data: snapshot.data);
      },
    );
  }
}
```

## Demo Screen

Access the interactive demo at:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LoadingDemoScreen(),
  ),
);
```

The demo screen showcases:
- Live preview with all variants
- Interactive size and variant selection
- Fullscreen overlay examples
- Service integration examples
- Usage code samples

## Design Guidelines

### Colors
- Default: Uses theme's primary color (primaryBlue or darkPrimary)
- Custom: Pass any color via the `color` parameter
- Automatic theme adaptation for light/dark modes

### Animation Timing
- Heartbeat: 1200ms (realistic heartbeat rhythm)
- Pills: 2000ms (smooth rotation)
- Medical Cross: 1500ms (calm breathing)
- Progress Ring: 1800ms (complete circle)

### Best Practices

1. **Choose the right variant**:
   - Heartbeat for general health operations
   - Pills for medication-related tasks
   - Medical Cross for doctor/medical actions
   - Progress Ring for data operations

2. **Use appropriate sizes**:
   - Small for inline elements
   - Medium for standard loading
   - Large for fullscreen overlays
   - XLarge for critical operations

3. **Provide context with messages**:
   - Always include a message for fullscreen overlays
   - Keep messages short and actionable
   - Use localized strings

4. **Don't overuse**:
   - Only show for operations > 500ms
   - Use skeleton screens for lists
   - Consider progressive loading

## Technical Details

### Performance
- Uses `CustomPainter` for efficient rendering
- Single `AnimationController` per indicator
- Repaint only on animation changes
- No memory leaks with proper disposal

### Accessibility
- Semantic labels for screen readers
- Respect reduced motion preferences
- High contrast support

### Browser/Platform Support
- iOS: Full support
- Android: Full support
- Web: Full support
- Desktop: Full support

## File Structure

```
lib/
├── services/
│   └── loading_overlay_service.dart    # Global service
├── ui/
│   ├── screens/
│   │   └── demo/
│   │       └── loading_demo_screen.dart  # Demo screen
│   └── widgets/
│       └── loading/
│           ├── health_loading_indicator.dart  # Main widget
│           └── loading.dart                   # Barrel file
└── l10n/
    ├── app_en.arb  # English translations
    └── app_km.arb  # Khmer translations
```

## Contributing

When adding new variants:
1. Create a new `CustomPainter` class
2. Add to `HealthLoadingVariant` enum
3. Implement in `_getPainter` method
4. Update documentation and demo screen

## License

Part of the DasTern medication management app.
