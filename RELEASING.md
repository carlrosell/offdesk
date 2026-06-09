# Releasing Offdesk

Offdesk is distributed as a signed, notarized DMG attached to a **GitHub
Release**, with in-app auto-updates powered by [Sparkle](https://sparkle-project.org).
Everything is automated: push a version tag and the
[`Release` workflow](.github/workflows/release.yml) builds, signs, notarizes,
packages, and publishes.

```
git tag v1.0.1
git push origin v1.0.1      # → builds + publishes the release
```

The rest of this document is the **one-time setup** you do before the first
release. After that, cutting a release is just the two commands above.

---

## How it works

On a `v*` tag push, the workflow:

1. Builds `Offdesk.app` in Release config and signs it with **Developer ID
   Application** + hardened runtime.
2. **Notarizes** the app with Apple and **staples** the ticket.
3. Packages a drag-to-Applications **DMG**, signs it, notarizes + staples it.
4. **EdDSA-signs** the DMG with the Sparkle private key.
5. Rebuilds the **cumulative `appcast.xml`** (downloads the previous one from the
   last release and prepends the new entry, so all versions stay listed).
6. Publishes a **GitHub Release** for the tag with the DMG and `appcast.xml`
   attached, and auto-generated release notes.

Installed copies check `appcast.xml` daily (the `SUFeedURL` in
[`Offdesk/Info.plist`](Offdesk/Info.plist) points at
`releases/latest/download/appcast.xml`, which always resolves to the newest
release) and offer the update in place. Users can also trigger a check from the
menu bar or the Info tab via **Check for Updates…**.

---

## One-time setup

You need an **Apple Developer Program** membership ($99/yr). Team ID:
`8JSX675783`.

### 1. Sparkle signing keys

From the repo root:

```sh
scripts/setup-sparkle-keys.sh
```

This generates an EdDSA keypair in your login Keychain, writes the **public**
key into `Offdesk/Info.plist` (`SUPublicEDKey`), and prints the **private** key.

- **Commit** the `Offdesk/Info.plist` change (the public key is meant to ship).
- Add the printed private key as the `SPARKLE_PRIVATE_KEY` repository secret.

> Back up the private key (or the Keychain item "Private key for signing Sparkle
> updates"). If you lose it, you can't sign updates and existing users can't
> auto-update to anything new under the same public key.

### 2. Developer ID certificate

If you don't already have a **Developer ID Application** certificate, create one
in Xcode (Settings → Accounts → Manage Certificates → ＋ → Developer ID
Application) or on the [Apple Developer site](https://developer.apple.com/account/resources/certificates/list).

Export it **with its private key** from **Keychain Access** as a `.p12` (select
the certificate *and* its key → right-click → Export → set a password), then
base64-encode it:

```sh
base64 -i DeveloperID.p12 | pbcopy   # → MACOS_CERTIFICATE
```

Secrets:

- `MACOS_CERTIFICATE` — the base64 string above
- `MACOS_CERTIFICATE_PWD` — the password you set on the `.p12`

### 3. App Store Connect API key (for notarization)

In [App Store Connect → Users and Access → Integrations → App Store Connect
API](https://appstoreconnect.apple.com/access/integrations/api), create a **Team
Key** with the **Developer** role (or higher). Download the `AuthKey_XXXXXX.p8`
(you can only download it once).

```sh
base64 -i AuthKey_XXXXXX.p8 | pbcopy   # → APPLE_API_KEY
```

Secrets:

- `APPLE_API_KEY` — the base64 of the `.p8`
- `APPLE_API_KEY_ID` — the key's **Key ID** (shown next to the key)
- `APPLE_API_ISSUER_ID` — the **Issuer ID** (shown at the top of the Keys page)

### 4. Secrets checklist

Add all of these under **Settings → Secrets and variables → Actions**:

| Secret                  | Source                                            |
|-------------------------|---------------------------------------------------|
| `SPARKLE_PRIVATE_KEY`   | `scripts/setup-sparkle-keys.sh`                   |
| `MACOS_CERTIFICATE`     | base64 of the Developer ID Application `.p12`     |
| `MACOS_CERTIFICATE_PWD` | password on that `.p12`                           |
| `APPLE_API_KEY`         | base64 of the App Store Connect `.p8`             |
| `APPLE_API_KEY_ID`      | the API key's Key ID                              |
| `APPLE_API_ISSUER_ID`   | the API key's Issuer ID                           |

---

## Cutting a release

1. Bump the marketing version. The DMG/app version comes from the **tag**
   (`v1.0.1` → version `1.0.1`), and the Sparkle build number (`CFBundleVersion`)
   is derived from it (`MAJOR×1000000 + MINOR×1000 + PATCH`) so it always
   increases in step with the version. You don't have to edit `MARKETING_VERSION`
   in the project — the workflow injects it from the tag — but keeping it in sync
   is tidy.

   Tag the **tip of `main`** so release order matches version order. Sparkle
   compares only `CFBundleVersion` and never downgrades, so a tag placed on an
   older commit (e.g. a backport) ships with a lower build number and won't be
   offered to users already on a newer version — which is the intended behavior,
   but worth knowing.
2. Commit any changes, then tag and push:

   ```sh
   git tag v1.0.1
   git push origin v1.0.1
   ```

3. Watch the **Release** workflow in the Actions tab. When it's green, the
   release is live with the DMG attached, and existing users will be offered the
   update within a day.

Tags must look like `v1.2` or `v1.2.3`. Pushing a tag that already has a release
will fail at the publish step — delete the release/tag first if you're redoing
one.

---

## Troubleshooting

- **"No 'Developer ID Application' identity found"** — `MACOS_CERTIFICATE` is the
  wrong cert (e.g. an *Apple Development* cert) or was exported without its
  private key. Re-export the Developer ID Application cert *with* its key.
- **Notarization fails** — the `notarytool submit --wait` output includes a
  submission ID. Run `xcrun notarytool log <id> --key … --key-id … --issuer …`
  locally to see exactly which binary was rejected (usually a missing hardened
  runtime or timestamp on a nested helper).
- **Updates not detected** — confirm the published `appcast.xml` lists the new
  `sparkle:version` and that it's larger than the installed build, and that
  `SUPublicEDKey` in the shipped app matches the key that signed the DMG.
- **Placeholder guard tripped** — you tagged before running
  `scripts/setup-sparkle-keys.sh`. Run it, commit `Info.plist`, re-tag.
