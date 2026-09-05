import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/business_config_provider.dart';
import '../../../core/business_config.dart';
import 'package:common_widgets/common_widgets.dart';

class BusinessConfigScreen extends StatelessWidget {
  const BusinessConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<BusinessConfigProvider>();
    final currentConfig = configProvider.config;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Business'),
        actions: [
          TextButton(
            onPressed: () => context.go('/app'),
            child: Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose your business type to customize the app experience', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
            SizedBox(height: Responsive.spacing(context, mobile: 20)),
            Text('Current: ${currentConfig.name}', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold, color: currentConfig.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: Responsive.spacing(context, mobile: 16)),

            // Business Type Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.isDesktop(context) ? 4 : (Responsive.isTablet(context) ? 3 : 2),
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: BusinessType.values.length,
              itemBuilder: (context, index) {
                final type = BusinessType.values[index];
                final config = BusinessConfig.getConfig(type);
                final isSelected = type == currentConfig.type;
                return GestureDetector(
                  onTap: () => configProvider.setBusinessType(type),
                  child: Container(
                    padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12)),
                    decoration: BoxDecoration(
                      color: isSelected ? config.primaryColor : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? config.primaryColor : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: config.primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                          : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          config.icon,
                          size: Responsive.fontSize(context, mobile: 32),
                          color: isSelected ? Colors.white : config.primaryColor,
                        ),
                        SizedBox(height: Responsive.spacing(context, mobile: 8)),
                        Text(
                          config.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: Responsive.fontSize(context, mobile: 12),
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isSelected) ...[
                          SizedBox(height: 4),
                          Icon(Icons.check_circle, size: 16, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 24)),

            // Selected business preview
            if (currentConfig.type != BusinessType.custom) ...[
              Text('Preview - ${currentConfig.name}', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: Responsive.spacing(context, mobile: 12)),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(color: currentConfig.accentColor, borderRadius: BorderRadius.circular(12)),
                          child: Icon(currentConfig.icon, color: currentConfig.primaryColor, size: 32),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(currentConfig.name, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold, color: currentConfig.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(currentConfig.tagline, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12)),
                    Text('Categories:', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentConfig.categories.take(6).map((cat) => Chip(
                        label: Text(cat, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11))),
                        backgroundColor: currentConfig.accentColor,
                        labelStyle: TextStyle(color: currentConfig.primaryColor),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                    if (currentConfig.categories.length > 6)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('+${currentConfig.categories.length - 6} more categories', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11), color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12)),
                    Text('Product Fields:', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentConfig.productFields.map((field) => Chip(
                        label: Text(field, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11))),
                        backgroundColor: currentConfig.accentColor,
                        labelStyle: TextStyle(color: currentConfig.primaryColor),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: Responsive.spacing(context, mobile: 24)),

            AppButton(
              text: 'Continue to ${currentConfig.name}',
              onPressed: () => context.go('/app'),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
