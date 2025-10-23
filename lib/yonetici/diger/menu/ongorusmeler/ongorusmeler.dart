import 'dart:async';

import 'package:flutter/material.dart';
import 'package:randevu_sistem/Frontend/yukseltbutonu.dart';
import 'package:randevu_sistem/yonetici/dashboard/gunlukRaporlar/ajandaduzenle.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:randevu_sistem/Backend/backend.dart';
import 'package:randevu_sistem/Frontend/altyuvarlakmenu.dart';
import 'package:randevu_sistem/Frontend/sfdatatable.dart';
import 'ongorusmeduzenle.dart';
import 'ongorusmeekle.dart';

class OnGorusmeler extends StatefulWidget {
	final dynamic isletmebilgi;
	const OnGorusmeler({Key? key,required this.isletmebilgi}) : super(key: key);
	@override
	_OnGorusmelerState createState() => _OnGorusmelerState();
}

class _OnGorusmelerState extends State<OnGorusmeler> {
	TextEditingController _controller = TextEditingController();
	late OnGorusmeDataSource _ongorusmeDataGridSource;
	late String? seciliisletme;
	bool _isLoading = true;
	TextEditingController musteriController = TextEditingController();
	int totalPages = 1;
	bool anyChecked = false;
	bool selectAll = false;
	Timer? _debounce;
	bool firsttimetyping=true;
	String? lastQuery;
	@override
	void initState() {
		super.initState();
		initialize();
		_controller.addListener(() {
			_onSearchChanged();
		});
	}



	void _onSearchChanged() {

		if (_controller.text.length == 0 || _controller.text.length >= 3) {

			if (_debounce?.isActive ?? false) _debounce!.cancel();

			_debounce = Timer(const Duration(milliseconds: 500), () {
				if (_controller.text != lastQuery && !firsttimetyping) {  // Check if the query is different
					setState(() {

						firsttimetyping=false;
						lastQuery = _controller.text; // Update the last search query
						_ongorusmeDataGridSource.search(_controller.text);
						//FocusScope.of(context).unfocus();
					});
				}
			});
		}
		else
		{
			if((_controller.text == '' || _controller.text.length<3) && firsttimetyping)
			{

				setState(() {
					firsttimetyping = false;
				});
			}
		}
	}

	@override
	void dispose() {
		_controller.dispose();
		musteriController.dispose();
		super.dispose();
	}

	Future<void> initialize() async {
		seciliisletme = await secilisalonid();
		setState(() {
			_ongorusmeDataGridSource = OnGorusmeDataSource(
				isletmebilgi: widget.isletmebilgi,
				rowsPerPage: 10,
				salonid: seciliisletme!,
				context: context,
				arama: _controller.text,
			);
			_ongorusmeDataGridSource.isLoadingNotifier.addListener(_onLoadingStateChanged);
			_isLoading = false;
		});
	}

	void _onLoadingStateChanged() {
		setState(() {});
	}

