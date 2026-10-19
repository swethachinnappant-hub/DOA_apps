import 'package:flutter/material.dart';

import '../services/bespoke_screen.dart';
import '../services/try_in_store_screen.dart';
import '../virtual/co_shopping_screen.dart';
import '../virtual/virtual_store_screen.dart';
import '../virtual/virtual_tryon_screen.dart';
import 'about_screen.dart';
import 'blog_screen.dart';
import 'contact_screen.dart';
import 'content_screen.dart';
import 'feedback_screen.dart';

/// One H3 block on a reading page (§10.7).
class ContentSection {
  const ContentSection(this.heading, this.paragraphs);

  final String heading;
  final List<String> paragraphs;
}

/// One question on the FAQ accordion.
class ContentFaq {
  const ContentFaq(this.question, this.answer);

  final String question;
  final String answer;
}

/// A designed reading page: serif H1, narrow column, own copy (§10.7).
class ContentPageSpec {
  const ContentPageSpec({
    required this.title,
    this.eyebrow,
    this.intro,
    this.sections = const [],
    this.faqs = const [],
  });

  final String title;
  final String? eyebrow;
  final String? intro;
  final List<ContentSection> sections;
  final List<ContentFaq> faqs;
}

const faqPage = ContentPageSpec(
  title: 'Frequently Asked Questions',
  eyebrow: 'HELP CENTRE',
  intro:
      'Answers to the questions we hear most often. If something is still '
      'unclear, our customer delight team is one call away.',
  faqs: [
    ContentFaq(
      'How do I know the jewellery is certified?',
      'Every diamond above 0.30 carats ships with an IGI or GIA certificate, '
      'and every gold piece carries the BIS hallmark. The certificate number '
      'is printed on your invoice so you can verify it independently.',
    ),
    ContentFaq(
      'What is the purity of the gold you sell?',
      'We work in 18K and 22K yellow, rose and white gold. The purity is '
      'stamped on each piece and repeated in the product details, so what you '
      'see is what is hallmarked.',
    ),
    ContentFaq(
      'How long does delivery take?',
      'Ready-to-ship designs reach you in 3–5 working days across India. '
      'Made-to-order and bespoke pieces take 2–3 weeks, and the expected date '
      'is shown on the product page before you add the piece to your bag.',
    ),
    ContentFaq(
      'Can I return or exchange a piece?',
      'Unused jewellery in its original packaging can be returned within 15 '
      'days of delivery. Exchange for a different size or design is free '
      'once; reverse pickup is arranged by our team.',
    ),
    ContentFaq(
      'Do you offer buyback or exchange on gold?',
      'Yes. Lifetime buyback applies to gold jewellery at the prevailing '
      'metal rate, less making charges, on production of the original invoice '
      'and hallmark.',
    ),
    ContentFaq(
      'Which payment methods do you accept?',
      'UPI, all major cards, net banking, wallets and EMI on orders above '
      '₹25,000. Cash on delivery is available on ready-to-ship designs under '
      '₹50,000.',
    ),
    ContentFaq(
      'Can I book a piece to try in store?',
      'Use Try in Store to pick a boutique, a date and a time slot, and list '
      'the designs you want to see. Our team keeps them ready for your visit.',
    ),
    ContentFaq(
      'How do I care for my jewellery?',
      'Store pieces separately in the pouch they arrive in, avoid perfume and '
      'chlorine, and wipe with a soft cloth after wearing. Free professional '
      'polishing is included once a year at any of our stores.',
    ),
  ],
);

const privacyPage = ContentPageSpec(
  title: 'Privacy Policy',
  eyebrow: 'POLICIES',
  intro:
      'This policy explains what we collect when you browse, shop or contact '
      'us, and how that information is used.',
  sections: [
    ContentSection('What we collect', [
      'When you place an order we collect your name, delivery address, phone '
      'number and email so the order can be packed, shipped and supported. '
      'When you browse we store basic device and session information that '
      'keeps your cart and login alive.',
    ]),
    ContentSection('How it is used', [
      'Order details are shared only with the fulfilment partner carrying '
      'your parcel and with the jeweller fulfilling the piece. Contact details '
      'are used for order updates and, only with your consent, for design '
      'drops and event invitations.',
    ]),
    ContentSection('Cookies', [
      'We use cookies to remember your cart, keep you signed in and '
      'understand which collections are popular. You can clear cookies in '
      'your browser at any time; doing so signs you out and empties the cart.',
    ]),
    ContentSection('Your choices', [
      'You can ask for a copy of your data, correct it, or ask us to delete '
      'your account entirely by writing to Enquiry@online-kirtilals.com. We '
      'action verified requests within 30 days.',
    ]),
  ],
);

