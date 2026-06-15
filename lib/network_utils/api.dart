import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Network{
  final String _url = 'https://app.randevumcepte.com.tr/api/v1';
  //if you are using android studio emulator, change localhost to 10.0.2.2
  var token;

  _getToken() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();

    token = jsonDecode(localStorage.getString('token')!);
    log('Token : '+token.toString());
  }

  authData(data, apiUrl) async {
    var fullUrl = Uri.parse(_url + apiUrl);
    return await http.post(
        fullUrl ,
        body: jsonEncode(data),
        headers: _setHeaders()
    );
  }

  getData(apiUrl) async {
    var fullUrl = Uri.parse(_url + apiUrl);
    await _getToken();
    return await http.get(
        fullUrl,
        headers: _setHeaders()
    );
  }

  _setHeaders() => {
    'Content-type' : 'application/json',
    'Accept' : 'application/json',
    'Authorization' : 'Bearer $token'
  };

}