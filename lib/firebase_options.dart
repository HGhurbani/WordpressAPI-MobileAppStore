import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for the CreditPhone QA application.
///
/// Android and iOS values match `google-services.json` and
/// `ios/Runner/GoogleService-Info.plist`. Web values are placeholders unless
/// regenerated with `flutterfire configure`.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS. '
          'Run flutterfire configure to generate the Firebase options.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows. '
          'Run flutterfire configure to generate the Firebase options.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux. '
          'Run flutterfire configure to generate the Firebase options.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Fuchsia. '
          'Run flutterfire configure to generate the Firebase options.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyBBH19HM59oCsuSctz45G80Kb1dtnN8YQA",
      authDomain: "book-3d7c1.firebaseapp.com",
      projectId: "book-3d7c1",
      storageBucket: "book-3d7c1.appspot.com",
      messagingSenderId: "641037176066",
      appId: "1:641037176066:web:e6d20e02dcefe9c5c2061b",
      measurementId: "G-G96RWGKFJ7"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBSl6tHzf6x-WQAC4ecuuquoUGtwFfvUn8',
    appId: '1:641037176066:android:ceb3c46ae5f4436cc2061b',
    messagingSenderId: '641037176066',
    projectId: 'book-3d7c1',
    storageBucket: 'book-3d7c1.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCH3U06SRX_qypmd9haO_gon1KK2RQO1vA',
    appId: '1:641037176066:ios:e360cb9fd26d01cfc2061b',
    messagingSenderId: '641037176066',
    projectId: 'book-3d7c1',
    storageBucket: 'book-3d7c1.appspot.com',
    iosBundleId: 'com.creditphone.qatar.creditphoneqa',
  );
}
