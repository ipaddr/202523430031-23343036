# 🎯 Theme Refactoring Checklist & Implementation Guide

## ✅ Status: PARTIALLY COMPLETED

### **Completed (9 Admin Screens):**
- ✅ admin_activity_screen.dart
- ✅ admin_dashboard_screen.dart
- ✅ admin_notification_screen.dart
- ✅ admin_officers_management_screen.dart
- ✅ admin_officers_screen.dart
- ✅ admin_profile_screen.dart
- ✅ admin_reports_screen.dart
- ✅ admin_request_list_screen.dart
- ✅ admin_request_list_screen_new.dart
- ✅ admin_schedule_screen.dart
- ✅ admin_settings_screen.dart
- ✅ admin_users_screen.dart
- ✅ admin_waste_data_screen.dart

### **Pattern Used:**
```dart
// BEFORE (Hard-coded)
backgroundColor: const Color(0xFFF8FAFC),

// AFTER (Theme-aware)
backgroundColor: Theme.of(context).scaffoldBackgroundColor,
```

---

## 📋 Remaining Refactoring Tasks

### **GROUP 1: Petugas Screens (14 files)**

#### Pattern 1A: Scaffold backgroundColor
```dart
// BEFORE
backgroundColor: const Color(0xFFF1F5F9),

// AFTER
backgroundColor: Theme.of(context).scaffoldBackgroundColor,
```

**Files to refactor:**
- petugas_arrival_screen.dart
- petugas_history_screen.dart
- petugas_home_screen_new.dart
- petugas_input_hasil_screen.dart
- petugas_navigation_screen.dart ✅ (DONE)
- petugas_notification_screen.dart
- petugas_pickup_process_screen.dart
- petugas_profile_screen.dart
- petugas_statistics_screen.dart
- petugas_task_detail_screen.dart
- petugas_task_list_screen.dart

#### Pattern 1B: Container backgroundColor (light backgrounds)
```dart
// BEFORE
backgroundColor: const Color(0xFFF1F5F9),
border: Border.all(color: const Color(0xFFF1F5F9)),

// AFTER
backgroundColor: Theme.of(context).colorScheme.surface,
border: Border.all(color: Theme.of(context).dividerColor),
```

---

### **GROUP 2: User Screens (12 files)**

#### Pattern 2A: No explicit background (uses default)
**Files:**
- home_screen.dart
- history_screen.dart
- profile_screen.dart
- request_pickup_screen.dart
- scan_waste_screen.dart
- statistics_screen.dart
- tracking_screen.dart
- guide_screen.dart

**Action:** ✅ Already using theme defaults via Scaffold

#### Pattern 2B: Inline status colors (need mapping)
```dart
// BEFORE
color: const Color(0xFF2196F3),  // Blue (pending)
color: const Color(0xFFFF9800),  // Orange (in_progress)
color: const Color(0xFF9C27B0),  // Purple (arrived)
color: const Color(0xFF4CAF50),  // Green (completed)
color: const Color(0xFFE91E63),  // Pink (rejected)

// AFTER
color: ThemeColors.getStatusInProgressColor(context),  // Blue
color: ThemeColors.getStatusPendingColor(context),     // Orange
color: ThemeColors.getStatusArrivedColor(context),     // Purple
color: ThemeColors.getStatusCompletedColor(context),   // Green
color: ThemeColors.getStatusRejectedColor(context),    // Pink
```

**Files with this pattern:**
- user/request_pickup_screen.dart (5 colors)
- user/history_screen.dart (4 colors)
- user/tracking_screen.dart (5 colors)
- user/scan_waste_screen.dart (4 colors)
- petugas/statistics_screen.dart (custom colors)

---

### **GROUP 3: Auth Screens (8 files)**

#### Pattern 3A: Container backgroundColor
```dart
// BEFORE
color: const Color(0xFFF8FAFC),
color: const Color(0xFFF1F5F9),

// AFTER
color: Theme.of(context).colorScheme.surface,
```

**Files:**
- auth/login_screen.dart
- auth/register_screen.dart
- auth/forgot_password_screen.dart
- auth/forgot_password_verify_screen.dart
- auth/forgot_password_reset_screen.dart
- auth/email_verification_screen.dart
- auth/onboarding_screen.dart

