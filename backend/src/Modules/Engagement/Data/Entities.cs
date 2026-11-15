namespace Engagement.Data.Entities;

public class WishlistItem
{
    public Guid UserId { get; set; }
    public Guid ProductId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>One review per (product, user); order_item_id set ⇒ verified purchase (design §5.5).</summary>
public class Review
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public Guid UserId { get; set; }
    public Guid? OrderItemId { get; set; }
    public short Rating { get; set; }
    public string Title { get; set; } = "";
    public string Body { get; set; } = "";
    public string Status { get; set; } = "pending"; // pending | published | rejected
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>In-app feed; dedupe_key makes redelivered events harmless (design §5.5).</summary>
public class Notification
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Type { get; set; } = null!; // client NotificationType names
    public string Title { get; set; } = null!;
    public string Body { get; set; } = null!;
    public string? Route { get; set; }
    public string? Data { get; set; }
    public string? DedupeKey { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
