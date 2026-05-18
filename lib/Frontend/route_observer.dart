import 'package:flutter/widgets.dart';

/// Uygulama genelinde paylasilan RouteObserver.
/// MaterialApp.navigatorObservers icinde register edilir.
/// RouteAware widget'lar (orn. Takvim) buna subscribe olarak
/// bir alt sayfadan geri donulduginde (didPopNext) tetiklenir.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
