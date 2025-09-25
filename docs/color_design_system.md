# AFDYL Color Design System

## 🎨 Color Palette

### Primary Colors
| Color Name | Hex Code | Usage |
|------------|----------|--------|
| **Primary** | `#EDD1B0` | Main brand color, primary buttons, headers |
| **Secondary** | `#EDDD6E` | Accent elements, secondary buttons |
| **Tertiary** | `#E37100` | Highlights, call-to-action elements |
| **Yellow** | `#F8FD89` | Important notifications, warnings |

### Color Variations
| Base Color | Light Variant | Dark Variant |
|------------|---------------|--------------|
| Primary | `#F5E5D0` | `#E5C190` |
| Secondary | `#F1E68E` | `#E9D54E` |
| Tertiary | `#E98B33` | `#CC5C00` |

## 📱 Implementation Guide

### 1. Import Color Constants
```dart
import '../constants/app_colors.dart';
```

### 2. Basic Usage
```dart
// Using primary color
Container(
  color: AppColors.primary,
  child: Text('Hello'),
)

// Using gradient
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
  ),
  child: Text('Gradient Background'),
)

// Using with opacity
Container(
  color: AppColors.primaryWithOpacity(0.5),
  child: Text('Semi-transparent'),
)

// Using White Soft for backgrounds
Scaffold(
  backgroundColor: AppColors.whiteSoft,
  body: Container(
    color: AppColors.whiteSoft,
    child: Text('Soft background'),
  ),
)
```

### 3. Text Colors
```dart
Text(
  'Primary text',
  style: TextStyle(color: AppColors.textPrimary),
)

Text(
  'Secondary text',
  style: TextStyle(color: AppColors.textSecondary),
)

// Text on colored backgrounds
Container(
  color: AppColors.primary,
  child: Text(
    'Text on primary background',
    style: TextStyle(color: AppColors.textOnPrimary),
  ),
)
```

### 4. Semantic Colors
```dart
// Success state
Container(color: AppColors.success)

// Error state  
Container(color: AppColors.error)

// Warning state
Container(color: AppColors.warning)

// Info state
Container(color: AppColors.info)
```

### 5. Shadows
```dart
Container(
  decoration: BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowMedium,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
)
```

## 🏗️ Design System Structure

```
lib/
├── constants/
│   └── app_colors.dart          # Main color definitions
├── themes/
│   └── app_theme.dart           # Theme configuration
└── widgets/
    └── themed_components.dart   # Pre-styled components
```

## ✅ Usage Examples

### Dashboard Header
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(20),
  ),
  child: // Your content
)
```

### Button Styles
```dart
// Primary button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
  ),
  child: Text('Primary Button'),
)

// Secondary button  
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.textOnSecondary,
  ),
  child: Text('Secondary Button'),
)
```

### Card Components
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.whiteSoft, // atau AppColors.surface
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: // Card content
)
```

## 🎯 Best Practices

### DO ✅
- Always use AppColors constants instead of hardcoded hex values
- Use semantic colors for appropriate states (success, error, warning)
- Maintain proper contrast ratios for accessibility
- Use gradient variations for visual hierarchy
- Apply consistent shadow styles

### DON'T ❌
- Don't use hardcoded Color(0xFF...) values
- Don't mix old color scheme with new one
- Don't use colors that don't exist in the design system
- Don't forget to test color combinations for accessibility

## 🚀 Migration Guide

### From Old Colors to New Colors
```dart
// OLD ❌
Color(0xFFE8B4B8) → AppColors.primary
Color(0xFFD4A5A8) → AppColors.primaryDark
Color(0xFFF5F5DC) → AppColors.offWhite

// NEW ✅
AppColors.primary
AppColors.primaryDark  
AppColors.offWhite
```

## 🔄 Update Checklist

When implementing new design system:

- [ ] Import `app_colors.dart` in files
- [ ] Replace hardcoded colors with AppColors constants
- [ ] Update gradients to use new color combinations
- [ ] Test color contrast for accessibility
- [ ] Update theme configuration if needed
- [ ] Document any custom color usage

## 🎨 Color Preview

### Primary Palette
- **Primary (#EDD1B0)**: Warm beige, main brand color
- **Secondary (#EDDD6E)**: Golden yellow, for accents  
- **Tertiary (#E37100)**: Orange, for highlights
- **Yellow (#F8FD89)**: Bright yellow, for important elements

### Neutral Palette
- **White (#FFFFFF)**: Pure white
- **White Soft (#FDFFF2)**: Soft white for main backgrounds and cards
- **Off White (#FAF8F5)**: Warm off-white for alternative backgrounds
- **Light Gray (#F5F5F5)**: Very light gray for subtle borders
- **Gray (#9E9E9E)**: Medium gray for secondary text
- **Dark Gray (#424242)**: Dark gray for primary text
- **Black (#000000)**: Pure black for maximum contrast
