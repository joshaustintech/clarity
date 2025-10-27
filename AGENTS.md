# Repository Guidelines

## Overview
Clarity is an iOS SwiftUI app that persists data with Swift Data and verifies functionality through Swift Testing plus XCTest. The architecture is declarative: composable SwiftUI scenes, native state wrappers, and `async`/`await`, all aligned with Apple’s Human Interface Guidelines for clarity, deference, depth, and accessibility. **This project prohibits usage of UIKit and Combine. Use only SwiftUI, Swift Data, and native Swift concurrency/state APIs.**

## Project Setup Steps
1. Install Xcode 15.4+ with the latest iOS simulator set, then open `Clarity.xcodeproj` to resolve packages and schemes.
2. In the app target’s *Signing & Capabilities*, add the *Data* capability for Swift Data and register any needed entitlements up front.
3. Configure the shared `ModelContainer` in `ClarityApp.swift`, inject it into the root scene via `.modelContainer(_:)`, and reuse that helper inside previews.
4. Run once on a simulator to materialize the store, then create preview/sample fixtures under `/Data/Seeds` for consistent design-time data.

## Recommended Structure
- `/Models`: `@Model` entities and lightweight domain types.
- `/Data`: container setup, migrations, repositories, seeds.
- `/Views`: feature folders with screens, subviews, modifiers.
- `/ViewModels`: optional observable orchestrators for complex flows.
- `/Resources`: assets, localization, symbol catalogs.
- `/Tests`: Swift Testing suites for models and data services.
- `/UITests`: XCTest UI flows and accessibility assertions.
- `/Tooling`: SwiftLint configs, scripts, CI workflows.

## Naming & Style
Follow Swift API Design Guidelines: `UpperCamelCase` types, `lowerCamelCase` members, verbs for mutating functions. Limit each file to one primary type and keep view bodies under ~200 lines by extracting helpers. Adopt SwiftLint with a committed `.swiftlint.yml` enabling whitespace, identifier length, and unused declaration rules, and run `swiftlint` before commits. Use four-space indentation, align modifiers, format code with `swift-format` or Xcode re-indent. Write conventional commits (`feat:`, `fix:`, `chore:`) with subjects under 72 characters.

## UI Structure Guidance
Compose views hierarchically with `NavigationStack`, `List`, and other system components. Manage local value state with `@State`, reference-bound models with `@StateObject`, and share dependencies via `@EnvironmentObject` or `@Environment(\.modelContext)`. Trigger side effects through lifecycle modifiers (`task`, `.onAppear`) inside `@MainActor` async functions, avoiding work in the `body`. Prefer modifiers and composition over imperative configuration, and use previews to validate layouts across sizes.

## Persistence with Swift Data
Model data with the `@Model` macro, keeping properties value-oriented and annotating uniqueness where needed. Expose repositories that accept a `ModelContext`, centralizing fetch descriptors and migrations in `/Data`. In views, use `@Query` for live collections or fetch on demand with `try context.fetch(_:)`; persist via `context.insert` and `try context.save()`. For previews and tests, spin up in-memory containers with `ModelConfiguration(isStoredInMemoryOnly: true)` to keep runs isolated.

## Testing Strategy
Organize unit and integration coverage with Swift Testing suites under `/Tests/<Feature>Tests`, grouping scenarios with `@Suite` and shared fixtures. Fall back to XCTest APIs for expectations or failure annotations as needed. Treat repositories and formatters as unit-testable with in-memory containers and deterministic seeds. UI automation lives in `/UITests`, driving `XCUIApplication` to validate navigation, accessibility labels, and color-scheme resilience. Target ≥80 % statement coverage on models and data layers, and gate merges on a passing `xcodebuild test`.

## Feature Example Flow
Anchor early development around a “Tasks” experience: `TaskListView` reads `@Query(sort: \Task.createdAt, order: .reverse)` and sections items by status. Selecting a row opens `TaskDetailView` with description, due date, and completion toggle; Edit pushes `TaskEditorView`, binds form fields to a draft copy, validates, and commits via `try context.save()`. Mirror the flow in `TaskFlowUITests.swift`: add a task, confirm ordering, navigate to detail, edit, and assert persistence across relaunch.

## Running the App & Tests
```bash
xcodebuild -project Clarity.xcodeproj -scheme Clarity -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild -project Clarity.xcodeproj -scheme Clarity -destination 'platform=iOS Simulator,name=iPhone 15' test
```
Swap the simulator name as needed. Disable parallel testing (`-parallel-testing-enabled NO`) when investigating async races. In CI (Xcode Cloud, GitHub Actions), cache DerivedData, export test logs, and fail on warnings via `OTHER_SWIFT_FLAGS="-warnings-as-errors"`.

## Optional Packages
Keep dependencies lean. Approved additions:
- `realm/SwiftLint` to enforce consistent linting.
- `pointfreeco/swift-snapshot-testing` for UI regression checks once flows stabilize.
- `apple/swift-collections` when specialized data structures are required.
Add packages through Swift Package Manager, pin exact versions, commit `Package.resolved`, and document reviews in the PR description.

## Code Review Guidelines
Work on topic branches named `feature/<topic>` or `fix/<ticket>`, rebase on `main`, and push only after tests pass. Each PR must include a summary, screenshots for visual changes, and the commands executed. Require at least one reviewer approval plus green CI before merging. Tag releases with semantic versioning: major for breaking schema, minor for features, patch for fixes.

## HIG Compliance Checklist
- Confirm dynamic type scaling, VoiceOver labels, and minimum 44 pt hit targets.
- Validate layouts in light, dark, high-contrast, and large text modes.
- Respect safe areas, split-view multitasking, and rotation.
- Prefer system components, SF Symbols, and restrained Material effects.
- Audit color contrast against WCAG 2.1 AA and keep focus indicators obvious.

### Codex CLI Build Policy
Every milestone must pass a clean command-line build before completion.
After each code generation step, Codex must:
1. Run `xcodebuild -scheme Clarity -sdk iphonesimulator configuration=Debug build`
2. Fix any compile errors or warnings automatically.
3. Confirm exit code 0 before reporting success.
