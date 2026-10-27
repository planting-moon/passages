# Android Release Credentials

How to create the upload keystore and GitHub Actions secrets needed to produce a signed release AAB for Passages (app name: Hallways).

## Key concepts

- **Upload keystore**: the key you create and use to sign AABs before uploading them to Google Play. This credential GitHub Actions needs.
- **App signing key**: the key Google Play uses to sign the app delivered to users. If you choose **Google-managed app signing**, Google creates and stores this key for you.
- **Debug keystore**: for local testing only. Never use it for a Play Store release.
- **Service account JSON**: only needed if you want GitHub Actions to upload to Play automatically. Not needed for a manual upload.

## How the four secrets map to the keystore

`keytool -genkeypair` creates **one keystore file containing one private key and its certificate**. That single file is the source of all four GitHub secrets:

| Secret | Where it comes from |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | The keystore file, encoded as Base64 |
| `ANDROID_KEYSTORE_PASSWORD` | The keystore password you type into `keytool` |
| `ANDROID_KEY_ALIAS` | The `-alias` value you pass to `keytool` |
| `ANDROID_KEY_PASSWORD` | The key password you type into `keytool` |

So you do **not** create four separate keys. The only separate keys are:

- **Google Play app signing key** — created by Google when you enable Google-managed app signing. You never see or store it.
- **Debug keystore** — created separately for local/CI debug builds. Never used for Play.

The freesurf repos already use per-repository Actions secrets with these four names. Passages does not have them yet; they must be added to `planting-moon/passages`.

## 1. Create the upload keystore

Use JDK 17's `keytool`. Run this on your local machine.

> If you still have the existing freesurf release keystore (for example
> `%USERPROFILE%\secure-keys\freesurf\release.keystore`) and its password, you can
> reuse it instead of creating another one. List its alias first with
> `keytool -list -keystore <path>` (it prompts for the password). A dedicated
> Passages/Hallways keystore is cleaner, but reusing an upload keystore is allowed.

```powershell
keytool `
  -genkeypair -v `
  -keystore "C:\Users\<you>\secure-keys\hallways-upload.keystore" `
  -alias hallways `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -storetype PKCS12
```

It will prompt for:

- keystore password
- key password
- name/organization details

Use a strong password. For PKCS12, use the **same password for the keystore and key**.

Keep the keystore and password in a password manager and an encrypted backup. Never commit the keystore to the repository.

Verify the keystore:

```powershell
keytool -list -v `
  -keystore "C:\Users\<you>\secure-keys\hallways-upload.keystore" `
  -alias hallways
```

## 2. Add GitHub Actions secrets

Open the repository's Actions secrets page:

`https://github.com/planting-moon/passages/settings/secrets/actions`

Add these repository secrets (repo-level, not shared with the other freesurf apps):

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded contents of the keystore file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | The `-alias` value (`hallways` for a new keystore; check a reused keystore with `keytool -list`) |
| `ANDROID_KEY_PASSWORD` | Key password |

### Generate the base64 value

On Windows:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("C:\Users\<you>\secure-keys\hallways-upload.keystore")
) | Set-Clipboard
```

Paste the result into `ANDROID_KEYSTORE_BASE64`.

Do not paste the keystore, base64, or passwords into source files, issues, or chat.

### Using GitHub CLI

```powershell
gh secret set ANDROID_KEYSTORE_BASE64 --repo planting-moon/passages
gh secret set ANDROID_KEYSTORE_PASSWORD --repo planting-moon/passages
gh secret set ANDROID_KEY_ALIAS --repo planting-moon/passages
gh secret set ANDROID_KEY_PASSWORD --repo planting-moon/passages
```

`gh` prompts for each value so it does not appear in shell history.

## 3. What the GitHub Actions workflow does

The workflow is `.github/workflows/build-android.yml`. It is Godot-specific, not Expo/EAS. Trigger it manually from **Actions > Build Android > Run workflow** and provide:

- `version_code` — must increase for every Play upload (`1`, `2`, `3`, ...).
- `version_name` — the user-facing version (`0.1.0`, `0.1.1`, ...).

The workflow:

1. Installs JDK 17, Android SDK platform 36, build-tools 36.1.0, NDK 29.0.14206865, and CMake.
2. Installs Godot 4.7.2 and its Android export templates (templates and Gradle are cached between runs).
3. Writes Godot editor settings pointing at the runner's Android SDK and Java paths.
4. Copies the CI-only preset from `.github/godot/export_presets.ci.cfg` to `export_presets.cfg` and injects the requested version code/name.
5. Decodes `ANDROID_KEYSTORE_BASE64` into a temporary keystore and verifies the alias.
6. Installs the Android build template and exports a release AAB:

   ```bash
   godot --headless --path . \
     --install-android-build-template \
     --export-release "Android Hallways" build/Hallways.aab
   ```

7. Verifies the AAB is signed and uploads `build/Hallways.aab` as the `hallways-aab-<version_code>` artifact.
8. Builds an arm64-v8a native debug symbols zip from Godot's official symbols and uploads it as the `hallways-native-debug-symbols-<version_code>` artifact.

Signing is passed to Godot with environment variables, not stored in the preset:

- `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`
- `GODOT_ANDROID_KEYSTORE_RELEASE_USER`
- `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`

The keystore only exists temporarily on the runner and is never committed. The root
`export_presets.cfg` stays git-ignored because the Godot editor can write the keystore
password into it; CI uses the sanitized copy under `.github/godot/`.

## 4. Google Play signing

When creating the app in Play Console:

1. Choose **Use Google-managed app signing**.
2. Upload the AAB signed with the upload keystore.
3. Keep the upload keystore and password backed up.

If the upload key is lost, you can request an upload key reset through Play Console. If you opt out of Google-managed signing and manage the app signing key yourself, losing it can prevent future updates.

## 5. Optional: automated Play upload

Manual MVP flow: download the AAB from the GitHub Actions run and upload it in Play Console.

Automated flow requires a Google Cloud service account:

1. Enable the Google Play Developer API.
2. Create a service account and JSON key.
3. Invite the service account email in Play Console with release permissions.
4. Store the JSON as a repository secret, for example `PLAY_SERVICE_ACCOUNT_JSON`.
5. Have the workflow use a Play publishing action to upload to the internal testing track.

This is a separate credential from the upload keystore.

## 6. Security checklist

- [ ] Upload keystore stored outside the repository
- [ ] Password stored in a password manager
- [ ] Encrypted offline backup of the keystore and password
- [ ] Keystore never committed to Git
- [ ] Base64 value stored only as a GitHub secret
- [ ] Passwords never pasted into docs, issues, or chat
- [ ] Release builds signed with the upload key, not the debug key
- [ ] Google-managed app signing enabled in Play Console

## 7. Play Console warnings

When a release is uploaded, Play may show two warnings:

- **No deobfuscation file.** This is expected for Hallways. Godot's Android Gradle template
  ships with R8/minification disabled to avoid breaking its JNI bindings, so no
  `mapping.txt` is generated. Do not enable R8 just to clear this warning; there is nothing
  to deobfuscate, and enabling it can break the Godot runtime.
- **No native debug symbols.** The AAB contains Godot's native libraries. Download the
  `hallways-native-debug-symbols-<version_code>` artifact from the same workflow run and
  upload it in Play Console under the release's **Native debug symbols** section. This makes
  native crash traces readable. The symbols come from
  `Godot_native_debug_symbols.<version>.template_release.android.zip` and only the
  `arm64-v8a` folder is packaged (the ABI used by this app).
