# Jewellery B2B Wholesale E-Commerce Platform
## Phase 1 — Premium MVP Product & Technical Specification

**Platform Type:** Private B2B Jewellery Wholesale Commerce Platform  
**Business Model:** Jewellery Manufacturer / Wholesaler → Approved Jewellery Retail Shop Owners  
**Mobile Technology:** Flutter + Dart  
**Retailer App:** Flutter  
**Admin App:** Flutter  
**Admin Dashboard:** Web  
**Backend:** Node.js + Express.js  
**Database:** MongoDB  
**Authentication:** Secure OTP / password authentication with admin approval  
**Target Users:** Approved jewellery retailers only

---

# 1. Product Vision

Build a premium, secure and exclusive B2B jewellery ordering platform where a jewellery manufacturer/wholesaler can showcase products and sell directly to approved jewellery retail shop owners.

This is **NOT a public consumer e-commerce application**.

The platform works as a private jewellery trade network:

Manufacturer / Wholesaler
↓
Retailer Registration
↓
Admin Approval
↓
Private Product Catalogue
↓
Cart
↓
Checkout
↓
Payment Gateway
↓
Wholesale Order
↓
Order Processing

Only approved jewellery shop owners can access the catalogue and place orders.

---

# 2. Phase 1 Objectives

Phase 1 must deliver:

## Retailer / Client Flutter App

- Secure registration
- Admin approval workflow
- Secure login
- Private catalogue
- Product categories
- Product search
- Product filtering
- Product details
- Protected product images
- Wishlist
- Cart
- Wholesale pricing
- Checkout
- Payment gateway
- Payment verification
- Order placement
- Order history
- Order tracking/status
- Notifications
- Retailer profile
- Account management

## Admin Flutter App

- Secure admin login
- Dashboard
- Retailer approval
- Retailer management
- Product management
- Category management
- Collection management
- Pricing management
- Inventory/status management
- Order management
- Payment/transaction visibility
- Notifications
- Basic analytics
- Admin roles and permissions
- Audit logs

## Admin Web Dashboard

- Executive dashboard
- Retailer management
- Product management
- Category management
- Collection management
- Order management
- Payment management
- Enquiry management is NOT included
- Notifications
- Reports
- Admin roles
- Settings
- Audit logs

---

# 3. User Types

## 3.1 Super Admin

Full access.

Permissions:

- Dashboard
- Retailers
- Products
- Categories
- Collections
- Orders
- Payments
- Inventory
- Notifications
- Reports
- Admin users
- Roles & permissions
- Settings
- Audit logs

---

## 3.2 Admin / Staff

Access controlled by role.

Example roles:

- Product Manager
- Order Manager
- Customer Manager
- Catalogue Manager
- Finance Manager
- Support Manager

Admin users must only access features granted to their role.

---

## 3.3 Retailer

A jewellery shop owner approved by the manufacturer.

Retailer can:

- Register
- Login
- Browse private catalogue
- Search products
- Filter products
- View product details
- Add products to wishlist
- Add products to cart
- Checkout
- Make online payment
- View payment status
- Place orders
- View orders
- Track order status
- Receive notifications
- Manage profile

---

# 4. Private B2B Access Model

The application must never behave like public e-commerce.

## Retailer Registration

Retailer submits:

- Owner name
- Shop name
- Mobile number
- Email
- Shop address
- City
- State
- Pincode
- GST number
- Business registration details
- Jewellery shop type
- Years in business
- Optional shop photos
- Optional GST certificate
- Optional business proof

Registration status:

```text
PENDING
APPROVED
REJECTED
SUSPENDED
```

---

# 5. Approval Workflow

1. Retailer submits registration.
2. Account becomes `PENDING`.
3. Admin receives notification.
4. Admin reviews retailer information.
5. Admin can:
   - Approve
   - Reject
   - Request additional information
   - Suspend
6. Only `APPROVED` retailers can access the private catalogue.
7. Approved retailer receives notification.
8. Suspended/rejected retailers cannot access protected catalogue APIs.

---

# 6. Authentication & Security

Authentication must support:

- Mobile number
- OTP
- Optional password
- Secure session/token
- Refresh token
- Device/session management
- Logout
- Account status verification
- Token expiration
- Secure storage

