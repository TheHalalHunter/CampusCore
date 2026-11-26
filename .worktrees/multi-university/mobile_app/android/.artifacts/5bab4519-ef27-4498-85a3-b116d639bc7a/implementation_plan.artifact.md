# Fix Build Failures and Upgrade Dependencies

This plan addresses the missing dependency files and upgrades the Android Gradle Plugin (AGP) and Kotlin versions to meet Flutter's modern requirements.

## User Review Required

> [!IMPORTANT]
> **Missing File:** You MUST manually add the `google-services.json` file to the `app/` directory. I cannot generate this file as it is specific to your Firebase project.

## Proposed Changes

### Android Build Configuration

#### [MODIFY] [settings.gradle](file:///C:/Users/USER/Documents/CampusCoreNew/mobile_app/android/settings.gradle)
- Upgrade `com.android.application` to `9.0.1`.
- Upgrade `org.jetbrains.kotlin.android` to `2.3.20`.

#### [MODIFY] [app/build.gradle](file:///C:/Users/USER/Documents/CampusCoreNew/mobile_app/android/app/build.gradle)
- Update `kotlin-stdlib` dependency to `2.3.20`.

## Verification Plan

### Manual Verification
1. Place the `google-services.json` file in `android/app/`.
2. Run `./gradlew assembleDebug` to verify the build.
