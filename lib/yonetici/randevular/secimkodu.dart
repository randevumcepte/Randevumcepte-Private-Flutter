import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainListScreen(),
    );
  }
}

class MainListScreen extends StatefulWidget {
  @override
  _MainListScreenState createState() => _MainListScreenState();
}

class _MainListScreenState extends State<MainListScreen> {
  List<String> items = ['Item 1', 'Item 2', 'Item 3', 'Item 4'];
  String? selectedItemForItem1;

  void _openSelectableList() async {

    final selectedItem = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectableListScreen(),
      ),
    );

    if (selectedItem != null) {
      setState(() {
        selectedItemForItem1 = selectedItem;
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main List'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(items[index]),
            trailing: items[index] == 'Item 1' && selectedItemForItem1 != null
                ? Text(selectedItemForItem1!)
                : null,
            onTap: () => _openSelectableList(),
          );
        },
      ),
    );
  }
}

class SelectableListScreen extends StatefulWidget {
  final List<String> selectableItems = ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
  @override
  _SelectableListScreenState createState() => _SelectableListScreenState();
}
class _SelectableListScreenState extends State<SelectableListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selectable List'),
      ),
      body: ListView.builder(
        itemCount: widget.selectableItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(widget.selectableItems[index]),
            onTap: () {
              Navigator.pop(context, widget.selectableItems[index]);
            },
          );
        },
      ),
    );
  }
}