Every protected API request must validate:

```text
Authentication
+
User Status
+
User Role
+
Permission
```

A suspended or rejected retailer must immediately lose access.

---

# 7. Premium Retailer App

The Flutter retailer app must have a premium jewellery-business visual language.

## Design Principles

- Luxury
- Minimal
- Elegant
- Professional
- High-end
- Fast
- Clean
- Mobile-first

Avoid:

- Cheap gradients
- Excessive animations
- Clutter
- Generic marketplace appearance
- Consumer-shopping visual language

Suggested visual direction:

- Ivory
- Champagne
- Warm neutral backgrounds
- Elegant typography
- Controlled gold accents
- Large product imagery
- Spacious layouts
- Premium cards
- Subtle shadows
- Refined icons

The app should feel like a **private jewellery trade showroom**, not a generic marketplace.

---

# 8. Retailer App Navigation

Bottom navigation:

```text
Home
Catalogue
Wishlist
Orders
Account
```

Global actions:

- Search
- Cart
- Notifications

---

# 9. Home Screen

## Header

- Brand logo
- Retailer/shop name
- Notifications
- Cart

## Search

```text
Search jewellery, SKU, category...
```

## Promotional Banner

Admin-controlled banners.

## Categories

Examples:

- Gold Chains
- Gold Rings
- Gold Earrings
- Gold Bangles
- Bracelets
- Pendants
- Necklaces
- Children's Jewellery
- Men's Jewellery
- Bridal Jewellery

## Sections

- New Arrivals
- Featured Collection
- Best Sellers
- Recently Viewed

All content must be configurable through admin.

---

# 10. Product Catalogue

Catalogue must support:

- Grid view
- List view
- Pagination
- Infinite scrolling
- Search
- Category
- Subcategory
- Collection
- Sorting
- Filters

Filters may include:

- Category
- Collection
- Gold purity
- Weight range
- Price range
- Gender
- Occasion
- Availability
- New arrival
- Featured
- Bestseller

---

# 11. Product Card

Product card should display:

- Product image
- Product name
- SKU
- Category
- Weight
- Purity
- Wholesale price
- Stock status
- Wishlist button

Optional badges:

```text
New
Featured
Bestseller
Limited
```

---

# 12. Product Detail Page

Display:

- Large product images
- Image gallery
- Product name
- SKU
- Category
- Gold purity
- Gross weight
- Net weight
- Stone weight
- Diamond weight
- Making charge
- Wastage
- Wholesale price
- Availability
- Stock status
- Product description
- Specifications
- Related products
- Wishlist
- Add to cart

Do NOT include:

- WhatsApp enquiry
- WhatsApp product enquiry
- WhatsApp-generated product messages

There must be no WhatsApp enquiry functionality anywhere in the product flow.

---

# 13. Jewellery-Specific Product Fields

Product model must support:

```text
Product ID
SKU
Product Name
Category
Subcategory
Collection
Gold Purity
Gross Weight
Net Weight
Stone Weight
Diamond Weight
Making Charge
Wastage
Wholesale Price
MRP
Stock Status
Stock Quantity
Size
Length
Width
Colour
Gender
Occasion
Description
Specifications
Images
Videos
Tags
Featured
New Arrival
Bestseller
Active
Created Date
Updated Date
```

---

# 14. Product Image Security

Critical requirement:

> Product photos should not be downloadable and screenshots should be prevented as far as technically possible.

Implement multiple protection layers.

## Android

Use:

```text
FLAG_SECURE
```

on protected screens.

This prevents standard screenshots and screen recording on supported Android devices.

## iOS

Implement screen-capture detection and appropriate protection behavior where supported.

The app should:

- Detect screen capture where technically supported
- Obscure sensitive imagery when capture is detected where possible
- Prevent image save actions
- Prevent image sharing actions
- Never expose permanent public image URLs

---

# 15. Secure Image Delivery

Never expose permanent public product-image URLs through APIs.

Architecture:

```text
Flutter App
    ↓
Authenticated API
    ↓
Image Authorization
    ↓
Private Object Storage
    ↓
Short-Lived Signed URL
    ↓
Flutter App
```

