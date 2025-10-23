import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AppointmentProvider with ChangeNotifier {
  List<Appointment> _appointments = [];
  List<CalendarResource> _resources = [];

  List<Appointment> get appointments => _appointments;
  List<CalendarResource> get resources => _resources;

  void setAppointments(List<Appointment> appointments) {
    _appointments = appointments;
    notifyListeners();
  }

  void setResources(List<CalendarResource> resources) {
    _resources = resources;
    notifyListeners();
  }

  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
    notifyListeners();
  }

  void fetchAppointments() async {
    // Fetch your appointments here and update the state
    // final response = await http.get(...);
    // if (response.statusCode == 200) {
    //   final List<dynamic> data = json.decode(response.body);
    //   final List<Appointment> fetchedAppointments = data.map<Appointment>((item) => Appointment(...)).toList();
    //   setAppointments(fetchedAppointments);
    // }
  }

  void fetchResources() async {
    // Fetch your resources here and update the state
    // final response = await http.get(...);
    // if (response.statusCode == 200) {
    //   final List<dynamic> data = json.decode(response.body);
    //   final List<CalendarResource> fetchedResources = data.map<CalendarResource>((item) => CalendarResource(...)).toList();
    //   setResources(fetchedResources);
    // }
  }
}