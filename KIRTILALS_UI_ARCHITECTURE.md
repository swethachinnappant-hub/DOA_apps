# Kirtilals-Style Jewellery Storefront — Complete UI Architecture

**Scope:** UI only (look, layout, sections, behaviour, rendering per platform). No code.
**Reference:** https://www.kirtilals.com (+ its iOS app `id1542775915`, Android `com.kirtilals.promoapp`)
**Targets:** Android phone · iOS phone · tablets · mobile web · desktop web · Windows app (macOS optional)
**Inputs reviewed:** `KIRTILALS_CLONE_SPEC.md`, `JEWELLERY_ECOMMERCE_PROJECT_COMPLETE_REPORT.md`, a fresh fetch of the live homepage (nav, mega-menu, drawer, search overlay, mini-cart, footer), and a **Revision 2 re-fetch (Oct 2026)** that verified/corrected 15+ statements (see **§0.4**).
**Implementation target:** `DOA_apps-master/ecommerce_app` (Flutter → Android · iOS · Web · Windows) — file-level build plan in **§16**.

---

## 0. Read this first

### 0.1 Confidence tags (used on every statement)

| Tag | Meaning |
|---|---|
| **[V]** | Verified from the live site's markup (fetched today) |
| **[P]** | Proposed: standard for premium jewellery e-commerce and my design judgement. **Not confirmed pixel-exact.** |
| **[?]** | Needs a screenshot / DevTools / app capture from you to lock down |

### 0.2 Honest limit: what "exact clone" requires

kirtilals.com is client-rendered. The fetch returns the **full navigation, mega-menu, mobile drawer, search overlay, mini-cart, footer, bottom bar, cookie banner, SEO block and asset file paths**. It does **not** return computed CSS, hero banners, home section order, product-card visuals, filter sidebar, product page body, checkout or account pages.

So this document is exact for **structure, navigation, URLs, menu content, assets naming, footer, mini-cart logic, search overlay**, and a strong, industry-standard proposal for the rest. The only colour verified is the theme colour **`#C87F44`**. To convert every [P]/[?] to [V], use the **Capture Checklist in §14**. That checklist is the shortest path to a true pixel-level match.

**Legal note:** replicate layout, structure and interaction patterns. Do not copy Kirtilals' logo, photography, banner artwork or copy text. Use your own brand assets.

### 0.3 Audit: is everything from the two .md files included here?

| Item in the .md files | Status in this file |
|---|---|
| Verified nav, mega-menu, URL scheme, search overlay, mini-cart, footer, bottom bar | Included, **expanded** (§4, §5) |
| Colour palette, typography, shape | Included, restructured as tokens (§2). Contrast figures **corrected** (see §2.1) |
| Home / PLP / PDP / Cart / Checkout / Account / Orders / Collections / Services | Included, now with wireframes per breakpoint (§6–§10) |
| Flutter file lists, class names, packages, tests, B2B flags | **Deliberately removed** (you asked for UI architecture, not code). Business flags remain only as UI visibility switches (§11.3) |
| Project report: B2B wholesale app status, bugs, tests, build sizes | Not UI-architecture; excluded, except the responsive findings that matter (full-bleed on ultra-wide → capped width, §3) |

**Gaps in the original spec that this file closes:**

1. **Drawer order differs from desktop order** [V]: desktop is Diamond · Gemstone · Gold · Platinum · Solitaire · Bridal · Virtual · Collections · Gifts · By Price. Mobile drawer is Diamond · Gold · Platinum · Gemstone · Solitaire · Collections · Gifts · Bridal Collection · Virtual · By Price · About Us. The original spec treated them as one list.
2. **Drawer drill-down structure** [V]: Top-level → "View All" → Category → "All {Metal} {Category}" link → grouped thumbnail rows. Not in the original.
3. **URL irregularities** [V]: gender is a *prefix* for rings (`/women-diamond-ring`, `/men-diamond-ring`) but a *suffix* elsewhere (`/gold-chain/men`); occasion paths mix singular and plural (`/diamond-earring/daily-wear` vs `/diamond-rings/daily-wear`). The router must accept both.
4. **Mobile drawer uses a light-on-dark icon variant** (`white_bandhan_11.png`) [V file name], implying the drawer header/rows sit on a coloured/dark surface [P].
5. **Region-aware content** [V]: blog URL is `/blog/country/kirtilals-usa`; price pop-ups render both ₹ and $ lines.
6. **Per-platform rendering** (iOS, Windows specifics) was only a table row; now a full section (§12).
7. **Missing UI module list:** component inventory with states, motion, accessibility, asset inventory, per-screen empty/error states. Added (§2, §11, §13).
8. **Original contrast claim was slightly off.** White on `#C87F44` is about **3.2:1** (not 3.4), and white-on-`#A9672F` is about **4.5:1** (not 4.9). Verify with a contrast checker before finalising.

### 0.4 Revision 2 delta — live re-fetch (Oct 2026) [all **[V]**]

The live site has **changed since the first capture**. Every row below was re-verified from today's fetch; the body sections have been corrected accordingly. Treat this table as the changelog.

| # | Area | Old in this doc | Live now (verified) |
|---|---|---|---|
| 1 | Top strip | "NEED HELP? CALL +1 732 510 0099" | **USP strip: "Free Shipping · Ease Returns · Lifetime Buyback"**; help moved into drawer/sign-in panel: **"NEED HELP? CALL 18001200411"** (`tel:18001200411`) |
| 2 | Desktop nav order | Diamond · Gemstone · Gold · Platinum · **Solitaire · Bridal** · Virtual · Collections · Gifts · By Price | Diamond · Gemstone · Gold · Platinum · **Bridal · Virtual · Collections · Gifts · Solitaire** · By Price |
| 3 | Mobile drawer order | …Gemstone · **Solitaire · Collections · Gifts · Bridal** · Virtual · By Price… | Diamond · Gold · Platinum · Gemstone · **Collections · Gifts · Bridal Collection · Virtual · Solitaire** · By Price · About Us |
| 4 | By Price bands | Below $500 / $1000 / $2000 / Above $2000 (`/500-dollar-products`…) | **India-first INR bands:** Under 20K `/20k-products` · Under 30K `/30k-products` · Under 50K `/50k-products` · Above 50K `/above-50k` |
| 5 | By-Price icon file | `Dollars1.png` | **`price_icons.png`** |
| 6 | Solitaire target | `/solitaire-product-list` | **`/solitaire-collections`** (footer also links `/solitaire-collection-rings`, `/solitaire-collection-pendants`) |
| 7 | Diamond categories | included **Hair Deco** (Maang Tikka) | **Hair Deco gone**; live: Earrings · Rings · Pendant · Necklace · Bracelets · Bangles · Chain · Nose Pin · **Watch Jewellery** |
| 8 | Diamond earring styles | …Clip-on, **Ear Supports** | …Koppu, **Clip on earrings** (`/clip-on-earrings`); "Ear Supports" not present |
| 9 | Gold menu | Earrings…Pendant | **adds "Gold Promotions" `/goldjewellerypromotion`** (first item) **and "Accessories → Gold Coin" `/gold-coin`** |
| 10 | Gifts menu | Occasion (3) + Special (2) | **adds "Gift Card" `/giftcardsforms` and "Gold Coin" `/gold-coin`** |
| 11 | Collections (20) | …Symphony, Exclusive… | **removed: Symphony, Exclusive. Added: Ikat `/ikat`, Couple Band `/coupleband`**; Muse → `/the-muse`; Promise → `/mens-platinum-collection` |
| 12 | Region / blog | `country/kirtilals-usa` | **`/blog/country/kirtilals-india`** (India-first; $ lines still rendered in mini-cart & search = dual-currency backend) |
| 13 | Footer | generic 4 columns | verified 5 columns + app block; **new: "CLP Terms & Conditions" `/clp-terms`**; phones/WhatsApp/email verified (§5.8) |
| 14 | Copyright | `{your company}` | **"© KIRTILAL KALIDAS JEWELLERS PVT. LTD."** |
| 15 | Popular searches | "NECKLACE" | live label is **"NECKALCE"** (typo on site) — replicate or fix, decision §14 |
| 16 | Floating action | not documented | **WhatsApp bot FAB** `images/homepage/whatsapp_bot.svg` → `wa.me/+919655200411` |
| 17 | Home SEO block | "H1 + 5 H3" | H1 **"Online Diamond Jewellery Store"**; H3s: Diamond Pendants · Diamond Rings · Diamond Necklaces · Diamond Earrings · Diamond Bracelets |
| 18 | App promo text | not documented | footer: **"Shining new app, made just for you! It's Free, Easy & Smart."** + badges `google_play_store2.png` / `google_app_store2.png` (variant B: un-numbered) |

---

## 1. Platform & rendering strategy

### 1.1 One design language, adaptive behaviour

Build **one brand UI** (copper, serif display, airy white) and adapt *behaviour and chrome* per platform, not the brand look. Same screens, same tokens, different shells.

| Class | Width | Devices | Shell |
|---|---|---|---|
| **Compact** | < 600 | Android/iOS phones, mobile web | Header (menu · logo · search · cart) + bottom bar + left drawer |
| **Medium** | 600–1199 | Tablets, small windows | Header with wishlist; bottom bar hidden ≥ 768 [P]; drawer or collapsed nav |
| **Expanded** | 1200–1599 | Laptops, desktop web, Windows app | Full header with horizontal nav + mega-menu, no bottom bar |
| **Wide** | ≥ 1600 | Large monitors | Same as Expanded; content capped, 5-col grids |

### 1.2 How each target renders

