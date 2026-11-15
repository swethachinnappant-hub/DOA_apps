namespace Payments.Data.Entities;

/// <summary>Payment intents + gateway outcomes (design §5.4).</summary>
public class Payment
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid CheckoutId { get; set; }
    public string Provider { get; set; } = null!; // razorpay | cashfree | ...
    public string? ProviderOrderId { get; set; }
    public string? ProviderPaymentId { get; set; }
    public string? Method { get; set; }
    public string Status { get; set; } = "created"; // created | authorized | captured | failed | cancelled
    public long AmountMinor { get; set; }
    public string Currency { get; set; } = "INR";
    public string? FailureCode { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class Refund
{
    public Guid Id { get; set; }
    public Guid PaymentId { get; set; }
    public Payment? Payment { get; set; }
    public Guid OrderId { get; set; }
    public long AmountMinor { get; set; }
    public string Status { get; set; } = "pending"; // pending | processed | failed
    public string? ProviderRefundId { get; set; }
    public string? Reason { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
}

/// <summary>Gateway webhook inbox: PK (provider, event_id) dedupes redelivery (design §5.4).</summary>
public class WebhookEvent
{
    public string Provider { get; set; } = null!;
    public string EventId { get; set; } = null!;
    public string Payload { get; set; } = null!;
    public DateTime ReceivedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
}
