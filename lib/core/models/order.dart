class Order {
  final String id;          // Mã đơn hàng (auto-generated)
  final String productName; // = Tên sản phẩm
  final int quantity;
  final double amountDue;   // Số tiền phải trả
  final double discount;    // Giảm giá
  final double amountPaid;  // Số tiền khách trả
  final double debt;        // Công nợ = amountPaid - amountDue (nếu âm = 0)
  final double totalRevenue;// = amountPaid - discount
  final DateTime createdAt;

  Order({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.amountDue,
    required this.discount,
    required this.amountPaid,
    required this.debt,
    required this.totalRevenue,
    required this.createdAt,
  });

  // Tính toán tự động
  static double calcDebt(double amountPaid, double amountDue) {
    final result = amountPaid - amountDue;
    return result < 0 ? 0 : result;
  }

  static double calcRevenue(double amountPaid, double discount) {
    return amountPaid - discount;
  }

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'],
    productName: json['product_name'],
    quantity: json['quantity'],
    amountDue: (json['amount_due'] as num).toDouble(),
    discount: (json['discount'] as num).toDouble(),
    amountPaid: (json['amount_paid'] as num).toDouble(),
    debt: (json['debt'] as num).toDouble(),
    totalRevenue: (json['total_revenue'] as num).toDouble(),
    createdAt: DateTime.parse(json['created_at']),
  );

  get customerName => null;

  get totalAmount => null;

  get date => null;
}