| Target | Shell | Navigation | Distinctive behaviours |
|---|---|---|---|
| **Android phone** | Compact | Drawer + bottom bar | System back closes overlays first; Material ripple only on tappable list rows (brand buttons stay flat); edge-to-edge with status-bar tint |
| **iOS phone** | Compact | Drawer + bottom bar | Edge-swipe-back on every pushed screen; safe-area insets (notch/Dynamic Island, home indicator); bottom sheets with grabber; haptic on add-to-cart and wishlist; share via native share sheet; Sign in with Apple required if any social login exists; Dynamic Type respected |
| **iPad / Android tablet** | Medium | Drawer; grids 3-col; PDP two-column in landscape | Landscape uses the Expanded layout |
| **Mobile web** | Compact | Same as app | Sticky bottom bar; browser bars shrink; cookie banner |
| **Desktop web** | Expanded | Hover mega-menu | Hover states, quick view, scroll-wheel zoom, keyboard shortcuts |
| **Windows app** | Expanded | Same as desktop web | Resizable window (min ≈ 360×640 [P]); title bar (system or custom); DPI scaling 100–250%; always-visible scrollbars; Ctrl+K search, Esc closes overlays, Tab focus rings; right-click disabled on product images when protection is on; Windows toast notifications; high-contrast support |
| **macOS (optional)** | Expanded | Same | Native menu bar entries, Cmd+K |

### 1.3 Rules that apply to every target

1. Header and footer are **full-bleed**; page content is centred and capped (see §3).
2. No horizontal page scroll at any width from 320 to 3840.
3. Every async region has a skeleton, an empty state and an error state (§11.1).
4. Overlays stack in a fixed order (§3.4), and **Esc / system back / swipe-back** closes the topmost first.
5. Prices never overflow: price, MRP and discount flow onto a second line.

---

## 2. Design system (tokens + components)

### 2.1 Colour

| Role | Value | Tag | Used for |
|---|---|---|---|
| `brand.primary` | `#C87F44` | **[V]** (site theme-color) | Primary buttons, active nav underline, cart badge, links on hover, focus ring |
| `brand.primaryDark` | `#A9672F` | [P] | Pressed/hover, **small copper text on white** (≈ 4.5:1, borderline; darken further to ≈ `#94592A` for body-size text) |
| `brand.primaryTint` | `#F3E3D3` | [P] | Selected chips, coupon background, eligible-state fill |
| `text.primary` | `#1E1E1E` | [P] | Headings, body |
| `text.secondary` | `#555555` | [P] | Supporting text |
| `text.muted` | `#8A8A8A` | [P] | Captions, strikethrough MRP |
| `surface.page` | `#FFFFFF` | [P] | Page and cards |
| `surface.warm` | `#FAF6F1` | [P] | Alternate section bands |
| `surface.drawer` | dark/copper [?] | [?] | Mobile drawer (inferred from white icon set) |
| `border.hairline` | `#EAE3DB` | [P] | Dividers, card borders |
| `state.success` | `#2D7D46` | [P] | Coupon applied, in stock |
| `state.danger` | `#C0392B` | [P] | Errors, out of stock |
| `metal.yellow` | `#E6C46A` | [P] | Swatch |
| `metal.white` | `#E5E5E8` | [P] | Swatch (also Platinum) |
| `metal.rose` | `#E8B4A0` | [P] | Swatch |
| `metal.twoTone` | split gradient yellow/white | [P] | Swatch (Platinum "Two Tone") |

Metal swatches on the live site are **image files** (`SBM/Yellow.png`, `White.png`, `Rose.png`, `Two-Tone.png`) [V]; replace the hex swatches with your own images for an exact match.

### 2.2 Typography [P]

| Role | Face (proposal) | Weight | Desktop / Mobile size |
|---|---|---|---|
| Display / hero headline | Cormorant Garamond or Playfair Display | 500–600 | 48/56 · 32/40 |
| H1 (page title) | Same serif | 600 | 32 · 24 |
| H2 (section title) | Same serif | 500 | 26 · 20 |
| H3 / group heading | UI sans (Lato or Montserrat) | 600 | 16 · 14 |
| Body | UI sans | 400 | 14–15 · 14 |
| Nav label | UI sans, **uppercase**, +0.8 letter-spacing | 500 | 13 · 13 |
| Button label | UI sans, uppercase, +0.6 | 600 | 13–14 |
| Price | UI sans | 600 | 20 · 18 |
| MRP | UI sans, line-through | 400 | 14 · 13 |
| Caption | UI sans | 400 | 12 |

The live site's top nav shows labels in capitals (e.g. "DIAMOND") with an icon beside them [V]. Exact typefaces are [?].

### 2.3 Spacing, radius, elevation, motion

| Token | Values |
|---|---|
| Spacing scale | 4 · 8 · 12 · 16 · 24 · 32 · 40 · 56 · 80 |
| Section vertical gap | 32 (compact) · 40 (medium) · 56 (expanded) [P] |
| Grid gutter | 12 · 16 · 24 |
| Page side padding | 16 · 24 · 32 · centred cap |
| Radius | Buttons 4 · inputs 4 · cards 0–4 · chips 20 · avatars full · sheets 16 top corners |
| Elevation | Hairline borders by default; shadow only on drawers, dialogs, mega-menu panel and hover-lifted cards (`0 6 24 rgba(0,0,0,.08)`) |
| Motion | 150 ms (hover/press) · 250 ms (drawer/sheet) · 400 ms (carousel crossfade) · easing standard ease-out; respect "reduce motion" |

### 2.4 Iconography [V]

- Header icons are SVG files: `menu-toogle.svg`, `search.svg`, `user_signin.svg`, `product-wishlist.svg`; close is `md_close_icon.png`; social SVGs `Facebook`, `IG`, `YouTube`, `Pint`.
- Top-level nav icons are **PNG pictograms** beside labels (diamond, gemstone, gold, platinum, solitaire, Bandhan, virtual, collections, gifts, dollars).
- Bottom bar and search overlay use **Material icons**: `home`, `store`, `shopping_cart`, `person`, `arrow_back`, `trending_up`.
- Icon sizes: 20–24 header, 24 bottom bar, 16 inline.

### 2.5 Imagery rules [P]

- Product images: square 1:1 (compact), 4:5 (expanded); white or soft-warm background; consistent crop.
- Menu thumbnails: square, ≈ 56–72 px, cropped lifestyle/jewellery tile [V: `.jpg` per facet].
- Hero: full-bleed, 4:5 (compact), 16:9 (medium), ≈ 560 px tall (expanded).
- Lazy-load everything below the fold; pre-load the first hero.

### 2.6 Component inventory (each needs default · hover · pressed · focus · disabled · loading)

| Group | Components |
|---|---|
| Buttons | Primary (copper fill, white label), Secondary (copper outline), Text link, Icon button, Floating cart/WhatsApp (if used) |
| Inputs | Text field (underline or 4 px outline), Search field, OTP boxes, Pincode field, Dropdown/sort, Range slider, Checkbox, Radio, Stepper (− n +) |
| Selection | Metal swatch, Purity chip, Size chip, Filter chip, Active-filter chip, Toggle |
| Cards | Product card, Category tile, Collection tile, Occasion tile, Price-band tile, Banner card, Service card, Coupon tile, Address card, Order card |
| Navigation | Header, Mega-menu panel, Drawer accordion, Bottom bar, Breadcrumb, Tabs, Pagination / Load-more |
| Feedback | Badge (NEW / BESTSELLER / −x%), Cart count badge, Toast/snackbar, Dialog, Bottom sheet, Progress bar (coupon), Skeleton, Empty state, Error banner, Cookie banner |
| Media | Carousel (hero), Product gallery, Zoom viewer, Video/360 slot |

---

## 3. Layout system

### 3.1 Breakpoints and grid

| Class | Width | Product grid | Page margins | Content cap |
|---|---|---|---|---|
| Compact | < 600 | 2 col | 16 | none |
| Medium | 600–1199 | 3 col | 24 | none |
| Expanded | 1200–1599 | 4 col | 32 | **1320** [P] |
| Wide | ≥ 1600 | 5 col | 40 | **1480** [P] |

Phone landscape: 3-col grid, header compact. Tablet landscape: Expanded layout.

### 3.2 Safe areas

Apply top/bottom safe insets everywhere on iOS/Android (status bar, notch, home indicator, gesture bar). Sticky PDP buy bar sits **above** the home indicator and **replaces** the bottom nav on that screen.

### 3.3 Scroll behaviour

- Desktop header sticky; logo shrinks ≈ 20% after 80 px scroll [P].
- Mobile header sticky; hides on scroll-down, shows on scroll-up [P].
- Listing pages keep scroll position on back navigation.

### 3.4 Overlay stacking (low → high)

1. Sticky header
2. Mega-menu panel (desktop)
3. Drawer (mobile nav)
4. Mini-cart drawer / sheets
5. Search overlay
6. Dialogs
7. Toasts
8. Cookie banner sits at the bottom, **under** dialogs

---

## 4. Information architecture

### 4.1 Top-level navigation [V — Revision 2 re-verified]

**Desktop order** (hover mega-menu; icon file in brackets):

| # | Item | Icon file | Target |
|---|---|---|---|
| 1 | DIAMOND | `diamond_icons.png` | `/diamond` + mega-menu |
| 2 | Gemstone | `gemstone_icons.png` | mega-menu (root link is `javascript:;`, items carry `/gemstone/...`) |
| 3 | Gold | `gold_icon.png` | `/gold` + mega-menu |
| 4 | Platinum | `platinum_icons.png` | `/platinum` + mega-menu |
| 5 | Bridal | `Bandhan_11.png` | `/realbrides` |
| 6 | Virtual | `virtual_icon.png` | tile menu of 3 |
| 7 | Collections | `Collections_1.png` | tile menu of 20 |
| 8 | Gifts | `gifts_icon.png` | menu of 4 groups |
| 9 | Solitaire | `solitaire_icons.png` | `/solitaire-collections` |
| 10 | By Price | **`price_icons.png`** | tile menu of 4 (INR bands) |

**Mobile drawer order** (icon files identical except Bridal):

| # | Item | Target |
|---|---|---|
| 1 | Diamond | accordion |
| 2 | Gold | accordion |
| 3 | Platinum | accordion |
| 4 | Gemstone | accordion |
| 5 | Collections | tile list of 20 |
| 6 | Gifts | accordion of 4 groups |
| 7 | Bridal Collection (`white_bandhan_11.png`) | `/realbrides` |
| 8 | Virtual | tile list of 3 |
| 9 | Solitaire (`solitaire_icons.png`) | `/solitaire-collections` |
| 10 | By Price (`price_icons.png`) | 4 tiles (INR) |
| 11 | About Us (`About-Us_2.png`) | `/world-of-kirtilals` |

