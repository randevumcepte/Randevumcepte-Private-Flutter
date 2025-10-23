import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/diger/menu/etkinlik/tumkatilimcilar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../Frontend/progressloading.dart';
import '../../../../Models/etkinlikler.dart';
import 'beklenenkatilimcilar.dart';
import 'katilankatilimcilar.dart';
import 'package:http/http.dart' as http;
import 'katilmayankatilimcilar.dart';


class EtkinlikDetay extends StatefulWidget {
	final Etkinlik etkinlikdetayi;
	final dynamic isletmebilgi;
	const EtkinlikDetay({Key? key,required this.etkinlikdetayi,required this.isletmebilgi}) : super(key: key);

	@override
	_EtkinlikDetayState createState() =>
			_EtkinlikDetayState();
}


class _EtkinlikDetayState extends State<EtkinlikDetay> {
	bool isloading = false;
	@override
	Widget build(BuildContext context) {
		double width = MediaQuery.of(context).size.width;
		double height = MediaQuery.of(context).size.height;
		return
			Scaffold(
				floatingActionButton: (widget.etkinlikdetayi.katilimcilar.where((element) => element['durum']==null).length > 0) ?_bottomButtons():null,
				floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
				appBar: AppBar(
					centerTitle: false,
					title: const Text(' Etkinlik Detay',style: TextStyle(color: Colors.black),),
					leading: IconButton(
						icon: Icon(Icons.clear_rounded, color: Colors.black),
						onPressed: () => Navigator.of(context).pop(),
					),
					actions: [
						if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
						Padding(
							padding: const EdgeInsets.all(12.0),
							child: SizedBox(
								width: 100, // <-- Your width
								child:  YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
							),
						),
					],

					toolbarHeight: 60,

					backgroundColor: Colors.white,




				),


				body: DefaultTabController(
					length: 4,
					child: SingleChildScrollView(
						child: Column(
							children: [
								Padding(
									padding: const EdgeInsets.all(8.0),
									child: ListTile(
											title: Row(
												children: [
													Column(
														children: [
															Text('Tarih'),
															Row(
																children: [
																	Text(DateFormat('dd.MM.yyyy hh:mm').format(DateTime.parse(widget.etkinlikdetayi.tarih_saat))),

																],
															),

														],
													),
													Spacer(),
													Column(
														children: [
															Text('Etkinlik Adı'),
															Text(widget.etkinlikdetayi.etkinlik_adi)
														],
													)

												],
											)

									),
								),
								Divider(),
								Padding(
									padding: const EdgeInsets.all(8.0),
									child: ListTile(
											title: Row(
												children: [
													Column(
														children: [
															Text('Katılımcı Sayısı'),
															Text(widget.etkinlikdetayi.katilimcilar.length.toString()),
														],
													),
													Spacer(),
													Column(
														children: [
															Text('Fiyat'),
															Text(widget.etkinlikdetayi.fiyat+' ₺')
														],
													)

												],
											)

									),
								),
								Divider(),
								TabBar(indicatorSize: TabBarIndicatorSize.label,

										unselectedLabelColor: Colors.purple[800],
										labelPadding: EdgeInsets.only(left: 2,right: 2),
										indicator: BoxDecoration(
												gradient: LinearGradient(
														colors: [Color(0xFF6A1B9A), Colors.purpleAccent]),

												borderRadius: BorderRadius.circular(10),
												color: Colors.purple[800]),
										tabs: [

											Tab(
												child: Align(
													alignment: Alignment.center,
													child: Text("Tümü",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
												),
											),
											Tab(
												child: Align(
													alignment: Alignment.center,
													child: Text("Katılanlar",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
												),
											),
											Tab(
												child: Align(
													alignment: Alignment.center,
													child: Text("Katılmayanlar",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
												),
											),
											Tab(
												child: Align(
													alignment: Alignment.center,
													child: Text("Beklenenler",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
												),
											),
										]),
								SizedBox(
									height: height*0.55,
									child: SingleChildScrollView(
										scrollDirection: Axis.vertical,
										child: ConstrainedBox(
											constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height*2.0),
											child: Column(
												children: [
													Expanded(
														child: SizedBox(
															height: double.infinity,
															child: TabBarView(
																children: <Widget>[
																	TumEtkinlikKatilimci(etkinlikdetayi: widget.etkinlikdetayi),
																	KatilanEtkinlikKatilimci(etkinlikdetayi: widget.etkinlikdetayi),
																	KatilmayanEtkinlikKatilimci(etkinlikdetayi: widget.etkinlikdetayi),
																	BeklenenEtkinlikKatilimci(etkinlikdetayi: widget.etkinlikdetayi)
																],
															),
														),
													),
												],
											),
										),
									),
								),


							],
						),
					),
				),
			);

	}
	Widget _bottomButtons() {
		return FloatingActionButton(
			shape: StadiumBorder(),
			onPressed: () {
				// Show the confirmation dialog when the button is pressed
				showDialog(
					context: context,
					builder: (BuildContext context) {
						return AlertDialog(
							title: const Text('SMS Gönder',style: TextStyle(color:Colors.deepPurple),),
							content: const Text('Beklenen katılımcılara SMS gönder !'),
							actions: <Widget>[
								TextButton(
									child: const Text('İptal',style: TextStyle(color:Colors.red),),
									onPressed: () {
										Navigator.of(context).pop(); // Close the dialog
									},
								),
								TextButton(
									child: const Text('Gönder',style: TextStyle(color:Colors.purple),),
									onPressed: () {
										// Close the dialog and send the SMS
										Navigator.of(context).pop();
										smsgonder(context);



									},
								),
							],
						);
					},
				);
			},
			backgroundColor: Colors.redAccent,
			child: const Icon(
				Icons.message,
				size: 20.0,
			),
		);
	}

	Future<void> smsgonder(BuildContext context) async {



		Map<String, dynamic> formData = {
			'etkinlikid':widget.etkinlikdetayi.id.toString()
		};

		final response = await http.post(
			Uri.parse('https://app.randevumcepte.com.tr/api/v1/etkinliktekrarsmsgonder'),

			headers: {'Content-Type': 'application/json'},
			body: jsonEncode(formData),
		);

		if (response.statusCode == 200) {

			setState(() {
				isloading = false;
			});
			Fluttertoast.showToast(
				msg: "Mesajınız gönderildi!",
				toastLength: Toast.LENGTH_SHORT,
				gravity: ToastGravity.BOTTOM,
				backgroundColor: Colors.green,
				textColor: Colors.white,
				fontSize: 16.0,
			);

		}else {
			setState(() {
				isloading = false;
				debugPrint('Error: ${response.body}');
			});


		}




	}
}