Signed URLs should have a short expiry, for example:

```text
1–5 minutes
```

Use private storage.

---

# 16. Dynamic Watermarking

Each retailer can optionally receive dynamically watermarked product images.

Example:

```text
CONFIDENTIAL
Retailer Shop Name
Retailer ID
```

Watermark should be subtle but difficult to remove.

This helps deter:

- Screenshots
- Screen photography
- Unauthorized sharing
- Catalogue redistribution

---

# 17. Image Security Reality

No mobile application can provide 100% protection against photography because a user can photograph the screen with another device.

Therefore implement:

```text
Private Storage
+
Authenticated Access
+
Short-Lived Image URLs
+
No Download Button
+
FLAG_SECURE
+
Screen-Capture Protection
+
Dynamic Watermark
+
Access Logging
```

This provides strong practical protection.

---

# 18. Wishlist

Retailer can:

- Add product
- Remove product
- View wishlist
- Move wishlist product to cart

Wishlist must be retailer-specific.

---

# 19. Cart

Retailer can:

- Add product
- Remove product
- Increase/decrease quantity
- Save for later
- View subtotal
- View applicable charges
- View estimated total
- Add order notes

Before checkout, the backend must revalidate:

- Product status
- Price
- Stock
- Quantity
- Retailer authorization

---

# 20. B2B Checkout

Checkout flow:

```text
Cart
↓
Checkout
↓
Billing Details
↓
Shipping Details
↓
Order Review
↓
Payment Gateway
↓
Payment Verification
↓
Order Confirmation
```

Consumer-style checkout assumptions should not be used.

The system should remain suitable for wholesale jewellery orders.

---

# 21. Payment Gateway Integration

Payment gateway integration is a mandatory Phase 1 feature.

The architecture must be gateway-agnostic.

Potential Indian gateway options include:

- Razorpay
- Cashfree
- PhonePe
- Other approved payment providers

The final gateway should be configurable based on the client's business/account requirements.

---

# 22. Payment Flow

Payment must follow this architecture:

```text
Retailer
↓
Checkout
↓
Backend Creates Payment Order
↓
Payment Gateway
↓
Retailer Completes Payment
↓
Gateway Response
↓
Backend Verifies Payment
↓
Order Created / Confirmed
↓
Payment Record Stored
↓
Retailer Receives Confirmation
```

Never trust only the Flutter app's payment-success callback.

The backend must verify the payment with the gateway.

---

# 23. Payment Security

Implement:

- Server-side payment order creation
- Server-side signature verification
- Webhook verification
- Payment status reconciliation
- Idempotency
- Duplicate payment protection
- Transaction IDs
- Gateway order IDs
- Gateway payment IDs
- Payment timestamps
- Failed payment handling
- Cancelled payment handling

Never store raw card details.

Payment-sensitive information must remain with the payment gateway.

---

# 24. Payment Status

Support:

```text
INITIATED
PENDING
SUCCESS
FAILED
CANCELLED
REFUNDED
PARTIALLY_REFUNDED
```

Payment and order status must be separate.

Example:

```text
Payment:
SUCCESS

Order:
PROCESSING
```

---

# 25. Payment Transaction Record

Store:

```text
Transaction ID
Order ID
Retailer ID
Gateway
Gateway Order ID
Gateway Payment ID
Amount
Currency
Payment Status
Payment Method
Created At
Updated At
Failure Reason
Webhook Status
```

Do not store sensitive payment credentials.

---

# 26. Order Creation Rules

Order creation must be server-controlled.

Recommended process:

```text
1. Validate retailer
2. Validate cart
3. Validate product availability
4. Validate quantity
5. Fetch current server-side prices
6. Calculate totals
7. Create payment order
8. Complete payment
9. Verify payment
10. Create/confirm order
11. Reserve/update stock
12. Send notification
```

Use idempotency to prevent duplicate orders if payment callbacks/webhooks are repeated.

---

# 27. Order Status

Order lifecycle:

```text
PENDING_PAYMENT
↓
PAID
↓
CONFIRMED
↓
PROCESSING
↓
PACKED
↓
SHIPPED
↓
DELIVERED
```

