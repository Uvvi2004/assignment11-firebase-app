import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProductPage(),
    );
  }
}

class ProductPage extends StatefulWidget {
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');

  String searchQuery = '';
  double? minPrice;
  double? maxPrice;

  TextEditingController minController = TextEditingController();
  TextEditingController maxController = TextEditingController();

  // ADD
  Future<void> _addProduct(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                double price =
                    double.tryParse(priceController.text) ?? 0.0;

                await products.add({
                  'name': nameController.text,
                  'price': price,
                });

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // UPDATE
  Future<void> _updateProduct(
      String id, String currentName, double currentPrice) async {
    TextEditingController nameController =
        TextEditingController(text: currentName);
    TextEditingController priceController =
        TextEditingController(text: currentPrice.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                double price =
                    double.tryParse(priceController.text) ?? 0.0;

                await products.doc(id).update({
                  'name': nameController.text,
                  'price': price,
                });

                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // DELETE
  Future<void> _deleteProduct(String id) async {
    await products.doc(id).delete();
  }

  // FILTER LOGIC
  bool _matchesFilters(DocumentSnapshot doc) {
    final name = doc['name'].toString().toLowerCase();
    final price = (doc['price'] as num).toDouble();

    if (searchQuery.isNotEmpty &&
        !name.contains(searchQuery.toLowerCase())) {
      return false;
    }

    if (minPrice != null && price < minPrice!) return false;
    if (maxPrice != null && price > maxPrice!) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),

      body: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // FILTER
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    decoration:
                        const InputDecoration(labelText: 'Min Price'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        minPrice = double.tryParse(value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    decoration:
                        const InputDecoration(labelText: 'Max Price'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        maxPrice = double.tryParse(value);
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      minPrice = null;
                      maxPrice = null;
                      minController.clear();
                      maxController.clear();
                    });
                  },
                )
              ],
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder(
              stream: products.snapshots(),
              builder: (context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data.docs
                    .where((doc) => _matchesFilters(doc))
                    .toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return ListView(
                  children: docs.map<Widget>((doc) {
                    return ListTile(
                      title: Text(doc['name']),
                      subtitle: Text('\$${doc['price']}'),
                      onTap: () => _updateProduct(
                        doc.id,
                        doc['name'],
                        (doc['price'] as num).toDouble(),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(doc.id),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _addProduct(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}