import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  
  AdService._();

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // Real Ad Unit IDs from AdMob
  static const String _bannerAdUnitIdAndroid = 'ca-app-pub-4211412916177305/5735993394'; // Real ID
  static const String _bannerAdUnitIdIOS = 'ca-app-pub-4211412916177305/2656751528'; // Real ID

  // Production AdMob IDs configured
  /*
  Android:
  - App ID: ca-app-pub-4211412916177305~2736642577
  - Banner: ca-app-pub-4211412916177305/5735993394
  
  iOS:
  - App ID: ca-app-pub-4211412916177305~3576733916
  - Banner: ca-app-pub-4211412916177305/2656751528
  */

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return _bannerAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      return _bannerAdUnitIdIOS;
    }
    throw UnsupportedError('Unsupported platform');
  }


  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  void createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdReady = true;
          print('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
          _isBannerAdReady = false;
        },
        onAdOpened: (ad) => print('Banner ad opened'),
        onAdClosed: (ad) => print('Banner ad closed'),
      ),
    );

    _bannerAd?.load();
  }


  BannerAd? get bannerAd => _isBannerAdReady ? _bannerAd : null;

  void dispose() {
    _bannerAd?.dispose();
  }
}