Additional statuses:

```text
PAYMENT_FAILED
CANCELLED
REJECTED
ON_HOLD
```

---

# 28. Order Details

Display:

- Order number
- Date
- Products
- Quantity
- Product SKU
- Weight
- Price
- Applicable charges
- Total
- Billing details
- Shipping details
- Payment status
- Order status
- Notes
- Invoice availability

---

# 29. Payment History

Retailer should be able to view payment information associated with orders:

- Order number
- Transaction ID
- Amount
- Date
- Payment status
- Payment method where available
- Invoice/receipt where applicable

---

# 30. Refund-Ready Architecture

Phase 1 should prepare the architecture for refunds.

Support database/API structures for:

- Full refund
- Partial refund
- Refund status
- Gateway refund ID
- Refund amount
- Refund reason
- Refund timestamp

Actual advanced refund workflows may be expanded in Phase 2.

---

# 31. Notifications

Support push and in-app notifications.

Examples:

- Registration submitted
- Account approved
- Account rejected
- Account suspended
- New collection
- New product
- Order placed
- Payment successful
- Payment failed
- Order confirmed
- Order processing
- Order shipped
- Order delivered
- Payment/refund update
- Admin announcement

---

# 32. Retailer Profile

Profile fields:

```text
Owner Name
Shop Name
Mobile
Email
GST Number
Address
City
State
Pincode
Business Details
Account Status
```

Actions:

- Edit profile
- Change password
- Logout
- Contact support through the configured support mechanism

Do not add WhatsApp product enquiry functionality.

---

# 33. Admin Dashboard

Web dashboard must provide an executive overview.

## KPI Cards

```text
Total Retailers
Pending Approvals
Active Retailers
Total Products
Active Products
Low Stock Products
Today's Orders
Pending Orders
Paid Orders
Failed Payments
Total Orders
Today's Revenue
Total Revenue
```

## Charts

- Orders over time
- Revenue trend
- Payment success/failure
- Top products
- Top retailers
- Category performance
- Order status distribution

---

# 34. Retailer Management

Admin can:

- View retailers
- Search retailers
- Filter retailers
- Approve
- Reject
- Suspend
- Activate
- View retailer profile
- View documents
- View orders
- View payment history
- View account activity

Filters:

```text
Pending
Approved
Rejected
Suspended
```

---

# 35. Product Management

Admin can:

- Create product
- Edit product
- Archive product
- Upload images
- Reorder images
- Add specifications
- Set price
- Set stock
- Assign category
- Assign collection
- Mark featured
- Mark bestseller
- Mark new arrival
- Activate/deactivate

---

# 36. Bulk Product Management

Architecture should support:

- Bulk product upload
- CSV import
- Bulk price update
- Bulk stock update
- Bulk activate/deactivate

If full CSV functionality is deferred to Phase 2, the Phase 1 API/database design must remain compatible with it.

---

# 37. Category Management

Admin can manage:

```text
Category
Subcategory
Collection
```

Actions:

- Create
- Edit
- Archive
- Reorder
- Activate/deactivate

---

# 38. Order Management

Admin dashboard:

```text
All Orders
Pending Payment
Paid
Confirmed
Processing
Packed
Shipped
Delivered
Cancelled
Rejected
On Hold
```

Admin can:

- Open order
- Change status
- Add notes
- View retailer
- View order history
- View payment details
- Verify transaction status
- Generate invoice
- Export order data

---

# 39. Payment Management

Admin must have a dedicated payment/transaction section.

Display:

```text
Transaction ID
Order ID
Retailer
Amount
Gateway
Payment Method
Payment Status
Date
```

Filters:

- Successful
- Pending
- Failed
- Cancelled
- Refunded
- Partially Refunded

Admin can open a transaction and view its complete audit trail.

---

# 40. Admin Flutter App

Flutter Admin App should provide mobile access to important operations.

Primary navigation:

```text
Dashboard
Retailers
Products
Orders
Payments
Notifications
More
```

Prioritize:

- Retailer approvals
- Orders
- Payment status
- Product management
- Notifications
- Important alerts

Complex analytics can remain in the web dashboard.

---

# 41. Admin Roles & Permissions

