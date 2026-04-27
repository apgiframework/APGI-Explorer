# APGI macOS Design Guide

## Overview

This document specifies the exact design specifications for the APGI Appendix macOS application in light mode. All colors, typography, spacing, and component specifications are defined to ensure consistency across the application.

---

## Color Palette

### Neural Glow Semantics

The light mode uses a semantic color system based on neural terminology, providing clear visual hierarchy and meaning.

| Semantic Name | Hex Code | RGB | Usage |
| -------------- | ---------- | --- | ---- |
| **thresholdBlue** | `#0066CC` | rgb(0, 102, 204) | Primary actions, links, info states |
| **precisionRed** | `#CC0033` | rgb(204, 0, 51) | Errors, danger states, critical alerts |
| **errorYellow** | `#CC9900` | rgb(204, 153, 0) | Warnings, caution states |
| **workspacePurple** | `#6633CC` | rgb(102, 51, 204) | Secondary actions, workspace elements |
| **neuromodGreen** | `#008866` | rgb(0, 136, 102) | Success states, confirmations |
| **inactiveSlate** | `#6B7280` | rgb(107, 114, 128) | Disabled states, inactive elements |
| **spaceBlack** | `#FFFFFF` | rgb(255, 255, 255) | Backgrounds, cards, surfaces |
| **darkNavy** | `#F3F4F6` | rgb(243, 244, 246) | Secondary backgrounds, dividers |

### Legacy Brand Color Aliases

For backward compatibility, the following aliases map to the semantic colors:

| Legacy Name | Maps To |
| ------------ | ------- |
| `apgiBlue` | `thresholdBlue` |
| `apgiPurple` | `workspacePurple` |
| `apgiGreen` | `neuromodGreen` |
| `apgiOrange` | `errorYellow` |
| `apgiRed` | `precisionRed` |

### Semantic State Colors

| State | Color | Usage |
| ----- | ----- | ---- |
| `apgiSuccess` | `neuromodGreen` | Success messages, completed states |
| `apgiWarning` | `errorYellow` | Warning messages, caution alerts |
| `apgiDanger` | `precisionRed` | Error messages, destructive actions |
| `apgiInfo` | `thresholdBlue` | Information messages, help text |

---

## Typography

### Font Families

The application uses three font families for different purposes:

#### Crimson Pro (Headlines & Titles)

- **Usage**: Display text, headings, titles
- **Characteristics**: Serif font, elegant and readable for long-form content

#### Inter (Body, Labels, Captions)

- **Usage**: Body text, UI labels, captions
- **Characteristics**: Sans-serif, highly legible at small sizes

#### Fira Code (Monospace)

- **Usage**: Code snippets, technical content
- **Characteristics**: Monospace, optimized for code readability

### Typography Scale

| Name | Font Family | Weight | Size | Usage |
| ---- | ------------ | ------ | ---- | ---- |
| **display** | Crimson Pro | Bold | 72pt | Hero titles, main headings |
| **h1** | Crimson Pro | Bold | 48pt | Page titles |
| **h2** | Crimson Pro | SemiBold | 30pt | Section headings |
| **h3** | Inter | SemiBold | 20pt | Subsection headings |
| **body** | Inter | Regular | 16pt | Body text, paragraphs |
| **label** | Inter | Medium | 14pt | UI labels, form fields |
| **caption** | Inter | Regular | 14pt | Captions, helper text |
| **micro** | Inter | Regular | 12pt | Small text, footnotes |
| **mono** | Fira Code | Regular | 14pt | Code, technical content |

### System Font Fallbacks

When custom fonts are not available, the following system fonts are used:

- **Headlines**: System serif font with bold weight
- **Body**: System default font with regular weight

---

## Spacing System

### Base Unit

The spacing system is based on an 8px grid unit (`unit = 8`).

### Spacing Scale

