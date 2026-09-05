class AppConstants {
  static const String appName = 'Chirag Associates';
  static const String appVersion = '1.0.0';

  static const List<String> userRoles = [
    'Super Admin',
    'Admin',
    'Accountant',
    'Chartered Accountant',
    'Marketing Executive',
    'Client',
  ];

  static const List<String> invoiceStatuses = [
    'UPLOADED',
    'PROCESSING',
    'OCR_COMPLETED',
    'AI_EXTRACTED',
    'VALIDATION_COMPLETED',
    'PENDING_REVIEW',
    'APPROVED',
    'POSTED',
    'GST_UPDATED',
    'TALLY_SYNCED',
  ];

  static const List<String> documentTypes = [
    'PDF',
    'JPEG',
    'JPG',
    'PNG',
  ];

  static const List<String> transactionTypes = [
    'Sales',
    'Purchase',
    'Debit Note',
    'Credit Note',
    'Receipt',
    'Payment',
  ];

  static const List<String> gstReturns = [
    'GSTR-1',
    'GSTR-3B',
    'GSTR-2B',
  ];

  static const List<String> reportTypes = [
    'Sales Register',
    'Purchase Register',
    'GST Summary',
    'Bank Book',
    'Cash Book',
    'Ledger',
    'Trial Balance',
    'Profit & Loss',
    'Balance Sheet',
    'Outstanding',
    'Ageing',
    'Cash Flow',
    'Expense Analysis',
    'Profit Analysis',
  ];

  static const double maxFileSizeMB = 10;
  static const int maxUploadAttempts = 3;
  static const Duration sessionTimeout = Duration(hours: 2);
}
