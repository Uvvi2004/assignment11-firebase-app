import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ProductPage(),
    );
  }
}

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  // 🔥 ADD PRODUCT FUNCTION
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
                await FirebaseFirestore.instance.collection('products').add({
                  'name': nameController.text,
                  'price': double.parse(priceController.text),
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

  @override
  Widget build(BuildContext context) {
    final CollectionReference products =
        FirebaseFirestore.instance.collection('products');

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
              );
            }).toList(),
          );
        },
      ),

      // 🔥 ADD BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addProduct(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}