### 4.2 Mega-menu content (desktop) and drawer content (mobile) [V]

Pattern: **left column = categories**; **right area = grouped thumbnails** under headings "Shop By Style", "Shop By Gender", "Shop By Metal", "Shop By Occasion". Each item = square thumbnail + label.

**Diamond**

| Category | Style / Gender | Metal | Occasion |
|---|---|---|---|
| Earrings | Studs, Dangling, Vallies, Jhumkas, Chandeliers, Hoops, Koppu, Clip on earrings (`/clip-on-earrings`) | Yellow, White, Rose | Daily, Casual, Office, Party, Festive & Bridal |
| Rings | Gender: Women, Men, Unisex, Neliring | Yellow, Rose, White | Daily, Casual, Office, Party |
| Pendant | Single Hook, Mangalsutra, Double Hook, Men | Yellow, Rose, White | Daily, Casual, Office, Party, Festive & Bridal |
| Necklace | Necklace, Choker, Haram | Yellow, Rose, White | Party, Festive & Bridal |
| Bracelets | Gender: Men, Women | Yellow, Rose, White | Daily, Office |
| Bangles | Gender: Women | Yellow, Rose, White | Office, Party |
| Chain | Chain, Side Hunt (Mugappu) | Yellow, Rose | Office, Festive & Bridal |
| Nose Pin | Nose Fastener | Yellow, Rose | Daily |
| Watch Jewellery | Charm, Pin, Band | n/a | n/a |

(**Hair Deco / Maang Tikka was removed from the live menu** — keep the `/hair-deco` route as a legacy alias only.)

**Gemstone:** Earrings (Studs, Dangling, Jhumkha, Chandeliers, Ear lobes, Hoops · metals · 5 occasions), Rings (Men, Women · metals · Daily/Office/Party), Pendant (Single Hook, Mangalsutra, Double Hook · gender · metals · 5 occasions), Necklace (Semi Long, Choker, Haram · metals · Party/Festive), Bracelets (Women, Men · metals · Office/Party), Bangles (metals · Office/Party), Chains (Rose Gold only).

**Gold:** **Gold Promotions `/goldjewellerypromotion` (first item, single tile)** · Earrings (Chandeliers, Studs, Danglers, Vallies · Daily, Festive & Bridal), Rings (Women, Men, Children · Daily, Festive & Bridal), Bangles (Women), Chain (Men, Women, Unisex), Bracelets (Women, Men, Children), Necklace (Necklace, Haram), Pendant (Single Hook, Double Hook), **Accessories → Gold Coin `/gold-coin`**.

**Platinum:** Earrings (Danglers, Vallies, Studs), Rings (Men, Women, Unisex · metals **Platinum, Two Tone**), Pendant (Single Hook), Bracelets (Kada · Women, Men · Platinum, Two Tone), Chain (Women, Men · Two Tone).

**Solitaire:** link target **`/solitaire-collections`** (footer also exposes `/solitaire-collection-rings`, `/solitaire-collection-pendants`).
**Virtual:** Virtual Try-on, Virtual Store, Decide With Friends.
**Collections (20, live order):** Voyage of Hearts `/voyage-of-hearts`, Hope `/hope`, Glow & Go `/glow-and-go`, Tribal `/tribal`, Bandhan `/realbrides`, **Ikat `/ikat`**, Honeycomb `/honeycomb`, Bestsellers `/bestsellers`, Style Switch `/style-switch`, Promise `/mens-platinum-collection`, **Couple Band `/coupleband`**, Muse `/the-muse`, Illume `/illume`, Valentine `/valentine`, Divyadarsanam `/divyadarsanam`, Alchemist `/alchemist`, Paridhi `/paridhi`, Gemstone `/gemstone`, Divine `/divine`, Navarathiri `/navarathiri`. (Alchemist and Paridhi use a separate `Tech_Jewel/` image folder. **Removed vs old spec: Symphony, Exclusive.**)
**Gifts (4 groups):** *Gift By Occasion* → Wedding `/wedding`, Birthday `/birthday`, Anniversary `/anniversary`. *Gift For Special* → Gift for her `/gift-for-her`, Gift for him `/gift-for-him`. **Gift Card `/giftcardsforms`**. **Gold Coin `/gold-coin`**.
**By Price (INR bands, live):** Under 20K `/20k-products` · Under 30K `/30k-products` · Under 50K `/50k-products` · Above 50K `/above-50k` (image tiles `ByPrice/Under-10k.jpg`… — file names lag the labels). Keep the old USD routes (`/500-dollar-products`…) as redirects for the US locale.

### 4.3 Route map [V]

```
/                         Home
/diamond  /gold  /platinum  /gemstone  /solitaire-collections        (legacy: /solitaire-product-list)
/{metal}-{category}                    /diamond-earrings   /gold-ring   /platinum-chain
/{metal}-{category}/{facet}            /diamond-earrings/studs   /gold-chain/men   /diamond-ring/rose-gold
/{gender}-{metal}-{category}           /women-diamond-ring   /men-diamond-ring      (ring-only prefix pattern)
/gemstone/diamond-{category}[/{facet}] /gemstone/diamond-earrings/studs
/nose-pin  /nose-pin/nose-screw  /hair-deco  /hair-deco/maang-tikka  /watch-jewellery/{charms|pin|band}
/solitaire-collections  /solitaire-collection-rings  /solitaire-collection-pendants  /solitaire-product-list/{pendant|earring|ring|bracelets|bangles|necklace}
/{collection-slug}                     /hope  /honeycomb  /bestsellers  /style-switch  /illume ...
/realbrides   /gift-by-occasion  /gift-for-special  /wedding  /birthday  /anniversary  /gift-for-her  /gift-for-him
/20k-products  /30k-products  /50k-products  /above-50k            (INR bands [V]; legacy USD: /500-dollar-products /1000-dollar-products /2000-dollar-products /above-2000-dollar-products)
/virtual-tryon  /virtualstoreproduct  /co-shopping-products
/wishlist  /shopping-cart  /account  /tryinstore  /bespoke  /faq  /feedback  /contactusform
/world-of-kirtilals  /blog/country/kirtilals-india  /privacy-policy  /shipping-and-return-policy  /investors  /terms-and-conditions
/{product-slug}                        /beautiful-ring   (product page lives at the root slug)
Extra links seen in footer: /navaratna  /coupleband  /solitaire-collection-rings  /solitaire-collection-pendants  /product-list  /clp-terms
Revision-2 additions (live menu [V]): /goldjewellerypromotion  /gold-coin  /gold-accessories  /giftcardsforms  /ikat  /the-muse  /mens-platinum-collection  /clip-on-earrings  /gemstone (as collection)  /divine  /navarathiri
Legacy aliases to keep resolving: /hair-deco  /solitaire-product-list  /500-dollar-products …
```

**Routing rules the UI depends on**
1. Facet vocabulary: `yellow-gold | white-gold | rose-gold | two-tone | platinum`, `daily-wear | casual-wear | office-wear | party-wear | festive-bridal-wear`, `men | women | unisex | children`, plus style slugs (`studs, dangling, ear-lobes, jhumkha, chandeliers, hoops, koppu, single-hook, double-hook, choker, haram, mugappu, maang-tikka, nose-screw, charms, pin, band`).
2. Accept **singular and plural** category segments (`earring`/`earrings`, `ring`/`rings`, `bangle`/`bangles`).
3. Unknown slug → product lookup → else a 404 page with a search box.
4. Filter, sort and page live in the query string so refresh/back/share works.

---

## 5. Global chrome (appears on every screen)

### 5.1 Top support strip [V — Revision 2]

Slim line above the header is a **3-item USP strip**: **"Free Shipping" · "Ease Returns" · "Lifetime Buyback"** (rotating/static items from the CMS). The old "+1 732 510 0099" help line is **gone from the strip**; the help call-to-action now lives in the drawer / sign-in panel as **"NEED HELP? CALL 18001200411"** (`tel:18001200411`). Strip hidden on compact after scroll; the phone also appears in the footer (§5.8).

**Floating WhatsApp bot** [V]: bottom-corner FAB `images/homepage/whatsapp_bot.svg` → `https://wa.me/+919655200411`, shown on web only (hide inside native apps [P]).

### 5.2 Header

**Desktop / Windows (Expanded)**
```
┌────────────────────────────────────────────────────────────────────────────────┐
│ NEED HELP? CALL +1 732 510 0099                                                │
├────────────────────────────────────────────────────────────────────────────────┤
│ [LOGO]  ◆DIAMOND ◇Gemstone ●Gold ○Platinum ✦Solitaire ✿Bridal ▣Virtual …       │
│                                        🔍  👤 Name   1,250 points  ♡  👜(2)     │
└────────────────────────────────────────────────────────────────────────────────┘
        right cluster order [V]: search · sign-in/name · loyalty points · wishlist · cart(count)
```
- Logo left (`kk-logo-visible.png` equivalent: your wordmark), primary nav row with icon + uppercase label, right icon cluster.
- Hover a nav item (150 ms hover-intent) → mega-menu. Active route → copper underline.
- Signed-out: person icon + "Sign In / Sign Up"; signed-in: user name, loyalty chip "{n} points" [V], profile icon → `/account`.
- Cart bag shows a copper count badge; wishlist heart shows a dot/count when non-empty [P].
- Sticky; logo shrinks on scroll [P].

**Mobile / Tablet (Compact–Medium)**
```
┌──────────────────────────────────┐
│ ☰        [ LOGO ]       🔍   👜(2)│   (medium adds ♡)
└──────────────────────────────────┘
```
- Menu toggle (`menu-toogle.svg`) opens drawer; centred logo; search; cart badge.

### 5.3 Mega-menu panel (desktop only) [V content, P geometry]

