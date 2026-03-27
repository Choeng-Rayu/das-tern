# Migration Guide: Replacing Existing Loading Indicators

This guide helps you migrate from existing loading indicators to the new Health Loading Indicator system.

## Overview

The Health Loading Indicator system provides a unified, health-themed loading experience across the DasTern app. This guide shows how to replace various existing loading patterns.

## Migration Patterns

### 1. Replace CircularProgressIndicator

#### Before:
```dart
Center(
  child: CircularProgressIndicator(),
)
```

#### After:
```dart
Center(
  child: HealthLoadingIndicator(
    variant: HealthLoadingVariant.heartbeat,
    size: HealthLoadingSize.medium,
  ),
)
```

**Benefit**: Health-themed animation instead of generic spinner.

---

### 2. Replace Loading with Text

#### Before:
```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    CircularProgressIndicator(),
    SizedBox(height: 16),
    Text('Loading...'),
  ],
)
```

#### After:
```dart
HealthLoadingIndicator(
  variant: HealthLoadingVariant.pills,
  size: HealthLoadingSize.large,
  message: 'Loading medications...',
)
```

**Benefit**: Integrated message support with consistent styling.

---

### 3. Replace Custom Loading Overlay

#### Before:
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => Center(
    child: CircularProgressIndicator(),
  ),
);
```

#### After:
```dart
LoadingOverlayService.show(
  context,
  variant: HealthLoadingVariant.medicalCross,
  message: 'Processing...',
);
```

**Benefit**: Singleton service, no manual dialog management.

---

### 4. Replace FutureBuilder Loading

#### Before:
```dart
FutureBuilder(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    return YourWidget(data: snapshot.data);
  },
)
```

#### After:
```dart
FutureBuilder(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: HealthLoadingIndicator(
          variant: HealthLoadingVariant.heartbeat,
          size: HealthLoadingSize.large,
          message: 'Loading patient data...',
        ),
      );
    }
    return YourWidget(data: snapshot.data);
  },
)
```

**Benefit**: Better UX with themed animation and message.

---

### 5. Replace Button Loading State

#### Before:
```dart
ElevatedButton(
  onPressed: _isLoading ? null : _submit,
  child: _isLoading 
    ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
    : Text('Submit'),
)
```

#### After:
```dart
ElevatedButton(
  onPressed: _isLoading ? null : _submit,
  child: _isLoading 
    ? HealthLoadingIndicator.inline(
        variant: HealthLoadingVariant.progressRing,
        size: HealthLoadingSize.small,
      )
    : Text('Submit'),
)
```

**Benefit**: Cleaner code with health-themed inline indicator.

---

### 6. Replace Scaffold Loading

#### Before:
```dart
Scaffold(
  body: _isLoading
    ? Center(child: CircularProgressIndicator())
    : YourContent(),
)
```

#### After:
```dart
Scaffold(
  body: _isLoading
    ? Center(
        child: HealthLoadingIndicator(
          variant: HealthLoadingVariant.pills,
          size: HealthLoadingSize.large,
          message: 'Loading medications...',
        ),
      )
    : YourContent(),
)
```

---

### 7. Replace Manual Overlay Management

#### Before:
```dart
OverlayEntry? _overlay;

