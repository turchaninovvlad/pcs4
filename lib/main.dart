import 'dart:convert';
import 'dart:io';  // Добавлено для работы с файлами
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart'; // Для получения директории приложения

void main() {
  runApp(ProductA());
}

class ProductA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Магазин товаров',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProductListPage(),
    );
  }
}

class Product {
  final int id;
  final String name;
  final String description;
  final String image;

  Product({required this.id, required this.name, required this.description, required this.image});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
    };
  }
}

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Product> products = [];
  int nextId = 1;
  String jsonPath = '';

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  // Получение пути к JSON файлу
  Future<String> getJsonFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/data.json';
  }

  Future<void> loadProducts() async {
    jsonPath = await getJsonFilePath();
    if (File(jsonPath).existsSync()) {
      final String response = await File(jsonPath).readAsString();
      final List<dynamic> data = json.decode(response);
      setState(() {
        products = data.map((json) => Product.fromJson(json)).toList();
        nextId = products.isNotEmpty ? products.last.id + 1 : 1;
      });
    } else {
      // Если файл не существует, создаем пустой список
      File(jsonPath).writeAsString('[]');
    }
  }

  Future<void> saveProductsToFile() async {
    final file = File(jsonPath);
    final List<Map<String, dynamic>> jsonProducts = products.map((p) => p.toJson()).toList();
    await file.writeAsString(json.encode(jsonProducts));
  }

  void addProduct(Product product) {
    setState(() {
      products.add(product);
      nextId++;
    });
    saveProductsToFile();
  }

  void removeProduct(int id) {
    setState(() {
      products.removeWhere((product) => product.id == id);
    });
    saveProductsToFile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список товаров'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProductPage(onProductAdded: addProduct, nextId: nextId),
                ),
              );
            },
          ),
        ],
      ),
      body: products.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(
                    product: product,
                    onDelete: () => removeProduct(product.id),
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blue,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.asset(
                          product.image,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(product.name),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AddProductPage extends StatelessWidget {
  final Function(Product) onProductAdded;
  final int nextId;

  AddProductPage({required this.onProductAdded, required this.nextId});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageController = TextEditingController();

  void saveProduct(BuildContext context) {
    final String name = nameController.text;
    final String description = descriptionController.text;
    final String image = imageController.text;

    if (name.isNotEmpty && description.isNotEmpty && image.isNotEmpty) {
      final newProduct = Product(
        id: nextId,
        name: name,
        description: description,
        image: image,
      );
      onProductAdded(newProduct);
      Navigator.pop(context); // Закрываем форму после сохранения
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Заполните все поля')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить товар'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Название:', style: TextStyle(fontSize: 16)),
            TextField(controller: nameController),
            SizedBox(height: 10),
            Text('Описание:', style: TextStyle(fontSize: 16)),
            TextField(controller: descriptionController),
            SizedBox(height: 10),
            Text('Изображение (путь к файлу):', style: TextStyle(fontSize: 16)),
            TextField(controller: imageController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => saveProduct(context),
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;

  ProductDetailPage({required this.product, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              // Подтверждение удаления
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Удалить товар"),
                    content: Text("Вы уверены, что хотите удалить этот товар?"),
                    actions: [
                      TextButton(
                        child: Text("Отмена"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text("Удалить"),
                        onPressed: () {
                          onDelete();
                          Navigator.of(context).pop();
                          Navigator.of(context).pop(); // Возврат к списку товаров после удаления
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(product.image),
            SizedBox(height: 10),
            Text(
              product.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(product.description),
          ],
        ),
      ),
    );
  }
}
