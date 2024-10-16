import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_shopping_list/data/categories.dart';
import 'package:flutter_shopping_list/models/grocery_item.dart';
import 'package:flutter_shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  bool _isloading = true;
  String? _error;

  @override
  void initState() {
    _loadItem();
    super.initState();
  }

  void _loadItem() async {
    final url = Uri.https(
        'orderice-19a30-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping_list.json');
    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = "Failed to fetch data. Please try again later";
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isloading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);

      List<GroceryItem> loadedItems = [];
      for (var item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (element) => element.value.type == item.value['category'])
            .value;
        loadedItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category));
      }
      _isloading = false;
      setState(() {
        _groceryItems = loadedItems;
      });
    } catch (err) {
      setState(() {
        _error = "Something went wrong!. Please try again later";
      });
    }
  }

  void _addItem() async {
    final newItem =
        await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(
      builder: (context) => const NewItem(),
    ));

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
        'orderice-19a30-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping_list/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet!.'));
    if (_isloading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          onDismissed: (direction) => _removeItem(_groceryItems[index]),
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        body: content);
  }
}
