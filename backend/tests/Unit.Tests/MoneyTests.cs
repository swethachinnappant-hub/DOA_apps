using BuildingBlocks.Money;
using FsCheck;
using FsCheck.Xunit;
using Shouldly;

namespace Unit.Tests;

public class MoneyTests
{
    [Fact]
    public void FromRupees_converts_and_rounds_half_up()
    {
        Money.FromRupees(1299).Minor.ShouldBe(129900);
        Money.FromRupees(1.005m).Minor.ShouldBe(101);   // 100.5 paise → 101 (half-up, design §1)
        Money.FromRupees(1.004m).Minor.ShouldBe(100);
        Money.FromRupees(-1.005m).Minor.ShouldBe(-101); // symmetric away-from-zero
    }

    [Fact]
    public void ApplyBps_is_half_up()
    {
        Money.FromMinor(10000).ApplyBps(1800).Minor.ShouldBe(1800);      // 18% of ₹100 = ₹18
        Money.FromMinor(199).ApplyBps(500).Minor.ShouldBe(10);           // 9.95 → 10
        Money.FromMinor(198).ApplyBps(500).Minor.ShouldBe(10);           // 9.90 → 10? 9900/10000=0 rem 9900 → 9900*2=19800>=10000 → +1 → 9+1=10... wait 198*500=99000; 99000/10000=9 rem 9000 → 9000*2=18000>=10000 → 9+1=10
        Money.FromMinor(10).ApplyBps(500).Minor.ShouldBe(1);             // 0.5 → 1
        Money.FromMinor(9).ApplyBps(500).Minor.ShouldBe(0);              // 0.45 → 0
        Money.FromMinor(-199).ApplyBps(500).Minor.ShouldBe(-10);         // away from zero
        Money.FromMinor(10000).ApplyBps(10000).Minor.ShouldBe(10000);    // 100% identity
        Money.FromMinor(10000).ApplyBps(0).Minor.ShouldBe(0);
    }

    [Fact]
    public void ApplyFraction_matches_lending_style_percent()
    {
        Money.FromMinor(299900).ApplyFraction(0.18m).Minor.ShouldBe(53982); // 18% GST style
        Money.Zero.ApplyFraction(0.18m).Minor.ShouldBe(0);
    }

    [Fact]
    public void RoundToRupee_is_half_up()
    {
        Money.FromMinor(1050).RoundToRupee().Minor.ShouldBe(1100);
        Money.FromMinor(1049).RoundToRupee().Minor.ShouldBe(1000);
        Money.FromMinor(-1050).RoundToRupee().Minor.ShouldBe(-1100);
        Money.FromMinor(1000).RoundToRupee().Minor.ShouldBe(1000);
    }

    [Fact]
    public void Share_splits_without_losing_paise()
    {
        var total = Money.FromRupees(100);
        var sellerCut = Money.Share(total, 1, 3);
        sellerCut.Minor.ShouldBe(3333); // caller distributes the remainder (design §6.1)
        Money.Share(total, 2, 3).Minor.ShouldBe(6666);
        Money.Share(total, 0, 3).Minor.ShouldBe(0);
    }

    [Fact]
    public void Arithmetic_and_comparisons_behave()
    {
        var a = Money.FromRupees(100);
        var b = Money.FromRupees(40);
        (a + b).Minor.ShouldBe(14000);
        (a - b).Minor.ShouldBe(6000);
        (b * 3).Minor.ShouldBe(12000);
        (-b).Minor.ShouldBe(-4000);
        (a > b).ShouldBeTrue();
        (Money.Zero <= b).ShouldBeTrue();
        (b >= Money.Zero).ShouldBeTrue();
        Money.Zero.IsZero.ShouldBeTrue();
        Money.FromRupees(1).IsNegative.ShouldBeFalse();
    }

    [Fact]
    public void ToStringInr_uses_indian_grouping()
    {
        Money.FromMinor(12345678).ToStringInr().ShouldBe("1,23,456.78");
        Money.FromMinor(12345678).ToStringInr(includePaise: false).ShouldBe("1,23,457");
        Money.FromRupees(50).ToStringInr(includePaise: false).ShouldBe("50");
    }

    [Fact]
    public void ToRupeesDecimal_is_the_dto_value()
    {
        Money.FromMinor(129900).ToRupeesDecimal().ShouldBe(1299m);
        Money.FromMinor(999).ToRupeesDecimal().ShouldBe(9.99m);
        Money.FromRupees(79).ToRupeesTruncated().ShouldBe(79);
    }

    [Property]
    public bool addition_is_cancellable(int x, int y) =>
        Money.FromMinor(x) + Money.FromMinor(y) - Money.FromMinor(y) == Money.FromMinor(x);

    [Property]
    public bool full_percent_is_identity(int minor) =>
        Money.FromMinor(minor).ApplyBps(10000).Minor == minor;

    [Property]
    public bool zero_percent_yields_zero(int minor) =>
        Money.FromMinor(minor).ApplyBps(0).Minor == 0;
}