	@override
	Widget build(BuildContext context) {
		final double width = MediaQuery.of(context).size.width;
		final double height = MediaQuery.of(context).size.height;
		return GestureDetector(
			onTap: () {
				// Unfocus the current text field, dismissing the keyboard
				FocusScope.of(context).unfocus();
			},
		  child: _isLoading
		  		? Center(child: CircularProgressIndicator())
		  		: Scaffold(
		  	resizeToAvoidBottomInset: false,
		  	//floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),
		  	appBar: AppBar(
		  		title: Text('Ön Görüşmeler', style: TextStyle(color: Colors.black, fontSize: 18)),
		  		leading: IconButton(
		  			icon: Icon(Icons.arrow_back, color: Colors.black),
		  			onPressed: () => Navigator.of(context).pop(),
		  		),
		  		toolbarHeight: 60,
		  		actions: <Widget>
					[
						if (widget.isletmebilgi["demo_hesabi"].toString() == "1")
		  			Padding(
		  				padding: const EdgeInsets.all(12.0),
		  				child: SizedBox(
		  					width: 100, // <-- Your width
		  					child: YukseltButonu(isletme_bilgi: widget.isletmebilgi,)
		  				),
		  			),
		  			IconButton(
		  				onPressed: () {
		  					Navigator.push(
		  						context,
		  						MaterialPageRoute(
		  							builder: (context) => YeniOnGorusme(ongorusmedatasource: _ongorusmeDataGridSource,isletmebilgi: widget.isletmebilgi,),
		  						),
		  					);
		  				},
		  				icon: Icon(Icons.add, color: Colors.black),
		  				iconSize: 26,
		  			),
		  		],
		  		backgroundColor: Colors.white,
		  	),
		  	body: Column(
		  		children: [
		  			Padding(
		  				padding: const EdgeInsets.all(8.0),
		  				child: TextFormField(
		  					controller: _controller,
		  					keyboardType: TextInputType.text,
		  					decoration: InputDecoration(
		  						hintText: 'Müşteri/danışan adı...',
		  						enabled: true,
		  						focusColor: Color(0xFF6A1B9A),
		  						hoverColor: Color(0xFF6A1B9A),
		  						hintStyle: TextStyle(color: Color(0xFF6A1B9A)),
		  						contentPadding: EdgeInsets.all(5.0),
		  						enabledBorder: OutlineInputBorder(
		  							borderSide: BorderSide(color: Color(0xFF6A1B9A)),
		  							borderRadius: BorderRadius.circular(10.0),
		  						),
		  						border: OutlineInputBorder(
		  							borderRadius: BorderRadius.circular(10.0),
		  						),
		  						focusedBorder: OutlineInputBorder(
		  							borderSide: BorderSide(color: Color(0xFF6A1B9A)),
		  							borderRadius: BorderRadius.circular(10.0),
		  						),
		  					),
		  				),
		  			),
		  			Expanded(

		  				child: SfDataGrid(
		  					source: _ongorusmeDataGridSource,
		  					shrinkWrapRows: true,
		  					columnWidthMode: ColumnWidthMode.fill,
		  					defaultColumnWidth: 120,
		  					allowSwiping: true,
		  					onSwipeStart: (details) {
		  						if (details.swipeDirection == DataGridRowSwipeDirection.startToEnd) {
		  							details.setSwipeMaxOffset(50);
		  						} else if (details.swipeDirection == DataGridRowSwipeDirection.endToStart) {
		  							details.setSwipeMaxOffset(50);
		  						}
		  						return true;
		  					},
		  					startSwipeActionsBuilder: (BuildContext context, DataGridRow row, int rowIndex) {
		  						return GestureDetector(
		  							onTap: () {
		  								Navigator.push(
		  									context,
		  									MaterialPageRoute(
		  										builder: (context) => OnGorusmeDuzenle(
														isletmebilgi: widget.isletmebilgi,
		  											ongorusme: row.getCells()[0].value,
		  											ongorusmedatasource: _ongorusmeDataGridSource,
		  										),
		  									),
		  								);
		  							},
		  							child: Container(
		  								color: Colors.purple,
		  								child: Center(
		  									child: Icon(Icons.edit, color: Colors.white),
		  								),
		  							),
		  						);
		  					},
		  					endSwipeActionsBuilder: (BuildContext context, DataGridRow row, int rowIndex) {
		  						return GestureDetector(
		  							onTap: () async {
		  								// Add your delete logic here
		  							},
		  							child: Container(
		  								color: Colors.red,
		  								child: Center(
		  									child: Icon(Icons.delete, color: Colors.white),
		  								),
		  							),
		  						);
		  					},
		  					onCellTap: (DataGridCellTapDetails details) {
		  						final tappedRow = _ongorusmeDataGridSource.rows[details.rowColumnIndex.rowIndex - 1];
		  						Navigator.push(
		  							context,
		  							MaterialPageRoute(
		  								builder: (context) => OnGorusmeDuzenle(
												isletmebilgi: widget.isletmebilgi,
		  									ongorusmedatasource: _ongorusmeDataGridSource,
		  									ongorusme: tappedRow.getCells()[0].value,
		  								),
		  							),
		  						);
		  					},
		  					columns: <GridColumn>[
		  						GridColumn(
		  							width: width * 0,
		  							columnName: 'ongorusme',
		  							label: Container(
		  								padding: EdgeInsets.all(5.0),
		  								alignment: Alignment.centerLeft,
		  								child: Text('a'),
		  							),
		  						),
		  						GridColumn(
		  							width: width * 0,
		  							columnName: 'id',
		  							label: Container(
		  								padding: EdgeInsets.all(5.0),
		  								alignment: Alignment.centerLeft,
		  								child: Text('#'),
		  							),
		  						),
		  						GridColumn(
		  							width: width * 0.3,
		  							columnName: 'musteridanisan',
		  							label: Container(
		  								padding: EdgeInsets.all(5.0),
		  								alignment: Alignment.centerLeft,
		  								child: Text('Müşteri/Danışan'),
		  							),
		  						),
		  						GridColumn(
		  							width: width * 0.3,
		  							columnName: 'paketurun',
		  							label: Container(
		  								padding: EdgeInsets.all(5.0),
		  								alignment: Alignment.centerLeft,
		  								child: Text('Paket/Ürün'),
		  							),
		  						),
		  						GridColumn(
		  							width: width * 0,
		  							columnName: 'durum',
		  							label: Container(
		  								padding: EdgeInsets.all(5.0),
		  								alignment: Alignment.centerLeft,
		  								child: Text('Durum'),
		  							),
		  						),
		  						GridColumn(
		  							width: width * 0.3,
		  							columnName: 'durum_text',
		  							label: Container(
		  								padding: EdgeInsets.all(5.0),
		  								alignment: Alignment.centerLeft,
		  								child: Text('Durum'),
		  							),
		  						),
		  						GridColumn(
		  							width: width * 0.1,
		  							columnName: 'islem',
		  							label: Container(
		  								padding: EdgeInsets.all(5.0),
		  								alignment: Alignment.center,
		  								child: Text("")
		  							),
		  						),
		  					],
		  				),
		  			),
		  			_buildPaginationControls(),
		  		],
		  	),
		  ),
		);
	}

	Widget _buildPaginationControls() {
		final totalPages = (_ongorusmeDataGridSource.totalPages).ceil();
		return Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: [
				IconButton(
					icon: Icon(Icons.arrow_back),
					onPressed: _ongorusmeDataGridSource.currentPage > 1
							? () {
						setState(() {
							_ongorusmeDataGridSource.setPage(_ongorusmeDataGridSource.currentPage - 1);
						});
					}
							: null,
				),
				Text('Sayfa ${_ongorusmeDataGridSource.currentPage} / $totalPages'),
				IconButton(
					icon: Icon(Icons.arrow_forward),
					onPressed: _ongorusmeDataGridSource.currentPage < totalPages
							? () {
						setState(() {
							_ongorusmeDataGridSource.setPage(_ongorusmeDataGridSource.currentPage + 1);
						});
					}
							: null,
				),
			],
		);
	}
}
