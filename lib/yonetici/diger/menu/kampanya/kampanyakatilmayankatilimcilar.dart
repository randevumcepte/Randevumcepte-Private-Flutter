
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:randevu_sistem/Models/katilimcilar.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../Frontend/sfdatatable.dart';
import '../../../../Models/kampanyalar.dart';
import 'package:randevu_sistem/Models/colorandtext.dart';


class KatilmayanKampanyaKatilimci extends StatefulWidget {
	final Kampanya kampanyadetayi;
	KatilmayanKampanyaKatilimci({Key? key, required this.kampanyadetayi}) : super(key: key);
	@override
	_TumKampanyaKatilimciState createState() => _TumKampanyaKatilimciState();
}

class _TumKampanyaKatilimciState extends State<KatilmayanKampanyaKatilimci> {
	late List<dynamic> _filteredkatilimcilar = widget.kampanyadetayi.katilimcilar.where((element) => element['durum']=='0').toList();
	late List<dynamic> _katilimcilar = widget.kampanyadetayi.katilimcilar.where((element) => element['durum']=='0').toList();
	late KatilimciDataSource _KatilimciDataGridSource;
	TextEditingController _controller = TextEditingController();

	void initState() {
		super.initState();
		setState(() {

			_KatilimciDataGridSource = KatilimciDataSource(_filteredkatilimcilar,context,'0');

		});

		_controller.addListener(() {
			filterKatilimciData(
					_controller.text, _KatilimciDataGridSource,_katilimcilar);
		});
	}
	void filterKatilimciData(String query, KatilimciDataSource source, List<dynamic>_katilimcilar) {
		List<dynamic> filteredData = _katilimcilar.where((katilimci) {
			return katilimci['musteri']['name'].toLowerCase().contains(query.toLowerCase()) ||
					katilimci['musteri']['cep_telefon'].toLowerCase().contains(query.toLowerCase());
		}).toList();

		setState(() {
			_filteredkatilimcilar = filteredData;

			source.updateKatilimciDataSource(_filteredkatilimcilar,'0');
		});
	}
	@override
	Widget build(BuildContext context) {

		double width = MediaQuery.of(context).size.width;
		double height = MediaQuery.of(context).size.height;
		return Scaffold(

			body: (_filteredkatilimcilar.length == 0) ?
			Container(
				padding: EdgeInsets.all(10),
				height: 100,
				child:
				Center(child:Text('Kayıt bulunmamaktadır.', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.red),)) ,) :
			SingleChildScrollView(
				child: Column(

					children: [
						Padding(
							padding: const EdgeInsets.all(8.0),
							child: TextField(
								controller: _controller,
								decoration: InputDecoration(
									labelText: 'Kayıtta ara...',
									border: OutlineInputBorder(),
								),
							),
						),
						Container(
							height: height-225, // Adjust the height based on your requirements
							child: SfDataGrid(
								source: _KatilimciDataGridSource,
								shrinkWrapRows: true,
								columnWidthMode: ColumnWidthMode.fill,
								defaultColumnWidth: 120,
								allowSwiping: false,



								onSwipeStart: (details) {
									if (details.swipeDirection == DataGridRowSwipeDirection.startToEnd) {
										details.setSwipeMaxOffset(50);
									} else if (details.swipeDirection == DataGridRowSwipeDirection.endToStart) {
										details.setSwipeMaxOffset(50);
									}
									return true;
								},



								columns: <GridColumn>[

									GridColumn(

										width: width*0.3,
										columnName: 'musteri',
										label: Container(

											padding: EdgeInsets.only(left:10.0),
											alignment: Alignment.centerLeft,
											child: Text('Müşteri & Danışan'),
										),
									),
									GridColumn(
										width: width*0.3,
										columnName: 'telefon',
										label: Container(
											//padding: EdgeInsets.all(5.0),
											alignment: Alignment.centerLeft,
											child: Text('Telefon'),
										),
									),
									GridColumn(
										width: width*0,
										columnName: 'durum',
										label: Container(
											//padding: EdgeInsets.all(5.0),
											alignment: Alignment.centerLeft,
											child: Text('Durum'),
										),
									),
									GridColumn(
										width: width*0.3,
										columnName: 'durum_text',
										label: Container(
											//padding: EdgeInsets.all(5.0),
											alignment: Alignment.centerLeft,
											child: Text('Durum'),
										),
									),

								],
							),
						),
					],
				),
			),


		);
	}




}