Use RBAC.

Example:

```text
SUPER_ADMIN
ADMIN
PRODUCT_MANAGER
ORDER_MANAGER
CUSTOMER_MANAGER
FINANCE_MANAGER
SUPPORT_MANAGER
```

Permission examples:

```text
retailer.view
retailer.approve
retailer.suspend

product.view
product.create
product.update
product.delete

order.view
order.update
order.cancel

payment.view
payment.refund

category.manage

notification.send

reports.view
```

Backend must enforce permissions.

Never rely only on Flutter UI visibility.

---

# 42. Audit Logs

Every sensitive operation must be logged.

Examples:

```text
Retailer approved
Retailer rejected
Retailer suspended
Product created
Product price changed
Product archived
Order status changed
Payment status changed
Refund initiated
Admin login
Admin logout
Admin permission changed
```

Log:

```text
Admin ID
Action
Entity
Entity ID
Timestamp
IP/device information where appropriate
```

---

# 43. Search

Global product search must support:

- Product name
- SKU
- Category
- Collection
- Tags

Use indexed MongoDB fields.

Prepare architecture for Elasticsearch/OpenSearch if the catalogue grows significantly.

---

# 44. Performance Requirements

Target:

- Fast app launch
- Smooth scrolling
- Lazy image loading
- Pagination
- Secure image handling
- Efficient caching strategy
- API pagination
- Database indexes
- Skeleton loading
- Empty states
- Error states

Do not load thousands of products in one request.

---

# 45. API Architecture

Use versioned REST APIs.

Suggested structure:

```text
/api/v1/auth
/api/v1/users
/api/v1/retailers
/api/v1/products
/api/v1/categories
/api/v1/collections
/api/v1/cart
/api/v1/wishlist
/api/v1/checkout
/api/v1/payments
/api/v1/orders
/api/v1/notifications
/api/v1/uploads
/api/v1/admin
/api/v1/reports
```

Payment webhooks:

```text
/api/v1/payments/webhook
```

Webhook endpoint must independently verify gateway signatures.

---

# 46. Backend Security

Implement:

- JWT access tokens
- Refresh tokens
- Password hashing
- OTP verification
- Rate limiting
- Input validation
- Request sanitization
- CORS configuration
- Helmet/security headers
- RBAC
- API authorization
- MongoDB indexes
- Audit logging
- Secure file upload validation
- File type validation
- File size limits
- Payment webhook verification
- Idempotency protection

Never trust client-side validation.

---

# 47. Database Collections

Initial MongoDB collections:

```text
users
retailers
admins
roles
permissions
products
categories
collections
wishlists
carts
orders
order_items
payments
refunds
notifications
banners
audit_logs
settings
```

---

# 48. Product Image Storage

Recommended:

```text
Private Object Storage
        ↓
Image Processing
        ↓
Optimized Versions
        ↓
Secure API
        ↓
Short-Lived Signed URL
        ↓
Flutter App
```

Do not expose permanent public image URLs.

---

# 49. API Response Rules

Product API must return only information authorized for the current retailer.

Example:

```json
{
  "id": "product_id",
  "sku": "JG1001",
  "name": "Premium Gold Chain",
  "purity": "22K",
  "grossWeight": 12.45,
  "netWeight": 12.10,
  "price": 85000,
  "stockStatus": "AVAILABLE",
  "images": [
    {
      "url": "short_lived_signed_url",
      "expiresAt": "timestamp"
    }
  ]
}
```

---

# 50. Business Rules

## Rule 1

Unapproved users cannot access catalogue APIs.

## Rule 2

Suspended users cannot place orders.

## Rule 3

Only active products appear in catalogue.

## Rule 4

Prices must be validated server-side.

## Rule 5

Cart prices must be revalidated before payment.

## Rule 6

Stock must be checked during order/payment flow.

## Rule 7

Retailer cannot modify product pricing.

## Rule 8

Retailer cannot access another retailer's orders.

## Rule 9

Admin permissions must be server-enforced.

## Rule 10

Archived products should remain available in historical orders.

## Rule 11

Payment success must be verified by backend before an order is treated as paid.

## Rule 12

Duplicate payment callbacks/webhooks must not create duplicate orders.

