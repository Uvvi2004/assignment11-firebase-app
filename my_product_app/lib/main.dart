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

class ProductPage extends StatelessWidget {
  ProductPage({super.key});

  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');

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

  // DELETE
  Future<void> _deleteProduct(String id, BuildContext context) async {
    await products.doc(id).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: StreamBuilder(
        stream: products.snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data.docs.map<Widget>((doc) {
              return ListTile(
                title: Text(doc['name']),
                subtitle: Text('\$${doc['price']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProduct(doc.id, context),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addProduct(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}