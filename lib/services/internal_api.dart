import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:universal_io/io.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unipi_orario/utils/globals.dart' as globals;

class InternalAPI {
  late SharedPreferences prefs;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  bool get isDarkMode => prefs.getBool('isDarkMode') ?? true;
  bool get isDynamicTheme => prefs.getBool('isDynamicTheme') ?? false;
  String get currentUserName =>
      (prefs.getString('currentUserName') != null && prefs.getString('currentUserName')!.isNotEmpty) ? prefs.getString('currentUserName')! : 'TOTTI';

  set isDarkMode(bool value) => prefs.setBool('isDarkMode', value);
  set isDynamicTheme(bool value) => prefs.setBool('isDynamicTheme', value);
  set currentUserName(String value) => prefs.setString('currentUserName', value);

  Future<bool> isDynamicThemeSupported() async {
    if (Platform.isAndroid && !kIsWeb) {
      final AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 31;
    }
    return false;
  }

  void setDarkMode(bool value, BuildContext ctx) {
    String themeName = value ? 'dark' : 'light';
    isDynamicTheme ? themeName += 'Dynamic' : null;
    isDarkMode = value;

    ThemeSwitcher.of(ctx).changeTheme(
      theme: globals.allThemes[themeName]!,
    );
  }

  void setDynamicMode(bool value, BuildContext ctx) {
    String themeName = isDarkMode ? 'dark' : 'light';
    value ? themeName += 'Dynamic' : null;
    isDynamicTheme = value;

    ThemeSwitcher.of(ctx).changeTheme(
      theme: globals.allThemes[themeName]!,
    );
  }

  ThemeData getLastTheme() {
    String themeName = isDarkMode ? 'dark' : 'light';
    isDynamicTheme ? themeName += 'Dynamic' : null;

    return globals.allThemes[themeName]!;
  }

  requestSnackBar({
    required String title,
    required void Function() onClick,
    required String subtitle,
    required String buttonText,
    required BuildContext context,
  }) {
    if (Get.isSnackbarOpen) {
      return;
    }

    Get.snackbar(
      title,
      subtitle,
      onTap: (_) => onClick,
      mainButton: TextButton(
        onPressed: onClick,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: Text(buttonText),
      ),
      snackPosition: SnackPosition.BOTTOM,
      overlayBlur: 0,
      isDismissible: true,
      colorText: Theme.of(context).colorScheme.onError,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }
}
