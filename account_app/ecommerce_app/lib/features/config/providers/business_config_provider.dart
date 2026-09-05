import 'package:flutter/material.dart';
import '../../../core/business_config.dart';

class BusinessConfigProvider extends ChangeNotifier {
  BusinessConfig _config = BusinessConfig.getConfig(BusinessType.jewellery);

  BusinessConfig get config => _config;

  void setBusinessType(BusinessType type) {
    _config = BusinessConfig.getConfig(type);
    notifyListeners();
  }

  void updateRules(BusinessRules rules) {
    _config = _config.copyWith(rules: rules);
    notifyListeners();
  }

  void updateSingleRule(String ruleName, bool value) {
    final currentRules = _config.rules;
    BusinessRules newRules;

    switch (ruleName) {
      case 'allowScreenshots':
        newRules = currentRules.copyWith(allowScreenshots: value);
        break;
      case 'allowDownload':
        newRules = currentRules.copyWith(allowDownload: value);
        break;
      case 'allowShare':
        newRules = currentRules.copyWith(allowShare: value);
        break;
      case 'showWatermark':
        newRules = currentRules.copyWith(showWatermark: value);
        break;
      case 'showPrices':
        newRules = currentRules.copyWith(showPrices: value);
        break;
      case 'showContactInfo':
        newRules = currentRules.copyWith(showContactInfo: value);
        break;
      case 'allowPriceSharing':
        newRules = currentRules.copyWith(allowPriceSharing: value);
        break;
      case 'showMOQ':
        newRules = currentRules.copyWith(showMOQ: value);
        break;
      default:
        return;
    }

    _config = _config.copyWith(rules: newRules);
    notifyListeners();
  }
}
