# Chirag Associates ERP — OCR Implementation Guide

## Goal

Build the OCR and AI invoice-processing module as a reliable accounting workflow:

```text
Invoice / Bill
    ↓
Upload
    ↓
Image Processing
    ↓
OCR / Handwriting Recognition
    ↓
AI Invoice Understanding
    ↓
Validation
    ↓
Confidence Scoring
    ↓
Accountant Verification
    ↓
Approval
    ↓
Accounting Entry
    ↓
GST
    ↓
Tally Sync
    ↓
Audit Trail
```

The Chirag Associates requirement document defines the core workflow as client upload → AI reads invoice → accountant verifies → approval → entry posted → GST updated.

---

# 1. Recommended Technology

## Frontend

```text
React.js
Flutter
```

## Backend

```text
Node.js
```

## Database

```text
PostgreSQL
```

## OCR

Start with:

```text
Tesseract / open-source OCR
```

Then add a stronger OCR/handwriting service if real-world testing requires better accuracy.

## AI

Use an AI/vision model for:

- Invoice field extraction
- Document understanding
- Line-item understanding
- Ambiguous field interpretation

## Storage

Use object storage for original:

- JPG
- PNG
- PDF
- Camera images

---

# 2. Development Strategy

Do not build everything simultaneously.

Build this first:

```text
Upload one invoice
       ↓
OCR
       ↓
AI extraction
       ↓
PostgreSQL
       ↓
Accountant verification
       ↓
One accounting voucher
```

Once this works correctly, expand it.

---

# 3. Recommended Project Structure

```text
chirag-erp/
│
├── backend/
│   ├── src/
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   ├── clients/
│   │   │   ├── documents/
│   │   │   ├── ocr/
│   │   │   ├── invoices/
│   │   │   ├── validation/
│   │   │   ├── accounting/
│   │   │   ├── gst/
│   │   │   └── tally/
│   │   │
│   │   ├── workers/
│   │   │   ├── ocr.worker.js
│   │   │   ├── ai.worker.js
│   │   │   └── validation.worker.js
│   │   │
│   │   ├── database/
│   │   └── server.js
│   │
│   └── package.json
│
├── web/
│   └── React application
│
└── mobile/
    └── Flutter application
```

---

# 4. Step 1 — Document Upload

Create:

```http
POST /api/documents/upload
```

Client uploads:

```text
invoice.jpg
```

Backend:

```text
Receive file
    ↓
Validate file type
    ↓
Generate unique filename
    ↓
Store file
    ↓
Create documents record
    ↓
Return document_id
```

Example response:

```json
{
  "document_id": 10052,
  "status": "UPLOADED"
}
```

---

# 5. Step 2 — Database

Start with these tables.

## documents