```
┌──────────────┬─────────────────────────────────────────────────────────────────┐
│ Earrings   ▸ │  Shop By Style                                                  │
│ Rings        │  [img]Studs [img]Dangling [img]Vallies [img]Jhumkas [img]Chandeliers
│ Pendant      │  [img]Hoops [img]Koppu [img]Clip-on [img]Ear Supports           │
│ Necklace     │  Shop By Metal                                                  │
│ Bracelets    │  (●)Yellow Gold (●)White Gold (●)Rose Gold                      │
│ Bangles      │  Shop By Occasion                                               │
│ Chain        │  [img]Daily [img]Casual [img]Office [img]Party [img]Festive&Bridal
│ Nose Pin     │                                          [ All Diamond Earrings ] │
│ Hair Deco    │                                                                 │
│ Watch Jewel. │                                                                 │
└──────────────┴─────────────────────────────────────────────────────────────────┘
```
- Full-width under header; left column ≈ 240 px; right grid auto-wraps; thumbnails 56–72 px square with label beneath.
- Hovering a left category swaps the right content with no layout jump; panel max-height ≈ 70 vh, scrolls.
- Open on hover (150 ms intent), also on click/Enter; close on Esc, route change, mouse leave (200 ms grace).
- Non-category menus (Solitaire, Virtual, Collections, Gifts, By Price) render **a single tile grid** (no left column) [V structure]. Gifts renders two headed groups.
- Keyboard: Tab through top items, Enter opens, arrows move between categories, Esc closes.

### 5.4 Mobile drawer (left slide-in) [V structure]

```
┌──────────────────────────┐
│ ✕                 [LOGO] │
├──────────────────────────┤
│ ◆ Diamond              ▾ │   ← accordion rows with PNG icons
│ ● Gold                 ▾ │
│ ○ Platinum             ▾ │
│ ◇ Gemstone             ▾ │
│ ✦ Solitaire            ▾ │
│ ▣ Collections          ▾ │
│ 🎁 Gifts               ▾ │
│ ✿ Bridal Collection    › │
│ ◉ Virtual              ▾ │
│ $ By Price             ▾ │
│ ⓘ About Us             › │
└──────────────────────────┘
```
Drill-down (tapping Diamond):
```
Diamond                         [View All]
 Earrings ▾
   All Diamond Earrings
   Shop By Style
     [thumb] Studs
     [thumb] Dangling …
   Shop by Metal      …
   Shop by occasion   …
 Rings ▾ …
```
- Width ≈ 85% of screen (max 360). Backdrop dim; swipe or ✕ to close. One top-level section open at a time. Rows are thumbnail + label (list, not grid).
- Footer of drawer [P]: sign-in, phone, WhatsApp shortcuts.

### 5.5 Bottom bar (compact only) [V]

```
┌────────┬───────────┬──────────┬─────────┐
│ 🏠 Home │ 🏬 Our Store │ 🛒 Cart(n) │ 👤 Account │
└────────┴───────────┴──────────┴─────────┘
```
- Icons: `home`, `store`, `shopping_cart` (+ count badge), `person`. Active tab = copper icon + label. Hidden on PDP, checkout, search overlay, drawer open. Hidden at ≥ 768 [P].
- "Our Store" → `/tryinstore`; "Account" → `/account` (sign-in if signed out).

### 5.6 Search overlay [V content]

```
Compact (full screen)                         Expanded (top sheet, 640 px, dimmed backdrop)
┌──────────────────────────────┐              ┌──────────────────────────────────────┐
│ ←  🔍 [ Search jewellery… ]  │              │ 🔍 [ Search jewellery… ]        ✕    │
├──────────────────────────────┤              ├──────────────────────────────────────┤
│ Related Searches             │              │ Related Searches   | Related Products│
│  ↗ Studs                     │              │  ↗ Studs           | [img] Name  ₹  │
│  ↗ Diamond Earrings          │              │  ↗ Earrings        | [img] Name  ₹  │
│ Popular Searches             │              │ Popular Searches                     │
│  ↗ EARRINGS  ↗ RINGS         │              │  ↗ EARRINGS ↗ RINGS ↗ NECKLACE …     │
│  ↗ NECKLACE  ↗ PENDANTS      │              └──────────────────────────────────────┘
│  ↗ BRACELET  ↗ HOPE          │
│ Related Products             │
│  [img] Name … ₹ price        │
└──────────────────────────────┘
```
- `arrow_back` + search-icon input; list rows with `trending_up` icon [V].
- Popular Searches (fixed) → EARRINGS `/diamond-earrings`, RINGS `/diamond-ring`, **NECKALCE** `/diamond-necklace` (sic — the live label is misspelled; decide in §14 whether to replicate or fix), PENDANTS `/diamond-pendant`, BRACELET `/diamond-bracelet`, HOPE `/hope` [V].
- Typing (min 2 chars, 250 ms debounce [P]): "Related Searches" show the matching category or sub-category name; "Related Products" show live product suggestions linking to product URLs [V].
- Product suggestion rows show name and price (₹, and $ where multi-currency is on) [V: both price formats exist].
- Empty query: Popular + Recent (last 8) [P]. Enter → listing with `?search=`. Shortcut Ctrl/Cmd+K, Esc closes.

### 5.7 Mini-cart drawer [V]

```
┌──────────────────────────────────────────────┐
│ Your Mini Cart                 ( 2 Item )   ✕ │
├──────────────────────────────────────────────┤
│ [img] Product name                Qty : 1     │
│       Price ₹ 45,900                           │
│       Price $ 549                              │
│ ─────────────────────────────────────────────  │
│ COUPON                                         │
│ ┌ HOPE500 ───────────────────────── [Apply] ┐ │
│ │ Add ₹4,100 more to get a flat ₹500 off…   │ │   ← needs-more state (+ progress bar [P])
│ │ You've unlocked a flat ₹500 off on this order! │ ← eligible state
│ │ You've saved ₹500 on this order.   [Remove]│ │   ← applied state
│ └────────────────────────────────────────────┘ │
│ View all coupons ▼   (accordion of other codes) │
│ ─────────────────────────────────────────────  │
│ Sub Total (before tax)        ₹ 91,800         │
│ Coupon                        − ₹ 500          │
│ Tax                           ₹ 2,754          │
│ Grand Total                   ₹ 94,054         │
│ Sub Total $                   $ 1,098          │
│ [   View Cart   ]  [  Quick Checkout  ]        │
└──────────────────────────────────────────────┘
```
- Right drawer 420 px (Expanded), 90% bottom sheet (Compact). Opens from the cart icon; auto-opens after Add to Cart on desktop, on mobile show a toast + badge pulse [P].
- Three coupon states exactly as above; **View Cart** = secondary button, **Quick Checkout** = primary [V].
- Both ₹ and $ lines appear on each item, plus "Sub Total $" [V]; hide $ lines when single-currency.

### 5.8 Footer [V content]

```
Expanded (6 zones)
┌───────────────────────────────────────────────────────────────────────────────┐
│ Our Popular Searches                                                          │
│  Earrings – Diamond Earrings | Koppu | Studs | Danglers | Jhumkas             │
│  Rings – Solitaire Collection | Men's Rings | Ring        … (10 groups)       │
├───────────────┬────────────────┬────────────────────┬──────────┬────────────────────────┤
│ About Us      │ Customer Delight│ Policies           │ Services │ Join our email list    │
│ About Kirtilals│ Contact Us     │ Privacy Policy     │ Bespoke, │ "Please sign me up to  │
│ Blog (…-india)│ 18001200411    │ Shipping & Returns │ Try in   │  receive information   │
│ F.A.Q.        │ WhatsApp ×2    │ Investors          │ Store    │  about new designs and │
│ Give Feedback │ Enquiry@online-│ Terms of Service   │          │  exclusive … events."  │
│               │  kirtilals.com │ **CLP Terms & Cond.**│         │ [email] [SUBSCRIBE]     │
│               │                │                    │          │ ◉ FB ◉ IG ◉ YT ◉ Pin    │
│               │                │                    │          │ "Shining new app, made  │
│               │                │                    │          │  just for you! …"       │
│               │                │                    │          │ [Google Play][App Store]│
├───────────────┴────────────────┴────────────────────┴──────────┴────────────────────────┤
│ © KIRTILAL KALIDAS JEWELLERS PVT. LTD.                                                   │
└───────────────────────────────────────────────────────────────────────────────┘
```
- Verified contact targets [V]: `tel:18001200411`, `wa.me/+919894840711`, `wa.me/+919655200411`, `mailto:Enquiry@online-kirtilals.com`. Blog → `/blog/country/kirtilals-india`.
- Policies now include **CLP Terms & Conditions `/clp-terms`** (loyalty programme) [V].
- Popular-searches groups [V]: Earrings, Rings, Necklace, Chain, Pendant, Nose Pin, Bangles, Bracelets, Gemstone/Material, Collections; links separated by " | ". Verified highlights: Solitaire Collection `/solitaire-collection-rings`, Men's Rings `/men-diamond-ring`, Mangalsutra `/diamond-pendant-mangalsutra`, Haram `/gold-necklace/haram`, Mugappu `/diamond-chain/mugappu`, Navaratna `/navaratna`, Divyadarsanam `/divyadarsanam`, Couple Band `/coupleband`.
- App block [V]: heading "Download Our App", copy "Shining new app, made just for you! It's Free, Easy & Smart.", badges → Play Store `com.kirtilals.promoapp`, App Store `id1542775915`. **Hide the whole app block inside the native apps.**
- Compact: each column becomes a collapsible accordion; newsletter and social stay expanded; app badges shown only on web, hidden inside the native apps [P].
- Newsletter: single email field, consent sentence (about new designs and exclusive events) [V], SUBSCRIBE button; validates email, shows success/error inline.
- Two badge image variants exist (`google_play_store.png` / `…2.png`) [V], suggesting separate light/dark footer renderings [P].
- **Cookie banner** [V]: bottom strip "We use cookies to optimise your visits. By continuing to browse our site you are accepting our cookie policy." with ✕; dismissal persisted.

---

## 6. Home

