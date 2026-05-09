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

// ----------------------------------------------------------------
// DATABASE MODELS
// ----------------------------------------------------------------

class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String category;
  final List<String> images;
  final int stock;
  final int soldCount;
  final bool isFeatured;
  final DateTime? preOrderStart;
  final DateTime? arrivalDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.images = const [],
    this.stock = 0,
    this.soldCount = 0,
    this.isFeatured = false,
    this.preOrderStart,
    this.arrivalDate,
    this.createdAt,
    this.updatedAt,
  });

  String get imageUrl => images.isNotEmpty ? images.first : '';
  String get formattedPrice => 'P ${price.toStringAsFixed(2)}';

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      category: map['category'],
      images: List<String>.from(map['images'] ?? []),
      stock: map['stock'] ?? 0,
      soldCount: map['sold_count'] ?? 0,
      isFeatured: map['is_featured'] ?? false,
      preOrderStart: map['pre_order_start'] != null
          ? DateTime.tryParse(map['pre_order_start'])
          : null,
      arrivalDate: map['arrival_date'] != null
          ? DateTime.tryParse(map['arrival_date'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'])
          : null,
    );
  }
}

class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final DateTime? createdAt;
  Product? product;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.createdAt,
    this.product,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'],
      userId: map['user_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String status;
  final double? totalAmount;
  final DateTime? preOrderStart;
  final DateTime? arrivalDate;
  final Map<String, dynamic>? shippingAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  List<OrderItemModel>? items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.status,
    this.totalAmount,
    this.preOrderStart,
    this.arrivalDate,
    this.shippingAddress,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'],
      userId: map['user_id'],
      status: map['status'],
      totalAmount: map['total_amount'] != null
          ? (map['total_amount'] as num).toDouble()
          : null,
      preOrderStart: map['pre_order_start'] != null
          ? DateTime.tryParse(map['pre_order_start'])
          : null,
      arrivalDate: map['arrival_date'] != null
          ? DateTime.tryParse(map['arrival_date'])
          : null,
      shippingAddress: map['shipping_address'] is Map
          ? Map<String, dynamic>.from(map['shipping_address'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'])
          : null,
    );
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  Product? product;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.product,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'],
      orderId: map['order_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      unitPrice: (map['unit_price'] as num).toDouble(),
    );
  }
}

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  String? username;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.username,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'],
      productId: map['product_id'],
      userId: map['user_id'],
      rating: map['rating'],
      comment: map['comment'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }
}

class ProfileModel {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'],
      username: map['username'],
      fullName: map['full_name'],
      avatarUrl: map['avatar_url'],
      phone: map['phone'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }
}