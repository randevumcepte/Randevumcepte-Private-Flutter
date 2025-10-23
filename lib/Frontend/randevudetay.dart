import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/yonetici/randevular/randevu_page.dart';
import 'package:randevu_sistem/yonetici/randevular/randevuduzenle.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:randevu_sistem/Models/randevular.dart';


import '../../Frontend/indexedstack.dart';
import '../../yukselt.dart';
