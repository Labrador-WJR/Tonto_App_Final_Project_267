import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/data_models.dart';
import '../services/supabase_service.dart';
import 'address_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItemModel> checkoutItems;
  const CheckoutPage({super.key, required this.checkoutItems});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late List<CartItemModel> _activeItems;
  late Map<String, int> _quantities;
  String selectedAddress = 'No address selected';
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isPaymentExpanded = false;
  final List<String> _allPaymentMethods = ['Cash on Delivery', 'GCash', 'PayMaya', 'Palawan'];
  String _selectedVoucherTitle = 'Select a Voucher';

  @override
  void initState() {
    super.initState();
    _activeItems = List<CartItemModel>.from(widget.checkoutItems);
    _quantities = {for (var item in _activeItems) item.id: item.quantity};
    selectedAddress = mockSavedAddresses.isNotEmpty
        ? mockSavedAddresses[0].addressString
        : 'No address selected';
  }

  double _getSubtotal() {
    double sum = 0;
    for (var item in _activeItems) {
      final qty = _quantities[item.id] ?? item.quantity;
      sum += (item.product?.price ?? 0) * qty;
    }
    return sum;
  }

  double _getMinRequirement(String title) {
    switch (title) {
      case '₱ 200.00 off': return 500.00;
      case '₱ 150.00 off': return 400.00;
      case '₱ 100.00 off': return 300.00;
      case '₱ 50.00 off':  return 200.00;
      default: return 0.00;
    }
  }

  double _getDiscountValue() {
    switch (_selectedVoucherTitle) {
      case '₱ 200.00 off': return 200.00;
      case '₱ 150.00 off': return 150.00;
      case '₱ 100.00 off': return 100.00;
      case '₱ 50.00 off':  return 50.00;
      default: return 0.00;
    }
  }

  Future<void> _placeOrder() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to place an order.')),
      );
      return;
    }

    final itemsForOrder = _activeItems.map((item) {
      return {
        'productId': item.productId,
        'quantity': _quantities[item.id] ?? item.quantity,
        'unitPrice': item.product?.price ?? 0,
      };
    }).toList();

    try {
      final order = await SupabaseService.placeOrder(
        userId: userId,
        items: itemsForOrder,
        shippingAddress: {
          'address': selectedAddress,
          'payment': _selectedPaymentMethod,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order placed! Total: ₱${order.totalAmount?.toStringAsFixed(2)}')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = 0;
    for (var item in _activeItems) {
      totalItems += _quantities[item.id] ?? item.quantity;
    }
    double subtotal = _getSubtotal();
    double discount = _getDiscountValue();
    double shipping = 50.00;
    double adjustedSubtotal = subtotal - discount;
    if (adjustedSubtotal < 0) adjustedSubtotal = 0;
    double grandTotal = adjustedSubtotal + shipping;

    final cardDecoration = BoxDecoration(
      color: const Color(0xFFD5D5D5),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFF2D3238),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Shipping Address
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddressPage(initialSelectedAddress: selectedAddress)),
                );
                if (result != null) setState(() => selectedAddress = result);
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF383E46),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Shipping Address:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(selectedAddress, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Product List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activeItems.length,
              itemBuilder: (context, index) {
                final item = _activeItems[index];
                final product = item.product;
                final name = product?.name ?? 'Unknown Product';
                final price = product?.price ?? 0;
                final imageUrl = product?.imageUrl ?? '';
                final qty = _quantities[item.id] ?? item.quantity;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.horizontal,
                    background: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(8)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                    secondaryBackground: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(8)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                    onDismissed: (direction) {
                      setState(() {
                        _quantities.remove(item.id);
                        _activeItems.removeAt(index);
                        if (_selectedVoucherTitle != 'Select a Voucher' && _getSubtotal() < _getMinRequirement(_selectedVoucherTitle)) {
                          _selectedVoucherTitle = 'Select a Voucher';
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher removed: Minimum spend no longer met.')));
                        }
                        if (_activeItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No Items left. Returning.')));
                          Navigator.pop(context);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: cardDecoration,
                      child: Row(
                        children: [
                          const Icon(Icons.menu, color: Color(0xFF2D3238)),
                          const SizedBox(width: 12),
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF383E46), width: 2), borderRadius: BorderRadius.circular(8)),
                            child: imageUrl.isNotEmpty
                                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Color(0xFF383E46), size: 30)))
                                : const Icon(Icons.image, color: Color(0xFF383E46), size: 30),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 16),
                            ]),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (qty > 1) setState(() => _quantities[item.id] = qty - 1);
                                    },
                                    child: const Icon(Icons.remove, size: 16),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    color: const Color(0xFF383E46),
                                    child: Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _quantities[item.id] = qty + 1),
                                    child: const Icon(Icons.add, size: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('₱ ${(price * qty).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),

            // 3. Voucher
            GestureDetector(
              onTap: () async {
                final selected = await Navigator.push(context, MaterialPageRoute(builder: (context) => VoucherPage(currentVoucher: _selectedVoucherTitle)));
                if (!context.mounted) return;
                if (selected != null && selected != _selectedVoucherTitle) {
                  double minReq = _getMinRequirement(selected);
                  if (_getSubtotal() >= minReq) {
                    setState(() => _selectedVoucherTitle = selected);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Minimum spend of ₱${minReq.toStringAsFixed(2)} required for this voucher.')));
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16.0), decoration: cardDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.discount, color: Color(0xFF2D3238)), const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Voucher:', style: TextStyle(fontSize: 10, color: Colors.black54)), Text(_selectedVoucherTitle, style: const TextStyle(fontSize: 16, color: Color(0xFF2D3238)))])),
                    const Icon(Icons.chevron_right, color: Color(0xFF2D3238)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Payment Method
            AnimatedContainer(
              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, decoration: cardDecoration,
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _isPaymentExpanded = !_isPaymentExpanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Payment Method:', style: TextStyle(fontSize: 10, color: Colors.black54)), Text(_selectedPaymentMethod, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3238)))]),
                          Icon(_isPaymentExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF2D3238)),
                        ],
                      ),
                    ),
                  ),
                  if (_isPaymentExpanded) ...[
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Divider(color: Colors.black45, thickness: 1, height: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: _allPaymentMethods.map((method) {
                          if (method == _selectedPaymentMethod) return const SizedBox.shrink();
                          return InkWell(
                            onTap: () => setState(() { _selectedPaymentMethod = method; _isPaymentExpanded = false; }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(children: [Container(width: 18, height: 18, decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12), Text(method, style: const TextStyle(fontSize: 16, color: Color(0xFF2D3238)))]),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Payment Details
            Container(
              padding: const EdgeInsets.all(16.0), decoration: cardDecoration,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Payment Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 12),
                _buildSummaryRow('Total Items:', '$totalItems'),
                _buildSummaryRow('Subtotal:', '₱ ${subtotal.toStringAsFixed(2)}'),
                _buildSummaryRow('Discount:', '- ₱ ${discount.toStringAsFixed(2)}'),
                _buildSummaryRow('Shipping Subtotal:', '₱ ${shipping.toStringAsFixed(2)}'),
                const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(color: Colors.black26, thickness: 1)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('₱ ${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
              ]),
            ),
            const SizedBox(height: 24),

            // 6. Place Order
            ElevatedButton(
              onPressed: _activeItems.isEmpty ? null : _placeOrder,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF383E46), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 4, disabledBackgroundColor: Colors.grey),
              child: const Text('Place Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)), Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87))]));
  }
}

class VoucherPage extends StatefulWidget {
  final String currentVoucher;
  const VoucherPage({super.key, this.currentVoucher = ''});
  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  late String _selectedVoucher;
  final List<Map<String, String>> _vouchers = [
    {'title': '₱ 200.00 off', 'min': 'min. ₱500', 'expiry': 'Expiring: 5 hours left'},
    {'title': '₱ 150.00 off', 'min': 'min. ₱400', 'expiry': 'Expiring: 2 hours left'},
    {'title': '₱ 100.00 off', 'min': 'min. ₱300', 'expiry': 'Expiring: 1 day left'},
    {'title': '₱ 50.00 off',  'min': 'min. ₱200', 'expiry': 'Expiring: 3 days left'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedVoucher = widget.currentVoucher;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Voucher'), backgroundColor: const Color(0xFF2D3238), foregroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context, _selectedVoucher))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Padding(padding: EdgeInsets.only(bottom: 16.0), child: Text('Note: One voucher can be applied at a time', style: TextStyle(color: Colors.black54, fontSize: 12))),
          Expanded(
            child: ListView.builder(
              itemCount: _vouchers.length,
              itemBuilder: (context, index) {
                final voucher = _vouchers[index];
                final isSelected = _selectedVoucher == voucher['title'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedVoucher = voucher['title']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 16.0), padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(color: isSelected ? const Color(0xFF383E46) : const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))]),
                    child: Row(children: [
                      Icon(Icons.discount, size: 40, color: isSelected ? Colors.white : const Color(0xFF2D3238)),
                      const SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(voucher['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.white : const Color(0xFF2D3238))),
                        const SizedBox(height: 4),
                        Text(voucher['min']!, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.black87)),
                        Text(voucher['expiry']!, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.black87)),
                      ]),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}