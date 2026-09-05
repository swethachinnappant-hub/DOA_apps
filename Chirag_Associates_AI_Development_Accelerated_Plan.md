# Chirag Associates ERP — Accelerated AI Development Plan

## Goal

Complete the Chirag Associates OCR + AI accounting module using multiple AI development tools efficiently:

- ChatGPT
- OpenCode
- Google Antigravity
- Claude Free
- Cursor Free

The goal is not to make every AI build the same code. Each tool should have a clearly defined responsibility.

---

# 1. Core MVP Goal

The first milestone should be:

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

Once this works reliably, expand to GST, Tally, handwriting, CRM and other ERP modules.

---

# 2. AI Team Structure

```text
                    YOU
                     │
                     ▼
                 ChatGPT
              ARCHITECT / LEAD
                     │
        ┌────────────┼────────────┐
        ↓            ↓            ↓
    OpenCode     Antigravity   Claude
    BACKEND       FRONTEND     REVIEWER
        │            │            │
        └────────────┼────────────┘
                     ↓
                   Cursor
                FINAL REVIEW
                     ↓
                   YOU
                  APPROVE
```

You remain the project owner and final decision maker.

---

# 3. Role of Each AI Tool

## ChatGPT — Architect / Technical Lead

Use ChatGPT for:

- System architecture
- Database design
- API design
- OCR workflow
- AI extraction schema
- Accounting logic
- GST workflow
- Security design
- Code reviews
- Debugging difficult problems
- Reviewing work produced by other AI tools
- Breaking large requirements into small development tasks

ChatGPT should primarily decide **what needs to be built and how it should work**, rather than typing every file.

---

## OpenCode — Main Backend Developer

Use OpenCode for:

- Node.js backend
- PostgreSQL
- Database migrations
- APIs
- OCR service
- AI service
- Validation engine
- Accounting engine
- Tests
- Background workers

Example task:

```text
Build the document upload module according to
ARCHITECTURE.md and DATABASE.md.

Implement:

POST /api/documents/upload

Requirements:
- Validate file type
- Generate unique filename
- Store document
- Create PostgreSQL record
- Return document_id
- Add validation
- Add unit tests

Do not modify unrelated modules.
```

---

## Google Antigravity — Frontend / Browser Agent

Use Antigravity for:

- React UI
- Accountant verification screen
- Invoice viewer
- Drag/drop upload
- Field highlighting
- Dashboard
- Browser testing
- End-to-end UI testing
- Mobile-responsive UI

Example:

```text
Build the accountant invoice verification screen.

Show:
- Original invoice image
- Extracted fields
- Confidence
- Validation warnings
- Edit controls
- Approve
- Reject

When an extracted field is selected,
highlight its OCR bounding box on the invoice.
```

---

## Claude Free — Code Reviewer

Use Claude for:

- Large code review
- Refactoring
- SQL review
- API review
- Security review
- Finding logical bugs
- Reviewing complex backend modules

Example:

```text
Review this accounting module.

Check:
- Double-entry correctness
- Transaction consistency
- Database integrity
- Race conditions
- Tenant isolation
- Error handling
- Security
- Edge cases

Do not rewrite everything.
List specific problems and recommended fixes.
```

---

## Cursor Free — Second Reviewer / Debugger

Use Cursor as an independent second pair of eyes.

Good uses:

- Review changed files
- Find bugs
- Debug errors
- Refactor small sections
- Inspect Git diff
- Check frontend/backend integration

Do not have Cursor, Claude and OpenCode independently rewrite the same module.

---

# 4. Golden Rule

Do NOT do this:

```text
OpenCode → invoice.js
Claude → invoice.js
Cursor → invoice.js
Antigravity → invoice.js
ChatGPT → invoice.js
```

This causes conflicts and inconsistent implementations.

Instead:

```text
OpenCode
   ↓
Implement
   ↓
Claude
   ↓
Review
   ↓
Cursor
   ↓
Second review
   ↓
OpenCode
   ↓
Fix
   ↓
You
   ↓
Merge
```

---

# 5. Git Strategy

Use Git from Day 1.

Suggested branches:

```text
main
│
├── develop
│
├── feature/document-upload
├── feature/ocr
├── feature/ai-extraction
├── feature/validation
├── feature/accounting
├── feature/gst
└── feature/tally
```

Example:

```bash
git checkout -b feature/ocr-service
```

Then:

```text
OpenCode
   ↓
Code
   ↓
Tests
   ↓
Commit
   ↓
Review
   ↓
Merge
```

---

# 6. Project Documentation

Create a central documentation folder:

```text
docs/
├── ARCHITECTURE.md
├── DATABASE.md
├── API.md
├── OCR.md
├── ACCOUNTING.md
├── GST.md
├── TALLY.md
├── SECURITY.md
└── DEVELOPMENT_PLAN.md
```

Also create:

```text
AGENTS.md
```

The AI agents should read these files before modifying the project.

---

# 7. AGENTS.md

Example:

