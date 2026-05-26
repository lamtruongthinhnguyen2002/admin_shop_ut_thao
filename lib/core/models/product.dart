class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String qrCode;      // URL hoặc dữ liệu mã QR
  final bool isOutOfStock;
  final bool isUnavailable;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.qrCode,
    this.isOutOfStock = false,
    this.isUnavailable = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    price: (json['price'] as num).toDouble(),
    quantity: json['quantity'],
    imageUrl: json['image_url'],
    qrCode: json['qr_code'],
    isOutOfStock: json['is_out_of_stock'] ?? false,
    isUnavailable: json['is_unavailable'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'quantity': quantity,
    'image_url': imageUrl,
    'qr_code': qrCode,
    'is_out_of_stock': isOutOfStock,
    'is_unavailable': isUnavailable,
  };
}