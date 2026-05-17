import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:audioplayers/audioplayers.dart'; 
import '../models/data_models.dart';
import 'address_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> checkoutItems;
  const CheckoutPage({super.key, required this.checkoutItems});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer(); 
  
  bool _isProcessing = false; 

  late List<CartItem> _activeItems;
  String selectedAddress = 'No address selected';
  
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isPaymentExpanded = false;
  final List<String> _allPaymentMethods = ['Cash on Delivery']; //, 'GCash', 'PayMaya', 'Palawan'] //
  String _selectedVoucherTitle = 'Select a Voucher';

  @override
  void initState() {
    super.initState();
    _activeItems = List.from(widget.checkoutItems);
    _fetchDefaultAddress();
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); 
    super.dispose();
  }

  Future<void> _fetchDefaultAddress() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final res = await _supabase.from('user_addresses').select('address_string').eq('user_id', user.id).eq('is_default', true).maybeSingle(); 
      if (res != null && mounted) { setState(() { selectedAddress = res['address_string']; }); }
    } catch (e) {
      debugPrint('Error fetching default address: $e');
    }
  }

  double _getSubtotal() { return _activeItems.fold(0, (sum, item) => sum + (item.price * item.quantity)); }

  double _getMinRequirement(String title) {
    switch (title) { case '₱ 200.00 off': return 500.00; case '₱ 150.00 off': return 400.00; case '₱ 100.00 off': return 300.00; case '₱ 50.00 off': return 200.00; default: return 0.00; }
  }

  double _getDiscountValue() {
    switch (_selectedVoucherTitle) { case '₱ 200.00 off': return 200.00; case '₱ 150.00 off': return 150.00; case '₱ 100.00 off': return 100.00; case '₱ 50.00 off': return 50.00; default: return 0.00; }
  }

  void _showErrorPopup(String message) {
    () async {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    }();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent, elevation: 0,
          child: Center(
            child: Container(
              width: 250, padding: const EdgeInsets.all(24.0), decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50, height: 50, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Center(child: Text('!', style: TextStyle(color: Color(0xFF383E46), fontSize: 28, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 16), const Text('Oops!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)), const SizedBox(height: 24),
                  SizedBox(width: 120, height: 40, child: ElevatedButton(onPressed: () => Navigator.pop(dialogContext), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF383E46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- FIXED: Explicitly pulls down the dialog before navigating ---
  void _showSuccessPopupAndNavigate(String message) {
    () async {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/checkout.mp3'));
    }();

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(seconds: 2), () {
          // 1. Destroy the invisible dialog layer FIRST
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext); 
          }
          // 2. THEN tell the actual screen to go home
          if (mounted) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent, elevation: 0,
          child: Center(
            child: Container(
              width: 250, padding: const EdgeInsets.all(24.0), decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 60, height: 60, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.black, size: 40)),
                  const SizedBox(height: 24),
                  Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _placeOrder(double grandTotal) async {
    if (selectedAddress == 'No address selected' || selectedAddress.isEmpty) { _showErrorPopup('Please select a shipping\naddress before checking out!'); return; }
    setState(() => _isProcessing = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) { _showErrorPopup('Please log in to place an order.'); return; }
      final orderResponse = await _supabase.from('orders').insert({'user_id': user.id, 'total_price': grandTotal, 'status': 'Pending'}).select('id').single();
      final orderId = orderResponse['id'];

      for (var item in _activeItems) {
        final productResp = await _supabase.from('products').select('id').eq('name', item.name).limit(1).maybeSingle();
        final productId = productResp != null ? productResp['id'] : null;
        await _supabase.from('order_items').insert({'order_id': orderId, 'product_id': productId, 'quantity': item.quantity, 'price': item.price});
        if (item.id < 1000000000) { await _supabase.from('cart_items').delete().eq('id', item.id); }
      }

      if (mounted) { _showSuccessPopupAndNavigate('Order Placed Successfully!'); }
    } catch (e) {
      debugPrint('Order Error: $e');
      if (mounted) { _showErrorPopup('Failed to place order.\nPlease try again.'); }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = _activeItems.fold(0, (sum, item) => sum + item.quantity);
    double subtotal = _getSubtotal(); double discount = _getDiscountValue(); double shipping = 50.00; 
    double adjustedSubtotal = subtotal - discount; if (adjustedSubtotal < 0) adjustedSubtotal = 0; 
    double grandTotal = adjustedSubtotal + shipping;
    final cardDecoration = BoxDecoration(color: const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))]);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(title: const Text('Checkout'), backgroundColor: const Color(0xFF2D3238), foregroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddressPage(initialSelectedAddress: selectedAddress)));
                if (result != null) { setState(() { selectedAddress = result; }); }
              },
              child: Container(
                padding: const EdgeInsets.all(16.0), decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Shipping Address:', style: TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 4), Text(selectedAddress, style: TextStyle(color: selectedAddress == 'No address selected' ? Colors.redAccent : Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)])),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _activeItems.length,
              itemBuilder: (context, index) {
                final item = _activeItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: ValueKey(item.id), direction: DismissDirection.horizontal,
                    background: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(8)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                    secondaryBackground: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(8)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                    onDismissed: (direction) {
                      setState(() {
                        _activeItems.removeAt(index);
                        if (_selectedVoucherTitle != 'Select a Voucher' && _getSubtotal() < _getMinRequirement(_selectedVoucherTitle)) { _selectedVoucherTitle = 'Select a Voucher'; _showErrorPopup('Voucher removed:\nMinimum spend no longer met.'); }
                        if (_activeItems.isEmpty) { Navigator.pop(context); }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12.0), decoration: cardDecoration,
                      child: Row(
                        children: [
                          const Icon(Icons.menu, color: Color(0xFF2D3238)), const SizedBox(width: 12),
                          Container(width: 60, height: 60, decoration: BoxDecoration(border: Border.all(color: const Color(0xFF383E46), width: 2), borderRadius: BorderRadius.circular(8)), child: item.imagePath.isNotEmpty && item.imagePath != 'placeholder' ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(item.imagePath, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, color: Colors.grey))) : const Icon(Icons.image, color: Color(0xFF383E46), size: 30)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 16)])),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(onTap: () { if (item.quantity > 1) { setState(() { item.quantity--; if (_selectedVoucherTitle != 'Select a Voucher' && _getSubtotal() < _getMinRequirement(_selectedVoucherTitle)) { _selectedVoucherTitle = 'Select a Voucher'; _showErrorPopup('Voucher removed:\nMinimum spend no longer met.'); }}); } }, child: const Icon(Icons.remove, size: 16)),
                                  Container(margin: const EdgeInsets.symmetric(horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: const Color(0xFF383E46), child: Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                                  GestureDetector(onTap: () { setState(() { item.quantity++; }); }, child: const Icon(Icons.add, size: 16)),
                                ],
                              ),
                              const SizedBox(height: 4), Text('₱ ${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
            GestureDetector(
              onTap: () async {
                final selected = await Navigator.push(context, MaterialPageRoute(builder: (context) => VoucherPage(currentVoucher: _selectedVoucherTitle)));
                if (!context.mounted) return;
                if (selected != null && selected != _selectedVoucherTitle) {
                  double minReq = _getMinRequirement(selected);
                  if (_getSubtotal() >= minReq) { setState(() { _selectedVoucherTitle = selected; }); } else { _showErrorPopup('Minimum spend of ₱${minReq.toStringAsFixed(2)}\nrequired for this voucher.'); }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16.0), decoration: cardDecoration,
                child: Row(children: [const Icon(Icons.discount, color: Color(0xFF2D3238)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Voucher:', style: TextStyle(fontSize: 10, color: Colors.black54)), Text(_selectedVoucherTitle, style: const TextStyle(fontSize: 16, color: Color(0xFF2D3238)))])), const Icon(Icons.chevron_right, color: Color(0xFF2D3238))]),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, decoration: cardDecoration,
              child: Column(
                children: [
                  InkWell(
                    onTap: () { setState(() { _isPaymentExpanded = !_isPaymentExpanded; }); }, borderRadius: BorderRadius.circular(8),
                    child: Padding(padding: const EdgeInsets.all(16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Payment Method:', style: TextStyle(fontSize: 10, color: Colors.black54)), Text(_selectedPaymentMethod, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3238)))]), Icon(_isPaymentExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF2D3238))])),
                  ),
                  if (_isPaymentExpanded) ...[
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Divider(color: Colors.black45, thickness: 1, height: 1)),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Column(children: _allPaymentMethods.map((method) { if (method == _selectedPaymentMethod) return const SizedBox.shrink(); return InkWell(onTap: () { setState(() { _selectedPaymentMethod = method; _isPaymentExpanded = false; }); }, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), child: Row(children: [Container(width: 18, height: 18, decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12), Text(method, style: const TextStyle(fontSize: 16, color: Color(0xFF2D3238)))]))); }).toList())),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16.0), decoration: cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 12),
                  _buildSummaryRow('Total Items:', '$totalItems'), _buildSummaryRow('Subtotal:', '₱ ${subtotal.toStringAsFixed(2)}'), _buildSummaryRow('Discount:', '- ₱ ${discount.toStringAsFixed(2)}'), _buildSummaryRow('Shipping Subtotal:', '₱ ${shipping.toStringAsFixed(2)}'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(color: Colors.black26, thickness: 1)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('₱ ${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _placeOrder(grandTotal),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF383E46), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 4),
              child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Place Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30), 
          ],
        ),
      ),
    );
  }
  Widget _buildSummaryRow(String label, String value) { return Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)), Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87))])); }
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
    {'title': '₱ 200.00 off', 'min': 'min. ₱500', 'expiry': 'Expiring: 5 hours left'}, {'title': '₱ 150.00 off', 'min': 'min. ₱400', 'expiry': 'Expiring: 2 hours left'}, {'title': '₱ 100.00 off', 'min': 'min. ₱300', 'expiry': 'Expiring: 1 day left'}, {'title': '₱ 50.00 off',  'min': 'min. ₱200', 'expiry': 'Expiring: 3 days left'},
  ];

  @override
  void initState() { super.initState(); _selectedVoucher = widget.currentVoucher; }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Voucher'), backgroundColor: const Color(0xFF2D3238), foregroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context, _selectedVoucher))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(padding: EdgeInsets.only(bottom: 16.0), child: Text('Note: One voucher can be applied at a time', style: TextStyle(color: Colors.black54, fontSize: 12))),
            Expanded(
              child: ListView.builder(
                itemCount: _vouchers.length,
                itemBuilder: (context, index) {
                  final voucher = _vouchers[index]; final isSelected = _selectedVoucher == voucher['title'];
                  return GestureDetector(
                    onTap: () { setState(() { _selectedVoucher = voucher['title']!; }); },
                    child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 16.0), padding: const EdgeInsets.all(16.0), decoration: BoxDecoration(color: isSelected ? const Color(0xFF383E46) : const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))]), child: Row(children: [Icon(Icons.discount, size: 40, color: isSelected ? Colors.white : const Color(0xFF2D3238)), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(voucher['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.white : const Color(0xFF2D3238))), const SizedBox(height: 4), Text(voucher['min']!, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.black87)), Text(voucher['expiry']!, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.black87))])])),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}