## Rule 13

Payment amount must be calculated server-side.

## Rule 14

Retailer must not be able to manipulate payment/order totals from the Flutter app.

---

# 51. Error Handling

Every screen must have:

## Loading

Premium skeleton/shimmer.

## Empty

Elegant empty-state design.

## Error

Friendly message + retry.

## Offline

```text
No internet connection.
Please check your connection and try again.
```

## Payment Failure

Show:

- Payment failed
- Retry payment
- Return to order/cart
- Do not create duplicate order

---

# 52. Flutter Architecture

Recommended:

```text
Flutter
Dart
Clean Architecture
Feature-based structure
Repository pattern
Dependency Injection
State Management
REST API
Secure Storage
```

Suggested structure:

```text
lib/
 ├── core/
 │   ├── network/
 │   ├── security/
 │   ├── storage/
 │   ├── theme/
 │   ├── routing/
 │   └── utils/
 │
 ├── features/
 │   ├── auth/
 │   ├── home/
 │   ├── catalogue/
 │   ├── product/
 │   ├── wishlist/
 │   ├── cart/
 │   ├── checkout/
 │   ├── payments/
 │   ├── orders/
 │   ├── notifications/
 │   └── profile/
 │
 └── main.dart
```

---

# 53. Admin Flutter Architecture

Separate admin application:

```text
admin_app/
 ├── core/
 ├── auth/
 ├── dashboard/
 ├── retailers/
 ├── products/
 ├── categories/
 ├── orders/
 ├── payments/
 ├── notifications/
 └── settings/
```

Do not unnecessarily mix retailer and admin permissions in the same application architecture.

---

# 54. Admin Web Dashboard

Recommended:

```text
React
TypeScript
Modern component architecture
Responsive dashboard
REST API
RBAC
Charts
Tables
Search
Filters
Pagination
```

Dashboard must work well on:

- Desktop
- Laptop
- Tablet

---

# 55. Testing

## Flutter Unit Tests

Test:

- Authentication
- Cart calculations
- Product parsing
- Payment states
- Order states
- Validation

## Widget Tests

Test:

- Login
- Registration
- Catalogue
- Product page
- Cart
- Checkout
- Payment result
- Orders

## Backend Tests

Test:

- Authentication
- Authorization
- Retailer approval
- Product APIs
- Cart
- Checkout
- Payment creation
- Payment verification
- Webhooks
- Orders
- Admin permissions

## Security Tests

Test:

- Unapproved API access
- Suspended user access
- Another retailer's order access
- Admin privilege escalation
- Invalid product price
- Invalid quantity
- Expired image URL
- Invalid upload
- Token expiry
- Duplicate payment callback
- Invalid payment signature
- Payment amount manipulation
- Duplicate order creation

---

# 56. Production Quality Requirements

Code must be:

- Modular
- Maintainable
- Secure
- Scalable
- Properly validated
- Properly documented
- Production-oriented

Do not create a prototype using fake business logic.

Avoid:

```text
TODO
FIXME
dummy API
hardcoded products
hardcoded prices
fake authentication
fake payment success
fake order processing
```

unless specifically marked as temporary development infrastructure.

---

# 57. Phase 1 Deliverables

## Retailer Flutter App

- Registration
- Approval status
- Login
- Home
- Catalogue
- Search
- Filters
- Product details
- Secure product images
- Wishlist
- Cart
- Checkout
- Payment gateway
- Payment verification
- Order placement
- Orders
- Payment history
- Notifications
- Profile
- Account management

## Admin Flutter App

- Login
- Dashboard
- Retailer approvals
- Retailer management
- Product management
- Category management
- Collection management
- Order management
- Payment management
- Notifications
- Basic reports

## Admin Web Dashboard

- Dashboard
- Retailer management
- Product management
- Category management
- Collection management
- Order management
- Payment management
- Reports
- Admin roles
- Settings
- Audit logs

## Backend

- Authentication
- Authorization
- Retailer approval
- Product APIs
- Catalogue APIs
- Wishlist APIs
- Cart APIs
- Checkout APIs
- Payment APIs
- Payment webhook
- Payment verification
- Order APIs
- Notification APIs
- Secure image APIs
- Admin APIs
- Audit logs

