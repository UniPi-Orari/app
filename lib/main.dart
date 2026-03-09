import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:unipi_orario/helper/app_database.dart';
import 'package:unipi_orario/services/internal_api.dart';
import 'package:unipi_orario/ui/theme/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  AppDatabase appDatabase = AppDatabase();
  Get.put(appDatabase);

  InternalAPI internalAPI = InternalAPI();
  await internalAPI.init();
  Get.put(internalAPI);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black.withOpacity(0.002),
    ),
  );

  runApp(const UniPiOrario());
}

class UniPiOrario extends StatelessWidget {
  const UniPiOrario({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicThemeBuilder();
  }
}
