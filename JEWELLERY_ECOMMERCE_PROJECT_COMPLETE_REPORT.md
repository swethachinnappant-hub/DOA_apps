# Jewellery E-Commerce (B2B) — Complete Project Report

**Repo:** `DOA_apps-master\`
**Primary app:** `ecommerce_app\` (Flutter, 42 files / 13,288 lines in `lib\`)
**Design system:** `common_widgets\` (local package, 15 files / 4,233 lines)
**Tests:** 19 files / ~2,665 lines (149 pass, 2 stale failures — see §10)
**Spec:** `jewellery-b2b-premium-flutter-phase-1.md` (2,001-line Phase-1 MVP spec)
**Also in repo (not part of this app):** `account_app\` (accounting/OCR app), Chirag Associates OCR/AI planning docs.

---

## 1. What this project is

A **private B2B jewellery wholesale ordering platform** — Manufacturer/Wholesaler → approved jewellery retail shop owners. Per the Phase-1 spec it must feel like a *private trade showroom*, not a public marketplace: luxury, minimal, secure (screenshot protection, watermarking, price hiding, no WhatsApp enquiry).

**Current state = premium offline MVP (Phase-1 front-end foundation):**
- No backend yet. Catalogue is seeded locally (`lib\core\demo_catalog.dart`, 18 bundled jewellery photos), mutated by an in-memory store, persisted with `shared_preferences`.
- Auth is demo OTP (`123456`) with session restore. Backend (Node/Express + MongoDB), payment gateway, admin approval flow are **specified but not built** (spec §45–§50).
- Two roles: **customer/retailer** (`/app`) and **owner/seller** (`/owner`), switchable at login.

---

## 2. File map — what we manage

```
ecommerce_app/
├── lib/main.dart                     # providers + router + screenshot protection init
├── lib/core/
│   ├── business_config.dart          # 8 business types, rules matrix, 20 brand palettes, jewellery fields (699 lines)
│   ├── demo_catalog.dart             # offline seed catalogue (223)
│   ├── pricing.dart                  # GST 18%, shipping ₹79/free >₹999, Indian money format (39)
│   ├── product.dart                  # Product + ProductVariant models (164)
│   ├── models/                       # cart, order (state machine), user (roles), notification
│   ├── router/app_router.dart        # GoRouter, guards, 404 fallback (249)
│   ├── services/                     # realtime_service (event bus), screenshot_protection_service
│   └── store/commerce_store.dart     # single ChangeNotifier source of truth (506)
├── lib/features/
│   ├── main_screen.dart              # customer shell: 5-tab custom bottom bar (376)
│   ├── auth/                         # splash, login (695), register, role selector, sign-out
│   ├── config/                       # business type + brand colours + 8 business-rule toggles
│   ├── home/home_sections.dart       # hero carousel, rails, price bands (575)
│   ├── catalogue/                    # filters/sort/search/grid-list, deep links (954)
│   ├── product/                      # detail page: gallery, specs, related, buy bar (1033)
│   ├── wishlist/ cart/ checkout/     # full purchase flow (checkout = 472)
│   ├── orders/                       # order list + detail timeline + status chip
│   ├── notifications/ profile/
│   └── owner/                        # seller console: dashboard, products, product form (923), orders, shell
└── lib/widgets/product_card.dart     # card with carousel, badges, rating, wishlist (425)

common_widgets/                       # shared design-system package (path dependency)
├── lib/core/design_tokens.dart       # colours, spacing, radius, type scale, shadows, durations
├── lib/core/theme.dart               # full Material-3 component themes (390)
├── lib/core/responsive.dart          # breakpoints + responsive helpers (167)
└── lib/widgets/                      # app_bar, app_button, app_card, app_dialog, app_text_field,
                                      # app_list_tile, category_carousel, color_picker_sheet,
                                      # navigation_shell, product_image_carousel (802), skeleton