```markdown
# Chirag ERP Development Rules

## Backend

Node.js

## Database

PostgreSQL

## Frontend

React

## Mobile

Flutter

## Architecture

Modular monolith initially.

## Rules

- Never bypass validation.
- Never allow AI to directly execute SQL.
- Never post accounting entries without approval.
- Every accounting record must contain client_id.
- Every important operation requires audit logging.
- Do not modify unrelated modules.
- Write tests for financial calculations.
- Preserve existing functionality.
- Do not expose secrets.
- Never hardcode API keys.
```

This file becomes the common instruction set for coding agents.

---

# 8. Week 1 — Foundation

## Day 1 — Architecture

Use ChatGPT.

Prepare:

```text
ARCHITECTURE.md
DATABASE.md
API.md
OCR.md
ACCOUNTING.md
GST.md
TALLY.md
SECURITY.md
DEVELOPMENT_PLAN.md
```

Define:

- Modules
- Services
- Database entities
- API contracts
- Authentication
- Tenant isolation
- OCR flow
- AI flow
- Accounting flow
- Approval flow

---

# 9. Day 2 — Database

Give OpenCode:

```text
Read DATABASE.md.

Create the PostgreSQL schema.

Implement:

- companies
- clients
- users
- roles
- documents
- ocr_results
- ocr_fields
- invoices
- invoice_items
- suppliers
- customers
- ledgers
- vouchers
- voucher_entries
- validation_results
- approval_logs
- audit_logs

Create migrations.

Do not implement OCR yet.
```

Then ask Claude:

```text
Review this database architecture for:

- accounting correctness
- multi-tenancy
- scalability
- referential integrity
- auditability
```

Send corrections back to OpenCode.

---

# 10. Day 3–4 — Authentication

OpenCode implements:

```text
Login
JWT/session authentication
Role-based permissions
Admin
Accountant
CA
Client
```

Then Cursor reviews:

```text
Review authentication for:

- privilege escalation
- tenant isolation
- IDOR
- insecure APIs
- missing authorization
- session problems
```

Fix issues before continuing.

---

# 11. Day 5–7 — Document Upload

OpenCode:

```text
Implement document upload.

Supported:
PDF
JPG
JPEG
PNG

Create:
POST /api/documents/upload

Store:
- original file
- client_id
- uploaded_by
- timestamp
- status

Add:
- file validation
- size validation
- authentication
- audit log
- tests
```

Antigravity:

```text
Build the React document-upload UI.

Requirements:
- drag/drop
- mobile-friendly
- upload progress
- preview
- processing status
- error handling
```

---

# 12. Week 2 — OCR + AI

## Day 8–9 — OCR

OpenCode:

```text
Implement OCR service.

Input:
document_id

Process:
document
→ image preprocessing
→ OCR

Store:
- raw text
- confidence
- bounding boxes
- OCR engine
- processing time

Do not create accounting entries.
```

Test with approximately:

```text
10 printed invoices
```

---

# 13. Day 10–11 — AI Extraction

ChatGPT defines the structured JSON schema.

Example:

```json
{
  "supplier": {},
  "customer": {},
  "invoice": {},
  "tax": {},
  "items": [],
  "totals": {},
  "confidence": {}
}
```

OpenCode implements the AI extraction service.

Required architecture:

```text
OCR
 ↓
AI
 ↓
JSON
 ↓
Schema Validation
 ↓
PostgreSQL
```

Never:

```text
OCR
 ↓
AI
 ↓
SQL
```

---

# 14. Day 12 — Accountant Review UI

Antigravity builds:

```text
Invoice Image
      +
Extracted Fields
      +
Confidence
      +
Warnings
      +
Edit
      +
Approve
      +
Reject
```

Example:

```text
Invoice Number       INV-125     97% ✓
Date                 10/08/26    92% ✓
GSTIN                29ABCDE...  99% ✓
Taxable Amount       ₹50,000     98% ✓
HSN                  1234        71% ⚠
```

---

# 15. Day 13–14 — Validation

OpenCode implements:

```text
GSTIN validation
Date validation
Duplicate invoice
Duplicate invoice number
Amount validation
Tax validation
Line-item validation
Supplier matching
```

Claude reviews the validation logic.

ChatGPT reviews the accounting implications.

---

# 16. Week 3 — Accounting

Once OCR and validation work:

```text
Approved Invoice
       ↓
Accounting Engine
       ↓
Voucher
       ↓
Ledger
       ↓
GST Transaction
```

---

# 17. Day 15–17 — Ledger Engine

OpenCode:

```text
Implement double-entry accounting engine.

Create:

- chart of accounts
- ledger
- journal
- voucher
- voucher entries

Every transaction must satisfy:

Total Debit = Total Credit
```

Add automated tests for all financial calculations.

---

# 18. Day 18–19 — Purchase Voucher

Example:

```text
Purchase A/C       Dr ₹50,000
Input CGST A/C     Dr  ₹4,500
Input SGST A/C     Dr  ₹4,500

Supplier A/C       Cr ₹59,000
```

Test:

```text
GST
Discount
Round-off
Credit note
Debit note
Reverse charge where applicable
```