| Name | Value (px) | Usage |
| ---- | --------- | ---- |
| **xs** | 4px | Tight spacing between related elements |
| **sm** | 8px | Small gaps, icon padding |
| **md** | 16px | Standard spacing, paragraph spacing |
| **lg** | 24px | Component padding, section margins |
| **xl** | 32px | Large spacing between sections |
| **xxl** | 48px | Extra large spacing |
| **xxxl** | 64px | Major section breaks |
| **giant** | 96px | Page-level spacing |

### Contextual Spacing

| Context | Value | Usage |
| ------- | ----- | ---- |
| **cardPadding** | 24px | Padding inside cards |
| **sectionSpacing** | 96px | Spacing between major sections |
| **componentSpacing** | 48px | Spacing between components |
| **elementSpacing** | 24px | Spacing between related elements |

---

## Border Radius

| Name | Value | Usage |
| ---- | ----- | ---- |
| **standard** | 12px | Standard corner radius for cards, buttons, containers |

---

## Accessibility Specifications

### Color Blind Modes

The application supports the following color blind modes with automatic adjustments:

| Mode | Adjustment |
| ---- | ---------- |
| **None** | No adjustments |
| **Protanopia** | Opacity: 0.8, Saturation: 0.7 |
| **Deuteranopia** | Opacity: 0.8, Saturation: 0.6 |
| **Tritanopia** | Opacity: 0.8, Saturation: 0.5 |

### High Contrast Mode

When high contrast is enabled:

- **Background**: Pure white (`#FFFFFF`)
- **Foreground**: Pure black (`#000000`)
- **Color Scheme**: Forced to light mode

### Accessibility Preferences

Default accessibility settings:

- **Color Blind Mode**: None
- **High Contrast**: Disabled
- **Reduced Motion**: Disabled
- **Haptic Feedback**: Enabled

### Dynamic Type

The application honors the user's system dynamic type settings. No forced font sizes are applied to ensure accessibility for users with vision impairments.

---

## Component Specifications

### Buttons

#### Primary Button

- Background: `thresholdBlue` (`#0066CC`)
- Text: White
- Corner Radius: `standard` (12px)
- Padding: `md` (16px) horizontal, `sm` (8px) vertical
- Font: `label` (Inter Medium, 14pt)

#### Secondary Button

- Background: Transparent
- Border: `thresholdBlue` (`#0066CC`)
- Text: `thresholdBlue` (`#0066CC`)
- Corner Radius: `standard` (12px)
- Padding: `md` (16px) horizontal, `sm` (8px) vertical
- Font: `label` (Inter Medium, 14pt)

#### Destructive Button

- Background: `precisionRed` (`#CC0033`)
- Text: White
- Corner Radius: `standard` (12px)
- Padding: `md` (16px) horizontal, `sm` (8px) vertical
- Font: `label` (Inter Medium, 14pt)

### Cards

#### Content Card

- Background: `spaceBlack` (`#FFFFFF`)
- Border: 1px solid `darkNavy` (`#F3F4F6`)
- Corner Radius: `standard` (12px)
- Padding: `cardPadding` (24px)
- Shadow: Subtle drop shadow

#### Interactive Card

- Background: `spaceBlack` (`#FFFFFF`)
- Border: 1px solid `darkNavy` (`#F3F4F6`)
- Corner Radius: `standard` (12px)
- Padding: `cardPadding` (24px)
- Hover State: Border color changes to `thresholdBlue` (`#0066CC`)

### Navigation

#### Sidebar

- Background: `darkNavy` (`#F3F4F6`)
- Selected Item Background: `thresholdBlue` (`#0066CC`)
- Selected Item Text: White
- Unselected Item Text: `inactiveSlate` (`#6B7280`)
- Item Padding: `md` (16px)
- Font: `label` (Inter Medium, 14pt)

#### Toolbar

- Background: `spaceBlack` (`#FFFFFF`)
- Border: 1px solid `darkNavy` (`#F3F4F6`)
- Height: 52px
- Icon Color: `inactiveSlate` (`#6B7280`)
- Active Icon Color: `thresholdBlue` (`#0066CC`)

### Tables

#### Enhanced Data Table

