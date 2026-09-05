# Chirag Associates AI Accounting ERP — OCR & AI Invoice Processing

## 1. Purpose

This document explains how the OCR, handwriting recognition, AI invoice understanding, validation, database storage, accountant verification, and accounting-posting workflow should work inside the Chirag Associates AI Powered Accounting ERP & CRM Platform.

The main objective is to reduce manual accounting data entry while keeping accountant approval and auditability.

The original Software Requirement Document defines the AI Invoice Scanner as the core module. It accepts PDF, JPEG, PNG and camera images and extracts GSTIN, invoice number, invoice date, supplier/customer, taxable value, CGST, SGST, IGST, HSN, quantity, rate and total amount. It then creates purchase entries, sales entries and vouchers.

---

# 2. OCR — What It Means

OCR stands for **Optical Character Recognition**.

OCR converts text visible inside an image or PDF into machine-readable text.

Example:

```text
IMAGE

ABC TRADERS
Invoice No: INV-125
Date: 10/08/2026
Total: ₹59,000
```

OCR converts it into:

```text
ABC TRADERS
Invoice No: INV-125
Date: 10/08/2026
Total: ₹59,000
```

However, OCR by itself does not fully understand accounting.

OCR answers:

> What text is visible?

AI/document intelligence answers:

> What does this text mean?

---

# 3. Printed Invoice vs Handwritten Bill

There are two major document types.

## Printed Invoice

Example:

```text
Invoice Number: INV-125
Invoice Date: 10-08-2026
GSTIN: 29ABCDE1234F1Z5
Taxable Amount: 50,000
CGST: 4,500
SGST: 4,500
Total: 59,000
```

Traditional OCR can perform well on this type.

## Handwritten Bill

Example:

```text
ABC STORES

Date: 10/08/26
Bill No: 125

Rice       2    1200
Oil        3     450
Sugar      5     250

Subtotal          1900
GST                342
Total             2242
```

Handwriting is more difficult.

A handwriting-capable recognition model is needed.

---

# 4. Important Principle

Do not build the system as:

```text
Image → OCR → Database
```

Instead build:

```text
Image
  ↓
Image Processing
  ↓
OCR / Handwriting Recognition
  ↓
Text + Coordinates + Confidence
  ↓
AI Document Understanding
  ↓
Structured Invoice Data
  ↓
Validation Engine
  ↓
Confidence / Error Detection
  ↓
Accountant Verification
  ↓
Approval
  ↓
Accounting Engine
  ↓
GST / Ledger / Voucher
  ↓
Tally Sync
```

This is much safer for accounting.

---

# 5. Complete OCR Workflow

## Step 1 — Client Uploads Document

The client can upload:

- PDF
- JPEG/JPG
- PNG
- Camera image

The mobile application should allow:

```text
[ Take Photo ]
[ Choose From Gallery ]
[ Upload PDF ]
```

The document should first be stored securely.

Example:

```text
documents/
  2026/
    08/
      client_25/
        document_10052.jpg
```

The database stores metadata about the file.

---

# 6. Step 2 — Document Processing

The original camera image may have:

- Rotation
- Shadows
- Background
- Blur
- Perspective distortion
- Low lighting
- Noise
- Uneven brightness

Before OCR, process the image.

Typical operations:

1. Detect document boundary
2. Crop document
3. Perspective correction
4. Rotate
5. Resize
6. Noise removal
7. Contrast enhancement
8. Sharpening
9. Optional grayscale/binarization

Example:

```text
Camera Image
     ↓
Document Detection
     ↓
Crop
     ↓
Perspective Correction
     ↓
Noise Removal
     ↓
Contrast Enhancement
     ↓
OCR-ready Image
```

This step can significantly improve recognition.

---

# 7. Step 3 — OCR / Handwriting Recognition

The recognition engine looks at the document.

For printed text:

```text
INV-125
```

It may return:

```json
{
  "text": "INV-125",
  "confidence": 0.97
}
```

For handwriting:

```text
[handwritten image]
```

The handwriting model may predict:

```text
125
```

with:

```text
confidence = 0.96
```

If the handwriting is unclear:

```text
125 / 128
```

confidence may be low.

The ERP should not blindly accept low-confidence values.

---

# 8. OCR Must Return Coordinates

A good OCR result should contain more than text.

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

The bounding box tells the system where the text was found.

Example:

```text
Text                  Location           Confidence

ABC STORES            Top-left            99%
10/08/26              Top-right           96%
INV-125               Top-right           97%
Rice                  Row 1               98%
2                     Row 1               95%
1200                  Row 1               91%
GST                   Bottom              97%
342                   Bottom              94%
2242                  Bottom              98%
```

Coordinates are useful because the AI can understand the layout of the invoice.

---

# 9. Step 4 — AI Document Understanding

OCR produces text.

AI determines what each value represents.

OCR output:

```text
ABC STORES
10/08/26
125
Rice
2
1200
Oil
3
450
Sugar
5
250
1900
342
2242
```

AI converts it into structured data:

```json
{
  "supplier_name": "ABC STORES",
  "invoice_number": "125",
  "invoice_date": "2026-08-10",
  "items": [
    {
      "description": "Rice",
      "quantity": 2,
      "rate": 1200
    },
    {
      "description": "Oil",
      "quantity": 3,
      "rate": 450
    },
    {
      "description": "Sugar",
      "quantity": 5,
      "rate": 250
    }
  ]
}
```

The AI should also identify:

- GSTIN
- Invoice number
- Invoice date
- Supplier
- Customer
- Taxable value
- CGST
- SGST
- IGST
- HSN
- Quantity
- Rate
- Total amount

---

# 10. OCR Is Not the Accounting Engine

This distinction is critical.

OCR:

```text
Reads visual text
```

AI:

```text
Understands invoice fields
```

Validation:

```text
Checks whether the information makes sense
```

Accounting engine:

```text
Creates accounting entries
```

Therefore:

```text
OCR ≠ Accounting
AI ≠ Final Approval
```

The accountant should remain the final checker before posting.

---

# 11. Step 5 — Validation Engine

Before saving/posting an invoice, validate the extracted data.

The requirements specify checks for:

- Duplicate invoice
- Wrong GSTIN
- Wrong date
- Duplicate amount
- Duplicate invoice number
- GST mismatch
- Tax mismatch

Example:

```text
OCR GSTIN
   ↓
Format Validation
   ↓
Supplier Master
   ↓
Existing GSTIN?
   ↓
Compare
```

---

# 12. Amount Validation

Never blindly trust OCR.

Suppose OCR reads:

```text
Quantity = 5
Rate = ₹250
Amount = ₹1,250
```

The system calculates:

```text
5 × ₹250 = ₹1,250
```

Result:

```text
✓ Amount matches
```

If OCR reads:

```text
Quantity = 5
Rate = ₹250
Amount = ₹1,350
```

System calculates:

```text
5 × ₹250 = ₹1,250
```

Result:

```text
✗ Amount mismatch
```

The invoice should be sent for manual verification.

---

# 13. Tax Validation

Example:

```text
Taxable Value = ₹50,000
CGST = ₹4,500
SGST = ₹4,500
```

The system should calculate the tax percentage and compare it with the extracted tax.

Then:

```text
Taxable Amount
      +
CGST
      +
SGST
      =
Invoice Total
```

If the total doesn't match:

```text
OCR Total:       ₹59,000
Calculated:      ₹59,100

⚠ Total mismatch
```

Status:

```text
PENDING_REVIEW
```

---

# 14. GSTIN Validation

Suppose OCR reads:

```text
29ABCDE1234FIZ5
```

But the supplier master contains:

```text
29ABCDE1234F1Z5
```

The system should flag the discrepancy.

It should compare:

- GSTIN format
- Supplier master
- Existing supplier records
- Invoice information
- Other known business data

The accountant can correct the value.

---

# 15. Duplicate Invoice Detection

Suppose an invoice has:

```text
Supplier = ABC Stores
Invoice Number = INV-125
Date = 10/08/2026
Amount = ₹59,000
```

The system searches the database.

Possible matching keys:

```text
supplier_id
+
invoice_number
+
invoice_date
+
total_amount
```

If a matching invoice already exists:

```text
⚠ POSSIBLE DUPLICATE

ABC Stores
INV-125
10/08/2026
₹59,000
```

The accountant decides whether it is actually a duplicate.

---

# 16. Confidence Score

Every extracted field should have a confidence score.

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

Do not rely only on one overall document confidence.

Field-level confidence is better.

Suggested workflow:

```text
95–100% → High confidence
85–94%  → Review recommended
Below 85% → Mandatory verification
```

These thresholds should be configurable and tested with real documents rather than treated as universal rules.

---

# 17. Accountant Verification Screen