**Verified:** header, nav, footer, bottom bar, floating WhatsApp FAB, and an SEO text block: H1 **"Online Diamond Jewellery Store"** + intro paragraphs, then H3s **Diamond Pendants · Diamond Rings · Diamond Necklaces · Diamond Earrings · Diamond Bracelets** (each with body copy linking to the category route) [V].
**Section order below is [P] / [?]**: confirm with a home-page screenshot. Everything is driven by an ordered "home layout" list so sections can be reordered or hidden without redesign.

### 6.1 Section stack (top → bottom)

| # | Section | Compact | Expanded | Tag |
|---|---|---|---|---|
| 1 | **Hero carousel** | 4:5, swipe, dots | ≈ 560 px tall, arrows + dots, 5 s auto-advance, pause on hover | [P] |
| 2 | **Shop by Category** | Horizontal scroll, 72 px circular tiles, 4.5 visible | 8 tiles in one row, 120 px | [P] |
| 3 | **Shop by Metal** | 3 swatch tiles (Yellow / White / Rose) | Same, larger | [P] |
| 4 | **Collections rail** | Horizontal scroll of the 20 collection tiles | 6–7 visible, arrows | [V content] |
| 5 | **Bestsellers rail** | Product cards 160 px wide, "View all" → `/bestsellers` | 260 px cards, 4–5 visible | [V route] |
| 6 | **New Arrivals rail** | Same | Same | [P] |
| 7 | **Shop by Occasion** | 2-col horizontal scroll | 5 tiles in a row (Daily, Casual, Office, Party, Festive & Bridal) | [V content] |
| 8 | **Shop by Price** | 2×2 tiles | 4 in a row (Below $500 / $1000 / $2000 / Above $2000; ₹ variant for India) | [V content] |
| 9 | **Bridal banner (Bandhan)** | Full-width image + CTA | Wide split banner | [V route] |
| 10 | **Services strip** | 2×2 cards | 4 cards: Virtual Try-on · Try in Store · Bespoke · Decide With Friends | [V routes] |
| 11 | **Trust bar** | 2×2 icons | 4 in a row (certified diamonds, exchange, shipping, returns) | [P] |
| 12 | **Gift for Her / Him** | Stacked | Side-by-side split banners | [V routes] |
| 13 | **Social strip** (optional) | Horizontal | 6-up grid | [P] |
| 14 | **About-collection text** | Collapsed accordion | Expandable paragraph, H1 + 5 H3 sections | [V structure] |
| 15 | **Footer** | §5.8 | §5.8 | [V] |

> **Revision (live mobile):** on the real site the circular **Shop by Category row sits above the hero** (the home-page template closes the category row, then opens `#ss_home_banner`) — though the live site reverts to hero-first in narrow layouts. In the app the **category row leads at every width**, with the hero second.

### 6.2 Wireframe (Expanded)
```
[ Support strip ]
[ Header + nav ]
┌───────────────────────────────────────────────────────────────┐
│  HERO  (eyebrow • serif headline • [ SHOP NOW ])      ‹  ●○○○ ›│
└───────────────────────────────────────────────────────────────┘
        SHOP BY CATEGORY
 (○)Earrings (○)Rings (○)Pendant (○)Necklace (○)Bracelets (○)Bangles (○)Chain (○)Nose Pin
        SHOP BY METAL     [Yellow] [White] [Rose]
        COLLECTIONS  ‹ [Voyage][Hope][Glow&Go][Tribal][Bandhan]… ›
        BESTSELLERS                                   View all →
 ‹ [card][card][card][card][card] ›
 …
```

### 6.3 Behaviour
- Skeletons render first (minimum ≈ 300 ms to avoid flicker), then content.
- Every tile/banner navigates to a valid route from §4.3.
- Hero: swipe on touch; pause on hover/focus; respects reduce-motion; first image preloaded.
- Section title style: small uppercase eyebrow + serif title + optional "View all" text link.

---

## 7. Listing pages (PLP) and landing pages

One reusable listing screen serves every route in §4.3: metal pages, category pages, facet pages, collections, gifts, price pages, search results, solitaire list.

### 7.1 Layout

```
Expanded (≥1200)
┌───────────────────────────────────────────────────────────────────────────┐
│ Home / Diamond / Earrings / Studs                                          │
│ Diamond Studs Earrings                          124 designs                │
│ (○Studs)(○Dangling)(○Vallies)(○Jhumkas)(○Hoops) …  ← sub-category chips    │
├───────────────┬───────────────────────────────────────────────────────────┤
│ FILTERS       │ Active: [Yellow Gold ✕][Under ₹50k ✕]  Clear all           │
│ Price ▬●━━●▬  │ Sort: Featured ▾        View: ▦ 3 ▦ 4 ▦ 5                  │
│ Metal ◉◉◉     │ ┌────┐ ┌────┐ ┌────┐ ┌────┐                               │
│ Style ☐☐☐     │ │card│ │card│ │card│ │card│                               │
│ Occasion ☐☐   │ └────┘ └────┘ └────┘ └────┘                               │
│ Gender ☐☐     │            [ LOAD MORE ]                                   │
│ Purity ☐☐     │                                                            │
│ Carat ▬●━━●▬  │  About this collection ▾                                   │
└───────────────┴───────────────────────────────────────────────────────────┘

Compact
┌──────────────────────────┐
│ ← Diamond Earrings   🔍 👜│
│ 124 designs               │
│ (Studs)(Dangling)(Hoops)→ │  ← horizontal chips
│ [ Filter ]    [ Sort ▾ ]  │  ← sticky toolbar
│ ┌──────┐ ┌──────┐         │
│ │ card │ │ card │  2 col   │
│ └──────┘ └──────┘         │
└──────────────────────────┘
```

- **Header block:** breadcrumb, serif H1 from the route label, result count, optional collapsed description, sub-category thumbnail chips (from the §4.2 groups for that category).
- **Filters [P]:** Price (range, ₹ / $), Metal (swatches), Style, Occasion, Gender, Purity (14K/18K/22K/PT950), Diamond carat, Availability, Delivery time, Collection.
- **Filter placement:** left sidebar (Expanded); full-screen sheet from bottom (Compact) with "Apply (n results)" and "Clear"; right drawer 420 px (Medium).
- **Sort [P]:** Featured, Newest, Price low→high, Price high→low, Best sellers, Discount.
- **Grid:** 2 / 3 / 4 / 5 columns by breakpoint; gap 12 / 16 / 24; density toggle on desktop.
- **Pagination:** infinite scroll with "Load more" fallback, page size 24, scroll position preserved on back.
- **Active-filter chips** with × and "Clear all".

### 7.2 Product card

```
┌─────────────────────┐
│ [NEW]            ♡  │   badge top-left, wishlist top-right
│     image 1:1/4:5   │   hover: 2nd image crossfade + [Quick view]
├─────────────────────┤
│ Product name (2 ln) │
│ ₹ 45,900  ̶₹̶ ̶5̶2̶,̶0̶0̶0̶  12% off │   Wrap, never overflow
│ ($ 549)             │   multi-currency only
│ ● ● ●  metal dots   │
└─────────────────────┘
```
- States: default · hover (lift + second image + quick view) · wishlisted (filled copper heart, 150 ms pop) · out of stock (greyed + label) · loading skeleton.
- Badges: NEW, BESTSELLER, −x% (copper fill, white label).
- Touch: no auto-sliding image on mobile (manual swipe only). If prices are hidden by business rule → "Contact for Price".
- Quick view (desktop): dialog with gallery, price, metal/size selectors, Add to Cart.

### 7.3 Variants of the listing screen

| Page | Differences |
|---|---|
| **Metal page** (`/diamond`, `/gold`, `/platinum`, `/gemstone`) | Hero banner + category tile grid first, then "All designs" grid |
| **Category / facet page** | As §7.1 |
| **Collection page** (`/hope`…) | Full-bleed hero (image + serif title + 2-line text) → sticky category sub-nav (All / Earrings / Rings…) → grid scoped to that collection |
| **Solitaire** | Flat tile row of 6 categories above the grid; no metal filters |
| **Gift hubs** (`/gift-by-occasion`, `/gift-for-special`) | Tile grid (Wedding/Birthday/Anniversary or Her/Him) → listing |
| **Bridal** (`/realbrides`) | Editorial: hero, "Real brides" masonry gallery, shop-the-look carousel [P] |
| **By Price** | Listing with a preset price range; band labels in $ or ₹ by locale |
| **Search results** | Header "Results for 'x'" and the same grid/filters |
| **Empty result** | Illustration, "No designs match", chips to remove filters, link to bestsellers |

---

## 8. Product detail page (PDP)

**[?] Not verifiable from source.** The layout below is the standard for premium jewellery and should be checked against a PDP screenshot (the product pages live at the root slug, e.g. `/beautiful-ring`).

### 8.1 Expanded (two columns ≈ 58 / 42)

```
┌──────────────────────────────────────────────────────────────────────────┐
│ Home / Diamond / Rings / Product name                                     │
├───────────────────────────────────────┬──────────────────────────────────┤
│ ┌──┐ ┌──────────────────────────────┐ │ Product name (serif 28)   ♡  ⤴   │
│ │▢ │ │                              │ │ SKU ABC123                       │
│ │▢ │ │       main image             │ │ ₹ 45,900  ̶₹̶ ̶5̶2̶,̶0̶0̶0̶  12% off   │
│ │▢ │ │   hover zoom / click → full  │ │ (Inclusive of all taxes)  $ 549  │
│ │▢ │ │                              │ │ Metal  (●Yellow)(●White)(●Rose)  │
│ │▢ │ └──────────────────────────────┘ │ Purity [14K][18K]                │
│ └──┘  [ Images | Video | 360° ]       │ Size   [12][13][14]…  Size guide │
│                                       │ Pincode [______] [Check]         │
│                                       │ Delivery by Tue, 14 Oct          │
│                                       │ [   ADD TO CART   ] (copper)     │
│                                       │ [   BUY NOW       ] (outline)    │
│                                       │ Try at Home · Try in Store       │
│                                       │ ◈ Offers: Flat ₹500 off …        │
│                                       │ ✓ Certified ✓ Exchange ✓ Shipping│
├───────────────────────────────────────┴──────────────────────────────────┤
│ ▾ Product Details  ▾ Price Breakup  ▾ Diamond Details  ▾ Gold Details    │
│ ▾ Certification    ▾ Shipping & Returns   ▾ Care                          │
├──────────────────────────────────────────────────────────────────────────┤
│ You may also like  ‹ rail ›      Recently viewed ‹ rail ›   Complete the look │
└──────────────────────────────────────────────────────────────────────────┘
```
- Left: vertical thumbnail rail (6–8), large image with hover zoom; click → full-screen viewer with pinch/scroll zoom. Wishlist and share overlay on image.
- Right column is **sticky** while the left scrolls.
- Selecting metal / purity / size updates **price, price breakup, gallery and SKU** immediately.
- Add to Cart disabled until required size is chosen (rings, bangles, bracelets); tapping shows "Select a size".
- Price breakup table rows [P]: Gold value, Diamond value, Making charges, GST, **Total**.
- Specs accordions [P]: diamond carat/clarity/colour/count; gold purity, net/gross weight; certification; shipping & returns; care.

