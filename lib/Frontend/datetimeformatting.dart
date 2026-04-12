import 'dart:developer';

import 'package:intl/intl.dart';

String formattedDate(String date) {


  String dateString = date+'T00:00:00';

  // Parse the ISO 8601 date string into a DateTime object
  DateTime dateTime = DateTime.parse(dateString);

  // Create a DateFormat instance with the desired output format
  DateFormat outputFormat = DateFormat('dd.MM.yyyy');

  // Format the DateTime object into a string
  String formattedDate = outputFormat.format(dateTime);

  // Print the formatted date
  return formattedDate;  // Output: Tuesday, June 11, 2024 3:20 PM
}
String formatDateTime(String date)
{
  String dateString = date.replaceAll(" ", "T");

  // Parse the ISO 8601 date string into a DateTime object
  DateTime dateTime = DateTime.parse(dateString);

  // Create a DateFormat instance with the desired output format
  DateFormat outputFormat = DateFormat('dd.MM.yyyy');

  // Format the DateTime object into a string
  String formattedDate = outputFormat.format(dateTime);

  // Print the formatted date
  return formattedDate;  // Output: Tuesday, June 11, 2024 3:20 PM
}
String formatDateTimeSantral(String date)
{
  String dateString = date.replaceAll(" ", "T");

  // Parse the ISO 8601 date string into a DateTime object
  DateTime dateTime = DateTime.parse(dateString);

  // Create a DateFormat instance with the desired output format
  DateFormat outputFormat = DateFormat('dd.MMM.yyyy','tr_TR');

  // Format the DateTime object into a string
  String formattedDate = outputFormat.format(dateTime);

  // Print the formatted date
  return formattedDate;  // Output: Tuesday, June 11, 2024 3:20 PM
}
String fullFormatDate(String date)
{
  String dateString = date+'T00:00:00';

  // Parse the ISO 8601 date string into a DateTime object
  DateTime dateTime = DateTime.parse(dateString);

  // Create a DateFormat instance with the desired output format
  DateFormat outputFormat = DateFormat('d MMMM yyyy', 'tr_TR');

  // Format the DateTime object into a string
  String formattedDate = outputFormat.format(dateTime);

  // Print the formatted date
  return formattedDate;  // Output:
}
String fullFormatDateTime(String date,String time)
{
  String dateString = date+'T'+time;

  // Parse the ISO 8601 date string into a DateTime object
  DateTime dateTime = DateTime.parse(dateString);

  // Create a DateFormat instance with the desired output format
  DateFormat outputFormat = DateFormat('d MMMM yyyy', 'tr_TR');

  // Format the DateTime object into a string
  String formattedDate = outputFormat.format(dateTime);

  // Print the formatted date
  return formattedDate;  // Output:
}
String tarihsaatdonustur(String date,String time)
{
  if(date=='' && time == '')
    return 'Belirtilmemiş';
  String dateString = date+'T'+time;

  // Parse the ISO 8601 date string into a DateTime object
  DateTime dateTime = DateTime.parse(dateString);

  // Create a DateFormat instance with the desired output format
  DateFormat outputFormat = DateFormat('dd.MM.yyyy H:mm', 'tr_TR');

  // Format the DateTime object into a string
  String formattedDate = outputFormat.format(dateTime);

  // Print the formatted date
  return formattedDate;
}
String saatsnkaldir(String time)
{
  String dateString = time;

  // Parse the ISO 8601 date string into a DateTime object
  DateTime dateTime = DateTime.parse("0000-00-00T"+dateString);

  // Create a DateFormat instance with the desired output format
  DateFormat outputFormat = DateFormat('H:mm', 'tr_TR');

  // Format the DateTime object into a string
  String formattedDate = outputFormat.format(dateTime);

  // Print the formatted date
  return formattedDate;

}