The accountant should see the invoice and extracted information together.

Suggested UI:

```text
┌─────────────────────┬──────────────────────────┐
│                     │ Extracted Information    │
│                     │                          │
│   INVOICE IMAGE     │ Supplier: ABC Stores     │
│                     │ GSTIN: 29ABCDE1234F1Z5   │
│                     │ Invoice: INV-125         │
│                     │ Date: 10/08/2026         │
│                     │ Taxable: ₹50,000         │
│                     │ CGST: ₹4,500             │
│                     │ SGST: ₹4,500             │
│                     │ Total: ₹59,000            │
│                     │                          │
│                     │ [Approve] [Edit]         │
│                     │ [Reject]                 │
└─────────────────────┴──────────────────────────┘
```

When the accountant clicks a field, the system can highlight the corresponding region on the original invoice using the OCR bounding box.

---

# 18. Accountant Correction

Suppose OCR reads:

```text
Invoice Number = INV-128
```

Accountant sees the image and changes it to:

```text
Invoice Number = INV-125
```

Store both values.

Example:

```text
OCR Value:
INV-128

Verified Value:
INV-125

Verified By:
Accountant ID 42

Verified At:
2026-08-10 10:25:00
```

This is valuable for audit history and future AI improvement.

---

# 19. Checker-Maker Workflow

The required workflow is:

```text
Step 1
Client uploads invoice
        ↓
Step 2
AI reads invoice
        ↓
Step 3
Data goes to Accountant
        ↓
Step 4
Accountant verifies
        ↓
Step 5
Approved
        ↓
Step 6
Entry posted
        ↓
Step 7
GST Return Updated
```

The OCR module therefore feeds the checker-maker process rather than bypassing it.

---

# 20. Database Architecture

Do not put everything into one table.

Use separate logical entities.

## documents

Stores original uploaded files.

```text
documents
--------------------------------
id
client_id
file_url
file_type
uploaded_by
uploaded_at
document_status
```

Example:

```text
id:           10052
client_id:    25
file_url:     /documents/2026/08/10052.jpg
file_type:    image/jpeg
status:       PROCESSING
```

---

# 21. ocr_results Table

Stores raw OCR output.

```text
ocr_results
--------------------------------
id
document_id
ocr_engine
raw_text
confidence
processed_at
```

Example:

```text
document_id: 10052

raw_text:
"ABC STORES
INV-125
10/08/26
..."

confidence:
0.94
```

Keep raw OCR output because it provides traceability.

---

# 22. invoices Table

Stores structured invoice information.

```text
invoices
--------------------------------
id
document_id
client_id
supplier_id
invoice_number
invoice_date
gstin
taxable_amount
cgst
sgst
igst
total_amount
status
confidence
```

Example:

```text
id:              50125
supplier_id:     234
invoice_number:  INV-125
invoice_date:    2026-08-10
gstin:           29ABCDE1234F1Z5
taxable_amount:  50000
cgst:            4500
sgst:            4500
igst:            0
total_amount:    59000
status:          PENDING_REVIEW
confidence:      0.94
```

---

# 23. invoice_items Table

Each invoice can have many line items.

```text
invoice_items
--------------------------------
id
invoice_id
description
hsn
quantity
unit
rate
taxable_amount
cgst
sgst
igst
total
```

Relationship:

```text
Invoice 50125
     |
     |--- Rice
     |--- Oil
     |--- Sugar
     |--- Other item
```

This is better than putting all items in the invoice table.

---

# 24. ocr_fields Table

This is particularly useful for OCR and AI.

```text
ocr_fields
--------------------------------
id
document_id
field_name
field_value
confidence
x
y
width
height
verified
verified_value
```

Example:

```text
field_name:      invoice_number
field_value:     INV-125
confidence:      0.97
verified:        true
```

Another example:

```text
field_name:      invoice_date
field_value:     10/08/26
confidence:      0.72
verified:        false
```

After correction:

```text
verified_value:
10/08/2026
```

---

# 25. Recommended Additional Tables

For a production accounting ERP, consider:

```text
documents
ocr_results
ocr_fields
invoices
invoice_items
suppliers
customers
ledgers
vouchers
voucher_entries
gst_transactions
validation_results
approval_logs
audit_logs
```

Relationships:

```text
Document
   ↓
OCR Result
   ↓
OCR Fields
   ↓
Invoice
   ↓
Invoice Items
   ↓
Validation
   ↓
Approval
   ↓
Voucher
   ↓
Ledger
   ↓
GST
```