### 8.2 Compact
```
┌──────────────────────────┐
│ ←                  ⤴  ♡  │
│  swipe gallery  ● ○ ○ ○  │  (counter 1/6)
│ Name                     │
│ ₹ 45,900  ̶5̶2̶,̶0̶0̶0̶  12% off│
│ Metal (●)(●)(●)          │
│ Purity [14K][18K]        │
│ Size [..][..]  Size guide│
│ Pincode [____][Check]    │
│ ▾ Product Details        │
│ ▾ Price Breakup …        │
│ You may also like ‹ › │
├──────────────────────────┤
│ [Add to Cart] [Buy Now]  │  ← sticky bar above home indicator; bottom nav hidden
└──────────────────────────┘
```

### 8.3 Interactions and states
- Gallery: swipe (touch), arrows/thumbnail click (desktop), double-tap or scroll-wheel zoom; video/360° tabs only when available.
- Variant change cross-fades the main image; unavailable combinations are disabled with a tooltip.
- Out of stock: replace CTAs with "Notify me" / "Enquire".
- Share → native share sheet (iOS/Android) or copy-link (desktop).
- Optional wholesale overlays (weights, making charge, MOQ, enquire) are shown only when the matching visibility switch is on (§11.3).

---

## 9. Commerce flow screens

### 9.1 Wishlist (`/wishlist`) [V route, P layout]
- Same card grid as the listing, each card gains **Move to cart** and a remove ✕.
- Header: "My Wishlist (n)", "Share wishlist" [P], "Continue shopping".
- Empty: heart illustration, serif title, CTA to bestsellers.
- Guest wishlist stored locally and merged on sign-in. Header heart shows a dot when non-empty.

### 9.2 Cart page (`/shopping-cart`) [V route, P layout]
```
Expanded                                          Compact
┌──────────────────────────────┬───────────────┐  ┌──────────────────────────┐
│ Shopping Cart (2)            │ ORDER SUMMARY │  │ Shopping Cart (2)        │
│ [img] Name  SKU  chips       │ Sub Total     │  │ [img] Name  chips        │
│  metal·purity·size  [−1+]    │ Coupon        │  │  [−1+]  ₹  🗑 ♡ Move     │
│  ₹ price      🗑  ♡ Move     │ Tax           │  │ Coupon block (as mini)   │
│ …                            │ Grand Total   │  │ Summary                  │
│ Gift wrap ☐  + note          │ [ CHECKOUT ]  │  ├──────────────────────────┤
│ Pincode / delivery ETA       │ Coupon block  │  │ [ Proceed to Checkout ]  │ sticky
└──────────────────────────────┴───────────────┘  └──────────────────────────┘
```
- Left 65% items, right sticky summary. Coupon block identical to the mini-cart (3 states, "View all coupons").
- Per line: image, name, SKU, metal/purity/size chips, qty stepper (max stock), price (₹ + $ if enabled), remove, move to wishlist.
- Empty cart: illustration, "Your cart is empty", recommendations rail.

### 9.3 Checkout (entry "Quick Checkout" [V]; steps [P])
Steps: **1 Sign in / Guest → 2 Address → 3 Delivery → 4 Payment → 5 Review & Place**.
- Expanded: accordion steps on the left, order summary right (sticky). Compact: one step per screen with a progress stepper, summary collapsible at the top.
- Address: saved address cards, "Add new" form (name, phone, pincode → auto city/state, address lines, type Home/Work), optional GST number.
- Payment: UPI, Card, Net Banking, COD; wallet buttons per platform (Apple Pay on iOS [P], Google Pay on Android [P]).
- Review: items, address, delivery date, totals, **PLACE ORDER** primary button.
- Success page: check mark (no confetti), order id, ETA, "Track order", "Continue shopping".
- Inline validation under each field; errors never clear typed data.

---

## 10. Account, services and content screens

### 10.1 Sign in / Sign up [V entry point, P layout]
- Entry: person icon (header) / Account tab (bottom bar). Signed-in header shows the user name [V].
- Expanded: modal (≈ 440 px). Compact: full screen. Tabs "Sign In | Sign Up".
- Methods: phone or email + OTP; Google; Sign in with Apple (iOS) [P]. Guest checkout allowed.
- Fields have clear labels, OTP boxes auto-advance and support paste/autofill.

### 10.2 Account (`/account`) [V route, P layout]
- Menu (left on Expanded, list on Compact): **My Profile · My Orders · Addresses · Wishlist · Loyalty Points · Coupons · Notifications · Help · Sign out**.
- Loyalty (CLP) [V header chip "{n} points"]: balance card, earn/redeem ledger, redeem at checkout.
- Coupons: list of codes with state chips (eligible / needs more / applied) mirroring the mini-cart.

### 10.3 Orders
- List: order cards (thumbnail strip, id, date, total, status chip: copper = in progress, green = delivered, red = cancelled).
- Detail: vertical timeline (Placed → Confirmed → Packed → Shipped → Out for delivery → Delivered), items, address, payment, **Download invoice**, **Reorder**, **Return / Exchange** (within a configurable window), support contact.

### 10.4 Our Store / Try in Store (`/tryinstore`) [V route, P layout]
- Store list + map (Expanded: list left, map right; Compact: toggle List/Map). Card: name, address, hours, phone, Directions.
- "Book appointment" form: name, phone, date, time slot, products to try; success state with confirmation.

### 10.5 Bespoke (`/bespoke`) [V route, P layout]
Hero → 4-step process (Share idea → Design → Approve → Craft) → enquiry form with reference-image upload → success state.

### 10.6 Virtual (`/virtual-tryon`, `/virtualstoreproduct`, `/co-shopping-products`) [V routes, ? behaviour]
- **Try-on:** live camera (or upload-a-photo fallback) with jewellery overlay, capture and share.
- **Virtual Store:** embedded 360° walkthrough or hotspot panorama.
- **Decide With Friends:** shared shortlist link; friends react ❤ / 👎 and comment.
- If not yet built, show a designed "Coming soon" page with the same hero style.

### 10.7 Content pages
About (`/world-of-kirtilals`), Blog (list + article), FAQ (accordion), Feedback (rating + message), Contact (form + tel/WhatsApp/email actions), Privacy, Shipping & Returns, Investors, Terms. Layout: narrow reading column (≈ 760 px), serif H1, generous line-height; legal text is your own.

### 10.8 404 / route not found
Serif "We couldn't find that page", search box, links to Diamond / Gold / Collections.

---

## 11. Cross-cutting UI behaviour

### 11.1 State matrix (every data-driven screen)

| State | Presentation |
|---|---|
| Loading | Skeleton of the exact layout (cards, rails, PDP, cart) |
| Empty | Illustration + serif title + one CTA (cart, wishlist, orders, search, filtered list) |
| Error | Inline banner with Retry; full-screen version for page-level failures |
| Offline | Persistent top banner "You're offline"; cached content stays visible |
| Partial | Section-level error without blocking the rest of the page |

### 11.2 Feedback and forms
- Toasts: bottom (compact) / bottom-left (expanded), 3 s; success copper-neutral, error red.
- Dialogs: confirm remove / clear cart / sign out; max width 400–600.
- Forms: labels above fields, inline validation on blur, errors in `state.danger`, primary action disabled only while submitting (with spinner).

### 11.3 Visibility switches (so one UI covers public and wholesale use)
`guestBrowse`, `showPrices` (off → "Contact for Price"), `coupons`, `loyalty`, `multiCurrency` (off → hide all $ lines), `virtualTryOn`, `screenshotProtection`, `watermark`. Each switch only hides or shows UI elements already defined above.

### 11.4 Motion
Drawer/sheet slide 250 ms; mega-menu fade+8 px slide 150 ms; carousel crossfade 400 ms; wishlist heart pop 150 ms; cart badge pulse on add; skeleton shimmer 1.2 s loop. All disabled under reduce-motion.

### 11.5 Accessibility
- Semantics label on every icon-only control; focus ring in copper on all interactive elements; logical tab order through header → main → footer.
- Contrast: white text on `#C87F44` only for large/bold button labels; small copper text uses the darker shade (§2.1).
- Touch targets ≥ 44×44 (iOS) / 48×48 (Android); hit areas extend beyond icon bounds.
- Dynamic Type / system font scaling up to 200% without clipping (price rows wrap).
- Screen readers: announce cart count changes and coupon state changes.

### 11.6 Localisation and currency [V basis — Revision 2]
- **India-first now** [V]: blog path `/blog/country/kirtilals-india`, "By Price" bands are INR (§4.2), helpline is `18001200411`, WhatsApp numbers are +91. Keep a region switch so a US/USD locale can still be served (old USD price-band routes remain as redirects).
- Primary currency ₹ with Indian digit grouping (₹ 45,900 → lakh/crore style where applicable); secondary $ shown as additional lines in mini-cart, line items and search suggestions [V: `price` and `usa_price` fields both rendered].
- Phone numbers rendered as tap-to-call; WhatsApp links use the `wa.me` pattern [V] (`+919655200411` bot, `+919894840711` support).

