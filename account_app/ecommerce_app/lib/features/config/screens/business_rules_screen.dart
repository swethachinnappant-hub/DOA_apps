import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/business_config_provider.dart';
import '../../../core/business_config.dart';
import 'package:common_widgets/common_widgets.dart';

class BusinessRulesScreen extends StatelessWidget {
  const BusinessRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<BusinessConfigProvider>();
    final config = configProvider.config;

    final ruleKeys = [
      'allowScreenshots',
      'allowDownload',
      'allowShare',
      'showWatermark',
      'showPrices',
      'showContactInfo',
      'allowPriceSharing',
      'showMOQ',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Rules'),
        actions: [
          TextButton(
            onPressed: () => context.go('/app'),
            child: Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16)),
              decoration: BoxDecoration(
                color: config.accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(Responsive.spacing(context, mobile: 12)),
                    decoration: BoxDecoration(
                      color: config.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(config.icon, color: config.primaryColor, size: 32),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(config.name, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold, color: config.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Configure business rules for this type', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 20)),

            // Privacy & Security Rules
            SectionHeader(title: 'Privacy & Security', padding: EdgeInsets.only(top: 16)),
            SizedBox(height: Responsive.spacing(context, mobile: 8)),
            ..._buildRuleGroup(context, configProvider, config, ruleKeys.sublist(0, 3)),

            SizedBox(height: Responsive.spacing(context, mobile: 20)),

            // Display Rules
            SectionHeader(title: 'Display Settings', padding: EdgeInsets.only(top: 16)),
            SizedBox(height: Responsive.spacing(context, mobile: 8)),
            ..._buildRuleGroup(context, configProvider, config, ruleKeys.sublist(3, 6)),

            SizedBox(height: Responsive.spacing(context, mobile: 20)),

            // Sharing Rules
            SectionHeader(title: 'Sharing & Ordering', padding: EdgeInsets.only(top: 16)),
            SizedBox(height: Responsive.spacing(context, mobile: 8)),
            ..._buildRuleGroup(context, configProvider, config, ruleKeys.sublist(6, 8)),

            SizedBox(height: Responsive.spacing(context, mobile: 24)),

            // Reset to defaults
            AppButton(
              text: 'Reset to Defaults',
              type: AppButtonType.outlined,
              onPressed: () {
                final defaultConfig = BusinessConfig.getConfig(config.type);
                configProvider.updateRules(defaultConfig.rules);
              },
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 24)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRuleGroup(
    BuildContext context,
    BusinessConfigProvider provider,
    BusinessConfig config,
    List<String> ruleKeys,
  ) {
    return ruleKeys.map((ruleKey) {
      final label = BusinessRules.ruleLabels[ruleKey] ?? ruleKey;
      final description = BusinessRules.ruleDescriptions[ruleKey] ?? '';
      final icon = BusinessRules.ruleIcons[ruleKey] ?? Icons.settings;
      final currentValue = _getRuleValue(config.rules, ruleKey);

      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: AppCard(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.spacing(context, mobile: 8)),
                decoration: BoxDecoration(
                  color: currentValue ? config.primaryColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: currentValue ? config.primaryColor : Colors.grey, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2),
                    Text(description, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11), color: Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Switch(
                value: currentValue,
                onChanged: (value) => provider.updateSingleRule(ruleKey, value),
                activeThumbColor: config.primaryColor,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  bool _getRuleValue(BusinessRules rules, String ruleName) {
    switch (ruleName) {
      case 'allowScreenshots': return rules.allowScreenshots;
      case 'allowDownload': return rules.allowDownload;
      case 'allowShare': return rules.allowShare;
      case 'showWatermark': return rules.showWatermark;
      case 'showPrices': return rules.showPrices;
      case 'showContactInfo': return rules.showContactInfo;
      case 'allowPriceSharing': return rules.allowPriceSharing;
      case 'showMOQ': return rules.showMOQ;
      default: return false;
    }
  }
}
