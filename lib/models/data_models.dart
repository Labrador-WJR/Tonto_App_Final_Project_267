class CartItem {
  int id;
  final String name;
  final String imagePath;
  final double price;
  int quantity;
  bool isChecked;

  CartItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.quantity,
    this.isChecked = true,
  });
}

class GarmentView {
  final String label;
  final String imagePath;
  GarmentView({required this.label, required this.imagePath});
}

class SavedAddress {
  final int id;
  final String addressString;
  SavedAddress({required this.id, required this.addressString});
}

List<SavedAddress> mockSavedAddresses = [
  SavedAddress(id: 1, addressString: '123 Main St, Springfield, IL 62704, (555) 123-4567'),
  SavedAddress(id: 2, addressString: '456 Oak Ave, Metropolis, NY 10001, (555) 987-6543'),
  SavedAddress(id: 3, addressString: 'Lorem, Ipsum, Dolar, (Placeholder Address)'),
];

// ---------- Admin Models ----------

class AdminOrder {
  final int id;
  final String customerName;
  final String productName;
  final int quantity;
  final double totalPrice;
  final String status; // Pending, Shipped, Done, etc.
  final DateTime createdAt;

  AdminOrder({
    required this.id,
    required this.customerName,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });
}

class AdminProduct {
  final int id;
  final String name;
  final int stock;
  final double price;
  final int sales;
  final List<String> categories;
  final String imageUrl;

  AdminProduct({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    required this.sales,
    required this.categories,
    this.imageUrl = '',
  });
}