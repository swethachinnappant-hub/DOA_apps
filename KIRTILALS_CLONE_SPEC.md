# Kirtilals-Style Redesign — Flutter Implementation Spec Pack

**Target app:** `DOA_apps-master\ecommerce_app` (+ `common_widgets` design package)
**Reference:** https://www.kirtilals.com (jewellery storefront: Diamond / Gold / Platinum / Gemstone / Solitaire)
**How to use:** Each section below is an independent spec (`SPEC-00` … `SPEC-20`). Tell your coding assistant *"Implement SPEC-04 only"* and give it this file. Every spec lists: goal, reference behaviour, layout per breakpoint, widgets, exact files to create/modify, data/state, and acceptance criteria.

---

## 0. READ FIRST — what is verified and what is not

I fetched the live site. It is a client-rendered (AngularJS) store, so the fetch returned the **full navigation, mega-menu, mini-cart, search overlay, footer, mobile bottom bar, and `theme-color`**, but **not** the computed CSS, hero banners, product-card visuals, or the product detail page body. Every statement in this document is tagged:

| Tag | Meaning |
|---|---|
| **[V]** | Verified directly from the live site's HTML/markup |
| **[P]** | Proposed — standard for premium jewellery e-commerce / my best design judgement; **not confirmed pixel-exact** |
| **[?]** | Needs a screenshot or DevTools inspection from you to lock down |

