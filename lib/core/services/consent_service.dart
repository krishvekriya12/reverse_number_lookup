import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

typedef OnConsentGatheringCompleteListener = void Function(FormError? error);

class ConsentService {
  static final ConsentService instance = ConsentService._internal();
  ConsentService._internal();

  Future<void> gatherConsent(OnConsentGatheringCompleteListener onComplete) async {
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
          () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          _loadAndShowConsentFormIfRequired(onComplete);
        } else {
          onComplete(FormError(errorCode: 0, message: "Consent form unavailable"));
        }
      },
          (FormError error) {
        debugPrint("Consent info update failed: ${error.message}");
        onComplete(error);
      },
    );
  }

  void _loadAndShowConsentFormIfRequired(OnConsentGatheringCompleteListener onComplete) {
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      onComplete(error);
    });
  }
}