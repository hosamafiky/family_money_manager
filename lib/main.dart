import 'package:family_money_manager/app/app.dart';
import 'package:family_money_manager/app/app_config.dart';
import 'package:family_money_manager/app/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  const config = AppConfig.development;
  config.validate();

  runApp(
    ProviderScope(overrides: [appConfigProvider.overrideWithValue(config)], child: const App()),
  );
}