```sql
CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'UPLOADED',
    uploaded_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## ocr_results

```sql
CREATE TABLE ocr_results (
    id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL,
    engine VARCHAR(100),
    raw_text TEXT,
    confidence NUMERIC(5,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## invoices

```sql
CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL,
    client_id BIGINT NOT NULL,
    supplier_id BIGINT,
    invoice_number VARCHAR(100),
    invoice_date DATE,
    gstin VARCHAR(20),
    taxable_amount NUMERIC(15,2),
    cgst NUMERIC(15,2),
    sgst NUMERIC(15,2),
    igst NUMERIC(15,2),
    total_amount NUMERIC(15,2),
    status VARCHAR(50) DEFAULT 'PENDING_REVIEW',
    confidence NUMERIC(5,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## invoice_items

```sql
CREATE TABLE invoice_items (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    description TEXT,
    hsn VARCHAR(20),
    quantity NUMERIC(15,3),
    unit VARCHAR(50),
    rate NUMERIC(15,2),
    taxable_amount NUMERIC(15,2),
    cgst NUMERIC(15,2),
    sgst NUMERIC(15,2),
    igst NUMERIC(15,2),
    total NUMERIC(15,2)
);
```

---

# 6. Step 3 — Image Processing

Before OCR, improve the image.

Typical processing:

```text
Camera Image
    ↓
Document Boundary Detection
    ↓
Crop
    ↓
Perspective Correction
    ↓
Rotate
    ↓
Resize
    ↓
Noise Removal
    ↓
Contrast Enhancement
    ↓
Sharpening
    ↓
OCR-ready Image
```

This is particularly important for mobile photographs.

Possible problems:

- Shadows
- Blur
- Rotation
- Poor lighting
- Perspective distortion
- Background objects
- Folded paper
- Low contrast

---

# 7. Step 4 — OCR

For the first prototype, use an open-source OCR engine.

Example:

```text
Tesseract OCR
```

Flow:

```text
document_id
    ↓
Get stored file
    ↓
Run OCR
    ↓
Receive text
    ↓
Save raw OCR result
```

Example:

```json
{
  "document_id": 10052,
  "raw_text": "ABC STORES\nINV-125\n10/08/2026\n...",
  "confidence": 0.94
}
```

Do not create an accounting entry at this stage.

---

# 8. Step 5 — OCR Bounding Boxes

Do not store only text.

Store the position of each recognized field.

Example:

```json
{
  "text": "INV-125",
  "confidence": 0.97,
  "boundingBox": {
    "x": 120,
    "y": 245,
    "width": 180,
    "height": 40
  }
}
```

This allows the UI to highlight the original location when an accountant selects a field.

---

# 9. Step 6 — OCR Fields Table

Create:

```sql
CREATE TABLE ocr_fields (
    id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL,
    field_name VARCHAR(100),
    field_value TEXT,
    confidence NUMERIC(5,4),
    x NUMERIC,
    y NUMERIC,
    width NUMERIC,
    height NUMERIC,
    verified BOOLEAN DEFAULT FALSE,
    verified_value TEXT
);
```

Example:

```text
field_name = invoice_number
field_value = INV-125
confidence = 0.97
verified = true
```

If the accountant changes it:

```text
original:
INV-128

verified:
INV-125
```

Keep both.

---

# 10. Step 7 — AI Invoice Extraction

OCR gives text.

AI understands the invoice.

OCR:

```text
ABC STORES
INV-125
10/08/2026
29ABCDE1234F1Z5
50000
4500
4500
59000
```

AI should return controlled JSON:

```json
{
  "supplier_name": "ABC STORES",
  "invoice_number": "INV-125",
  "invoice_date": "2026-08-10",
  "gstin": "29ABCDE1234F1Z5",
  "taxable_amount": 50000,
  "cgst": 4500,
  "sgst": 4500,
  "igst": 0,
  "total_amount": 59000,
  "items": []
}
```

Important:

```text
OCR
 ↓
AI
 ↓
JSON
 ↓
Backend validation
 ↓
Database
```

Never allow AI to directly execute SQL.

---

# 11. Step 8 — AI Field Extraction

The AI should identify:

```text
Supplier
Customer
GSTIN
Invoice Number
Invoice Date
Due Date
Taxable Amount
CGST
SGST
IGST
HSN
Quantity
Rate
Discount
Total
```

It should also identify line items.

Example:

```json
{
  "items": [
    {
      "description": "Rice",
      "hsn": "1006",
      "quantity": 10,
      "rate": 1200,
      "taxable_amount": 12000,
      "cgst": 600,
      "sgst": 600,
      "total": 13200
    }
  ]
}
```

---

# 12. Step 9 — Validation Engine

Create:

```text
validation.service.js
```

It should validate:

- Invoice number
- Date
- GSTIN
- Supplier
- Duplicate invoice
- Amount
- Tax
- Line-item calculations

---

# 13. Amount Validation

Example:

```text
Quantity = 5
Rate = ₹250
Amount = ₹1,250
```

Backend calculates:

```text
5 × ₹250 = ₹1,250
```

Result:

```text
✓ MATCH
```

If OCR says:

```text
Amount = ₹1,350
```

then:

```text
5 × ₹250 = ₹1,250

✗ AMOUNT MISMATCH
```

Set:

```text
PENDING_REVIEW
```

---

# 14. Tax Validation

Example:

```text
Taxable = ₹50,000
CGST = ₹4,500
SGST = ₹4,500
Total = ₹59,000
```

Backend independently checks:

```text
Taxable
+
CGST
+
SGST
+
IGST
=
Total
```

If it doesn't match:

```text
⚠ TAX/TOTAL MISMATCH
```

Do not automatically post it.

---

# 15. Step 10 — GSTIN Validation

Example OCR result:

```text
29ABCDE1234FIZ5
```

Supplier master:

```text
29ABCDE1234F1Z5
```

The system should flag the difference.

Validation can include:

```text
GSTIN format
    ↓
Supplier master
    ↓
Known GSTIN
    ↓
Compare
```

---

# 16. Step 11 — Duplicate Detection

Use a combination of:

```text
client_id
supplier_id
invoice_number
invoice_date
total_amount
```

Example:

```text
Supplier: ABC Stores
Invoice: INV-125
Date: 10/08/2026
Amount: ₹59,000
```

Search existing invoices.

If a close match exists:

```text
⚠ POSSIBLE DUPLICATE
```

The accountant decides whether it is actually a duplicate.

---

# 17. Step 12 — Confidence Scores

Every field should have its own confidence.

Example:

```text
GSTIN              99% ✓
Invoice Number     96% ✓
Invoice Date       91% ✓
Taxable Amount     98% ✓
CGST               97% ✓
SGST               97% ✓
HSN                71% ⚠
Quantity            82% ⚠
```

Suggested configurable workflow:

```text
95–100%
High confidence

85–94%
Review recommended

Below 85%
Mandatory verification
```

These are starting thresholds and should be calibrated using real invoices.

---

# 18. Step 13 — Accountant Verification Screen

Recommended UI:

```text
┌──────────────────────┬─────────────────────────┐
│                      │ Invoice Details         │
│                      │                         │
│                      │ Supplier  ABC Stores    │
│   INVOICE IMAGE      │ GSTIN     29ABCDE...    │
│                      │ Invoice   INV-125       │
│                      │ Date      10/08/2026    │
│                      │ Taxable   ₹50,000       │
│                      │ CGST      ₹4,500        │
│                      │ SGST      ₹4,500        │
│                      │ Total     ₹59,000       │
│                      │                         │
│                      │ [APPROVE] [EDIT]        │
│                      │ [REJECT]                │
└──────────────────────┴─────────────────────────┘
```

When the accountant selects a field, highlight the corresponding OCR bounding box on the invoice.

---

# 19. Step 14 — Accountant Correction

Example:

```text
AI extracted:
INV-128

Accountant sees:
INV-125
```

Store:

```text
original_value = INV-128
verified_value = INV-125
verified_by = accountant_id
verified_at = timestamp
```

This creates a complete audit trail.

---

# 20. Step 15 — Approval Boundary

The safest workflow is:

```text
OCR
 ↓
AI
 ↓
Validation
 ↓
Accountant
 ↓
APPROVE
 ↓
Accounting Engine
```

Never:

```text
OCR
 ↓
Accounting
```

The accountant approval is the control point.

---

# 21. Step 16 — Accounting Engine

After approval:

```text
Invoice
 ↓
Determine transaction type
 ↓
Find supplier ledger
 ↓
Find purchase ledger
 ↓
Find tax ledgers
 ↓
Create voucher
 ↓
Post ledger
```

Example:

```text
Purchase A/C       Dr ₹50,000
Input CGST A/C     Dr  ₹4,500
Input SGST A/C     Dr  ₹4,500

       To Supplier A/C ₹59,000
```

The exact accounting treatment must follow your accounting rules and transaction type.

---

# 22. Step 17 — GST

After the accounting entry is correct:

```text
Invoice
 ↓
Accounting Entry
 ↓
GST Transaction
```

Then build:

- Purchase Register
- Sales Register
- GSTR-1 data
- GSTR-3B data
- GSTR-2B reconciliation
- ITC reconciliation
- GST mismatch reports

Build these after the basic invoice-to-voucher flow is stable.

---

# 23. Step 18 — Tally Integration

Keep Tally separate from OCR.

```text
Chirag ERP
    ↓
Tally Integration Service
    ↓
Tally
```

Possible operations:

```text
Import
Export
Voucher Creation
Ledger Sync
Stock Sync
Bank Entries
Automatic Voucher Posting
```

The OCR module should not directly communicate with Tally.

---

# 24. Step 19 — Handwritten Bills

Add handwriting only after printed invoices work reliably.

Architecture:

```text
Image
 ↓
Image Quality Check
 ↓
Printed / Handwritten Detection
 ↓
 ┌─────────────────┐
 │                 │
Printed        Handwritten
 │                 │
OCR              Handwriting OCR
 │                 │
 └────────┬────────┘
          ↓
     AI Extraction
          ↓
      Validation
          ↓
     Accountant
```

If handwriting confidence is low:

```text
MANDATORY MANUAL REVIEW
```

---

# 25. Step 20 — Processing Queue

When the system grows, don't process OCR synchronously.

Use:

```text
Upload
  ↓
Queue
  ↓
OCR Worker
  ↓
AI Worker
  ↓
Validation Worker
  ↓
Review Queue
```

Example status:

```text
UPLOADED
    ↓
PROCESSING
    ↓
OCR_COMPLETED
    ↓
AI_EXTRACTED
    ↓
VALIDATION_COMPLETED
    ↓
PENDING_REVIEW
    ↓
APPROVED
    ↓
POSTED
    ↓
GST_UPDATED
    ↓
TALLY_SYNCED
```

Exception states:

```text
OCR_FAILED
VALIDATION_FAILED
DUPLICATE_SUSPECTED
REJECTED
SYNC_FAILED
```

---

# 26. Step 21 — Audit Logs

Record every important action.

Example:

```text
10:20 Client uploaded invoice
10:21 OCR completed
10:21 AI extraction completed
10:21 Validation completed
10:25 Accountant changed invoice number
10:26 Accountant approved
10:26 Voucher created
10:27 GST transaction created
10:28 Tally synchronization completed
```

This is essential for an accounting platform.

---

# 27. Step 22 — Multi-Tenant Security

Because the target is 10,000+ clients, every accounting record should belong to the correct tenant/company.

Use fields such as:

```text
client_id
company_id
branch_id
```

Every query must enforce tenant isolation.

Never allow:

```text
Client A
   ↓
Client B invoices
```

Security must be enforced at the backend, not only in the frontend.

---

# 28. Step 23 — Real-World Testing

Before production, collect real documents.

Example test set:

```text
100 printed invoices
100 handwritten bills
50 poor-quality photos
50 GST invoices
50 non-GST bills
50 duplicate invoices
```

Measure:

```text
GSTIN Accuracy
Invoice Number Accuracy
Date Accuracy
Amount Accuracy
Tax Accuracy
Item Extraction Accuracy
Duplicate Detection
Handwriting Accuracy
OCR Failure Rate
Manual Review Rate
```

Do not assume an OCR engine is accurate enough until you test it on your actual clients' documents.

---

# 29. Recommended Development Sequence

## Phase 1

```text
Upload invoice
↓
Store image
```

## Phase 2

```text
OCR
↓
Display extracted text
```

## Phase 3

```text
AI extraction
↓
Structured JSON
```

## Phase 4

```text
PostgreSQL
↓
Store invoice
```

## Phase 5

```text
Validation
↓
Duplicate/GST/amount checks
```

## Phase 6

```text
Accountant verification
↓
Edit
↓
Approve
```

## Phase 7

```text
Accounting engine
↓
Voucher
↓
Ledger
```

## Phase 8

```text
GST records
↓
GST reports
```

## Phase 9

```text
Tally integration
```

## Phase 10

```text
Handwriting recognition
↓
Advanced OCR
↓
AI document intelligence
```

---

# 30. The First Working Milestone

Do not initially try to complete:

```text
Complete AI Accounting ERP
```

Build this:

```text
ONE INVOICE
    ↓
UPLOAD
    ↓
OCR
    ↓
AI EXTRACTION
    ↓
POSTGRESQL
    ↓
ACCOUNTANT VERIFICATION
    ↓
APPROVE
    ↓
ONE CORRECT VOUCHER
```

Once this works reliably, expand the same architecture to:

```text
Sales
Purchase
Debit Notes
Credit Notes
Receipts
Expenses
Bank Statements
Cheques
GST
Tally
```

---

# 31. Final Architecture

```text
                    CLIENT
                      │
          ┌───────────┴───────────┐
          │                       │
      WEB APP                MOBILE APP
          │                       │
          └───────────┬───────────┘
                      ↓
               DOCUMENT SERVICE
                      ↓
                OBJECT STORAGE
                      ↓
              IMAGE PROCESSING
                      ↓
          ┌───────────┴───────────┐
          ↓                       ↓
     PRINTED OCR            HANDWRITING OCR
          └───────────┬───────────┘
                      ↓
               OCR RESULT
                      ↓
              AI EXTRACTION
                      ↓
             STRUCTURED JSON
                      ↓
             VALIDATION ENGINE
          ┌───────────┼───────────┐
          ↓           ↓           ↓
       GSTIN       Duplicate     Tax
       Check        Check       Check
          └───────────┼───────────┘
                      ↓
              CONFIDENCE SCORE
                      ↓
              ACCOUNTANT REVIEW
                      ↓
             ┌────────┴────────┐
             ↓                 ↓
          APPROVE            REJECT
             ↓
       ACCOUNTING ENGINE
             ↓
       ┌─────┼──────┐
       ↓     ↓      ↓
    LEDGER  GST   VOUCHER
       │     │      │
       └─────┼──────┘
             ↓
        TALLY SYNC
             ↓
        AUDIT LOG
```

---

# 32. Golden Rule

The most important design principle:

> **AI prepares the accounting data; the system validates it; the accountant approves it; only then does the accounting engine post it.**

In short:

```text
READ
 ↓
UNDERSTAND
 ↓
VALIDATE
 ↓
VERIFY
 ↓
APPROVE
 ↓
POST
```

This gives Chirag Associates automation while maintaining accountant control and an auditable accounting trail.
