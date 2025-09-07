// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyDPYWPqymQ6WL0eAaVMsbxc44R43YdrHt0",
      appId: "1:167044979864:web:89fea4a722b170f22584ed",
      messagingSenderId: "167044979864",
      projectId: "queuetime-app",
      authDomain: "queuetime-app.firebaseapp.com", // nur fuers Web wichtig
      storageBucket: "queuetime-app.firebasestorage.app",
    );
  }
}
