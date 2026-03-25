# Reusable AppButton Widget - Documentation

## 📍 Location

**File Created**: `das_tern_mcp/lib/ui/widgets/app_button.dart`

---

## 🎯 What Is This?

A comprehensive, reusable button widget that can be used across all screens in the app. It supports:

✅ Text and icons (leading or trailing)
✅ Multiple styles (filled, outlined, text)
✅ Custom shapes (rounded, pill, square)
✅ Multiple sizes (small, medium, large)
✅ Loading states
✅ Gradient backgrounds
✅ Full customization (colors, borders, padding, etc.)
✅ Light and dark mode support
✅ Disabled states

---

## 🚀 Quick Start

### Basic Usage

```dart
import 'package:das_tern_mcp/ui/widgets/app_button.dart';

// Simple button
AppButton(
  text: 'Continue',
  onPressed: () {
    print('Button pressed!');
  },
)
```

---

## 📚 Usage Examples

### 1. Basic Filled Button

```dart
AppButton(
  text: 'Submit',
  onPressed: () {},
)
```

### 2. Button with Leading Icon

```dart
AppButton(
  text: 'Add Item',
  icon: Icons.add,
  onPressed: () {},
)
```

### 3. Button with Trailing Icon

```dart
AppButton(
  text: 'Next',
  icon: Icons.arrow_forward,
  iconPosition: IconPosition.trailing,
  onPressed: () {},
)
```

### 4. Outlined Button

```dart
AppButton(
  text: 'Cancel',
  style: AppButtonStyle.outlined,
  onPressed: () {},
)
```

### 5. Text Button

```dart
AppButton(
  text: 'Skip',
  style: AppButtonStyle.text,
  onPressed: () {},
)
```

### 6. Different Sizes

```dart
// Small
AppButton(
  text: 'Small',
  size: AppButtonSize.small,
  onPressed: () {},
)

// Medium (default)
AppButton(
  text: 'Medium',
  size: AppButtonSize.medium,
  onPressed: () {},
)

// Large
AppButton(
  text: 'Large',
  size: AppButtonSize.large,
  onPressed: () {},
)
```

### 7. Different Shapes

```dart
// Rounded (default)
AppButton(
  text: 'Rounded',
  shape: AppButtonShape.rounded,
  onPressed: () {},
)

// Pill
AppButton(
  text: 'Pill',
  shape: AppButtonShape.pill,
  onPressed: () {},
)

// Square
AppButton(
  text: 'Square',
  shape: AppButtonShape.square,
  onPressed: () {},
)
```

### 8. Custom Colors

```dart
AppButton(
  text: 'Custom',
  backgroundColor: Colors.purple,
  textColor: Colors.white,
  onPressed: () {},
)
```

### 9. Gradient Button

```dart
AppButton(
  text: 'Premium',
  gradient: LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  ),
  onPressed: () {},
)
```

### 10. Loading State

```dart
AppButton(
  text: 'Processing',
  isLoading: true,
  onPressed: () {},
)
```

### 11. Disabled Button

```dart
AppButton(
  text: 'Disabled',
  disabled: true,
  onPressed: () {},
)
```

### 12. Auto-sized Button (not full width)

```dart
AppButton(
  text: 'Auto Size',
  fullWidth: false,
  onPressed: () {},
)
```

### 13. Custom Border (Outlined)

```dart
AppButton(
  text: 'Custom Border',
  style: AppButtonStyle.outlined,
  borderColor: Colors.red,
  borderWidth: 2.0,
  onPressed: () {},
)
```

### 14. Custom Padding

```dart
AppButton(
  text: 'Custom Padding',
  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
  onPressed: () {},
)
```

### 15. Custom Text Style

```dart
AppButton(
  text: 'Custom Text',
  textStyle: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  ),
  onPressed: () {},
)
```

---

## 🎨 Properties Reference

### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | Button text |

