import 'package:firebase_admob/firebase_admob.dart';

BannerAd myBanner;
InterstitialAd myInterstitial;
MobileAdTargetingInfo targetingInfo;


class Ads {

  Ads() {
    targetingInfo =  MobileAdTargetingInfo(
      keywords: <String>['flutterio', 'beautiful apps'],
      contentUrl: 'https://flutter.io',
      childDirected: false,
      testDevices: <String>[], // Android emulators are considered test devices
    );


    myInterstitial = InterstitialAd(
      // Replace the testAdUnitId with an ad unit id from the AdMob dash.
      // https://developers.google.com/admob/android/test-ads
      // https://developers.google.com/admob/ios/test-ads
      adUnitId: InterstitialAd.testAdUnitId,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("InterstitialAd event is $event");
      },
    );
  }

  Future showBanner() {
    /*              myBanner
                ..load()
                ..show(
                  anchorOffset: 0.0,
                  horizontalCenterOffset: 0.0,
                  anchorType: AnchorType.bottom,
                );*/

/*              myInterstitial
                ..load()
                ..show(
                  anchorType: AnchorType.bottom,
                  anchorOffset: 0.0,
                  horizontalCenterOffset: 0.0,
                );*/
  }
}