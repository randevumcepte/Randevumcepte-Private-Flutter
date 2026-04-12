import 'package:flutter/material.dart';

import 'hizmet_calisan.dart';





class Unisex extends StatefulWidget {
    final dynamic isletmebilgi;
    const Unisex({Key? key,required this.isletmebilgi}) : super(key: key);

    @override
    _UnisexState createState() =>
        _UnisexState();
}

class _UnisexState extends State<Unisex> {
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: _buildListView(),
        );
    }

    ListView _buildListView(){
        return ListView(
            children: <Widget>[
                ListTile(
                    leading: Icon(Icons.filter_list_outlined),
                    title: Text('Cilt Bakım'),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HizmetCalisan(isletmebilgi: widget.isletmebilgi,)),
                        );
                    },
                ),

            ],
        );


    }
}
