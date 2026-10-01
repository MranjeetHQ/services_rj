# QA report: caching, encryption, AppController and permissions

Date: 2026-09-25
Scope: the API cache, AES encryption of stored data, `AppController` feature switches, and the permission layer.

## Result

All flaws found were fixed before completion. The suite has 79 tests, and it passed three runs in a row.

```bash
flutter analyze
flutter test
```

The analyzer reports no errors or warnings. The remaining infos are style notes in older files.

**Not verified:** nothing ran on a real device or emulator. System permission dialogs, the Android Keystore, the iOS Keychain and an iOS build were not exercised. Before release, run the manual checklist at the end of this report on one Android 13+ device, one Android 12 or lower device, and one iPhone.

## Flaws found and fixed

| ID | Severity | Area | Flaw | Fix | Test |
|---|---|---|---|---|---|
| QA-1 | High | Cache, security | A request still in flight during logout wrote the previous user's data back into the cache. The next user's identical request also joined that old request and received the previous user's data. | The cache gets a generation counter that increases on every clear. Late responses are dropped, and in-flight sharing is keyed by generation. | `qa_regression_test.dart` QA-1. It fails when the fix is removed. |
| QA-2 | Medium | Cache | Identical requests shared one network call. Cancelling one screen's request cancelled the others too. | Requests that carry their own `CancelRequest` are never shared. | QA-2 |
| QA-3 | Low | Cache | A failed read deleted the file by name, and could delete a newer file written at the same moment. | The delete goes through the write queue and only runs if the file is unchanged. | Code review. The timing is not reproducible in a unit test. |
| QA-4 | High | Network (existing code) | `202` and `204` responses were treated as errors. A plain-text error body crashed the error handler with a type error. | Every 2xx is a success. The message is read only from JSON object bodies. | QA-4, two tests |
| QA-5 | Medium | Permissions | If Settings opened without the app going to the background, for example in iPad split view, `ensure()` waited up to 5 minutes. Every other permission request waited behind it. | The flow continues if the app has not left the foreground within 3 seconds. | QA-5 |
| QA-6 | High | Encryption | After an Android backup restore, the stored key can be unreadable. Reading it threw, and app start-up failed. | An unreadable key is replaced with a new one. Old encrypted values then read as `null`, and cached responses are fetched again. | QA-6 |
| QA-7 | Low | Encryption | Two concurrent `initialize()` calls could each create a key. The second key overwrote the first, and data written with the first became unreadable. | Concurrent calls share one load. | QA-7 |
| QA-8 | Low | Encryption | `wipeAllData(destroyEncryptionKey: true)` dropped a custom key provider and switched to the keystore key. | The provider is remembered. | QA-8 |
| QA-9 | Low | Controller | Enabling the cache at runtime ignored the `CacheConfig` passed to `initialize()`. | The controller stores the config. | QA-9 |
| QA-10 | Critical | Cache | The QA-1 fix introduced a future that waited on itself, so every cached request hung. The test suite caught it. | The cleanup callback no longer returns the future. | The whole cache suite |
| QA-11 | High | Permissions | On Android, "don't ask again" made `ensure()` fail silently with no way forward, because the branch for it could never run. | The flow detects a denial that returned without a dialog and offers Settings. | `permissions_test.dart`, two ensure tests |
| QA-12 | Medium | Network (existing code) | The exception handler crashed on its own `ApiException` because it read a `response` field that does not exist. | `ApiException` passes through unchanged. | Covered by the fallback tests |
| QA-13 | Low | Docs | The generated permission table showed some native names in snake_case and hid Android version ranges, such as motion needing nothing before Android 10. | The table groups by API range and uses Dart names. | Docs sync test |
| QA-14 | Medium | Package (existing code) | Networking, cache and button classes were not exported, so the README example did not compile for package users. | All public classes are exported from `services_rj.dart`. | Every test imports only the public library |

## Known limitations

These are design decisions. They are documented rather than changed.

- **Account switching without logout.** Cached data is shared unless you set `ApiCacheManager.instance.scope` to the user id after login. `logout()` always clears the cache.
- **Turning encryption off after release.** Existing encrypted values read as `null`, and cached responses are fetched again. Keep encryption on once it has shipped.
- **Android Auto Backup.** Exclude the shared preferences file and the `services_rj_api_cache` folder from backup. A restored copy cannot be decrypted on a new device, see QA-6.
- **Captive portals.** The connectivity feature can report "online" behind a Wi-Fi login page. Requests then fail normally and fall back to the cache.
- **Web.** The cache is memory only on web.
- **Callbacks inside `ensure()`.** Calling `request()` or `ensure()` from a prompt callback deadlocks, because requests are queued. This is documented in the method and in `docs/permissions.md`.
- **Existing code not reviewed.** The `AuthInterceptor` token refresh still retries with a new `Dio()`. That loses the base URL and timeouts. It is outside this change.

## Manual device checklist

- [ ] Android 13+: camera, photos with "select photos", notifications, and "don't ask again" leading to Settings and back.
- [ ] Android 12 or lower: photos uses storage, and notifications are not applicable.
- [ ] Android 11+: background location goes through the settings page.
- [ ] iOS: first denial becomes permanently denied, and the Settings round trip re-checks the status.
- [ ] iOS: an unused permission compiled out reports denied, as expected.
- [ ] Airplane mode: cached screens load instantly and show stale data.
- [ ] Kill and relaunch offline: the first screen shows cached data without a spinner.
- [ ] Logout, then log in as another user: no data from the first user appears.
- [ ] Reinstall the app: the old key is gone, and the app starts and fetches fresh data.
