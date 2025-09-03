import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  
  AdService._();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdReady = false;

  // Real Ad Unit IDs from AdMob
  static const String _bannerAdUnitIdAndroid = 'ca-app-pub-4211412916177305/5735993394'; // Real ID
  static const String _bannerAdUnitIdIOS = 'ca-app-pub-4211412916177305/2656751528'; // Real ID
  
  static const String _interstitialAdUnitIdAndroid = 'ca-app-pub-4211412916177305/4287180353'; // Real ID
  static const String _interstitialAdUnitIdIOS = 'ca-app-pub-4211412916177305/5602479064'; // Real ID

  // Production AdMob IDs configured
  /*
  Android:
  - App ID: ca-app-pub-4211412916177305~2736642577
  - Banner: ca-app-pub-4211412916177305/5735993394
  - Interstitial: ca-app-pub-4211412916177305/4287180353
  
  iOS:
  - App ID: ca-app-pub-4211412916177305~3576733916
  - Banner: ca-app-pub-4211412916177305/2656751528
  - Interstitial: ca-app-pub-4211412916177305/5602479064
  */

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return _bannerAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      return _bannerAdUnitIdIOS;
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _interstitialAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      return _interstitialAdUnitIdIOS;
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

  void createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          createInterstitialAd(); // Preload next ad
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Interstitial ad failed to show: $error');
          ad.dispose();
          createInterstitialAd(); // Preload next ad
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      print('Interstitial ad is not ready yet');
    }
  }

  BannerAd? get bannerAd => _isBannerAdReady ? _bannerAd : null;

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}