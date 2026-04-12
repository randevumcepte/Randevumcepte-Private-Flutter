import 'package:flutter/material.dart';
import '../../../../Frontend/altyuvarlakmenu.dart';
import '../../../../Models/musteri_danisanlar.dart';
import 'musteribilgileri/arsivdetay.dart';
import 'islemlerveseanslar.dart';
import 'musteriadisyonlari.dart';
import 'musteridetayrandevular.dart';
import 'musteribilgileri/musterisaglikbilgileri.dart';




class MusteriDetaylari extends StatefulWidget {
	final MusteriDanisan md;
	final dynamic isletmebilgi;
	final int kullanicirolu;
	const MusteriDetaylari({Key? key,required this.md,required this.isletmebilgi,required this.kullanicirolu}) : super(key: key);

	@override
	_MusteriDetaylariState createState() =>
			_MusteriDetaylariState();
}

class _MusteriDetaylariState extends State<MusteriDetaylari> {

	@override
	Widget build(BuildContext context) {
		double width = MediaQuery.of(context).size.width;
		double height = MediaQuery.of(context).size.height;
		return Scaffold(
			//floatingActionButton: AltYuvarlakYeniEkleMenu(isletme_bilgi: widget.isletmebilgi,),
			appBar: AppBar(
				backgroundColor: Colors.white,
				title: Text("${widget.md.name} Detayları",style: TextStyle(color: Colors.black,fontSize: 18),),
				toolbarHeight: 60,
				leading: IconButton(
					icon: Icon(Icons.arrow_back, color: Colors.black),
					onPressed: () => Navigator.of(context).pop(),
				),
			),
			body: _buildListView(),
		);
	}

	ListView _buildListView(){
		return ListView(
			children: <Widget>[
				ListTile(
					title: Text('Randevular'),
					trailing: Icon(Icons.keyboard_arrow_right),
					onTap: () {
						Navigator.push(
							context,
							MaterialPageRoute(
									builder: (context) => MusteriRandevulariMenu(kullanicirolu: widget.kullanicirolu, isletmebilgi: widget.isletmebilgi, md: widget.md,)),
						);
					},
				),
				Divider(),
				ListTile(
					title: Text('Seanslar'),
					trailing: Icon(Icons.keyboard_arrow_right),
					onTap: () {
						Navigator.push(
							context,
							MaterialPageRoute(
									builder: (context) => IslemlerveSeanslar(isletmebilgi: widget.isletmebilgi, kullanici: widget.md,)),
						);
					},
				),
				Divider(),
				ListTile(
					title: Text('Sözleşmeler/Belgeler'),
					trailing: Icon(Icons.keyboard_arrow_right),
					onTap: () {
						Navigator.push(
							context,
							MaterialPageRoute(
									builder: (context) => ArsivDetay(isletmebilgi: widget.isletmebilgi,md: this.widget.md,)),
						);
					},
				),
				Divider(),
				ListTile(
					title: Text('Satışlar'),
					trailing: Icon(Icons.keyboard_arrow_right),
					onTap: () {
						Navigator.push(
							context,
							MaterialPageRoute(
									builder: (context) => MusteriAdiayonlari(kullanicirolu:widget.kullanicirolu, isletmebilgi: widget.isletmebilgi, kullanici: widget.md,)),
						);
					},
				),
				Divider(),
				ListTile(
					title: Text('Sağlık Bilgileri'),
					trailing: Icon(Icons.keyboard_arrow_right),
					onTap: () {
						Navigator.push(
							context,
							MaterialPageRoute(
									builder: (context) => MusteriSaglikBilgileri(md: this.widget.md,)),
						);
					},
				),
				Divider()
			],
		);





	}
}
