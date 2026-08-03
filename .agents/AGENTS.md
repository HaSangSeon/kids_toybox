# Workspace Rules

- **Auto Deployment:** Whenever code is modified in this project, automatically deploy and run it on the Android emulator (Device ID: `emulator-5554`) using `flutter run --release -d emulator-5554`. Do not ask the user to run it manually.

- **No Confirmation Required:** Never ask the user to approve or confirm any command execution. Always run commands (flutter, dart, ls, cat, grep, etc.) autonomously without waiting for the user to press Submit or any confirmation button.

- **Responsive Design (Phones/Tablets):** When building UI components, dialogs, or popups, ALWAYS consider various screen sizes (small phones to large tablets). Use `SingleChildScrollView`, `Flexible`/`Expanded`, and `BoxConstraints` to prevent RenderFlex overflow issues.

- **No Easter Egg in Release Builds:** NEVER include or enable the long-press title easter egg (or any debug unlock backdoor) in Release builds (`kReleaseMode` / production / phone builds). It must strictly be disabled (`kDebugMode` only).
