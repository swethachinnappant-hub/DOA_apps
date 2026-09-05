import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:common_widgets/common_widgets.dart';
import '../../config/providers/business_config_provider.dart';
import '../../../core/business_config.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final rules = config.rules;
    final isWide = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details'), actions: [
        IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
        if (rules.allowShare)
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
      ]),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16)),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(child: AppButton(text: 'Add to Cart', onPressed: () => context.push('/cart'))),
              SizedBox(width: 12),
              Expanded(child: AppButton(text: 'Buy Now', color: config.secondaryColor, onPressed: () => context.push('/checkout'))),
            ],
          ),
        ),
      ),
      body: isWide ? _buildWideLayout(context, config) : _buildMobileLayout(context, config),
    );
  }

  Widget _buildWideLayout(BuildContext context, BusinessConfig config) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: config.accentColor,
            child: Stack(
              children: [
                Center(child: Icon(config.icon, size: 120, color: config.primaryColor.withValues(alpha: 0.3))),
                if (config.rules.showWatermark)
                  Positioned.fill(
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          config.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: config.primaryColor.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!config.rules.allowDownload)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Flexible(child: Text('Download Protected', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(flex: 1, child: _buildDetails(context, config)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, BusinessConfig config) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            color: config.accentColor,
            child: Stack(
              children: [
                Center(child: Icon(config.icon, size: 100, color: config.primaryColor.withValues(alpha: 0.3))),
                if (config.rules.showWatermark)
                  Positioned.fill(
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          config.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: config.primaryColor.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!config.rules.allowDownload)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Flexible(child: Text('Download Protected', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildDetails(context, config),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context, BusinessConfig config) {
    final rules = config.rules;
    return SingleChildScrollView(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Premium ${config.categories.first}', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 22), fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
          SizedBox(height: Responsive.spacing(context, mobile: 8)),
          Text('SKU: SKU-0001', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: Responsive.spacing(context, mobile: 8)),
          Row(children: [Icon(Icons.star, color: Colors.amber, size: 18), SizedBox(width: 4), Text('4.5 (128 reviews)', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13)), maxLines: 1, overflow: TextOverflow.ellipsis)]),
          SizedBox(height: Responsive.spacing(context, mobile: 12)),
          if (rules.showPrices)
            Text('${config.currencySymbol}4,999', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 28), fontWeight: FontWeight.bold, color: config.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis)
          else
            Text('Contact for Price', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 20), fontWeight: FontWeight.bold, color: config.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: Responsive.spacing(context, mobile: 8)),
          if (rules.showMOQ)
            Text('MOQ: 5 units', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: Responsive.spacing(context, mobile: 20)),
          Text('Product Details', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold)),
          SizedBox(height: Responsive.spacing(context, mobile: 12)),
          ...config.productFields.map((field) => Padding(
            padding: EdgeInsets.only(bottom: Responsive.spacing(context, mobile: 8)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: Text(field, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(width: Responsive.spacing(context, mobile: 8)),
                Flexible(
                  flex: 3,
                  child: Text('Premium Quality', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13)), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          )),
          SizedBox(height: Responsive.spacing(context, mobile: 20)),
          Text('Description', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold)),
          SizedBox(height: Responsive.spacing(context, mobile: 8)),
          Text('High quality wholesale product with best market prices. Available for bulk orders with attractive discounts.', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), height: 1.5), maxLines: 6, overflow: TextOverflow.ellipsis),
          if (rules.showContactInfo) ...[
            SizedBox(height: Responsive.spacing(context, mobile: 20)),
            Text('Contact Seller', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold)),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, color: config.primaryColor, size: 22),
                      SizedBox(width: 12),
                      Expanded(child: Text(config.name, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, color: config.primaryColor, size: 22),
                      SizedBox(width: 12),
                      Expanded(child: Text('+91 98765 43210', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: config.primaryColor, size: 22),
                      SizedBox(width: 12),
                      Expanded(child: Text('Rajkot, Gujarat, India', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (!rules.allowShare || !rules.allowPriceSharing) ...[
            SizedBox(height: Responsive.spacing(context, mobile: 16)),
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12)),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !rules.allowShare ? 'Sharing is disabled for this business type' : 'Price sharing is restricted',
                      style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.orange[800]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