---

# 58. Phase 1 Definition of Done

This complete workflow must work:

```text
Retailer Registration
        ↓
Admin Notification
        ↓
Admin Reviews Retailer
        ↓
Admin Approves Retailer
        ↓
Retailer Receives Notification
        ↓
Retailer Logs In
        ↓
Private Catalogue Opens
        ↓
Retailer Searches Jewellery
        ↓
Opens Product
        ↓
Views Protected Image
        ↓
Adds Product to Wishlist / Cart
        ↓
Reviews Cart
        ↓
Checkout
        ↓
Billing & Shipping Details
        ↓
Backend Calculates Final Amount
        ↓
Payment Gateway
        ↓
Payment Verification
        ↓
Order Confirmed
        ↓
Admin Receives Order
        ↓
Admin Views Payment
        ↓
Admin Processes Order
        ↓
Admin Changes Order Status
        ↓
Retailer Receives Notification
        ↓
Retailer Tracks Order
```

Every step must be functional.

---

# 59. Phase 1 UX Standard

The application must look like:

```text
Luxury Jewellery
+
Professional B2B
+
Private Members-Only Platform
+
Premium Commerce
+
Secure Business Platform
```

It must NOT look like:

```text
Cheap marketplace
Generic shopping app
Basic template e-commerce
Simple CRUD application
```

---

# 60. Future-Ready Architecture

Phase 1 architecture should be ready for:

- Retailer-specific pricing
- Customer-specific price lists
- MOQ
- Bulk ordering
- Credit limits
- Credit terms
- Partial orders
- Backorders
- Inventory reservations
- GST invoices
- PDF invoices
- Shipping integration
- Delivery tracking
- Returns
- Advanced refunds
- Retailer analytics
- Product analytics
- AI product search
- AI sales assistant
- AI recommendations
- ERP integration
- Tally integration
- WhatsApp Business API for support/operations if required later
- Multi-branch retailers
- Multi-warehouse inventory
- Multi-language
- Multi-currency
- Advanced CRM

Do not implement these fully in Phase 1 unless explicitly requested.

---

# 61. Development Priority

Build in this order:

```text
1. Project architecture
2. Database schema
3. Backend authentication
4. Retailer registration
5. Admin approval
6. Product/category APIs
7. Secure image infrastructure
8. Flutter authentication
9. Flutter catalogue
10. Product detail
11. Wishlist
12. Cart
13. Checkout
14. Payment gateway
15. Payment verification
16. Order system
17. Notifications
18. Admin dashboard
19. Admin Flutter app
20. Payment management
21. RBAC
22. Audit logs
23. Testing
24. Security hardening
25. UI polish
26. Production build
```

---

# 62. Critical Development Instruction

**Do not treat this project as a normal consumer e-commerce store.**

The defining business characteristics are:

```text
PRIVATE
+
APPROVED-RETAILER-ONLY
+
B2B JEWELLERY
+
WHOLESALE ORDERING
+
SECURE PRODUCT CATALOGUE
+
PROTECTED PRODUCT IMAGES
+
ONLINE PAYMENT
+
SERVER-SIDE PAYMENT VERIFICATION
```

Security, retailer approval, product confidentiality, payment integrity and wholesale ordering must be first-class features.

Build with clean separation between:

```text
Retailer App
Admin App
Admin Dashboard
Backend
Database
Private Media Storage
Payment Gateway
```

Every important operation must be validated on the backend.

The Flutter application must never be treated as the security boundary.

---

# 63. Phase 1 Success Criteria

The manufacturer/wholesaler should be able to confidently operate a private digital jewellery wholesale business where:

1. Only approved jewellery retailers can enter.
2. Retailers can securely browse the private catalogue.
3. Product images are protected as far as technically possible.
4. Retailers can add products to cart.
5. Retailers can complete checkout.
6. Retailers can make online payments.
7. The backend independently verifies payments.
8. Orders are securely created and tracked.
9. Admin can manage retailers, products, inventory, orders and payments.
10. Admin can monitor the complete business workflow from the web dashboard and mobile admin app.

This is the Phase 1 production MVP target.
