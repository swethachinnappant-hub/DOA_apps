import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pushes [location] when a router is available.
///
/// Shell widgets are pumped directly in widget tests (and can be embedded
/// without a router), so navigation degrades to a no-op instead of throwing.
void navTo(BuildContext context, String location) {
  final router = GoRouter.maybeOf(context);
  if (router == null) return;
  router.push(location);
}

/// Same as [navTo] but replaces the stack (used for "back to home" style hops).
void navGo(BuildContext context, String location) {
  final router = GoRouter.maybeOf(context);
  if (router == null) return;
  router.go(location);
}