const shippingPage = ContentPageSpec(
  title: 'Shipping & Returns',
  eyebrow: 'POLICIES',
  intro:
      'Insured shipping on every parcel, and a 15-day window to change your '
      'mind on ready-to-ship designs.',
  sections: [
    ContentSection('Shipping', [
      'Ready-to-ship designs are dispatched within 48 hours and reach most '
      'Indian cities in 3–5 working days. Every parcel is fully insured until '
      'it is signed for, and the tracking link is sent by SMS and email.',
      'Made-to-order and bespoke pieces are dispatched after final quality '
      'checks, usually within 2–3 weeks of design approval.',
    ]),
    ContentSection('Returns', [
      'Unused jewellery in its original packaging can be returned within 15 '
      'days of delivery. Book the return from your order page and our courier '
      'will collect it from your address at no cost.',
    ]),
    ContentSection('Exchanges', [
      'One free exchange is offered within 15 days for a different size or '
      'another design. Any difference in price is settled securely online '
      'before the new piece ships.',
    ]),
    ContentSection('Lifetime buyback', [
      'Gold jewellery carries a lifetime buyback at the prevailing metal '
      'rate, less making charges, on production of the original invoice and '
      'hallmark.',
    ]),
  ],
);

const investorsPage = ContentPageSpec(
  title: 'Investors',
  eyebrow: 'COMPANY',
  intro:
      'Kirtilal Kalidas Jewellers is a family-run house with eight decades of '
      'craft on the balance sheet.',
  sections: [
    ContentSection('Our story in numbers', [
      'Founded in 1937, the house today serves customers through boutiques '
      'across South and West India and a growing online store that ships '
      'nationwide.',
    ]),
    ContentSection('Governance', [
      'The company is privately held and publishes an annual letter to '
      'customers and partners each January. Statutory filings are available '
      'on request to registered shareholders.',
    ]),
    ContentSection('Working with us', [
      'Suppliers, artisans and retail partners can reach the development '
      'desk at Enquiry@online-kirtilals.com. We review new partnerships twice '
      'a year.',
    ]),
  ],
);

const termsPage = ContentPageSpec(
  title: 'Terms of Service',
  eyebrow: 'POLICIES',
  intro:
      'The ground rules for using this store, placing orders and joining our '
      'events.',
  sections: [
    ContentSection('Using this site', [
      'You may browse without an account. Placing an order requires a phone '
      'number we can reach you on, and an email for the invoice. Reselling '
      'purchases commercially requires a written trade account.',
    ]),
    ContentSection('Pricing and availability', [
      'Prices include GST at the prevailing rate and are held for the '
      'session shown at checkout. Gold-linked prices move with the daily '
      'metal rate; the price you see at checkout is the price you pay.',
    ]),
    ContentSection('Orders and cancellation', [
      'An order is confirmed once payment is authorised. Ready-to-ship '
      'orders can be cancelled before dispatch. Made-to-order pieces can be '
      'cancelled within 48 hours of design approval.',
    ]),
    ContentSection('Certification', [
      'Diamond certificates referenced on a product page ship with the piece. '
      'Hallmarking follows BIS norms for every gold design.',
    ]),
  ],
);

const clpTermsPage = ContentPageSpec(
  title: 'CLP Terms & Conditions',
  eyebrow: 'LOYALTY',
  intro:
      'The Club Loyal Programme rewards every purchase with points you can '
      'redeem at checkout.',
  sections: [
    ContentSection('Earning points', [
      'Members earn 1 point for every ₹100 spent on ready-to-ship and '
      'made-to-order designs. Points post after the return window closes.',
    ]),
    ContentSection('Redeeming points', [
      '100 points are worth ₹100 at checkout, up to 20% of the cart value. '
      'Points cannot be clubbed with select festive offers.',
    ]),
    ContentSection('Balance and expiry', [
      'Your balance lives in the account menu and never expires while the '
      'account is active. Closing the account forfeits unredeemed points.',
    ]),
    ContentSection('Programme changes', [
      'Earn and burn rates may be updated with 30 days notice on this page. '
      'Continued membership means acceptance of the updated rates.',
    ]),
  ],
);

/// Every §10.7 / §10.4 / §10.5 / §10.6 path that renders a designed body
/// instead of the shop listing or the 404 fallback.
final Map<String, Widget Function()> designedPages = {
  '/world-of-kirtilals': () => const AboutScreen(),
  '/blog/country/kirtilals-india': () => const BlogScreen(),
  '/faq': () => const ContentScreen(page: faqPage),
  '/privacy-policy': () => const ContentScreen(page: privacyPage),
  '/shipping-and-return-policy': () => const ContentScreen(page: shippingPage),
  '/investors': () => const ContentScreen(page: investorsPage),
  '/terms-and-conditions': () => const ContentScreen(page: termsPage),
  '/clp-terms': () => const ContentScreen(page: clpTermsPage),
  '/feedback': () => const FeedbackScreen(),
  '/contactusform': () => const ContactScreen(),
  '/tryinstore': () => const TryInStoreScreen(),
  '/bespoke': () => const BespokeScreen(),
  // §10.6: the virtual screens render their own coming-soon hero while the
  // virtualTryOn rule is off, so the switch needs no routing changes.
  '/virtual-tryon': () => const VirtualTryOnScreen(),
  '/virtualstoreproduct': () => const VirtualStoreScreen(),
  '/co-shopping-products': () => const CoShoppingScreen(),
};
