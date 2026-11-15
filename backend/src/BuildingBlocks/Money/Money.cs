using System.Globalization;

namespace BuildingBlocks.Money;

/// <summary>
/// Money in MINOR units (paise). Immutable value object — see design §1:
/// all arithmetic is integer, rounding is explicit and half-up, DTOs convert
/// to whole rupees at the edge so the Flutter contract never changes.
/// </summary>
public readonly record struct Money(long Minor) : IComparable<Money>
{
    public static readonly Money Zero = new(0);

    public static Money FromMinor(long minor) => new(minor);

    public static Money FromRupees(decimal rupees) =>
        new((long)Math.Round(rupees * 100m, MidpointRounding.AwayFromZero));

    public static Money FromRupees(long rupees) => new(rupees * 100);

    public static Money operator +(Money a, Money b) => new(a.Minor + b.Minor);
    public static Money operator -(Money a, Money b) => new(a.Minor - b.Minor);
    public static Money operator *(Money a, long factor) => new(a.Minor * factor);
    public static Money operator -(Money a) => new(-a.Minor);

    public static bool operator <(Money a, Money b) => a.Minor < b.Minor;
    public static bool operator >(Money a, Money b) => a.Minor > b.Minor;
    public static bool operator <=(Money a, Money b) => a.Minor <= b.Minor;
    public static bool operator >=(Money a, Money b) => a.Minor >= b.Minor;

    public bool IsZero => Minor == 0;
    public bool IsNegative => Minor < 0;

    /// <summary>Apply a percentage expressed in basis points (10000 bps = 100%), half-up.</summary>
    public Money ApplyBps(int basisPoints) =>
        new(Minor * basisPoints / 10000 + SignForRounding(Minor * basisPoints % 10000));

    /// <summary>Apply a decimal fraction (e.g. 0.18 for 18%), half-up.</summary>
    public Money ApplyFraction(decimal fraction) =>
        new((long)Math.Round(Minor * fraction, MidpointRounding.AwayFromZero));

    /// <summary>Pro-rata share of <paramref name="total"/> by <paramref name="weight"/>, remainder to the caller.</summary>
    public static Money Share(Money total, long weight, long totalWeight) =>
        new(total.Minor * weight / totalWeight);

    /// <summary>Round to the nearest rupee, half-up (design §6.1 round_off_minor).</summary>
    public Money RoundToRupee() =>
        new((long)Math.Round(Minor / 100m, MidpointRounding.AwayFromZero) * 100);

    public long ToRupeesTruncated() => Minor / 100;

    /// <summary>Whole rupees for DTOs — the value the Flutter client receives.</summary>
    public decimal ToRupeesDecimal() => Minor / 100m;

    public int CompareTo(Money other) => Minor.CompareTo(other.Minor);

    /// <summary>Indian digit grouping (1,23,456.78) — invoices and internal documents.</summary>
    public string ToStringInr(bool includePaise = true)
    {
        var culture = new CultureInfo("hi-IN");
        return includePaise
            ? string.Create(culture, $"{Minor / 100m:N2}")
            : string.Create(culture, $"{Math.Round(Minor / 100m, MidpointRounding.AwayFromZero):N0}");
    }

    public override string ToString() => ToStringInr();

    private static int SignForRounding(long remainder) =>
        remainder == 0 ? 0 : remainder > 0 ? (remainder * 2 >= 10000 ? 1 : 0) : (remainder * 2 <= -10000 ? -1 : 0);
}