- Background: `spaceBlack` (`#FFFFFF`)
- Header Background: `darkNavy` (`#F3F4F6`)
- Header Text: `h3` (Inter SemiBold, 20pt)
- Row Text: `body` (Inter Regular, 16pt)
- Border Color: `darkNavy` (`#F3F4F6`)
- Row Padding: `md` (16px)
- Corner Radius: `standard` (12px)

### Form Elements

#### Text Field

- Background: `spaceBlack` (`#FFFFFF`)
- Border: 1px solid `darkNavy` (`#F3F4F6`)
- Corner Radius: `standard` (12px)
- Padding: `md` (16px)
- Font: `body` (Inter Regular, 16pt)
- Focus State: Border color changes to `thresholdBlue` (`#0066CC`)

#### Toggle/Switch

- Active Color: `thresholdBlue` (`#0066CC`)
- Inactive Color: `inactiveSlate` (`#6B7280`)
- Corner Radius: Fully rounded

---

## Iconography

### SF Symbols

The application uses Apple's SF Symbols for consistency with macOS design language.

#### Common Icons

- Navigation: `chevron.left`, `chevron.right`, `house`, `book`
- Actions: `plus`, `minus`, `trash`, `pencil`
- Status: `checkmark.circle`, `exclamationmark.triangle`, `info.circle`
- Settings: `gear`, `slider.horizontal.3`

#### Icon Colors

- Default: `inactiveSlate` (`#6B7280`)
- Active: `thresholdBlue` (`#0066CC`)
- Success: `neuromodGreen` (`#008866`)
- Warning: `errorYellow` (`#CC9900`)
- Error: `precisionRed` (`#CC0033`)

---

## Animation & Motion

### Transitions

- **Default Duration**: 0.3s
- **Easing**: Ease-in-out
- **Reduced Motion**: Disabled when reduced motion preference is enabled

### Hover States

- **Duration**: 0.2s
- **Easing**: Ease-out
- **Effect**: Subtle opacity change or color transition

---

## Dark Mode Considerations

While this document specifies light mode, the application also supports dark mode. When implementing dark mode:

- Invert the semantic color meanings while maintaining contrast ratios
- Use darker backgrounds (`#1C1C1E` or similar)
- Adjust text colors to maintain WCAG AA compliance
- Preserve the semantic color relationships (e.g., `thresholdBlue` remains the primary action color)

---

## Implementation Notes

### Color Extension

All colors are accessible through the `Color` extension in `APGIColors.swift`:

```swift
Color.thresholdBlue
Color.precisionRed
Color.errorYellow
Color.workspacePurple
Color.neuromodGreen
Color.inactiveSlate
Color.spaceBlack
Color.darkNavy
```

### Typography Extension

All typography is accessible through the `APGITypography` enum:

```swift
APGITypography.display
APGITypography.h1
APGITypography.h2
APGITypography.h3
APGITypography.body
APGITypography.label
APGITypography.caption
APGITypography.micro
APGITypography.mono
```

### Spacing Extension

All spacing is accessible through the `APGISpacing` enum:

```swift
APGISpacing.xs
APGISpacing.sm
APGISpacing.md
APGISpacing.lg
APGISpacing.xl
APGISpacing.xxl
APGISpacing.xxxl
APGISpacing.giant
APGISpacing.cardPadding
APGISpacing.sectionSpacing
APGISpacing.componentSpacing
APGISpacing.elementSpacing
```

### Radius Extension

Border radius is accessible through the `APGIRadius` enum:

```swift
APGIRadius.standard
```

---

## Compliance

### WCAG 2.1 AA

This design guide ensures compliance with WCAG 2.1 AA standards:

- **Color Contrast**: Minimum 4.5:1 for normal text, 3:1 for large text
- **Text Resize**: Supports 200% zoom without loss of content
- **Keyboard Navigation**: All interactive elements are keyboard accessible
- **Focus Indicators**: Clear focus states for all interactive elements

### Apple Human Interface Guidelines

The design follows Apple's Human Interface Guidelines for macOS:

- Native macOS controls and patterns
- Consistent with system color schemes
- Proper use of SF Symbols
- Appropriate spacing and typography
- Accessibility-first design approach
