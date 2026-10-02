import 'package:flutter/material.dart';

import '../widgets/demo_widgets.dart';
import 'network/api_playground_page.dart';
import 'network/auth_interceptors_page.dart';
import 'network/cache_lab_page.dart';
import 'network/permission_setup_page.dart';
import 'network/permissions_page.dart';

export 'network/network_common.dart' show demoNetworkEvents;

/// Demos for networking, caching, auth and permissions.
final List<DemoEntry> networkDemos = [
  DemoEntry(
    icon: Icons.api,
    title: 'API playground',
    subtitle: 'GET to DELETE, errors, cancel, timeouts, upload and download',
    builder: (_) => const ApiPlaygroundPage(),
  ),
  DemoEntry(
    icon: Icons.cached,
    title: 'Cache lab',
    subtitle: 'Every CachePolicy side by side, watch, peek and CacheConfig',
    builder: (_) => const CacheLabPage(),
  ),
  DemoEntry(
    icon: Icons.vpn_key,
    title: 'Auth and interceptors',
    subtitle: 'Token storage, header injection, custom interceptors, callbacks',
    builder: (_) => const AuthInterceptorsPage(),
  ),
  DemoEntry(
    icon: Icons.verified_user,
    title: 'Permissions',
    subtitle: 'All 21 permission tags with live status, ensure and settings',
    builder: (_) => const PermissionsPage(),
  ),
  DemoEntry(
    icon: Icons.build_circle,
    title: 'Permission setup generator',
    subtitle: 'AndroidManifest, Info.plist and Podfile snippets to copy',
    builder: (_) => const PermissionSetupPage(),
  ),
];