### Optional Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `onPressed` | `VoidCallback?` | `null` | Callback when pressed |
| `icon` | `IconData?` | `null` | Optional icon |
| `iconPosition` | `IconPosition` | `leading` | Icon position (leading/trailing) |
| `style` | `AppButtonStyle` | `filled` | Button style |
| `shape` | `AppButtonShape` | `rounded` | Button shape |
| `size` | `AppButtonSize` | `medium` | Button size |
| `fullWidth` | `bool` | `true` | Take full width |
| `isLoading` | `bool` | `false` | Show loading spinner |
| `disabled` | `bool` | `false` | Disable button |
| `backgroundColor` | `Color?` | `null` | Custom background color |
| `textColor` | `Color?` | `null` | Custom text color |
| `borderColor` | `Color?` | `null` | Custom border color |
| `borderWidth` | `double?` | `null` | Custom border width |
| `gradient` | `Gradient?` | `null` | Custom gradient |
| `borderRadius` | `double?` | `null` | Custom border radius |
| `padding` | `EdgeInsets?` | `null` | Custom padding |
| `textStyle` | `TextStyle?` | `null` | Custom text style |
| `iconSize` | `double?` | `null` | Custom icon size |
| `iconSpacing` | `double?` | `null` | Space between icon and text |
| `elevation` | `double?` | `null` | Custom elevation |

---

## 🎭 Enums

### AppButtonStyle

```dart
enum AppButtonStyle {
  filled,    // Solid background
  outlined,  // Border only
  text,      // No background or border
}
```

### AppButtonShape

```dart
enum AppButtonShape {
  rounded,  // 12px radius
  pill,     // 999px radius (fully rounded)
  square,   // 4px radius
}
```

### AppButtonSize

```dart
enum AppButtonSize {
  small,   // 36px height
  medium,  // 48px height
  large,   // 56px height
}
```

### IconPosition

```dart
enum IconPosition {
  leading,   // Icon before text
  trailing,  // Icon after text
}
```

---

## 📏 Size Specifications

### Small
- Height: 36px
- Padding: 16px horizontal, 8px vertical
- Font size: 13px
- Icon size: 16px

### Medium (Default)
- Height: 48px
- Padding: 20px horizontal, 12px vertical
- Font size: 15px
- Icon size: 18px

### Large
- Height: 56px
- Padding: 24px horizontal, 16px vertical
- Font size: 17px
- Icon size: 20px

---

## 🎨 Style Specifications

### Filled
- Solid background color
- White text (default)
- 2px elevation
- No border

### Outlined
- Transparent background
- Colored text (matches border)
- 1.5px border
- No elevation

### Text
- Transparent background
- Colored text
- No border
- No elevation

---

## 🌈 Color Behavior

### Default Colors (if not specified)

**Filled Style**:
- Background: `Theme.of(context).primaryColor`
- Text: `Colors.white`

**Outlined Style**:
- Border: `Theme.of(context).primaryColor`
- Text: `Theme.of(context).primaryColor`

**Text Style**:
- Text: `Theme.of(context).primaryColor`

### Disabled State
- Background: `Colors.grey.shade300`
- Text: `Colors.grey.shade600`

---

## 💡 Real-World Examples

### Login Button

```dart
AppButton(
  text: 'Login',
  icon: Icons.login,
  size: AppButtonSize.large,
  onPressed: () {
    // Handle login
  },
)
```

### Cancel Button

```dart
AppButton(
  text: 'Cancel',
  style: AppButtonStyle.outlined,
  onPressed: () {
    Navigator.pop(context);
  },
)
```

### Premium Upgrade Button

```dart
AppButton(
  text: 'Upgrade to Premium',
  icon: Icons.workspace_premium,
  gradient: LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
  ),
  onPressed: () {
    // Navigate to upgrade screen
  },
)
```

### Delete Button

```dart
AppButton(
  text: 'Delete',
  icon: Icons.delete,
  backgroundColor: Colors.red,
  onPressed: () {
    // Show confirmation dialog
  },
)
```

### Loading Button

