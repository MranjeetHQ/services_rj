# AppController, caching and encryption

## AppController

`AppController` is the single switchboard for the package. Features are off by default; enable only what the app uses:

```dart
await AppController.initialize(
  features: const AppFeatures(sharedPref: true, theme: true),
);
```

Pass `themeConfig: AppThemeConfig(...)` to style the app; `ServicesApp` (or `AppThemeController.instance.lightTheme` / `darkTheme`) applies it. It applies even with the `theme` feature off; that feature adds the `app.theme` accessor. To start everything in one call, with error handlers, orientation and your own setup, use `AppSetup.run` (see the README or [FEATURES.md](../FEATURES.md)).

Networking is optional. Add `network: true` and an `ApiConfig` only when making API requests; without a config the network feature stays unready and other enabled features continue initializing.

| Feature | What it controls | Can change at runtime |
|---|---|---|
| `sharedPref` | `SharedPrefManager` | no |
| `theme` | `AppThemeController`. Without `sharedPref`, the theme works but is not saved. | no |
| `network` | `DioService`, `ApiClient`. Needs `apiConfig`, otherwise it is skipped with a warning. | no |
| `apiCache` | Response cache. Needs `network`. | yes |
| `encryption` | AES-256-GCM for preferences and the cache | no |
| `connectivity` | Online and offline tracking | yes |
| `logger` | `AppLogger` output | yes |
| `networkLogs` | Request and response logging | yes |
| `permissions` | `AppPermissionManager` | yes |

```dart
final app = AppController.instance;
app.isEnabled(AppFeature.apiCache);  // switched on?
app.isReady(AppFeature.apiCache);    // switched on and started?
await app.setEnabled(AppFeature.logger, false);

app.api;          // ApiClient
app.cache;        // ApiCacheManager
app.theme;        // AppThemeController
app.permissions;  // AppPermissionManager
app.encryption;   // AppEncryption
app.auth;         // AuthTokenService
```

An accessor for a feature that is off throws a `StateError`, so a misconfiguration shows up at once. `AppController` is a `ChangeNotifier`, so widgets can rebuild when a feature changes.

`AppInitializer.initialize(...)` still works. It forwards to `AppController`.

## Caching

GET responses are cached in memory and on disk. The default policy is **stale-while-revalidate**. Once a screen has loaded, it never waits for the network again. Cached data is returned instantly and refreshed in the background.

| Policy | Behaviour |
|---|---|
| `staleWhileRevalidate` (default) | Return cached data at once, even if expired, and refresh it in the background. Fetch only when nothing is cached. |
| `cacheFirst` | Use fresh cache without the network. Fetch when expired, and fall back to the expired copy on failure. |
| `networkFirst` | Fetch first. Use the cache when offline, on timeout or on 5xx. |
| `cacheOnly` | Cache or an error. |
| `networkOnly` | No cache. |

```dart
// Default policy
final res = await ApiClient.instance.request(
  ApiRequest(
    endpoint: '/products',
    method: ApiMethod.get,
    onRevalidated: (fresh) => setState(() => products = fresh.data),
  ),
);
res.isFromCache; res.isStale; res.cachedAt;

// Show cached data first, then fresh data
StreamBuilder(
  initialData: ApiClient.instance.peek(request), // synchronous, first frame
  stream: ApiClient.instance.watch(request),
  builder: ...,
);

// After a change on the server
ApiRequest(endpoint: '/products', method: ApiMethod.post, body: {...},
    invalidateCache: ['/products']);
```

**Why there is no lag:**

- The newest entries are loaded into memory during `initialize()`, so the first frame can read them synchronously with `peek()`.
- Identical requests made at the same time share one network call.
- When the device is known to be offline, cached data is returned without waiting for a timeout.
- Disk writes run in the background and never delay a response.

**Per-user data.** Set `ApiCacheManager.instance.scope = userId` after login. `AppController.instance.logout()` clears the token and the cache.

**Limits.** `CacheConfig` sets how long data stays fresh with `defaultTtl`, how long stale data may be served with `maxStale`, the number of entries kept in memory, and the disk size limit.

## Encryption

When `encryption` is on:

- A random 256-bit key is created on first launch. It is stored in the iOS Keychain or the Android Keystore, never in SharedPreferences or files.
- Every `SharedPrefManager` value, including the auth token and theme mode, is stored as AES-256-GCM ciphertext. Reads and writes keep the same API and the original types.
- Cache files are encrypted, and their names are SHA-256 hashes, so URLs are not visible on disk.
- Tampered data fails authentication and is discarded, never trusted.
- Values stored before encryption was turned on still read. Convert them with `SharedPrefManager.migrateToEncrypted()`.
- If the key cannot be read, for example after a backup restore, a new key is created and old data reads as empty.

To use your own key source, such as a server-provided key:

```dart
await AppController.initialize(
  encryptionKeyProvider: () async => myKeyBytes, // exactly 32 bytes
);
```

`AppController.instance.wipeAllData(destroyEncryptionKey: true)` deletes preferences, the cache and the key.

**Recommended Android setting.** Exclude app data from Auto Backup, because a restored copy cannot be decrypted:

```xml
<application android:allowBackup="false" ...>
```