#### Pattern 3B: Border colors
```dart
// BEFORE
border: Border.all(color: const Color(0xFFE2E8F0)),

// AFTER
border: Border.all(color: Theme.of(context).dividerColor),
```

---

## 🔧 Quick Refactoring Commands (Manual)

### For Petugas Screens:
1. Find: `backgroundColor: const Color(0xFFF1F5F9),`
2. Replace with: `backgroundColor: Theme.of(context).scaffoldBackgroundColor,`

### For Auth Screens:
1. Find: `color: const Color(0xFFF8FAFC),`
2. Replace with: `color: Theme.of(context).scaffoldBackgroundColor,`

### For Status Colors (User/Petugas):
Import at top:
```dart
import '../../utils/theme_colors.dart';
```

Then replace:
```dart
color: const Color(0xFF2196F3),  →  color: ThemeColors.getStatusInProgressColor(context),
color: const Color(0xFFFF9800),  →  color: ThemeColors.getStatusPendingColor(context),
color: const Color(0xFF9C27B0),  →  color: ThemeColors.getStatusArrivedColor(context),
color: const Color(0xFF4CAF50),  →  color: ThemeColors.getStatusCompletedColor(context),
color: const Color(0xFFE91E63),  →  color: ThemeColors.getStatusRejectedColor(context),
```

---

## 📊 Refactoring Summary

| Category | Total | Done | % | Effort |
|----------|-------|------|---|--------|
| Admin | 13 | 13 | 100% | ✅ |
| Petugas | 14 | 1 | 7% | Medium |
| User | 12 | 0 | 0% | Low |
| Auth | 8 | 0 | 0% | Medium |
| **TOTAL** | **47** | **14** | **30%** | **Ongoing** |

---

## 🎯 Implementation Strategy

### **Phase 1: High-Impact Replacements** ✅ DONE
- Admin screens background colors (13 files) → **100% complete**

### **Phase 2: Status Color Mapping** (NEXT)
- Petugas & User status badges
- Files: 5-7 with multiple status colors
- Estimated: 30 mins

### **Phase 3: Text & Border Colors** 
- Auth screens
- Petugas border colors
- Estimated: 20 mins

### **Phase 4: Validation & Testing**
- Visual verification in light/dark modes
- Check contrast ratios
- Estimated: 15 mins

---

## 💡 Pro Tips

### ✅ DO:
```dart
// Good: Use Theme.of(context)
backgroundColor: Theme.of(context).scaffoldBackgroundColor,

// Good: Use ThemeColors for status
color: ThemeColors.getStatusCompletedColor(context),

// Good: Use colorScheme for consistent theming
border: Border.all(color: Theme.of(context).dividerColor),
```

### ❌ DON'T:
```dart
// Bad: Hard-code colors
backgroundColor: const Color(0xFFF8FAFC),

// Bad: Mix hard-code and theme
color: const Color(0xFF4CAF50), // Should use ThemeColors
```

---

## 🔍 Verification Checklist

After refactoring each screen:

- [ ] Screen renders in light mode
- [ ] Screen renders in dark mode
- [ ] Text is readable in both modes
- [ ] Buttons are clickable and visible
- [ ] Icons are visible
- [ ] Dividers/borders are visible
- [ ] Status badges show correct colors
- [ ] No hard-coded colors remain

---

## 📝 Next Steps

**Option 1: Continue Auto-Refactoring**
- Systematically refactor remaining 33 screens
- Use batch operations for similar patterns
- Estimate: 1-2 hours

**Option 2: Manual Refactoring**
- Developers refactor their own screens
- Use guide above for patterns
- Estimate: 3-4 hours distributed

**Option 3: Hybrid Approach** (Recommended)
- Priority screens now (Petugas, high-traffic User screens)
- Others gradually during development
- Continuous validation during QA

---

## 📚 References

- [THEME_USAGE_GUIDE.md](./THEME_USAGE_GUIDE.md) - Complete usage guide
- [THEME_REFACTORING_EXAMPLES.dart](./THEME_REFACTORING_EXAMPLES.dart) - Code examples
- [theme_colors.dart](./lib/utils/theme_colors.dart) - Utility class
- [theme_provider.dart](./lib/utils/theme_provider.dart) - Theme definitions
