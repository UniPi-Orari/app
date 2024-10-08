import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:unipi_orario/services/internal_api.dart';
import 'package:unipi_orario/services/routes.dart';

import 'package:unipi_orario/utils/globals.dart' as globals;

class DynamicThemeBuilder extends StatefulWidget {
  const DynamicThemeBuilder({
    super.key,
  });

  @override
  State<DynamicThemeBuilder> createState() => _DynamicThemeBuilderState();
}

class _DynamicThemeBuilderState extends State<DynamicThemeBuilder> {
  InternalAPI internalAPI = Get.find<InternalAPI>();

  bool? dynamicSupported;

  initThings() async {
    dynamicSupported = await internalAPI.isDynamicThemeSupported();

    setState(() {});
  }

  @override
  void initState() {
    initThings();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final ThemeData lightDynamicTheme = ThemeData(
          useMaterial3: true,
          colorScheme: lightDynamic?.harmonized(),
        );
        final ThemeData darkDynamicTheme = ThemeData(
          useMaterial3: true,
          colorScheme: darkDynamic?.harmonized(),
        );

        if (dynamicSupported != null && dynamicSupported!) {
          globals.allThemes['lightDynamic'] = lightDynamicTheme;
          globals.allThemes['darkDynamic'] = darkDynamicTheme;
        }

        return dynamicSupported != null
            ? ThemeProvider(
                initTheme: internalAPI.getLastTheme(),
                builder: (_, theme) => GetMaterialApp(
                  theme: theme,
                  initialRoute: RouteGenerator.homePageRoute,
                  onGenerateRoute: RouteGenerator.generateRoute,
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates: [
                    FlutterI18nDelegate(
                      translationLoader: FileTranslationLoader(
                        basePath: 'assets/i18n',
                        fallbackFile: 'en_US',
                        useCountryCode: true,
                      ),
                      missingTranslationHandler: (key, locale) {
                        debugPrint("--- Missing Key: $key, languageCode: ${locale?.languageCode}");
                      },
                    ),
                    ...GlobalMaterialLocalizations.delegates,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('en', 'US'), // 🇺🇸
                    Locale('it', 'IT'), // 🇮🇹
                  ],
                ),
              )
            : const SizedBox();
      },
    );
  }
}
