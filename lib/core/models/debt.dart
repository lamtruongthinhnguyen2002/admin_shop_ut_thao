class Debt {
  final String id;
  final String name;        // Tên công nợ (user nhập tay)
  final double debtAmount;  // Số tiền nợ (trích từ đơn hàng)
  final double amountPaid;  // Số tiền khách trả
  final double discount;
  final double totalRevenue;// = debtAmount - amountPaid - discount

  Debt({
    required this.id,
    required this.name,
    required this.debtAmount,
    required this.amountPaid,
    required this.discount,
    required this.totalRevenue,
  });

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
    id: json['id'],
    name: json['name'],
    debtAmount: (json['debt_amount'] as num).toDouble(),
    amountPaid: (json['amount_paid'] as num).toDouble(),
    discount: (json['discount'] as num).toDouble(),
    totalRevenue: (json['total_revenue'] as num).toDouble(),
  );

  // SỬA TẠI ĐÂY: Trả về trường 'name' (hoặc chuỗi rỗng '' thay vì null)
  String get customerName => name.isNotEmpty ? name : 'Không rõ';

  // SỬA TẠI ĐÂY: Trả về số tiền nợ (hoặc tổng nợ còn lại tùy bạn tính toán)
  double get amount => debtAmount;

  // SỬA TẠI ĐÂY: Trả về chuỗi rỗng thay vì null (Vì model hiện tại của bạn chưa lưu ngày hẹn trả)
  String get dueDate => '';

  // SỬA TẠI ĐÂY: Tự động tính toán trạng thái dựa trên số tiền khách đã trả
  String get status {
    double conNo = debtAmount - amountPaid - discount;
    if (conNo <= 0) {
      return 'Đã thanh toán';
    } else if (amountPaid > 0) {
      return 'Trả một phần';
    } else {
      return 'Chưa trả';
    }
  }
}