Use the actual accounting rules applicable to the transaction.

---

# 19. Day 20–21 — Approval

Complete:

```text
PENDING
   ↓
REVIEW
   ↓
EDIT
   ↓
APPROVE
   ↓
POST
```

After posting:

```text
Invoice = POSTED
Voucher = POSTED
```

Any later change must be auditable.

---

# 20. Week 4 — GST + Tally

## Day 22–24 — GST

Implement:

```text
Purchase Register
Sales Register
GST Summary
Input Tax
Output Tax
GSTR-related reports
Mismatch Report
```

Start with internal GST reports before attempting live government filing integrations.

---

# 21. Day 25–27 — Tally

Architecture:

```text
Chirag ERP
    ↓
Tally Integration Service
    ↓
Tally
```

Implement:

```text
Voucher export
Ledger sync
Stock sync
Bank entries
Import/export
```

Keep Tally integration separate from OCR.

---

# 22. Week 5 — Handwritten Bills

Only after printed invoices work reliably.

Architecture:

```text
Bill Image
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
     Confidence
          ↓
      Accountant
```

If handwriting confidence is low:

```text
MANDATORY MANUAL REVIEW
```

---

# 23. Week 6 — Testing + Production

## OpenCode

Run:

```text
Unit tests
Integration tests
API tests
Database tests
```

## Antigravity

Run:

```text
Browser tests
Upload tests
Accountant workflow tests
Mobile responsive tests
```

## Claude

Security review:

```text
SQL injection
IDOR
Tenant isolation
Authentication bypass
Authorization problems
Insecure file uploads
Exposed secrets
Unsafe AI-generated SQL
Financial calculation bugs
```

## Cursor

Perform an independent code review of changed files.

## ChatGPT

Perform the final architecture review based on:

```text
Architecture
Database
API
Accounting logic
Test results
Known bugs
Git diff
```

---

# 24. Daily AI Workflow

## Morning — ChatGPT

Ask:

```text
Today I need to implement [MODULE].

Give me:
- architecture
- API contract
- database changes
- acceptance criteria
- test cases
```

## Main coding — OpenCode

Give the exact task.

## UI — Antigravity

Build/test the frontend.

## Review — Claude

Review implementation.

## Second review — Cursor

Find bugs and integration issues.

## Evening — ChatGPT

Provide:

```text
What was implemented
What failed
Error logs
Git diff
Tests
```

Then use the recommended next task.

---

# 25. Development Timeline

## 4 Weeks — OCR Accounting MVP

```text
Upload
+
OCR
+
AI extraction
+
Validation
+
Accountant verification
+
Voucher
```

## 5 Weeks

Add:

```text
GST
+
Reports
+
Basic Tally integration
```

## 6 Weeks

Add:

```text
Handwriting
+
Security
+
Testing
+
Performance
```

## 8+ Weeks

For a stronger production release:

```text
Bank integration
Advanced GST reconciliation
Tally two-way sync
Notifications
WhatsApp
CRM
CA portal
10,000-client scalability
Advanced audit
Backup/restore
Monitoring
```

The full Chirag Associates requirements are much larger than OCR alone and include CRM, CA portal, billing, GST, Tally, notifications, reporting, security and other modules. Therefore, the timeline should be treated as a staged implementation plan rather than a promise for the entire ERP.

---

# 26. First Milestone

The first successful milestone is:

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

Do not move to the next major module until this flow works reliably.

---

# 27. Final AI Development Model

```text
                         YOU
                          │
                          ▼
                      ChatGPT
                  ARCHITECT / LEAD
                          │
             ┌────────────┼────────────┐
             │            │            │
             ▼            ▼            ▼
          OpenCode    Antigravity    Claude
          BACKEND       FRONTEND     REVIEW
             │            │            │
             └────────────┼────────────┘
                          ▼
                        Cursor
                    SECOND REVIEW
                          │
                          ▼
                       Testing
                          │
                          ▼
                         YOU
                       APPROVE
                          │
                          ▼
                         Git
                          │
                          ▼
                       Release
```

---

# 28. Golden Rules

1. Never let AI directly post accounting entries.
2. Never let AI directly execute arbitrary SQL.
3. Always validate AI-generated invoice data.
4. Always keep the original invoice.
5. Always keep OCR results.
6. Always keep accountant corrections.
7. Always maintain an audit trail.
8. Always enforce client/tenant isolation.
9. Always test financial calculations.
10. Never let multiple AI agents blindly edit the same files.
11. Use Git branches.
12. Build one vertical slice before expanding.
13. Test OCR against real invoices.
14. Treat handwriting as a separate accuracy challenge.
15. Keep OCR, AI, validation and accounting as separate modules.

---

# 29. Final Architecture

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

# 30. One-Line Strategy

```text
ChatGPT decides
        ↓
OpenCode builds backend
        ↓
Antigravity builds/tests UI
        ↓
Claude reviews
        ↓
Cursor reviews again
        ↓
You approve
        ↓
Git merge
        ↓
Next module
```

This is the recommended way to combine the available AI tools without duplicating work or creating conflicting implementations.