**To get a true pixel-exact clone**, send me (a) screenshots of Home, a listing page, a product page, cart and checkout at 390px and 1440px wide, and (b) from Chrome DevTools → Elements → `:root`/`body`, the computed `font-family`, `color`, and `background-color` values of: header, primary button, price text, product card. I will then convert every **[P]**/**[?]** below into **[V]** values. Until then, the **[P]** values are good-looking defaults, not a guaranteed match.

**Legal/brand note:** Clone the *layout, structure and interaction patterns*. Do **not** copy Kirtilals' logo, product photos, banner artwork, or marketing copy — use your own brand name, logo, and imagery. (The SEO paragraphs on their pages are their copyrighted text.)

### 0.1 Two decisions you must make before SPEC-04 onward

Your current app is a **private B2B wholesale** app (screenshots blocked, watermark, "Contact for Price", login-gated). Kirtilals is a **public B2C** store (open browsing, public prices, coupons, loyalty points). These conflict. Pick one and tell the assistant:

| Option | Behaviour |
|---|---|
| **A. Full B2C clone** | Public browsing, prices visible, coupons, loyalty points, guest cart. Business rules (`business_config.dart`) default to jewellery-B2C preset: screenshots ON, watermark OFF, prices ON. |
| **B. Hybrid (recommended for your repo)** | Kirtilals visual design + navigation + PDP/cart UX, **but** keep login gate, approval, watermark, price-hiding as toggles in `BusinessConfig`. Specs below are written so every public-facing feature is behind a flag (`rules.guestBrowse`, `rules.showPrices`, `rules.coupons`, `rules.loyalty`). |

All specs assume **Option B** (superset — Option A is just all flags ON).

### 0.2 Recommended implementation order

`SPEC-01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13 …` Specs 01–03 are foundations; do not skip them. Specs 14–16 are optional/phase-2.

---

## 1. Reference analysis — verified facts

### 1.1 Brand & theme [V]
- Browser `theme-color`: **`#c87f44`** (copper / rose-gold-bronze). This is the only colour value confirmed from source.
- Logo asset: `kk-logo-visible.png` (wordmark, used in header and mobile drawer).
- Currency: **₹ (INR)** primary, **$ (USD)** secondary — price blocks render both (`item.price | currency:"₹"` and `item.usa_price | currency:"$"`; mini-cart shows "Price ₹" and "Price $"). "By Price" menu is in **USD** (Below $500 / $1000 / $2000 / Above $2000).
- Loyalty: header shows **`{{user_clp_points}} points`** (customer loyalty programme).
- Support phone shown globally: "NEED HELP? CALL +1 732 510 0099"; WhatsApp +91 98948 40711; enquiry email.

### 1.2 Global header [V]
Left → right (desktop): hamburger/menu toggle (mobile) · **logo** · primary nav · **search icon** · **sign-in icon (shows user name when logged in)** · **loyalty points** · **wishlist heart** (`/wishlist`) · **cart bag with item-count badge** (`/shopping-cart`). Profile icon links to `/account`.

### 1.3 Primary navigation (top-level order) [V]
`DIAMOND · Gemstone · Gold · Platinum · Solitaire · Bridal · Virtual · Collections · Gifts · By Price` (+ `About Us` in mobile drawer).
Each top-level has a **PNG icon** (`diamond_icons.png`, `gemstone_icons.png`, `gold_icon.png`, `platinum_icons.png`, `solitaire_icons.png`, `Bandhan_11.png`, `virtual_icon.png`, `Collections_1.png`, `gifts_icon.png`, `Dollars1.png`) displayed beside the label.

### 1.4 Mega-menu structure [V]
Pattern: **left column = product categories; right area = filter groups with image thumbnails**.

**Diamond** (also mirrored for Gemstone, Gold, Platinum with fewer entries)
| Category | Groups (each item = square thumbnail + label) |
|---|---|
| Earrings | **Style:** Studs, Dangling, Vallies, Jhumkas, Chandeliers, Hoops, Koppu, Clip-on, Ear Supports · **Metal:** Yellow/White/Rose Gold · **Occasion:** Daily, Casual, Office, Party, Festive & Bridal |
| Rings | **Gender:** Women, Men, Unisex, Neliring · **Metal** · **Occasion:** Daily, Casual, Office, Party |
| Pendant | **Style:** Single Hook, Mangalsutra, Double Hook, Men · Metal · Occasion (5) |
| Necklace | **Style:** Necklace, Choker, Haram · Occasion: Party, Festive & Bridal · Metal |
| Bracelets | **Gender:** Men, Women · Metal · Occasion: Daily, Office |
| Bangles | Gender: Women · Metal · Occasion: Office, Party |
| Chain | Style: Chain, Side Hunt (Mugappu) · Metal · Occasion: Office, Festive & Bridal |
| Nose Pin | Style: Nose Fastener · Metal · Occasion: Daily |
| Hair Deco | Style: Maang Tikka |
| Watch Jewellery | Style: Charm, Pin, Band |

**Gold:** Earrings, Rings, Bangles, Chain, Bracelets, Necklace, Pendant (Gender/Style/Occasion subsets).
**Platinum:** Earrings, Rings, Pendant, Bracelets, Chain; metal options are **Platinum** and **Two Tone** (not yellow/white/rose).
**Solitaire:** flat list (no categories) — Pendants, Earrings, Rings, Bracelet, Bangles, Necklace.
**Virtual:** Virtual Try-on, Virtual Store, Decide With Friends.
**Collections (21 named):** Voyage of Hearts, Hope, Glow & Go, Tribal, Bandhan, Honeycomb, Bestsellers, Style Switch, Gemstone, Promise, Illume, Valentine, Muse, Symphony, Exclusive, Divyadarsanam, Alchemist, Paridhi, Divine, Navarathiri.
**Gifts:** *Gift By Occasion* → Wedding, Birthday, Anniversary · *Gift For Special* → Gift for her, Gift for him.
**By Price:** Below $500, Below $1000, Below $2000, Above $2000 (image tiles).

### 1.5 URL scheme [V] (use as your route map)
```
/diamond  /gold  /platinum  /gemstone  /solitaire-product-list
/{metal}-{category}                  e.g. /diamond-earrings, /gold-ring, /platinum-chain
/{metal}-{category}/{facet}          e.g. /diamond-earrings/studs, /diamond-ring/rose-gold, /gold-chain/men
/gemstone/diamond-{category}[/{facet}]
/{collection-slug}                   e.g. /hope, /honeycomb, /bestsellers
/wishlist  /shopping-cart  /account  /tryinstore  /bespoke  /faq  /feedback
/virtual-tryon  /virtualstoreproduct  /co-shopping-products
/{product-slug}                      e.g. /beautiful-ring  (PDP lives at root slug)
```
Facet keys seen: `yellow-gold|white-gold|rose-gold|two-tone|platinum`, `daily-wear|casual-wear|office-wear|party-wear|festive-bridal-wear`, `men|women|unisex|children`, style slugs (`studs`, `dangling`, `ear-lobes`, `jhumkha`, `chandeliers`, `hoops`, `koppu`, `single-hook`, `double-hook`, `choker`, `haram`, `mugappu`, `maang-tikka`, `charms`, `pin`, `band`, `nose-screw`).

### 1.6 Search overlay [V]
Full-screen overlay: back arrow → input with search icon → sections **Related Searches** (live, shows category or sub-category name with `trending_up` icon), **Popular Searches** (EARRINGS, RINGS, NECKLACE, PENDANTS, BRACELET, HOPE), **Related Products** (live suggestions linking to product URLs).

### 1.7 Mini-cart drawer [V]
Opened from cart icon. Title **"Your Mini Cart"** + "( N Item )". Each line: thumbnail, name, `Qty : n`, `Price ₹ x` and `Price $ y`. **Coupon block:** promo code, states: *eligible* ("You've unlocked a flat ₹X off on this order!"), *needs more* ("Add ₹X more to get a flat ₹Y off on this order."), *applied* ("You've saved ₹X on this order."), Apply/Remove button, applied message, **"View all coupons ▼"** expander. **Totals:** Sub Total (pre-tax), Coupon (discount), Tax, **Grand Total**; USD "Sub Total $" row. Actions: **View Cart** (secondary) and **Quick Checkout** (primary).

### 1.8 Mobile bottom bar [V]
4 items: **Home · Our Store · Cart (count) · Account** (Material icons `home`, `store`, `shopping_cart`, `person`).

### 1.9 Footer [V]
Columns: **Our Popular Searches** (grouped by Earrings/Rings/Necklace/Chain/Pendant/Nose Pin/Bangles/Bracelets/Gemstone/Collections as pipe-separated links) · **About Us** (About, Blog, F.A.Q., Give Feedback) · **Customer Delight** (Contact Us, phone, WhatsApp, email) · **Policies** (Privacy, Shipping & Returns, Investors, Terms) · **Services** (Bespoke, Try in Store) · **Join our email list** (consent text + SUBSCRIBE) · **Social** (Facebook, Instagram, YouTube, Pinterest icons) · **Download Our App** (Play Store + App Store badges, tagline "Shining new app, made just for you! It's Free, Easy & Smart.") · © line. **Cookie banner:** "We use cookies to optimise your visits…" with close ×.

### 1.10 Page-level SEO block [V]
Home and listing pages end with an expandable text block with H1 + five H3 sections (Pendants, Rings, Necklaces, Earrings, Bracelets) — in-app this becomes an "About this collection" accordion (low priority).

### 1.11 Not verifiable from source → [?]
Hero carousel content, home section order/headings, product-card layout & badges, filter sidebar fields, PDP layout (gallery, price breakup, size/purity selectors, delivery pincode), checkout steps, account page layout, fonts, exact greys. Specs mark these **[P]**.

---

## SPEC-00 — Project conventions (apply to all specs)

**Goal:** Keep every spec consistent.

- State management stays **provider**; routing stays **go_router**. Add **no** new state libs.
- New folder convention: `lib/features/<feature>/{screens,widgets,models,providers}`.
- All colours/spacing/typography come from `common_widgets/lib/core/design_tokens.dart` — **no hard-coded colours in feature code**.
- Every screen must be wrapped in `ResponsiveShell` (SPEC-02) and constrained by `MaxWidthBox` (maxWidth **1320**) on desktop.
- Every list/grid uses `Skeleton*` loaders (already in `common_widgets`) while loading.
- Every new screen gets a render test at **320×568, 390×844, 768×1024, 1440×900** asserting `tester.takeException() == null`.
- Feature flags live in `BusinessConfig.rules` (extend `business_config.dart`): `guestBrowse`, `showPrices`, `coupons`, `loyalty`, `multiCurrency`, `virtualTryOn`.
- Add dependencies in `ecommerce_app/pubspec.yaml`: `google_fonts`, `cached_network_image`, `flutter_staggered_grid_view` (optional), `carousel_slider` (or keep own), `url_launcher`, `intl`, `shimmer` (already via common_widgets), `flutter_svg`.

---

## SPEC-01 — Design tokens & theme

**Goal:** Make the whole app look like a Kirtilals-style premium jewellery storefront (copper-led, white, airy, serif display).

### Colour palette
| Token | Value | Tag | Use |
|---|---|---|---|
| `primary` | `#C87F44` | **[V]** | Primary buttons, active nav, badges, links hover, cart badge |
| `primaryDark` | `#A9672F` | [P] | Pressed/hover |
| `primaryLight` | `#F3E3D3` | [P] | Chips, selected tint, coupon bg |
| `ink` | `#1E1E1E` | [P] | Headings, body |
| `inkSoft` | `#555555` | [P] | Secondary text |
| `inkMuted` | `#8A8A8A` | [P] | Captions, strikethrough MRP |
| `surface` | `#FFFFFF` | [P] | Page, cards |
| `surfaceAlt` | `#FAF6F1` | [P] | Section bands (warm off-white) |
| `divider` | `#EAE3DB` | [P] | Hairlines |
| `success` | `#2D7D46` | keep | Applied coupon |
| `danger` | `#C0392B` | keep | Errors, out of stock |
| `gold`/`goldLight`/`goldDark` | existing | keep | Optional accent for metal swatches only |
| Metal swatches | Yellow `#E6C46A`, White `#E5E5E8`, Rose `#E8B4A0`, Two-tone gradient | [P] | Filter swatches |

> Action for you: replace `[P]` hexes with real values once you send DevTools values (see §0).

### Typography [P]
- Display / headings: **Cormorant Garamond** (or Playfair Display) — weights 500/600.
- UI / body: **Lato** or **Montserrat** — 400/500/600.
- Scale: `display 40/48` (desktop hero), `h1 28`, `h2 22`, `h3 18`, `body 14`, `caption 12`, `price 18 w600`, `mrp 13 line-through`.
- Letter-spacing: nav labels `+0.8`, uppercase for top-nav and section eyebrows.

### Shape & elevation [P]
Radius: buttons `4` (sharp-ish luxury), cards `0–4`, chips `20`, inputs `4`. Shadows: only on drawers/dialogs/hover-card (`0 6 24 rgba(0,0,0,.08)`). Hairline borders over shadows elsewhere.

### Files
| Action | File |
|---|---|
| MODIFY | `common_widgets/lib/core/design_tokens.dart` — replace colours, add `AppColors.primary*`, `metalYellow/White/Rose`, `AppType` with google_fonts |
| MODIFY | `common_widgets/lib/core/theme.dart` — `ElevatedButton` (copper filled, 48h, radius 4, uppercase label +0.6 spacing), `OutlinedButton` (copper border), `AppBarTheme` (white, 0 elevation, ink icons), `ChipTheme`, `InputDecorationTheme` (underline or 4px outlined), `BottomNavigationBarTheme` |
| MODIFY | `ecommerce_app/lib/core/business_config.dart` — `getTheme()` must stop overriding primary with the 20 palettes when `brandLocked=true` (add flag) |
| CREATE | `common_widgets/lib/widgets/metal_swatch.dart` |
| CREATE | `common_widgets/lib/widgets/section_title.dart` (eyebrow + serif title + optional "View all") |
| CREATE | `common_widgets/lib/widgets/max_width_box.dart` |

### Acceptance
- No widget in `lib/features/**` references `Color(0x…)` literals.
- Buttons, chips, app bar, bottom bar, inputs all render copper primary.
- Golden test of a button, chip, text-field, price row.

---

## SPEC-02 — Responsive shell, header, mega-menu, drawer, bottom bar, footer

**Goal:** Reproduce Kirtilals' chrome on mobile (<600), tablet (600–1199), desktop/Windows (≥1200).

### Behaviour [V unless noted]
| Region | Mobile | Tablet | Desktop / Windows |
|---|---|---|---|
| Header | Menu icon · centered logo · search · cart badge | same + wishlist | Logo left · full nav row · right icons: search, account, points, wishlist, cart |
| Primary nav | In **left drawer** (accordion, icons, "About Us" last) | drawer | Horizontal bar with icon+label items |
| Mega-menu | Drawer accordion: Top → Category → groups | Drawer | **Hover/click panel** under header: left category list, right grid of groups with 56–72px thumbnails |
| Search | Full-screen overlay (SPEC-07) | overlay | Overlay/slide-down |
| Bottom bar | **Home · Our Store · Cart · Account** | hidden ≥768 [P] | hidden |
| Footer | Collapsible sections | 2-col | 5-col grid + app badges |
| Cart | Bottom sheet/right drawer | right drawer | right drawer 420px |

### Widgets to create
```
lib/shell/
  responsive_shell.dart        // picks Mobile/Desktop scaffold via LayoutBuilder
  site_header.dart             // desktop header
  mobile_header.dart
  mega_menu/
    mega_menu_overlay.dart     // hover intent (150ms), keyboard accessible, Esc closes
    mega_menu_panel.dart       // 2-pane: categories | groups
    nav_data.dart              // const NavTree built from SPEC-03 taxonomy
  nav_drawer.dart              // mobile accordion drawer
  bottom_nav_bar.dart          // 4 tabs (replaces custom 62px bar in main_screen.dart)
  site_footer.dart
  cookie_banner.dart           // dismiss persisted in shared_preferences
  support_strip.dart           // "NEED HELP? CALL ..." top strip [P]
```
### Files to modify
- `features/main_screen.dart` → replace 5-tab bar with `ResponsiveShell`; tabs become Home / Our Store / Cart / Account (+ Wishlist lives in header).
- `core/router/app_router.dart` → convert to `ShellRoute` wrapping all customer routes so header/footer persist; add all routes from §1.5.
- Owner shell stays; only apply new tokens.

### Details
- Mega-menu data is **config, not widgets**: `NavNode { label, iconAsset, route, children[], groups[] }` so the owner console can later edit it (SPEC-18).
- Hover panel max-height 70vh, scrollable; closes on route change.
- Cart badge: `Consumer<CommerceStore>` → `cart.itemCount`.
- Desktop header becomes **sticky**; shrink logo 20% after 80px scroll [P].
- Windows: add `MouseRegion` cursors, `Shortcuts` (Ctrl+K opens search, Esc closes overlays), focus rings.

### Acceptance
- Resize 320→1920: no overflow, bottom bar disappears ≥768, mega-menu appears ≥1200.
- Every nav link in §1.4 routes to a listing page (even if empty state).
- Keyboard: Tab through nav, Enter opens, Esc closes.

---

## SPEC-03 — Catalogue taxonomy & data model

**Goal:** Model the Metal → Category → Facet hierarchy so nav, filters, URLs and owner product form share one source.

### Models (create `lib/core/taxonomy/`)
```dart
enum MetalFamily { diamond, gemstone, gold, platinum, solitaire }
enum MetalColor  { yellowGold, whiteGold, roseGold, platinum, twoTone }
enum Occasion    { daily, casual, office, party, festiveBridal }
enum Audience    { women, men, unisex, children }

class Category { id, slug, label, iconAsset, allowedStyles[], allowedAudiences[], allowedOccasions[] }
class StyleFacet { id, slug, label, categoryId, thumbAsset }
class Collection { id, slug, label, heroImage, description, productIds[] }
class GiftGroup { id, label, items[] }           // occasion / special
class PriceBand { label, minUsd, maxUsd, minInr, maxInr, tileAsset }
```
### Product model changes (`core/product.dart`)
Add: `MetalFamily family`, `MetalColor metal`, `String categoryId`, `String? styleId`, `Audience audience`, `List<Occasion> occasions`, `List<String> collectionIds`, `double priceInr`, `double? priceUsd`, `double? mrpInr`, `String sku`, `String slug`, `bool isBestseller`, `bool isNew`, `int? diamondCarat`, `String? diamondClarity`, `String? diamondColor`, `double netWeightG`, `String purity` (14K/18K/22K/PT950), `List<String> sizeOptions`, `String? deliveryEta`.
Keep existing B2B fields (`makingCharge`, `wastage`, MOQ) behind `rules`.

### Files
| Action | File |
|---|---|
| CREATE | `core/taxonomy/taxonomy.dart` (const trees from §1.4), `core/taxonomy/route_parser.dart` (`/diamond-earrings/studs` → `ListingQuery`) |
| CREATE | `core/models/listing_query.dart` (`family, categoryId, styleId, metal, occasion, audience, collectionId, priceMin/Max, search, sort, page`) |
| MODIFY | `core/product.dart`, `core/demo_catalog.dart` (seed ≥ 60 products across families/categories so every nav link has results) |
| MODIFY | `core/store/commerce_store.dart` → `List<Product> query(ListingQuery q)` + paging (page size 24) |

### Acceptance
- `RouteParser.parse('/gold-chain/men')` → family=gold, category=chain, audience=men.
- Every nav link in the mega-menu yields ≥1 product in demo data or a designed empty state.

---
## SPEC-04 — Home page

**Goal:** Replace `home_sections.dart` with a Kirtilals-style storefront home.
**Reference:** Verified only: header/nav, footer, SEO text block with 5 category sections. Section order below is **[P]** typical for this store type — confirm with a screenshot **[?]**.

### Section order (top → bottom) [P]
1. **Hero carousel** — full-bleed, 3–5 slides, auto-advance 5s, dots + arrows (desktop), swipe (mobile). Height: mobile `aspect 4:5` (≈ 480), tablet `16:9`, desktop `≈ 560`. Slide = image + eyebrow + serif headline + CTA button → collection route.
2. **Shop by Category** — circular/rounded-square tiles (Earrings, Rings, Pendant, Necklace, Bracelets, Bangles, Chain, Nose Pin…). Mobile: horizontal scroll 4.5 visible. Desktop: 8 in a row.
3. **Shop by Metal** — Yellow / White / Rose Gold swatch tiles → `/diamond-ring/rose-gold` style routes.
4. **Collections strip** — horizontal rail of the 20 named collections (image + name).
5. **Bestsellers rail** — product cards, "View all" → `/bestsellers`.
6. **New Arrivals rail**.
7. **Shop by Occasion** — Daily / Casual / Office / Party / Festive & Bridal (image tiles, 5-col desktop, 2-col scroll mobile).
8. **Shop by Price** — 4 tiles (Below $500 / $1000 / $2000 / Above $2000; INR variant for India locale).
9. **Bridal banner** (Bandhan) — wide image with CTA.
10. **Virtual / Services strip** — Virtual Try-on · Try in Store · Bespoke · Decide With Friends (icon cards).
11. **Trust bar** — certified diamonds, lifetime exchange, free shipping, easy returns [P].
12. **Gift for her / him** split banner.
13. **Instagram/social strip** [P, optional].
14. **About-collection accordion** (the SEO H1 + 5 H3 text from §1.10, rewritten in *your* words).
15. **Footer** (SPEC-02).

### Widgets (create under `features/home/widgets/`)
`hero_carousel.dart`, `category_tiles.dart`, `metal_tiles.dart`, `collection_rail.dart`, `product_rail.dart`, `occasion_grid.dart`, `price_band_tiles.dart`, `promo_banner.dart`, `services_strip.dart`, `trust_bar.dart`, `seo_accordion.dart`.

### Files
- MODIFY `features/home/home_sections.dart` → thin composer that stacks the widgets above inside `MaxWidthBox`.
- CREATE `features/home/home_config.dart` — a `HomeLayout` list so section order/visibility is data-driven (owner can reorder in SPEC-18).
- CREATE `features/home/models/banner.dart` (`imageUrl/asset, eyebrow, title, ctaLabel, route, startAt, endAt`).

### Responsive
| Element | Mobile | Tablet | Desktop |
|---|---|---|---|
| Product rail card width | 160 | 200 | 260 |
| Category tile | 72px circle | 96 | 120 |
| Section vertical gap | 32 | 40 | 56 |

### Acceptance
- Home renders with skeletons first (300ms min) then content.
- Every tile/banner navigates to a valid route.
- Lighthouse-style check: no horizontal scroll on page body at any width.

---

## SPEC-05 — Product listing page (PLP)

**Goal:** One reusable `ProductListingScreen` serving every route in §1.5.
**Reference:** URLs and facets **[V]**; sidebar/filter/sort layout **[P]**.

### Layout
- **Header block:** breadcrumb (`Home / Diamond / Earrings / Studs`), serif H1 = route label, result count ("124 designs"), optional collapsed description.
- **Sub-category chips row** (style thumbnails from taxonomy) directly under H1 — horizontal scroll.
- **Toolbar:** Filter button (mobile) / filter sidebar (desktop) · Sort dropdown · grid density toggle (2/3/4 cols desktop) · view toggle grid⇄list (keep existing).
- **Grid columns:** mobile **2**, tablet **3**, desktop **4** (≥1200) or **5** (≥1600). Gap 12/16/24.
- **Filter groups [P]:** Price (range slider + INR/USD), Metal (swatches), Style, Occasion, Gender, Purity (14K/18K/22K), Diamond carat range, Availability, Delivery time, Collections.
- **Sort options [P]:** Featured, Newest, Price Low→High, Price High→Low, Best Sellers, Discount.
- **Pagination:** infinite scroll with "Load more" button fallback (page size 24). Preserve scroll position on back.
- **Active filter chips** row with "Clear all".

### Product card (replace `widgets/product_card.dart`)
```
┌─────────────────┐
│ [image 1:1 or 4:5, hover → 2nd image]  ♡ (top-right)
│ badge: NEW / BESTSELLER / -15% (top-left)
├─────────────────┤
│ Name (2 lines max, ellipsis)
│ ₹ 45,900   ̶₹̶ ̶5̶2̶,̶0̶0̶0̶   12% off     ← Wrap, never overflow
│ ($ 549)                                  ← only if multiCurrency
│ ★ rating (optional)  · metal dot swatches
└─────────────────┘
```
- Image aspect: `1:1` mobile, `4:5` desktop [P]. Mobile: image auto-slides removed (keep manual swipe) to cut jank.
- Hover (desktop/Windows): 2nd image crossfade + "Quick view" button + elevation.
- Wishlist heart: optimistic toggle, animated.
- If `rules.showPrices == false` → "Contact for Price".

### Files
| Action | File |
|---|---|
| CREATE | `features/catalogue/screens/product_listing_screen.dart` (replaces `catalogue_screen.dart` internals; keep file as thin wrapper for old deep links) |
| CREATE | `features/catalogue/widgets/{filter_panel,filter_sheet,sort_menu,active_filters,subcategory_chips,plp_header,quick_view_dialog}.dart` |
| MODIFY | `widgets/product_card.dart` |
| MODIFY | `core/router/app_router.dart` → wildcard matcher using `RouteParser` (SPEC-03) |
| MODIFY | existing overflow bugs listed in report §6 (list-view price row etc.) |

### Acceptance
- `/diamond-earrings/studs`, `/gold-chain/men`, `/hope`, `/500-dollar-products` all render correct filtered sets.
- Filter + sort state encoded in URL query so refresh/back works.
- Price row never overflows at 320px (use `Wrap`).

---

## SPEC-06 — Product detail page (PDP)

**Goal:** Rebuild `product_detail_screen.dart` to the standard premium-jewellery PDP.
**Reference:** Not verifiable from source **[?]**; layout below is **[P]** (industry standard for this exact store type).

### Desktop (≥1200) — two columns, 58 / 42
- **Left:** vertical thumbnail rail (6–8) + large image with hover-zoom / click → fullscreen pinch-zoom viewer; video/360° tab if available. Share + wishlist icons overlay.
- **Right (sticky):**
  1. Breadcrumb · SKU
  2. Title (serif 28)
  3. **Price block:** ₹ price (big), ~~MRP~~, % off, "(Inclusive of all taxes)", USD line if enabled
  4. Metal selector (swatches: Yellow/White/Rose; updates price/gallery)
  5. Purity selector (14K / 18K) · Size selector (rings/bangles/bracelets) + "Size guide" link
  6. **Pincode delivery check** → "Delivery by <date>"
  7. CTAs: **ADD TO CART** (primary copper, full width), **BUY NOW** (outlined), heart; + "Try at Home / Try in Store" link
  8. Offer/coupon chips ("Flat ₹X off above ₹Y")
  9. Trust icons row (Certified · Lifetime exchange · Free shipping)
- **Below (full-width tabs/accordions):** Product Details (collapsible) · **Price Breakup table** (Gold, Diamond, Making, GST, Total) · Diamond Details (carat, clarity, colour, count) · Gold Details (purity, net/gross weight) · Certification · Shipping & Returns · Care.
- **Rails:** "You may also like" (related), "Recently viewed", "Complete the look".

### Mobile
Single column: swipe gallery with dots/counter → title/price → selectors → sticky **bottom bar** (Add to Cart | Buy Now) above bottom nav (hide bottom nav on PDP). Accordions instead of tabs.

### B2B overlays (keep, behind flags)
Gross/Net/Stone weight, Making Charge, Wastage, MOQ stepper, "Enquire with the seller" button, watermark overlay over images.

### Files
| Action | File |
|---|---|
| MODIFY | `features/product/product_detail_screen.dart` (split; delete dead `_SectionLabel/_ShadeSwatch/_SizeChip`) |
| CREATE | `features/product/widgets/{pdp_gallery,pdp_zoom_viewer,price_block,variant_selectors,pincode_check,price_breakup,spec_accordion,pdp_buy_bar,related_rail,trust_row,size_guide_sheet}.dart` |
| CREATE | `features/product/providers/pdp_state.dart` (selected metal/purity/size, computed price) |
| MODIFY | `core/pricing.dart` → add `PriceBreakup computeBreakup(Product, metal, purity, size, goldRate)` |
| MODIFY | the 2 failing tests: restore variant selection (this fixes report §9 issue) |

### Acceptance
- Selecting metal/purity updates price and breakup instantly.
- Add to Cart disabled until required size chosen (rings/bangles); error toast "Select a size".
- Deep link `/beautiful-ring` opens PDP via slug lookup.

---

## SPEC-07 — Search overlay

**Goal:** Match the verified search overlay.
**[V]:** back arrow; input with search icon; sections **Related Searches** (with `trending_up` icon), **Popular Searches** (EARRINGS, RINGS, NECKLACE, PENDANTS, BRACELET, HOPE), **Related Products**.

### Behaviour
- Opens full-screen on mobile, 640px-wide top sheet (dimmed backdrop) on desktop; `Ctrl+K` shortcut.
- Debounce 250ms; min 2 chars; suggestions = matching categories/sub-categories/collections (Related Searches) + top 6 products (Related Products) with thumbnail + price.
- Empty query → Popular Searches + Recent searches (persist last 8 in `shared_preferences`) [P].
- Enter → `/product-list?search=<q>` (listing screen).

### Files
CREATE `features/search/{search_overlay.dart,search_provider.dart,search_index.dart}`; MODIFY `commerce_store.dart` (`search(String)`), header icon wiring (SPEC-02).

### Acceptance
Typing "stud" shows category "Studs" + products; tapping a suggestion closes overlay and navigates; ESC closes.

---

## SPEC-08 — Wishlist

**Goal:** `/wishlist` page + header heart.
- Grid identical to PLP (reuse card) with **Move to cart** + remove (X) per card; empty state with CTA "Continue shopping"; "Share wishlist" [P].
- Guest wishlist persisted locally; merged on login.
- Header heart shows count dot.

Files: MODIFY `features/wishlist/*`, `commerce_store.dart` (merge guest→user), `router`.
Acceptance: heart toggles sync across PLP/PDP/header instantly; survives app restart.

---

## SPEC-09 — Mini-cart drawer + Cart page + coupons

**Goal:** Reproduce the verified mini-cart and a full cart page.

### Mini-cart (right drawer 420px desktop; bottom sheet 90% mobile) [V]
```
Your Mini Cart                          ( 2 Item )   ×
[img] Name                       Qty : 1
      Price ₹ 45,900   (Price $ 549)       [−][1][+] 🗑
────────────────────────────────────────────
COUPON  HOPE500                               [Apply]
  “Add ₹4,100 more to get a flat ₹500 off on this order.”  (progress bar)
  “You've unlocked a flat ₹500 off on this order!”
  “You've saved ₹500 on this order.”          [Remove]
  View all coupons ▼   (accordion: other eligible/ineligible coupons)
────────────────────────────────────────────
Sub Total      ₹ 91,800
Coupon         − ₹ 500
Tax            ₹ 2,754
Grand Total    ₹ 94,054
Sub Total $    $ 1,098        (if multiCurrency)
[ View Cart ]   [ Quick Checkout ]
```
Coupon states (3): **needsMore** (shows delta + progress), **eligible** (Apply), **applied** (success tint + Remove). Auto-open drawer after Add to Cart (desktop), snackbar+badge pulse (mobile).

### Cart page (`/shopping-cart`) [P]
Two-column desktop: items list (left, 65%) + sticky order summary (right). Mobile: items → coupon → summary → sticky "Proceed to Checkout". Per-item: image, name, SKU, metal/purity/size chips, qty stepper (max stock), price, remove, "Move to wishlist". Gift-wrap toggle & note [P]. Pincode/ETA. Empty state with recommendations.

### Models / logic
- CREATE `core/models/coupon.dart` (`code, flatOffInr, minSubtotal, startsAt, endsAt, description`), `core/models/cart_totals.dart`.
- MODIFY `core/models/cart.dart`: line stores selected variant (metal/purity/size) + price snapshot.
- MODIFY `core/pricing.dart`: GST rate for jewellery = **3%** (replace flat 18%) [P — confirm with your CA], shipping rule configurable, `CartTotals compute(cart, coupon)`.
- MODIFY `commerce_store.dart`: `applyCoupon/removeCoupon`, `availableCoupons`.

### Files
CREATE `features/cart/widgets/{mini_cart_drawer,coupon_section,coupon_tile,cart_line_tile,order_summary}.dart`; MODIFY `features/cart/*`.

### Acceptance
- Tests: coupon needsMore→eligible transition on qty change; totals math; guest cart persists.

---

## SPEC-10 — Checkout

**Goal:** Multi-step, clean checkout (Kirtilals "Quick Checkout" entry **[V]**; steps **[P]**).
Steps (desktop = accordion left + summary right; mobile = stepper): **1 Login/Guest → 2 Address → 3 Delivery → 4 Payment → 5 Review & Place**.
- Address: saved addresses, add new (name, phone, pincode auto-city/state, address, type), GST number (B2B) [P].
- Payment: UPI, Card, NetBanking, COD (existing) + **Razorpay** hook (see report §10).
- Order success page with confetti-free subtle check, order id, ETA, "Track order".
- Keep order state machine unchanged.

Files: MODIFY `features/checkout/*`; CREATE `features/checkout/widgets/{checkout_stepper,address_form,address_card,payment_methods,review_step}.dart`, `features/checkout/order_success_screen.dart`.
Acceptance: place order → appears in Orders; empty cart redirects to cart.

---
## SPEC-11 — Authentication & Account

**Reference:** Header has sign-in icon showing user name once logged in **[V]**; `/account`; loyalty points shown in header **[V]**. Page layouts **[P]**.

- **Sign In / Sign Up** (single modal on desktop, full page on mobile): phone/email + OTP (keep demo OTP `123456`), Google sign-in hook [P]. Tabs "Sign In | Sign Up". Guest checkout allowed when `rules.guestBrowse`.
- **Account page** (`/account`): left menu (desktop) / list (mobile): *My Profile · My Orders · Addresses · Wishlist · Loyalty Points · Coupons · Notifications · Help · Sign out*.
- **Loyalty (CLP) points:** header chip "1,250 points"; Account → Loyalty shows balance, earn/redeem ledger, redeem at checkout (1 point = ₹1) [P].
- Role switch (customer/owner) stays on login; owner redirected to `/owner`.

Files: MODIFY `features/auth/*`, `features/profile/*`; CREATE `features/account/{account_screen,addresses_screen,loyalty_screen,coupons_screen}.dart`, `core/models/loyalty.dart`.
Acceptance: header shows name after login; sign out clears cart? (no — cart persists), wishlist persists.

---

## SPEC-12 — Orders & tracking

Keep state machine (`placed → … → delivered`). Restyle: order list cards (thumb strip, status chip in copper/green), detail page with vertical timeline, invoice download (PDF) [P], "Reorder", "Return/Exchange request" (≤ 30 days) [P], support CTA.
Files: MODIFY `features/orders/*`; CREATE `features/orders/widgets/{order_timeline,invoice_button,return_request_sheet}.dart`.
Acceptance: timeline matches status; PDF invoice opens on Windows/Android/iOS (`printing` + `pdf` packages).

---

## SPEC-13 — Collection, Gift, Bridal & By-Price landing pages

**Reference [V]:** 20 collections, Gifts (Gift By Occasion: Wedding/Birthday/Anniversary; Gift For Special: for her/him), Bridal (`/realbrides`, "Bandhan"), By Price tiles (`/500-dollar-products`, `/1000-dollar-products`, `/2000-dollar-products`, `/above-2000-dollar-products`). Page bodies **[P]**.

- **Collection page:** full-bleed hero (image + serif title + 2-line description) → sticky sub-nav (All / Earrings / Rings…) → PLP grid (SPEC-05) scoped to `collectionId`.
- **Gift hubs** (`/gift-by-occasion`, `/gift-for-special`): tile grid → PLP filtered by tag.
- **Bridal (`/realbrides`)**: editorial layout — hero, "Real brides" photo gallery (masonry), shop-the-look product carousel [P].
- **By Price:** PLP with price preset; INR band labels when locale = India.
Files: CREATE `features/collections/{collection_screen,gift_hub_screen,bridal_screen}.dart`; MODIFY router + taxonomy (SPEC-03).
Acceptance: all 20 collection slugs resolve; unknown slug → 404 page with search.

---

## SPEC-14 — Virtual Try-on / Virtual Store / Decide With Friends (Phase 2, optional)

**Reference [V]:** menu entries & routes exist (`/virtual-tryon`, `/virtualstoreproduct`, `/co-shopping-products`). Internal behaviour **[?]**.
- **Virtual Try-on:** camera (`camera` + ML Kit face/hand landmarks) overlay of earrings/rings/necklace PNGs; photo capture + share. Start with static "upload a photo & drag the jewellery" fallback [P].
- **Virtual Store:** 360° store walkthrough → embed `webview_flutter` of your vendor tour, or image-hotspot panorama [P].
- **Decide With Friends (co-shopping):** create a shared shortlist link; friends vote ❤/👎 and comment; realtime via `RealtimeService`/backend later [P].
Gate behind `rules.virtualTryOn`. Show "Coming soon" screen until built.

---

## SPEC-15 — Service & content pages

**Reference [V]:** Bespoke (`/bespoke`), Try in Store (`/tryinstore`, also bottom-bar "Our Store"), About (`/world-of-kirtilals`), Blog, FAQ, Feedback, Contact (`/contactusform`), Privacy, Shipping & Returns, Investors, Terms.
- **Our Store / Try in Store:** store locator (list + map via `google_maps_flutter`/`flutter_map`), address, hours, phone, "Book appointment" form (name, phone, date, time slot, products to try) [P].
- **Bespoke:** hero + 4-step process + enquiry form with reference-image upload [P].
- **Contact:** form + phone/WhatsApp (`url_launcher` `tel:` / `wa.me`) + email.
- **Static/legal pages:** generic `ContentPage` rendering Markdown from assets (`assets/content/*.md`) so legal text is replaceable. **Write your own text.**
- **FAQ:** accordion. **Blog:** list + detail (markdown) [P]. **Feedback:** rating + message.
Files: CREATE `features/content/{content_page,faq_screen,contact_screen,blog_*}.dart`, `features/services/{store_locator,appointment_form,bespoke_screen}.dart`, `assets/content/`.
Acceptance: all footer links open a real page; forms validate and show success states.

---

## SPEC-16 — Footer, newsletter, cookie consent, app-download

**[V] structure** in §1.9. Implement `site_footer.dart`: 5 columns desktop → accordion mobile; popular-search link groups; newsletter email field + consent checkbox + SUBSCRIBE (stores locally / API later); social icons (`flutter_svg`) via `url_launcher`; store badges (hide inside the app itself, show on web); cookie banner (SPEC-02) persisted. 
Acceptance: newsletter rejects invalid email; badges only on web build (`kIsWeb`).

---

## SPEC-17 — Notifications, loading, empty & error states

- Restyle notification centre with copper accents; keep types.
- **Skeletons everywhere** (Home rails, PLP grid, PDP, cart) — wire existing `Skeleton*` (report §11 item 5).
- **Empty states** (illustrated, serif title, CTA) for: cart, wishlist, orders, search, listing with filters.
- **Error states:** offline banner, retry button, 404/route-not-found with search box.
Acceptance: each async screen has loading/empty/error golden tests.

---

## SPEC-18 — Owner / seller console (CMS for the new storefront)

**Reference:** Kirtilals' admin is not public — nothing verifiable. This spec adapts the existing console so owners can run the new features **[P]**.

New/changed owner screens (all use new tokens; sidebar ≥600, bottom bar <600):
| Screen | Purpose |
|---|---|
| Dashboard (existing) | Add: today's orders, coupon redemptions, top products, low stock |
| Products (existing) | Form gains: family/category/style/metal/purity/occasions/audience/collections/sizes/diamond specs, multi-image upload, slug, SEO title, price in INR(+USD), MRP, stock, badges (New/Bestseller) |
| **Categories & Menu** | Edit `NavTree` (labels, icons, order, show/hide) |
| **Collections** | CRUD collections, hero image, assign products |
| **Home Builder** | Reorder/toggle `HomeLayout` sections; edit hero slides |
| **Coupons** | CRUD (code, flat off, min subtotal, validity, usage limit) |
| **Gold-rate / pricing** | Daily gold & platinum rate input → recompute dynamic prices (SPEC-19) |
| Orders (existing) | Add filters, export CSV |
| Customers | list, loyalty adjust |
Files: CREATE under `features/owner/screens/` + `features/owner/widgets/`; MODIFY `owner_shell.dart` nav items; persist via `CommerceStore` → API repository interface (`abstract class CatalogRepository`) for later backend.
Acceptance: changing a collection/home/menu in owner is reflected in the customer app without restart.

---

## SPEC-19 — Pricing engine & multi-currency

- `PricingService.compute(product, metal, purity, size)` → Gold value (rate×netWeight) + Diamond value + Making (% or per-g) + GST(3% jewellery, 5% making) [P — verify with CA] → total; show breakup in PDP.
- Owner sets daily rates (SPEC-18). Cache last rate; show "Price valid today".
- Multi-currency: `CurrencyProvider` (INR default; USD for non-IN locale or manual toggle). Use fixed owner-set conversion unless you add an FX API. `intl` NumberFormat (`en_IN` for ₹ grouping).
Acceptance: unit tests for breakup and rounding; USD hidden when `multiCurrency=false`.

---

## SPEC-20 — Platform behaviours (mobile / tablet / desktop / Windows / web)

| Concern | Rule |
|---|---|
| Breakpoints | `<600 mobile`, `600–1199 tablet`, `≥1200 desktop`, `≥1600 wide` |
| Max content width | 1320 (1480 wide) centered; header/footer full-bleed |
| Input | Touch (swipe galleries, bottom sheets) vs mouse (hover cards, mega-menu, scroll wheel zoom, right-click none) |
| Windows desktop | Resizable window min 360×640; custom scrollbars always visible; keyboard shortcuts (Ctrl+K search, Esc close, Tab focus); title bar via `window_manager` [P] |
| Safe areas | `SafeArea` + keyboard insets on every form; PDP sticky bar above home-indicator |
| Orientation | Tablet landscape uses desktop grid; phone landscape → 3-col grid |
| Web | URL strategy `PathUrlStrategy`, SEO meta via `flutter_meta_seo` [P], deep links from §1.5 |
| Performance | `cached_network_image`/precache hero, `const` constructors, `ListView.builder`, images ≤ 1200px, lazy rails |
| Accessibility | Semantics labels on icons, 4.5:1 contrast for text on copper (use white text only ≥ 18px bold or darken to `primaryDark`) |
| Security (B2B flag) | Keep `no_screenshot` + watermark when `rules.screenshot=false/watermark=true`; web: disable text selection & right-click on product images |

> Contrast warning: white text on `#C87F44` is ≈ 3.4:1 — fine for large/bold button labels, **fails** for small text. Use `primaryDark #A9672F` (≈ 4.9:1) for small copper text on white.

---

## SPEC-21 — Testing & acceptance matrix

| Spec | Required tests |
|---|---|
| 01 | Golden: button, chip, input, price row |
| 02 | Widget: header/bottom bar visibility at 360/768/1280; mega-menu open/close/keyboard |
| 03 | Unit: `RouteParser` (≥15 URLs from §1.5), `query()` filters |
| 04–06 | Render tests at 320/390/768/1440 (no overflow); PLP filter→URL; PDP variant→price |
| 07 | Search debounce, suggestion navigation |
| 09 | Coupon state machine, totals math, guest cart persistence |
| 10 | Checkout happy path & validation |
| 18 | Owner edit → customer reflects |
| all | `flutter analyze` = 0 warnings; the 2 stale tests from report §9 fixed |

---

## Appendix A — Master file change list

```
common_widgets/lib/core/{design_tokens,theme,responsive}.dart          MODIFY  (SPEC-01)
common_widgets/lib/widgets/{metal_swatch,section_title,max_width_box}   CREATE  (SPEC-01)
ecommerce_app/lib/shell/**                                              CREATE  (SPEC-02)
ecommerce_app/lib/core/taxonomy/**                                      CREATE  (SPEC-03)
ecommerce_app/lib/core/{product,pricing,demo_catalog,business_config}   MODIFY  (03,06,09,19)
ecommerce_app/lib/core/models/{coupon,cart_totals,loyalty,listing_query} CREATE (03,09,11)
ecommerce_app/lib/core/store/commerce_store.dart                        MODIFY  (03,07,08,09)
ecommerce_app/lib/core/router/app_router.dart                           MODIFY  (02,03,05,13)
ecommerce_app/lib/features/{home,catalogue,product,search,wishlist,cart,checkout,account,orders,collections,content,services}/**  CREATE/MODIFY
ecommerce_app/lib/features/owner/**                                     MODIFY/CREATE (SPEC-18)
ecommerce_app/lib/widgets/product_card.dart                             MODIFY  (SPEC-05)
ecommerce_app/assets/{content,nav,collections,banners}/**               CREATE  (your own images)
ecommerce_app/pubspec.yaml                                              MODIFY  (SPEC-00)
```

## Appendix B — How to prompt your coding assistant

> "Here is `KIRTILALS_CLONE_SPEC.md` and my repo. Implement **SPEC-01 only**. Follow the files list exactly, don't touch other specs, run `flutter analyze` and the tests in SPEC-21 for this spec, and list what you changed."

Then repeat for SPEC-02, SPEC-03, etc. in order (§0.2).

## Appendix C — Open questions (answer these to remove all [P]/[?])

1. Option A (B2C clone) or Option B (hybrid with B2B flags)? (§0.1)
2. Your brand name, logo, and whether copper `#C87F44` stays as primary.
3. Screenshots (mobile 390px + desktop 1440px) of Home, listing, PDP, cart, checkout, account.
4. DevTools computed fonts/colours (§0).
5. Do you need USD / international shipping at launch?
6. Is a backend coming now? (SPEC-18/19 assume repository interfaces so you can swap later.)