---

# 26. Store Original Image/PDF

Never store only extracted data.

Store:

```text
Original Document
+
OCR Result
+
AI Extracted Data
+
Accountant Corrections
+
Validation Result
+
Approval History
+
Accounting Entry
+
Audit Log
```

This creates a complete audit trail.

---

# 27. Invoice Status Lifecycle

Recommended statuses:

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

Possible exception states:

```text
OCR_FAILED
VALIDATION_FAILED
DUPLICATE_SUSPECTED
REJECTED
SYNC_FAILED
```

---

# 28. Accounting Entry After Approval

OCR should stop before final accounting approval.

Example invoice:

```text
Taxable Value = ₹50,000
CGST = ₹4,500
SGST = ₹4,500
Total = ₹59,000
```

After accountant approval, the accounting engine can generate the appropriate voucher.

Illustrative journal:

```text
Purchase A/C       Dr ₹50,000
Input CGST A/C     Dr  ₹4,500
Input SGST A/C     Dr  ₹4,500
       To Supplier A/C    ₹59,000
```

The exact accounting treatment should be determined by the ERP's accounting rules and transaction type.

---

# 29. OCR + AI + Accounting Separation

The architecture should have separate services/modules.

```text
1. Document Service
2. Image Processing Service
3. OCR Service
4. AI Extraction Service
5. Validation Service
6. Approval Service
7. Accounting Service
8. GST Service
9. Tally Integration Service
10. Notification Service
```

This makes the system easier to maintain.

---

# 30. Free OCR

OCR can be free if you use an open-source OCR engine and run it on your own infrastructure.

Example:

```text
Tesseract OCR
```

Advantages:

- No per-document OCR API fee
- Can run on your own server
- Open source
- Good for many printed documents

Limitation:

- Handwriting recognition is much harder
- Accuracy depends heavily on document quality
- It should not be treated as a complete handwritten-invoice solution

For high-quality handwriting recognition, dedicated handwriting models or cloud AI OCR services may be needed.

---

# 31. Recommended Low-Cost MVP

For the first version:

```text
Mobile/Web Upload
       ↓
Image Preprocessing
       ↓
Open-source OCR
       ↓
AI Document Extraction
       ↓
Validation
       ↓
Accountant Verification
       ↓
PostgreSQL
       ↓
Accounting Entry
```

Do not immediately build an expensive custom handwriting model.

First collect real invoice samples and measure accuracy.

---

# 32. Hybrid OCR Architecture

A practical production architecture can be:

```text
                  BILL
                    ↓
              IMAGE ANALYSIS
                    ↓
             Is text printed?
                /       \
              YES       NO/UNCLEAR
               ↓            ↓
        Local OCR       Handwriting
                         Recognition
               \            /
                \          /
                 ↓        ↓
               AI Extraction
                    ↓
              Validation
                    ↓
             Confidence Score
                    ↓
          ┌─────────┴─────────┐
          ↓                   ↓
      High Confidence      Low Confidence
          ↓                   ↓
     Accountant Review   Mandatory Review
          \                   /
           \                 /
                 APPROVE
                    ↓
             Accounting Engine
```

This can reduce OCR costs while improving reliability.

---

# 33. How AI Should Receive OCR Data

The backend should send structured OCR information to the AI rather than sending only a huge raw string.

Example:

```json
{
  "document_id": 10052,
  "ocr_blocks": [
    {
      "text": "ABC STORES",
      "confidence": 0.99,
      "x": 50,
      "y": 40
    },
    {
      "text": "INV-125",
      "confidence": 0.97,
      "x": 600,
      "y": 50
    }
  ]
}
```

AI then returns a controlled schema.

Example:

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

The backend should validate this response before storing it.

---

# 34. Never Allow AI to Directly Write SQL

Do not design:

```text
Invoice
 ↓
AI
 ↓
SQL INSERT
```

Instead:

```text
Invoice
 ↓
OCR
 ↓
AI JSON
 ↓
Backend Schema Validation
 ↓
Business Rules
 ↓
Database Transaction
```

The backend must remain in control.

---

# 35. Security

Because this is accounting data, implement:

- HTTPS/SSL
- Authentication
- Role-based access
- Tenant/client isolation
- Encryption at rest where appropriate
- Audit logs
- Secure object storage
- Access-controlled document URLs
- Backup
- Activity tracking
- 2FA/OTP where appropriate