---

## 12. Platform-specific rendering details

### 12.1 iOS app
| Concern | Rendering |
|---|---|
| Navigation | Bottom bar (Home · Our Store · Cart · Account) + drawer from the menu button; **edge swipe back** on all pushed screens |
| Safe areas | Respect notch / Dynamic Island and home indicator; PDP buy bar above indicator |
| Sheets | Native-style bottom sheets with grabber for filters, size guide, mini-cart, coupons |
| Haptics | Light impact on add-to-cart, wishlist toggle, successful coupon apply |
| Share | Native share sheet for product and wishlist |
| Auth | Sign in with Apple alongside any other social login |
| Payments | Apple Pay button on checkout [P] |
| Text | San Francisco for UI fallback; brand serif for headlines; Dynamic Type |
| Permissions | Camera (try-on), notifications, photos (bespoke upload) — prompt with context, never on launch |
| Orientation | Portrait on phone; both on iPad (iPad uses Expanded layout) |

### 12.2 Android app
Material back behaviour (back closes overlay → pops screen → exits); status bar tinted white with dark icons; bottom bar identical; ripple only on list rows; runtime permissions with rationale; Google sign-in / Google Pay.

### 12.3 Windows app
| Concern | Rendering |
|---|---|
| Window | Resizable, min ≈ 360×640 [P], remembers size/position; 100–250% DPI scaling |
| Title bar | System or custom with brand logo; window controls untouched |
| Layout | Expanded shell; mega-menu hover; no bottom bar |
| Input | Mouse hover states, scroll-wheel zoom on PDP, right-click suppressed on product images when protection is on, Ctrl+K search, Esc close, Tab focus rings, Enter submit |
| Scrollbars | Always visible, styled thin copper-grey |
| Notifications | Windows toast for order status [P] |
| Accessibility | High-contrast theme support, Narrator labels, keyboard-only operation |
| Distribution | Installer package (MSIX) [P] |

### 12.4 Desktop / mobile web
Path-style URLs matching §4.3, per-page title and meta, deep links for every route, cookie banner, store badges visible (hidden inside native apps), lazy-loaded rails, images ≤ 1200 px, responsive `srcset` [P].

---

## 13. Asset inventory (naming mirrors the live site [V])

| Group | Pattern on live site | You supply |
|---|---|---|
| Logo | `kk-logo-visible.png` (+ white variant for drawer) | Your wordmark: colour + white SVG |
| Header icons | `menu-toogle.svg`, `search.svg`, `user_signin.svg`, `product-wishlist.svg`, `md_close_icon.png` | Your 20–24 px SVG set |
| Top-nav pictograms | `navbar_icon/{diamond_icons, gemstone_icons, gold_icon, platinum_icons, solitaire_icons, Bandhan_11, white_bandhan_11, virtual_icon, Collections_1, gifts_icon, price_icons, About-Us_2}.png` (old name `Dollars1.png` retired) | 12 pictograms (colour + white) |
| Metal swatches | `menu_icon/SBM/{Yellow, White, Rose, Two-Tone}.png` | 4 swatch images |
| Menu thumbnails | `menu_icon/{Diamond\|Gemstone\|Gold\|Platinum}/{Earings\|Rings\|Pendants\|Necklaces\|Bracelets\|Bangle\|Chains\|NosePins\|watches}/{SBS\|SBG\|SBO}/*.jpg` | ≈ 150 square thumbnails (style/gender/occasion × category × metal family) |
| Solitaire tiles | `menu_icon/Solitaires/*.jpg` (6) | 6 tiles |
| Virtual tiles | `menu_icon/Virtual/*.jpg` (3) | 3 tiles |
| Collection tiles | `menu_icon/Collections/*.jpg`, `menu_icon/Tech_Jewel/*.jpg` (20; new: `Ikat.jpg`, `CB.jpg`, `The-Muse.jpg`) | 20 tiles |
| Gift tiles | `menu_icon/Gifts/*.jpg` (6; new `Gift-Cards.jpg`) | 6 tiles |
| By-Price tiles | `menu_icon/ByPrice/*.jpg` (4, INR labels) | 4 tiles (₹ bands) |
| Floating WhatsApp | `homepage/whatsapp_bot.svg` | your support FAB SVG |
| Social | `Facebook.svg`, `IG.svg`, `YouTube.svg`, `Pint.svg` | 4 SVGs |
| Store badges | `google_play_store(2).png`, `google_app_store(2).png` | Official badges |
| Hero / banners / product photography | [?] not in fetched markup | Your own, sized per §2.5 |

---

## 14. Capture Checklist (to reach a true pixel-exact match)

Send these and every [P]/[?] above can be replaced with exact values.

**Screenshots (full-page, signed-out and signed-in where noted)**
1. Home at 390 px and 1440 px (scroll fully, send in slices).
2. A listing page (e.g. `/diamond-earrings`) at 390 and 1440, with filter panel open, sort open.
3. A product page at 390 and 1440, including price breakup and tabs.
4. Cart, mini-cart (with a coupon in each of the 3 states), checkout steps, account, orders, wishlist, sign-in.
5. Desktop mega-menu open on Diamond → Earrings and on Collections.
6. Mobile drawer open and expanded one level.
7. **The native iOS and Android app:** onboarding, home, listing, PDP, cart, account (the apps may differ from the website).

**DevTools values (Chrome → Elements → Computed)**
- `font-family`, `font-size`, `font-weight`, `letter-spacing` of: nav label, H1, H2, body, product name, price, MRP, button.
- `background-color`, `color`, `border`, `border-radius`, `padding`, `box-shadow` of: header, primary button, secondary button, product card, badge, input, drawer, footer.
- Header height, mega-menu width, drawer width, mini-cart width, card gap, grid column count at 390 / 768 / 1024 / 1440.
- The page's `:root` CSS variables if present.

