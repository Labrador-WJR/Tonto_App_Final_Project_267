
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

// Global list of mock saved addresses
List<SavedAddress> mockSavedAddresses = [
  SavedAddress(id: 1, addressString: '123 Main St, Springfield, IL 62704, (555) 123-4567'),
  SavedAddress(id: 2, addressString: '456 Oak Ave, Metropolis, NY 10001, (555) 987-6543'),
  SavedAddress(id: 3, addressString: 'Lorem, Ipsum, Dolar, (Placeholder Address)'),
];
