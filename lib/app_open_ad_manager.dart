import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  static final AppOpenAdManager instance = AppOpenAdManager._internal();
  AppOpenAdManager._internal();

  AppOpenAd? _ad;
  bool _isShowing = false;
  bool _isLoaded = false;

  final String adUnitId = "ca-app-pub-3940256099942544/3419835294"; // Test ID baru

  void loadAd() {
    print("🔄 Load App Open Ad...");

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print("✅ App Open Ad LOADED!");
          _ad = ad;
          _isLoaded = true;
        },
        onAdFailedToLoad: (error) {
          print("❌ App Open Ad FAILED to load: $error");
          _ad = null;
          _isLoaded = false;
        },
      ),
    );
  }

  void showAdIfAvailable() {
    if (_isShowing) return;

    if (_ad == null) {
      print("⚠️ Iklan belum siap, load dulu...");
      loadAd(); // load ulang
      return;
    }

    print("🚀 TAMPILKAN App Open Ad!");

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowing = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        print("🔁 Iklan ditutup");

        _isShowing = false;
        ad.dispose();
        loadAd(); // Siapkan iklan berikutnya
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print("❌ GAGAL tampil: $error");

        _isShowing = false;
        ad.dispose();
        loadAd();
      },
    );

    _ad!.show();
    _ad = null;
  }

  bool get isLoaded => _isLoaded;
}