```

Assets: `ecommerce_app\assets\demo_jewellery\` — 18+ product JPG/PNG (bridal set, bangles, earrings, ring, pendant + detail shots).

---

## 3. Architecture

| Concern | Choice |
|---|---|
| State management | `provider ^6.1.2` — `AuthProvider`, `BusinessConfigProvider`, `CommerceStore` |
| Routing | `go_router ^14.8.1` with `refreshListenable` on auth + centralized `guardLocation()` |
| Data layer | In-memory `CommerceStore` + `RealtimeService` event bus, persisted via `shared_preferences` |
| Security | `no_screenshot` — FLAG_SECURE-style screen capture blocking, synced from business rules |
| Structure | Feature-first (`features/<name>/{screens,widgets,providers}`) + `core/` for domain/infra |

**Guards** (`app_router.dart:182-208`): restoring → allow; signed-out → `/login`; signed-in on auth page → role home; owner confined to `/owner` (+ shared config/profile/notifications); customer blocked from `/owner`; 404 screen with "Take me back".

**Order state machine** (`core/models/order.dart`): `placed → confirmed → packed → shipped → outForDelivery → delivered` (+ `cancelled`/`returned`), with `next`, `canTransitionTo`, colour/icon/label per status — drives both buyer timeline and seller "advance status" button.

**Realtime**: every store mutation publishes `AppEvent` (productPublished/Updated/Deleted, stockChanged, orderPlaced, orderStatusChanged) — ready to be swapped for WebSocket/API later.

---

## 4. Features

### Customer / retailer
- **Splash** (fade+scale, 1.6s → role redirect), **Login** (phone + demo OTP 123456, customer/owner selector, desktop two-pane brand layout), **Register** (name, shop, phone, email, address)
- **Onboarding config**: pick 1 of 8 business types, brand colours from 20 curated palettes (live preview), 8 business-rule toggles
- **Home**: auto-advancing hero gradient banner, quick links, category carousel, product rails with in-image auto-slide, price-band chips
- **Catalogue**: category/price/purity/stock filters, sort, grid⇄list toggle, search, deep-linkable (`/catalogue?category=&search=&min=&max=`)
- **Product detail**: gallery + thumbnail rail, breadcrumb, badges/% off, expandable details, spec rows (Gold Purity, Gross/Net/Stone Weight, Making Charge, Wastage), related rail, **Enquire with the seller / Add to Cart / Buy Now**
- **Wishlist** (store-backed, remove-all), **Cart** (steppers, clear-confirm, empty state)
- **Checkout**: 2 addresses, 4 payment methods (UPI/Card/NetBanking/COD), GST + shipping math, places real order
- **Orders**: list + `OrderStatusChip`, detail with derived timeline
- **Notifications**: typed (orderPlaced, orderStatus, outOfStock, priceChange, newArrival, sellerMessage, enquiry), mark-all-read, tap→route
- **Profile**: avatar card, sign-out dialog
- **Business rules in UI**: price hiding → "Contact for Price"; screenshot/watermark/share/download rules from config

### Owner / seller console
- **Dashboard**: open orders, low stock, revenue, pending work stat cards (FittedBox for big numbers)
- **Products**: inline stock stepper, create/edit form with dynamic spec fields driven by config, image list editor, size/shade set editors
- **Orders**: active/closed tabs, advance-status per row, order detail with buyer view + status control
- **Shell**: bottom `NavigationBar` on mobile; **labeled sidebar (232–260px) at ≥600px**

---

## 5. UI / look & feel

**Design intent** (spec §7/§59): luxury, minimal, elegant, high-end — ivory/champagne neutrals, controlled gold accents, big imagery, subtle shadows, no cheap gradients.

**Implemented:**
- **Palette** (`design_tokens.dart:57-79`): white surfaces `#FFFFFF`, muted `#F7F7F7`, text `#171717/#666666/#888888`, dividers `#E8E8E8`, success `#2D7D46`, error `#C0392B`, **gold `#C5A05E`, goldLight `#E8DCC8`, goldDark `#8B6914`**
- **Typography**: `display` 32 / `headline` 24 in **serif** (luxury feel), body scale 11–28 (Roboto default), price 22/28 semibold, strikethrough MRP. No Google Fonts — platform serif + Material defaults.
- **Spacing scale** 2→48 with semantic tokens (`screen 16`, `sectionGap 24`, `gridGap 12`); **radius scale** 4→28 + pill; **shadows** subtle/card/raised.
- **Theme** (`theme.dart`): full Material-3, light-only, elevation-0 cards with hairline borders, 48px buttons, radius-12 inputs, dark SnackBars, tinted chips, ink-sparkle splash. Brand colour injected per business config (`BusinessConfig.getTheme()`).
- **Polish details**: shimmer skeletons (package exists, currently unused), image carousel with dots + counter + pinch-zoom viewer, hero gradient scrims, animated nav pill, 1200ms splash, ellipsised text everywhere, empty states, confirm dialogs.
- **Dark mode**: not enabled (`themeMode: ThemeMode.light` hardcoded in `main.dart:99`).