```dart
AppButton(
  text: 'Submitting...',
  isLoading: _isSubmitting,
  onPressed: _isSubmitting ? null : _handleSubmit,
)
```

### Social Login Button

```dart
AppButton(
  text: 'Continue with Google',
  icon: Icons.g_mobiledata,
  style: AppButtonStyle.outlined,
  borderColor: Colors.grey,
  textColor: Colors.black,
  fullWidth: true,
  onPressed: () {
    // Handle Google login
  },
)
```

---

## 🔧 Advanced Customization

### Custom Gradient with Icon

```dart
AppButton(
  text: 'Platinum Plan',
  icon: Icons.diamond,
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFF7C3AED),
    ],
  ),
  shape: AppButtonShape.pill,
  size: AppButtonSize.large,
  onPressed: () {},
)
```

### Custom Everything

```dart
AppButton(
  text: 'Custom Button',
  icon: Icons.star,
  iconPosition: IconPosition.trailing,
  backgroundColor: Color(0xFF1E40AF),
  textColor: Colors.white,
  borderRadius: 20,
  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
  textStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  ),
  iconSize: 22,
  iconSpacing: 12,
  elevation: 4,
  onPressed: () {},
)
```

---

## 🎯 Use Cases by Screen

### Login/Register Screens
```dart
// Primary action
AppButton(
  text: 'Sign In',
  size: AppButtonSize.large,
  onPressed: _handleSignIn,
)

// Secondary action
AppButton(
  text: 'Create Account',
  style: AppButtonStyle.outlined,
  onPressed: _handleSignUp,
)
```

### Settings Screen
```dart
// Logout button
AppButton(
  text: 'Logout',
  icon: Icons.logout,
  style: AppButtonStyle.text,
  textColor: Colors.red,
  fullWidth: false,
  onPressed: _handleLogout,
)
```

### Payment Screen
```dart
// Confirm payment
AppButton(
  text: 'Confirm Payment',
  icon: Icons.payment,
  gradient: LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF28A745)],
  ),
  size: AppButtonSize.large,
  onPressed: _handlePayment,
)
```

### Form Screens
```dart
// Submit button
AppButton(
  text: 'Submit',
  isLoading: _isSubmitting,
  onPressed: _isSubmitting ? null : _handleSubmit,
)

// Cancel button
AppButton(
  text: 'Cancel',
  style: AppButtonStyle.outlined,
  onPressed: () => Navigator.pop(context),
)
```

---

## 🧪 Testing Checklist

### Visual Tests
- [ ] Button displays correctly in light mode
- [ ] Button displays correctly in dark mode
- [ ] Icon displays correctly (leading position)
- [ ] Icon displays correctly (trailing position)
- [ ] Loading spinner displays correctly
- [ ] Disabled state displays correctly
- [ ] All sizes display correctly (small, medium, large)
- [ ] All shapes display correctly (rounded, pill, square)
- [ ] All styles display correctly (filled, outlined, text)
- [ ] Gradient displays correctly
- [ ] Custom colors display correctly

### Interaction Tests
- [ ] Button responds to tap
- [ ] Disabled button doesn't respond to tap
- [ ] Loading button doesn't respond to tap
- [ ] Ripple effect works correctly
- [ ] Button works in scrollable views
- [ ] Button works in dialogs
- [ ] Button works in bottom sheets

### Responsive Tests
- [ ] Full width button takes full width
- [ ] Auto-sized button wraps content
- [ ] Button works on small screens
- [ ] Button works on large screens
- [ ] Button works in landscape mode

---

## 🔍 Where I Changed

### New File Created
✅ `das_tern_mcp/lib/ui/widgets/app_button.dart`

### Files NOT Modified
❌ No existing files were modified
❌ No backend changes
❌ No other UI files changed

---

## 📦 How to Use in Your Screens

### Step 1: Import the widget

```dart
import 'package:das_tern_mcp/ui/widgets/app_button.dart';
```

