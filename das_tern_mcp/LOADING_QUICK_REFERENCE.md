# Health Loading Indicator - Quick Reference Card

## 🎯 Quick Start

### Import
```dart
import 'package:das_tern_mcp/ui/widgets/loading/health_loading_indicator.dart';
import 'package:das_tern_mcp/services/loading_overlay_service.dart';
```

## 📋 Common Patterns

### Pattern 1: Simple Inline Loading
```dart
HealthLoadingIndicator()
```

### Pattern 2: Custom Variant
```dart
HealthLoadingIndicator(
  variant: HealthLoadingVariant.pills,
  message: 'Loading medications...',
)
```

### Pattern 3: Fullscreen Overlay
```dart
LoadingOverlayService.show(context, message: 'Processing...');
// ... do work ...
LoadingOverlayService.hide();
```

### Pattern 4: Auto-Hide
```dart
await LoadingOverlayService.showWhile(
  context,
  future: fetchData(),
  message: 'Loading...',
);
```

## 🎨 Variants

| Variant | Use For | Duration |
|---------|---------|----------|
| **heartbeat** | Health monitoring, vitals, general | 1200ms |
| **pills** | Medications, prescriptions | 2000ms |
| **medicalCross** | Doctor actions, medical ops | 1500ms |
| **progressRing** | Uploads, downloads, processing | 1800ms |

## 📏 Sizes

| Size | Pixels | Best For |
|------|--------|----------|
| **small** | 32px | Buttons, inline elements |
| **medium** | 64px | Cards, forms, default |
| **large** | 96px | Fullscreen, dialogs |
| **xlarge** | 128px | Splash, critical ops |

## 💡 Examples by Scenario

### Scenario: Loading List Data
```dart
FutureBuilder(
  future: fetchMedications(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: HealthLoadingIndicator(
          variant: HealthLoadingVariant.pills,
          message: 'Loading medications...',
        ),
      );
    }
    return ListView(...);
  },
)
```

### Scenario: Form Submission
```dart
Future<void> submit() async {
  await LoadingOverlayService.showWhile(
    context,
    future: saveForm(),
    variant: HealthLoadingVariant.medicalCross,
    message: 'Saving...',
  );
}
```

### Scenario: Button with Loading
```dart
ElevatedButton(
  onPressed: _isLoading ? null : _handlePress,
  child: _isLoading
    ? HealthLoadingIndicator.inline()
    : Text('Submit'),
)
```

### Scenario: Pull to Refresh
```dart
RefreshIndicator(
  onRefresh: () async {
    await LoadingOverlayService.showWhile(
      context,
      future: refresh(),
      variant: HealthLoadingVariant.heartbeat,
    );
  },
  child: ListView(...),
)
```

## 🌐 Localization

```dart
// Available l10n keys
AppLocalizations.of(context).loadingMedications
AppLocalizations.of(context).loadingProcessing
AppLocalizations.of(context).loadingMonitoringHealth
AppLocalizations.of(context).loadingPleaseWait
```

## 🎭 Named Constructors

```dart
// Default
HealthLoadingIndicator()

// Fullscreen
HealthLoadingIndicator.fullscreen(
  message: 'Processing...',
)

// Inline (small, no message)
HealthLoadingIndicator.inline(
  variant: HealthLoadingVariant.progressRing,
)
```

## ⚙️ Service Methods

```dart
// Show
LoadingOverlayService.show(
  context,
  variant: HealthLoadingVariant.heartbeat,
  message: 'Loading...',
  barrierDismissible: false,
);

// Hide
LoadingOverlayService.hide();

// Show while future runs (auto-hide)
await LoadingOverlayService.showWhile(
  context,
  future: someAsyncOperation(),
  message: 'Processing...',
);

// Show for specific duration
await LoadingOverlayService.showForDuration(
  context,
  duration: Duration(seconds: 2),
  message: 'Please wait...',
);

// Check if showing
bool showing = LoadingOverlayService.isShowing;
```

## 🎨 Customization

```dart
HealthLoadingIndicator(
  variant: HealthLoadingVariant.pills,
  size: HealthLoadingSize.large,
  color: Colors.red,                    // Custom color
  message: 'Custom message',             // Custom text
  messageStyle: TextStyle(fontSize: 16), // Custom style
)
```

## 🚀 Performance Tips

1. **Choose Appropriate Size**: Use smaller sizes for frequent updates
2. **Debounce Rapid Calls**: Avoid showing/hiding in quick succession
3. **Use Inline for Lists**: Prefer inline variants in scrollable content
4. **Clean Up**: Always call `hide()` in finally blocks

```dart
try {
  LoadingOverlayService.show(context);
  await doWork();
} finally {
  LoadingOverlayService.hide();
}
```

## 📱 Platform Support

| Platform | Status |
|----------|--------|
| iOS | ✅ Full support |
| Android | ✅ Full support |
| Web | ✅ Full support |
| Desktop | ✅ Full support |

## 🎯 Best Practices

### ✅ DO
- Use appropriate variant for context
- Provide meaningful messages
- Handle errors with try-finally
- Use localized strings
- Choose right size for UI

### ❌ DON'T
- Show for operations < 500ms
- Nest multiple overlays
- Forget to call hide()
- Block indefinitely
- Overuse in lists

## 🔍 Troubleshooting

### Loading doesn't show
- Ensure context is valid
- Check overlay not already showing
- Verify widget tree has Overlay

### Loading doesn't hide
- Call hide() in finally block
- Check for exceptions preventing cleanup
- Use showWhile() for auto-cleanup

### Animation stutters
- Use appropriate size
- Check device performance
- Reduce concurrent animations

## 📚 More Resources

- **Full Documentation**: `lib/ui/widgets/loading/README.md`
- **Examples**: `lib/ui/widgets/loading/loading_examples.dart`
- **Demo Screen**: `lib/ui/screens/demo/loading_demo_screen.dart`
- **Architecture**: `LOADING_SYSTEM_ARCHITECTURE.md`

## 🎬 Demo Screen

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LoadingDemoScreen(),
  ),
);
```

---

**Created for DasTern Medication Management App**  
*Production-ready Flutter loading system with health-themed animations*