---

## 6. Responsive layout — mobile, tablet, desktop/Windows

**Breakpoints** (`common_widgets\lib\core\responsive.dart`): `mobile < 600 ≤ tablet < 1200 ≤ desktop`.

| Adaptation | Mobile | Tablet | Desktop |
|---|---|---|---|
| Catalogue grid columns | 2 | 3 | 4 |
| Card aspect ratio | 0.62 | 0.72 | 0.82 |
| Customer nav | fixed 62px bottom bar | bottom bar | bottom bar (not adapted) |
| Owner nav | bottom NavigationBar | **232px sidebar** | **260px sidebar** |
| Catalogue filters | bottom sheet (88%) | right drawer 420px | right drawer 420px |
| Login / product detail | single column | single | **two-pane split**, own scroll per pane |
| Home rail card width | 202 | 232 | 272 |
| Hero height | 224 | 224 | 300 |

**Content width caps (desktop):** login 460, register 560, splash 620, profile 720, owner product form 720, dialogs 400/500/600. **Home/catalogue/cart/checkout are full-bleed** — no max-width on ultra-wide (noted as gap, §11).

**Overflow handling (how it's prevented):**
- `Flexible`/`Expanded` + `TextOverflow.ellipsis` — 100+ usages (price rows, names, nav labels, order rows)
- `Wrap` (11 places) so price+badge/chips flow to a second line instead of overflowing at 320px
- `SingleChildScrollView` (12 screens) + `ListView/GridView` (21 files) for vertical overflow
- `FittedBox.scaleDown` for dashboard revenue figures (`owner\widgets\stat_card.dart:56`)
- `SafeArea` + fixed 62px nav; `LayoutBuilder` for splash, login, category carousel paging
- **Viewport tests**: screens are pumped at 320×568, 360×800, tablet and desktop sizes in `screens_render_test.dart`, `customer_screens_render_test.dart`, `owner_screens_render_test.dart`, `login_screen_layout_test.dart` — asserting `takeException() == null` (no overflow)

**Residual overflow risks found (should fix):**
1. `catalogue_screen.dart:900-933` — list-view price row: 3 bare `Text`s, no `Flexible`
2. `product_detail_screen.dart:896-913` — `_SectionLabel` row, no `Flexible` (now dead code)
3. `order_detail_screen.dart:372-387` — halted-status row without `Flexible`
4. `checkout_screen.dart:445-468` — `_LineSummary` trailing amount not `Flexible`
5. `Responsive.fontSize/spacing` never scales: all 156 call sites pass only `mobile:` (typographic scaling is a no-op; only structural branching works)

---

## 7. Platform support & builds

| Platform | Scaffolding | Status |
|---|---|---|
| Android | `android\` (59 files) | code ready; **this machine** missing cmdline-tools/licenses (flutter doctor) |
| iOS | `ios\` (48 files) | scaffolded (build on macOS required) |
| Web | `web\` | ✅ **`flutter build web --release` succeeded** (128s) |
| Windows | `windows\` (19 files) | scaffolded; **this machine** missing Visual Studio "Desktop development with C++" |
| macOS / Linux | `macos\`, `linux\` | scaffolded |

**App size (web release, measured):** total `build\web` **32.9 MB** — but that includes CanvasKit (~25 MB runtime); actual app payload: **`main.dart.js` 2.98 MB** + assets (18 jewellery images) + tree-shaken fonts (MaterialIcons 1.6 MB → 23.5 KB, 98.6%; CupertinoIcons → 1.5 KB). Android APK/AAB and Windows EXE sizes require the missing toolchains above.

**Layout sizing safety at each class of device:** enforced by tests at 320/360dp (phone), ~600–1200 (tablet), 1200+ (desktop) — see §6.

---

## 8. Key business logic

- **Pricing** (`core/pricing.dart`): GST 18%, shipping ₹79 (free ≥ ₹999), Indian digit grouping (`₹85,000`), currency symbol from config. Discount % from MRP vs price. **Not gold-rate based** yet (flat prices).
- **Jewellery fields** (`business_config.dart:208-215`): Gold Purity, Gross Weight, Net Weight, Stone Weight, Making Charge, Wastage → dynamic spec rows in owner product form and product detail.
- **Business rules matrix** (8 flags; jewellery preset): screenshots OFF, download OFF, share OFF, watermark ON, prices ON, contact info OFF, price sharing OFF, MOQ ON — enforced via `ScreenshotProtectionService.syncWithRule()` and "Contact for Price" UI.
- **Roles** (`core/models/user.dart`): `UserRole.customer → /app`, `UserRole.owner → /owner`.

---

## 9. Quality verification run (today)

| Check | Result |
|---|---|
| `flutter analyze` — ecommerce_app | **3 warnings** (unused `_SectionLabel`, `_ShadeSwatch`, `_SizeChip` in `product_detail_screen.dart`) |
| `flutter analyze` — common_widgets | 4 infos (deprecated `Matrix4.translate/scale` in carousel zoom) |
| `flutter test` — common_widgets | ✅ **19/19 passed** (incl. explicit no-overflow tests at 360dp) |
| `flutter test` — ecommerce_app | ⚠️ **149 passed, 2 failed** |
| `flutter build web --release` | ✅ succeeded |
| `flutter build windows --release` | ❌ blocked by missing Visual Studio toolchain (environment, not code) |

**The 2 failing tests** (`test/product_render_test.dart:371` etc.):
- *"asks for a variant before allowing add to bag"* — expects `Select Shade` / `Select Size` labels that no longer exist
- *"enables add to bag when no variant is needed"* — expects button text **`Add to Bag`**; UI now says **`Add to Cart`** (`product_detail_screen.dart:872`)

Root cause: the shade/size variant picker was removed from the detail screen (`_BuyBar` is now gated only by `product.inStock` at line 60; `_ShadeSwatch`/`_SizeChip` are dead code). Either the picker was dropped accidentally (regression — restore it) or intentionally (then update the 2 tests + delete dead classes).

---

## 10. Spec (`jewellery-b2b-premium-flutter-phase-1.md`) vs current build

**Done (front-end):** auth + OTP demo, private-catalogue UX, search/filter/sort, product detail with jewellery fields, wishlist, cart, checkout, orders + status tracking, notifications, profile, seller management console, business config/rules, screenshot protection, premium light theme, responsive layouts, viewport tests.

**Not yet built (per spec):**
- Node/Express + MongoDB backend, real OTP, refresh tokens, **admin approval workflow** (PENDING/APPROVED/REJECTED/SUSPENDED)
- **Payment gateway** (Razorpay/Cashfree) with server-side verification, webhooks, refunds
- Admin app + Admin **web dashboard** (React), RBAC, audit logs
- Secure image delivery (short-lived signed URLs), dynamic watermark rendering, access logging
- Push notifications, pagination/infinite scroll, skeleton loading wired in, offline/error states
- Bulk/CSV product ops, GST invoices, shipping integration (Phase-2 ready)

---

## 11. Recommendations (priority order)

1. **Resolve the 2 failing tests** — restore variant selection on product detail (B2B buyers pick size/shade) or update tests; delete the 3 dead classes to clear analyzer warnings.
2. **Fix the 5 overflow risk rows** (§6) and add `Flexible` to catalogue list price row.
3. **Add desktop max-width** (e.g. `ConstrainedBox(maxWidth: 1280)`) to home/catalogue/cart/checkout so 1920px windows don't stretch full-bleed.
4. **Make `Responsive.fontSize/spacing` real** — pass `tablet:`/`desktop:` values (or drop the pretence).
5. Wire the already-built `Skeleton*` shimmer widgets into catalogue/home loading states (spec §44/§51 requires skeletons).
6. Start backend per spec §45–§50 (auth → retailer approval → product APIs → payments), swap `CommerceStore` for API repositories behind the same provider interface.
7. Install Android cmdline-tools + VS "Desktop development with C++" to produce APK/EXE and measure real install sizes.