void _showLoading() {
  _overlay = OverlayEntry(
    builder: (context) => Container(
      color: Colors.black54,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  Overlay.of(context).insert(_overlay!);
}

void _hideLoading() {
  _overlay?.remove();
  _overlay = null;
}

// Usage
_showLoading();
await doWork();
_hideLoading();
```

#### After:
```dart
// Usage
await LoadingOverlayService.showWhile(
  context,
  future: doWork(),
  variant: HealthLoadingVariant.heartbeat,
  message: 'Processing...',
);
```

**Benefit**: No manual management, auto-cleanup, cleaner code.

---

### 8. Replace RefreshIndicator Custom Loading

#### Before:
```dart
RefreshIndicator(
  onRefresh: () async {
    setState(() => _isLoading = true);
    await refresh();
    setState(() => _isLoading = false);
  },
  child: _isLoading
    ? Center(child: CircularProgressIndicator())
    : ListView(...),
)
```

#### After:
```dart
RefreshIndicator(
  onRefresh: () async {
    await LoadingOverlayService.showWhile(
      context,
      future: refresh(),
      variant: HealthLoadingVariant.pills,
    );
  },
  child: ListView(...),
)
```

**Benefit**: Cleaner state management, no manual loading flags.

---

## Choosing the Right Variant

| Old Pattern | New Variant | Reason |
|-------------|-------------|---------|
| Generic list loading | `pills` | Medication-related |
| Form submission | `medicalCross` | Medical action |
| Health data fetch | `heartbeat` | Health monitoring |
| File upload/download | `progressRing` | Progress indication |
| General processing | `heartbeat` | Default choice |

## Choosing the Right Size

| Location | Size | Example |
|----------|------|---------|
| Button | `small` | Submit button |
| Card | `medium` | List item card |
| Dialog | `large` | Modal dialog |
| Fullscreen | `large` or `xlarge` | Screen overlay |

## Migration Checklist

- [ ] Identify all `CircularProgressIndicator` usages
- [ ] Determine appropriate variant for each context
- [ ] Choose appropriate size for each location
- [ ] Add meaningful messages for fullscreen indicators
- [ ] Replace manual overlay code with `LoadingOverlayService`
- [ ] Update state management to use service methods
- [ ] Test on both light and dark themes
- [ ] Verify animations are smooth
- [ ] Check localization strings are used
- [ ] Remove old loading-related code

## Common Patterns to Update

### Pattern: Medication Loading
```dart
// Replace
CircularProgressIndicator()

// With
HealthLoadingIndicator(
  variant: HealthLoadingVariant.pills,
  message: AppLocalizations.of(context).loadingMedications,
)
```

### Pattern: Health Monitoring
```dart
// Replace
CircularProgressIndicator()

// With
HealthLoadingIndicator(
  variant: HealthLoadingVariant.heartbeat,
  message: AppLocalizations.of(context).loadingMonitoringHealth,
)
```

### Pattern: Doctor Actions
```dart
// Replace
CircularProgressIndicator()

// With
HealthLoadingIndicator(
  variant: HealthLoadingVariant.medicalCross,
  message: AppLocalizations.of(context).loadingProcessing,
)
```

## Automated Search & Replace

Use these patterns to find code that needs updating:

### Find CircularProgressIndicator:
```bash
grep -r "CircularProgressIndicator" lib/
```

### Find showDialog with loading:
```bash
grep -r "showDialog.*CircularProgressIndicator" lib/
```

### Find custom overlay code:
```bash
grep -r "OverlayEntry" lib/
```

## Testing Checklist

After migration:

- [ ] All loading states display correctly
- [ ] Animations are smooth (60 FPS)
- [ ] Messages are localized
- [ ] Light theme looks good
- [ ] Dark theme looks good
- [ ] Loading dismisses properly
- [ ] No memory leaks
- [ ] Overlay blocks interaction when needed
- [ ] Async operations complete correctly
- [ ] Error handling works

## Rollback Plan

If issues arise, you can temporarily revert:

1. Keep old loading code commented out initially
2. Test new loading thoroughly before removing old code
3. Use feature flags to toggle between old/new if needed

```dart
// Temporary feature flag approach
bool useNewLoading = true;

if (useNewLoading) {
  return HealthLoadingIndicator(...);
} else {
  return CircularProgressIndicator();
}
```

## Performance Considerations

The new system:
- ✅ Uses CustomPainter (efficient rendering)
- ✅ Single AnimationController per indicator
- ✅ Proper cleanup on dispose
- ✅ No unnecessary rebuilds

Should perform **better** than or **equal to** CircularProgressIndicator.

## Support

If you encounter issues during migration:
- Check `lib/ui/widgets/loading/README.md` for detailed docs
- Review `lib/ui/widgets/loading/loading_examples.dart` for examples
- Run the demo: `LoadingDemoScreen()`
- See `LOADING_QUICK_REFERENCE.md` for quick patterns

## Example Migration PR Template

```markdown
## Migration: Health Loading Indicators

### Changes
- Replaced CircularProgressIndicator with HealthLoadingIndicator in:
  - Patient home screen
  - Medication list
  - Prescription form
- Updated to use LoadingOverlayService for:
  - Form submissions
  - Data fetching
  - File uploads

### Variant Choices
- Pills: Medication-related screens
- Heartbeat: Health monitoring
- Medical Cross: Doctor actions
- Progress Ring: Data operations

### Testing
- [x] Light theme
- [x] Dark theme
- [x] All variants
- [x] Localization
- [x] Performance

### Screenshots
[Before/After screenshots]
```

## FAQ

**Q: Can I customize the colors?**  
A: Yes, pass a `color` parameter to any HealthLoadingIndicator.

**Q: Can I use my own messages?**  
A: Yes, but prefer using localized strings from l10n.

**Q: What if I need a custom size?**  
A: Use the closest size enum, or contribute a new size option.

**Q: Can I use this with existing dialogs?**  
A: Yes, but consider using LoadingOverlayService for consistency.

**Q: How do I handle errors during loading?**  
A: Always use try-finally to ensure hide() is called:
```dart
try {
  LoadingOverlayService.show(context);
  await doWork();
} catch (e) {
  // Handle error
} finally {
  LoadingOverlayService.hide();
}
```

Or use `showWhile()` which handles this automatically.

---

**Migration Complete!** 🎉

Your app now has a unified, health-themed loading experience that's:
- More professional
- Better UX
- Easier to maintain
- Consistent across all screens