The source requirements also include SSL encryption, role-based access, OTP, 2FA, daily backup, cloud storage and audit logs.

---

# 36. Multi-Tenant Design

Because the target is 10,000+ clients, every accounting record must belong to a client/company.

For example:

```text
client_id
company_id
branch_id
```

should be associated with documents, invoices, suppliers, ledgers and transactions.

Never allow:

```text
Client A → access → Client B invoice
```

The backend should enforce tenant isolation.

---

# 37. Example — Complete Handwritten Invoice

User uploads:

```text
ABC TRADERS

Bill No: 125
Date: 10/08/26

Rice     2 × 1200
Oil      3 × 450

GST      342
Total    2242
```

### Stage 1

```text
Image uploaded
```

### Stage 2

```text
Image cleaned
```

### Stage 3

```text
Handwriting recognition
```

### Stage 4

OCR result:

```text
ABC TRADERS
125
10/08/26
Rice
2
1200
Oil
3
450
342
2242
```

### Stage 5

AI extraction:

```json
{
  "supplier": "ABC TRADERS",
  "invoice_number": "125",
  "date": "2026-08-10",
  "items": [
    {
      "name": "Rice",
      "quantity": 2,
      "rate": 1200
    },
    {
      "name": "Oil",
      "quantity": 3,
      "rate": 450
    }
  ],
  "gst": 342,
  "total": 2242
}
```

### Stage 6

Validation:

```text
✓ Date valid
✓ Invoice number available
? Item amount mismatch
✓ Total detected
```

### Stage 7

```text
PENDING_REVIEW
```

### Stage 8

Accountant checks original image.

### Stage 9

Accountant corrects any wrong field.

### Stage 10

```text
APPROVED
```

### Stage 11

Accounting entry is generated.

### Stage 12

GST records are updated.

### Stage 13

Tally synchronization can occur if configured.

---

# 38. AI Learning From Corrections

An advanced future feature is to record corrections.

Example:

```text
OCR:
"INV-128"

Accountant:
"INV-125"
```

Store:

```text
original_value = INV-128
corrected_value = INV-125
field = invoice_number
```

Over thousands of invoices, these corrections can be analyzed to improve document processing rules and prompts.

Do not automatically train a model on sensitive client data without appropriate privacy, security and governance controls.

---

# 39. Performance Strategy

For large-scale processing:

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

Use asynchronous processing.

The mobile app should not wait for every OCR operation to finish.

Example:

```text
Client uploads invoice

Status:
"Processing..."

Then:

OCR completed
AI extraction completed
Validation completed

Notification:
"Invoice ready for verification"
```

---

# 40. Recommended Technology Direction

The original requirements propose:

### Frontend

```text
Flutter
React.js
```

### Backend

```text
Node.js / .NET Core
```

### Database

```text
PostgreSQL
```

### AI/OCR

```text
GPT-based AI
OCR Engine
Invoice Intelligence
```

### Cloud

```text
AWS / Azure / Google Cloud
```

This is a suitable overall direction for the planned platform.

---

# 41. Final Architecture

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

# 42. Key Design Rule

The most important rule for the Chirag Associates ERP is:

> **AI can prepare the accounting data, but the system should not blindly trust AI.**

The safe workflow is:

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

This gives the ERP automation while preserving accountant control and an auditable trail.

---

# 43. Expected Result

The overall objective is to reduce manual data entry substantially while maintaining:

- Faster invoice processing
- Automated extraction
- Automated validation
- Accountant verification
- GST-ready data
- Structured accounting records
- Searchable original documents
- Audit trail
- Scalable processing
- Tally synchronization
- Better client experience

The source requirements target a reduction of manual data entry by more than 90%, faster GST filing, centralized document management, AI-powered accounting automation, real-time dashboards, complete audit trail and scalability.

---

# 44. One-Line Summary

```text
HANDWRITTEN/PRINTED BILL
        ↓
OCR / HANDWRITING RECOGNITION
        ↓
AI UNDERSTANDS THE BILL
        ↓
VALIDATION CHECKS EVERYTHING
        ↓
ACCOUNTANT VERIFIES
        ↓
POSTGRESQL STORES STRUCTURED DATA
        ↓
ACCOUNTING ENTRY CREATED
        ↓
GST UPDATED
        ↓
TALLY SYNC
        ↓
COMPLETE AUDIT TRAIL
```

This is the recommended conceptual design for the OCR and AI invoice-processing module.
