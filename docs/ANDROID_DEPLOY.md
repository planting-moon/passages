# Android testing workflow


## Desktop first
- Open the project in Godot and press F5.
Deploy to an Android device
1. Install Godot’s Android export templates: Editor → Manage Export Templates.
2. Configure Editor Settings → Export → Android with your Android SDK path and debug keystore.
3. Enable Developer options + USB debugging on the phone, plug it in, and confirm adb devices sees it.
4. In Godot: Project → Export → Add → Android, set the package name (e.g. tools.freesurf.passages) and orientation.
5. Use the Android one-click deploy button in the editor, or export a debug APK and adb install -r Hallways.apk.

## Play testing
- Create the app in Play Console.
- Upload a release AAB to Internal testing, add yourself/testers, and install from the Play testing link.
- Once it feels right, promote to closed/open testing.

## Get it onto your phone
1. Install export templates
- Open Godot 4.7.2
- Editor → Manage Export Templates → Download and Install
- This is a one-time ~1.3 GB download.
2. Configure Android paths
- Editor → Editor Settings → Export → Android
- Android SDK Path: <Android SDK path>
- Java SDK Path: <Java SDK path>
- Debug Keystore: <debug keystore path>
- Debug Keystore User: androiddebugkey
- Debug Keystore Pass: <standard debug keystore password>
3. Install the Android build template
- Project → Install Android Build Template
- Accept/download if prompted. This is needed for one-click deploy.
4. Create the Android export preset
- Project → Export → Add → Android
- Package unique name: tools.freesurf.passages
- Package name: Hallways
- Version code: 1
- Version name: 0.1.0
- Orientation: Portrait
- Use the debug keystore above for testing.
5. Enable USB debugging on your phone
- Settings → About phone → tap Build number 7 times
- Developer options → enable USB debugging
- Connect USB, choose File Transfer, and allow the RSA prompt.
6. Verify the phone is visible
Run this in PowerShell:
& "<Android SDK path>\platform-tools\adb.exe" devices
You want to see your phone listed as device.
7. Deploy
- In Godot, click the Android one-click deploy button next to Play.
- Or Project → Export → Android → Export Project and install the APK.
If USB gives you 