### Step 2: Use it in your build method

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        AppButton(
          text: 'Click Me',
          onPressed: () {
            print('Button clicked!');
          },
        ),
      ],
    ),
  );
}
```

---

## 🎨 Design System Integration

This button follows the app's design system:

- Uses theme colors by default
- Supports light and dark mode
- Consistent sizing and spacing
- Matches existing button styles
- Compatible with existing widgets

---

## 🚫 What NOT to Do

### ❌ Don't use without text
```dart
// BAD
AppButton(
  text: '',  // Empty text
  onPressed: () {},
)
```

### ❌ Don't use gradient with backgroundColor
```dart
// BAD - gradient will override backgroundColor
AppButton(
  text: 'Button',
  backgroundColor: Colors.blue,  // This will be ignored
  gradient: LinearGradient(...),  // This will be used
  onPressed: () {},
)
```

### ❌ Don't use borderColor with filled style
```dart
// BAD - borderColor only works with outlined style
AppButton(
  text: 'Button',
  style: AppButtonStyle.filled,
  borderColor: Colors.red,  // This will be ignored
  onPressed: () {},
)
```

---

## 💡 Tips and Best Practices

### 1. Use Consistent Sizes
Use the same size for similar actions across your app.

### 2. Use Semantic Colors
Use colors that match the action (red for delete, green for success, etc.)

### 3. Use Loading State
Always show loading state for async operations.

### 4. Use Disabled State
Disable buttons when actions can't be performed.

### 5. Use Icons Wisely
Only use icons when they add clarity, not decoration.

### 6. Test Both Themes
Always test buttons in both light and dark mode.

---

## 🔄 Migration from Old Buttons

### From PrimaryButton (common_widgets.dart)

**Before**:
```dart
PrimaryButton(
  text: 'Submit',
  onPressed: () {},
  icon: Icons.check,
)
```

**After**:
```dart
AppButton(
  text: 'Submit',
  onPressed: () {},
  icon: Icons.check,
)
```

### From ElevatedButton

**Before**:
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Submit'),
)
```

**After**:
```dart
AppButton(
  text: 'Submit',
  onPressed: () {},
)
```

### From OutlinedButton

**Before**:
```dart
OutlinedButton(
  onPressed: () {},
  child: Text('Cancel'),
)
```

**After**:
```dart
AppButton(
  text: 'Cancel',
  style: AppButtonStyle.outlined,
  onPressed: () {},
)
```

---

## 📊 Comparison with Existing Buttons

| Feature | PrimaryButton | AppButton |
|---------|---------------|-----------|
| Text | ✅ | ✅ |
| Icon | ✅ | ✅ |
| Loading | ✅ | ✅ |
| Outlined | ✅ | ✅ |
| Sizes | ❌ | ✅ |
| Shapes | ❌ | ✅ |
| Gradient | ❌ | ✅ |
| Icon Position | ❌ | ✅ |
| Custom Colors | ❌ | ✅ |
| Custom Padding | ❌ | ✅ |
| Text Style | ❌ | ✅ |
| Auto Size | ❌ | ✅ |

---

## 🎯 Summary

**What**: Reusable button widget with extensive customization
**Where**: `das_tern_mcp/lib/ui/widgets/app_button.dart`
**Backend Changes**: None
**Breaking Changes**: None
**Ready to Use**: Yes ✅

---

## 📞 Questions?

**Q: Can I use this with existing buttons?**
A: Yes! It's designed to work alongside existing buttons.

**Q: Do I need to replace all existing buttons?**
A: No! Use it for new screens or gradually migrate.

**Q: Does it work with forms?**
A: Yes! Works perfectly in forms.

**Q: Can I customize everything?**
A: Yes! Every aspect is customizable.

**Q: Does it support animations?**
A: Yes! Uses Flutter's built-in button animations.

**Q: Is it accessible?**
A: Yes! Uses semantic widgets and proper contrast.

---

**Created**: March 25, 2026
**Status**: ✅ Complete and ready to use
**Backend Changes**: ❌ None
**Breaking Changes**: ❌ None

---

**Happy coding! 🚀**
