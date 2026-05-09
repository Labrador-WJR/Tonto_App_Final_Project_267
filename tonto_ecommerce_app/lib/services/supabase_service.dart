import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/data_models.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // ---------------- PRODUCTS ----------------
  static Future<List<Product>> getProducts({
    int limit = 20,
    int offset = 0,
    String? category,
  }) async {
    var query = client.from('products').select('*');
    if (category != null) query = query.eq('category', category);
    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return data.map<Product>((json) => Product.fromMap(json)).toList();
  }

  static Future<Product?> getProductById(String id) async {
    final data =
        await client.from('products').select().eq('id', id).single();
    return Product.fromMap(data);
  }

  // ---------------- CART ----------------
  static Future<List<CartItemModel>> getCartItems(String userId) async {
    final data = await client
        .from('cart_items')
        .select('*, product:product_id(*)')
        .eq('user_id', userId);
    return data.map<CartItemModel>((json) {
      final item = CartItemModel.fromMap(json);
      if (json['product'] != null) {
        item.product = Product.fromMap(json['product']);
      }
      return item;
    }).toList();
  }

  static Future<void> addToCart(String userId, String productId,
      {int quantity = 1}) async {
    // Check if already exists
    final existing = await client
        .from('cart_items')
        .select('id, quantity')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    if (existing != null) {
      final newQty = (existing['quantity'] as int) + quantity;
      await client
          .from('cart_items')
          .update({'quantity': newQty}).eq('id', existing['id']);
    } else {
      await client.from('cart_items').insert({
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
      });
    }
  }

  static Future<void> updateCartQuantity(
      String cartItemId, int newQuantity) async {
    await client
        .from('cart_items')
        .update({'quantity': newQuantity}).eq('id', cartItemId);
  }

  static Future<void> removeCartItem(String cartItemId) async {
    await client.from('cart_items').delete().eq('id', cartItemId);
  }

  // ---------------- ORDERS ----------------
  static Future<OrderModel> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    String status = 'pending',
    Map<String, dynamic>? shippingAddress,
    DateTime? preOrderStart,
    DateTime? arrivalDate,
  }) async {
    final total = items.fold<double>(
        0, (sum, item) => sum + (item['quantity'] * item['unitPrice']));
    final orderData = {
      'user_id': userId,
      'status': status,
      'total_amount': total,
      'shipping_address': shippingAddress,
      'pre_order_start': preOrderStart?.toIso8601String(),
      'arrival_date': arrivalDate?.toIso8601String(),
    };
    final orderRes = await client
        .from('orders')
        .insert(orderData)
        .select()
        .single();
    final orderId = orderRes['id'] as String;

    final orderItemsData = items.map((item) => {
          'order_id': orderId,
          'product_id': item['productId'],
          'quantity': item['quantity'],
          'unit_price': item['unitPrice'],
        }).toList();
    await client.from('order_items').insert(orderItemsData);

    // Clear the user's cart after successful order
    await client.from('cart_items').delete().eq('user_id', userId);

    return OrderModel.fromMap(orderRes);
  }

  static Future<List<OrderModel>> getOrders(String userId,
      {String? status}) async {
    var query = client
        .from('orders')
        .select('*, items:order_items(*, product:product_id(*))')
        .eq('user_id', userId);
    if (status != null) query = query.eq('status', status);
    final data = await query.order('created_at', ascending: false);
    return data.map<OrderModel>((json) {
      final order = OrderModel.fromMap(json);
      if (json['items'] != null) {
        order.items = List<OrderItemModel>.from(json['items'].map((i) {
          final item = OrderItemModel.fromMap(i);
          if (i['product'] != null) {
            item.product = Product.fromMap(i['product']);
          }
          return item;
        }));
      }
      return order;
    }).toList();
  }

  // ---------------- PROFILE ----------------
  static Future<ProfileModel?> getProfile(String userId) async {
    final data = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromMap(data);
  }

  static Future<void> updateProfile(String userId, {
    String? fullName,
    String? username,
    String? avatarUrl,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (phone != null) updates['phone'] = phone;
    await client.from('profiles').update(updates).eq('id', userId);
  }

  // ---------------- REVIEWS ----------------
  static Future<List<ReviewModel>> getReviews(String productId) async {
    final data = await client
        .from('reviews')
        .select('*, user:user_id(username, avatar_url)')
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return data.map<ReviewModel>((json) {
      final review = ReviewModel.fromMap(json);
      if (json['user'] is Map) {
        review.username = json['user']['username'];
      }
      return review;
    }).toList();
  }

  static Future<void> addReview({
    required String productId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    await client.from('reviews').insert({
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
    });
  }
}