**Decisions I need from you**
1. Your brand name and logo (the clone must not reuse the original's).
2. Public store (prices visible) or wholesale/private (login, hidden prices), or both via the §11.3 switches.
3. India only, or USD / international at launch (live site is now India-first with dual ₹/$ rendering).
4. Whether the 20 collections and 150 menu thumbnails will use your own catalogue.
5. Replicate the live site's quirks or fix them: "NECKALCE" label, `Earings`/`Chandliers` image folder typos, `Under-10k.jpg` file used for the "Under 20K" tile.
6. Keep legacy routes (`/hair-deco`, `/solitaire-product-list`, USD price bands) as redirects, or drop them.
7. Your support numbers for the strip/drawer/footer (live: 18001200411 · WhatsApp 9655200411 / 9894840711).

---

## 15. Build order and acceptance (UI only)

> **Repo-mapped version of this table (file paths, phases, per-platform matrix): §16.**

| Phase | Deliver | Done when |
|---|---|---|
| 1 | Tokens (§2), layout system (§3), component library (§2.6) with all states | Every component renders in light theme at 4 widths |
| 2 | Chrome (§5): header, mega-menu, drawer, bottom bar, search, mini-cart, footer, cookie | Every nav link in §4.2 routes; keyboard path works; no overflow 320→1920 |
| 3 | Listing + product card (§7) | All route patterns in §4.3 resolve to a filtered grid or a designed empty state |
| 4 | PDP (§8) | Variant change updates price, breakup, gallery; sticky bar on compact |
| 5 | Home (§6) | Sections reorderable; skeleton → content; all tiles navigate |
| 6 | Wishlist, cart, checkout (§9) | Coupon three-state works; order success reached |
| 7 | Account, orders, services, content (§10) | All footer links open real pages; forms validate |
| 8 | Platform polish (§12) + accessibility (§11.5) | iOS swipe-back, Android back, Windows shortcuts, high-contrast pass |
| 9 | Virtual try-on / store / co-shopping | Behind switch; "Coming soon" until built |

**Cross-platform acceptance checks:** render at 320×568, 390×844, 768×1024, 1280×800, 1440×900, 1920×1080; no horizontal page scroll; header/footer full-bleed with capped content; price rows wrap at 320; every async region has loading/empty/error; contrast ≥ 4.5:1 for body text; keyboard-only completion of search → PDP → add to cart → checkout.

---

## 16. Implementation plan mapped to this repo (`ecommerce_app`)

This section turns §15 into a file-level plan against the code that exists today. One Flutter codebase ships all four targets (Android, iOS, Web, Windows) — per-platform differences are handled by the responsive classes in §1.1 plus platform checks, not by separate apps.

### 16.1 Reality check — what already exists vs. what is net-new

| Capability (section) | Status in `ecommerce_app` | Where |
|---|---|---|
| Breakpoints / device classes (§1.1, §3.1) | **Done (Phase 0)** — compact/medium/expanded/wide, content caps | `common_widgets/lib/core/responsive.dart` |
| Design tokens & theme (§2) | **Done (Phase 0)** — copper `#C87F44` palette + full §2.1 token set | `common_widgets/lib/core/design_tokens.dart`, `core/theme.dart`, `ecommerce_app/lib/core/business_config.dart` |
| Runtime brand config (§11.3 switches) | Exists | `lib/core/business_config.dart` |
| Customer shell: header + bottom bar (§5.2, §5.5) | **Done (Phase 1)** — 4-item bar **Home · Our Store · Cart(n) · Account** | `lib/features/main_screen.dart` |
| Home sections (§6) | **Done (Phase 4)** — ordered `home_layout` list, all 15 §6.1 sections, skeleton→content handover | `lib/features/home/home_layout.dart`, `home_sections.dart`, `home_skeleton.dart` |
| Listing / PLP (§7) | **Done (Phase 5)** — shared `ListingView`: §7.3 scope (breadcrumb + serif H1 + sub-chips) for every §4.3 shop path, business category chips + search on `/catalogue`, filters (price / in-stock / purity / metal) + 6 sorts, FILTERS sidebar ≥1200 / "Refine collection" dialog 600–1199 / bottom sheet <600, 3/4/5-col density + grid/list toggle, 24-per-page LOAD MORE, empty state → bestsellers, `metal` query param | `lib/features/catalogue/listing_view.dart`, `filter_panel.dart`, `route_scope.dart`, `screens/catalogue_screen.dart`, `lib/features/shell/section_screen.dart` |
| PDP (§8) | **Done (Phase 6)** — variant→price/SKU/gallery + purity, price breakup, pincode, 8 accordions, related/viewed rails, sticky buy bar (inline CTAs on desktop); rotation gallery is a demo derivation [P] | `lib/features/product/screens/product_detail_screen.dart`, `lib/core/pricing.dart` |
| Cart / Checkout / Wishlist / Orders / Account (§9–§10) | **All Done (Phases 7–8)** — cart 65/35 with sticky ORDER SUMMARY + coupon block identical to the mini-cart, gift wrap, per-line SKU/chips/move-to-wishlist/stepper; 5-step checkout (guest→address→delivery→payment→review) with desktop accordion + compact stepper, empty bag redirects to `/cart`, success page `/order-success/:id`; wishlist "My Wishlist (n)" + Move to cart; orders list + timeline order detail with invoice/reorder/return/support actions; profile menu §10.2 → addresses, loyalty (demo 1250 pts), coupons | `lib/features/{cart,checkout,wishlist,orders,profile}/…`, `lib/features/cart/widgets/{coupon_section,order_summary}.dart`, `lib/features/checkout/order_success_screen.dart` |
| Router (§4.3 path scheme) | **Done (Phase 2)** — §4.3 jewellery paths + legacy aliases | `lib/core/router/app_router.dart` |
| Shared widgets | Partial kit: skeleton, product carousel, category carousel, app buttons/cards/dialogs; `navigation_shell.dart` and `app_bar.dart` are **built but unused** | `common_widgets/lib/widgets/…` |
| Targets android / ios / web / windows | **All present** | `ecommerce_app/{android,ios,web,windows}/` |
| **Net-new:** mega-menu, drawer, search overlay, mini-cart, footer, cookie banner, WhatsApp FAB, top USP strip, filter sidebar, SEO block, 404, content pages (about/blog/faq/feedback/contact/legal), bespoke, try-in-store, virtual showrooms | **Built (Phases 1–10)** — every §5.8 footer link opens a designed SectionScreen body; virtual try-on / store / co-shopping run local demos behind the `virtualTryOn` rule and show coming-soon heroes while it is off | see §16.2 |
| Platform polish (§12/§16.4) + accessibility (§11.5) | **Done (Phase 9)** — iOS edge-swipe back, Android system back + Escape, Ctrl/Cmd+K, keyboard-only search→card→bag→checkout walk, 44 px targets, live-region cart/coupon announcements, copper focus ring, §2.6.1 contrast, 200 % text with no clipping | `test/platform_polish_test.dart` (11 checks), `app_header.dart`, `bottom_bar.dart`, `product_card.dart`, `product_detail_screen.dart`, `coupon_tile.dart`, `mini_cart_drawer.dart`, `keyboard_hooks.dart`, `common_widgets/lib/{core/theme.dart,widgets/category_carousel.dart}` |

### 16.2 Net-new files (create in this order)

```
lib/core/navigation/menu_data.dart          # §4.1/§4.2 verified nav tree as data (order, icons, routes)
lib/core/navigation/route_aliases.dart      # legacy: /hair-deco, /solitaire-product-list, USD price bands
lib/features/shell/top_strip.dart           # Free Shipping · Ease Returns · Lifetime Buyback (§5.1)
lib/features/shell/app_header.dart          # compact + expanded variants (§5.2)
lib/features/shell/mega_menu_panel.dart     # desktop hover panel (§5.3)
lib/features/shell/nav_drawer.dart          # left drawer + drill-down (§5.4)
lib/features/shell/bottom_bar.dart          # Home · Our Store · Cart · Account (§5.5)
lib/features/shell/site_footer.dart         # 5 columns + popular searches + app block (§5.8)
lib/features/shell/cookie_banner.dart  lib/features/shell/whatsapp_fab.dart
lib/features/search/search_overlay.dart  search_provider.dart        # §5.6 (Ctrl+K / ⌘K)
lib/features/mini_cart/mini_cart_drawer.dart  coupon_tile.dart        # §5.7 3-state coupon
lib/features/home/home_layout.dart          # ordered section list → reorderable (§6.1)
lib/features/catalogue/filter_sidebar.dart  filter_sheet.dart  sort_menu.dart  active_filter_chips.dart  # §7.1
lib/features/content/seo_block.dart  lib/features/content/pages/*    # §10.7 + §6 SEO block, 404
```

### 16.3 Phases (each ends green: `flutter analyze` + `flutter test` + render check at 390 / 768 / 1440)

| Phase | Work | Primary files | Done when |
|---|---|---|---|
| **0** | Tokens & brand: copper palette, type scale (§2.1–2.3), 4 device classes (add `Wide ≥1600`, content caps 1320/1480) | `design_tokens.dart`, `theme.dart`, `responsive.dart` | Tokens compile; all 4 widths render |
| **1** | Chrome shell: top strip, header (compact + expanded), 4-item bottom bar, drawer, footer, cookie, WhatsApp FAB | `main_screen.dart` → becomes adaptive shell; §16.2 shell files | Every §4.1 item routes; no h-scroll 320→1920 |
| **2** | Nav data + router: `menu_data.dart`, §4.3 paths, aliases, mega-menu panel | `app_router.dart`, `menu_data.dart` | All §4.2 links open a real screen |
| **3** | Overlays: search overlay, mini-cart drawer + coupon states | §16.2 search/mini_cart files | Ctrl/Cmd+K opens search; coupon 3 states work |
| **4** | Home: rebuild as ordered `home_layout` list, all 15 sections, skeleton→content | `home_layout.dart`, `home_sections.dart` | Sections reorderable; every tile navigates |
| **5** | PLP: filters (sidebar/sheet), sort, chips, 2/3/4/5-col grid, load-more | `catalogue_screen.dart` + filter files | Every route pattern in §4.3 resolves to filtered grid or empty state |
| **6** | PDP: variant→price/breakup/gallery, accordions, pincode, rails, sticky buy bar | `product_detail_screen.dart` | Variant change updates price + gallery; compact sticky bar |
| **7** | Commerce polish: cart 65/35 summary, 5-step checkout, wishlist move-to-cart | `cart_screen.dart`, `checkout_screen.dart`, `wishlist_screen.dart` | Order success reached; coupon applies at both cart & mini-cart |
| **8** | Account, orders timeline, stores, bespoke, content pages, 404 | `profile`, `orders`, new `content/pages` | Every footer link opens a real page |
| **9** | Platform polish (§16.4) + accessibility (§11.5) | per-target rows below | **Done** — iOS swipe-back, Android back, Windows shortcuts, keyboard path pass (`test/platform_polish_test.dart`, 11/11) |
| **10** | Virtual try-on / store / co-shopping behind switch | new `features/virtual/` | **Done** — `virtualTryOn` rule (default off → designed "Coming soon" heroes); on → try-on viewfinder with piece overlay + capture/share, store hotspot panorama → BOOK APPOINTMENT, co-shopping shortlist with ❤️/❌ votes, clipboard invite link (`test/virtual_features_test.dart`, 6/6) |

### 16.4 Per-platform build matrix (how one codebase renders differently)

| Target | How it's selected | Shell | Distinct behaviour to implement |
|---|---|---|---|
| **Android phone** | `Responsive.isMobile` | Compact: header + drawer + 4-item bottom bar | System back closes overlay first; edge-to-edge status bar; ripple on list rows only |
| **iOS phone** | `Platform.isIOS` + isMobile | Compact | Safe-area insets (notch/home indicator), swipe-back on pushed screens, bottom sheets w/ grabber, haptics on cart/wishlist, Sign in with Apple, Dynamic Type |
| **Tablet** | `isTablet` (600–1199) | Medium: header + wishlist, grid 3-col, no bottom bar ≥768 | Landscape uses Expanded layout |
| **Mobile web** | `kIsWeb && isMobile` | Compact + cookie banner + WhatsApp FAB + app badges | Sticky bottom bar; deep links per §4.3 |
| **Desktop web** | `kIsWeb && isDesktop` | Expanded: full header + hover mega-menu, no bottom bar | Quick view, scroll-wheel zoom, hover-lift cards |
| **Windows app** | `Platform.isWindows` (desktop class) | Expanded (same as desktop web) | Resizable min ≈360×640, DPI 100–250%, always-visible scrollbars, **Ctrl+K search / Esc / Tab rings**, right-click suppressed on product images when protection on, toast notifications, MSIX installer |

Shared rules: header/footer full-bleed with capped content (§3), overlay stack (§3.4), skeleton/empty/error everywhere (§11.1), price rows wrap (§1.3).

### 16.5 Likely pubspec additions (verify before use)

`url_launcher` (tel:/wa.me/mailto links), `google_fonts` (Cormorant/Lato without bundling), `cached_network_image` (menu thumbnails, product rails), `flutter_keyboard_visibility` or `Shortcuts`/`Actions` (Ctrl+K). Everything else rides on existing `go_router`, `provider`, `shared_preferences`, `shimmer` and the `common_widgets` kit. Candidate deps for filter UI come from the existing widget kit first — avoid adding a state-mgmt or routing library.

### 16.6 Definition of done (release gate)

1. `flutter analyze` → no errors; `flutter test` green.
2. Render checks at **320×568, 390×844, 768×1024, 1280×800, 1440×900, 1920×1080** — no horizontal scroll, prices wrap, overlays stack per §3.4.
3. Every route in §4.3 (+ aliases) resolves to a real screen or designed 404.
4. Keyboard-only path: search → PDP → add to cart → checkout on web/Windows.
5. Per-target pass of §16.4 behaviours (iOS swipe-back, Android back, Windows Ctrl+K, cookie banner on web).
6. Contrast ≥ 4.5:1 for body text; touch targets ≥44/48 px.

---

*End of architecture. Everything tagged [P] or [?] becomes [V] once the §14 captures are provided. Revision 2 deltas are logged in §0.4.*
