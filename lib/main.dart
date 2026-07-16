import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'login_page.dart';

void main() {
  runApp(
    GetMaterialApp(
      builder: EasyLoading.init(),
      home: const LoginPage(),
    ),
  );
}
