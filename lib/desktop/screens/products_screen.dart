import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/models/product.dart';
import '../../shared/page_state.dart';
import '../../shared/widgets.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  PageState<List<Product>> _state = const PageState.initial();
  final _searchCtrl = TextEditingController();
  String _filter    = 'Tất cả';

  static const _filters = ['Tất cả', 'Còn hàng', 'Hết hàng', 'Không khả dụng'];

  // FIX: KHÔNG gọi _load() trong initState
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const PageState.loading());
    try {
      final data = await apiService.getProducts()
          .timeout(const Duration(seconds: 8));
      final products = data.map((e) => Product.fromJson(e)).toList();
      if (mounted) setState(() => _state = PageState.success(products));
    } catch (_) {
      if (mounted) setState(() => _state = PageState.failure(
          'Không kết nối được server.\nKiểm tra backend tại localhost:3000'));
    }
  }

  List<Product> get _filtered {
    final all = _state.data ?? [];
    var list  = all;

    // Filter trạng thái
    if (_filter == 'Còn hàng') {
      list = list.where((p) => !p.isOutOfStock && !p.isUnavailable).toList();
    } else if (_filter == 'Hết hàng') {
      list = list.where((p) => p.isOutOfStock).toList();
    } else if (_filter == 'Không khả dụng') {
      list = list.where((p) => p.isUnavailable).toList();
    }

    // Search
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.description?.toLowerCase().contains(q) ?? false)).toList();
    }
    return list;
  }

  final _isDesktop = true; // được xác định bởi MediaQuery trong build

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      // AppBar cho mobile
      appBar: isDesktop ? null : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Quản Lý Sản Phẩm',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1D2E))),
        actions: [
          TextButton.icon(
            onPressed: () => _goToForm(context),
            icon: const Text('➕', style: TextStyle(fontSize: 16)),
            label: const Text('Thêm'),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 28 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Desktop header
            if (isDesktop) ...[
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Quản Lý Sản Phẩm',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D2E))),
                  const SizedBox(height: 4),
                  Text(
                    _state.isSuccess
                        ? 'Tổng cộng: ${_state.data!.length} sản phẩm'
                        : 'Nhấn "Tải dữ liệu" để bắt đầu',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ]),
                ElevatedButton.icon(
                  onPressed: () => _goToForm(context),
                  icon: const Text('➕', style: TextStyle(fontSize: 16)),
                  label: const Text('Thêm Sản Phẩm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F7FFA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
            ],

            // Search + filter (chỉ hiện khi đã có dữ liệu)
            if (_state.isSuccess) ...[
              SearchFilterBar(
                controller: _searchCtrl,
                hint: 'Tìm tên hoặc mô tả sản phẩm...',
                filterOptions: _filters,
                selectedFilter: _filter,
                onFilterChanged: (v) => setState(() => _filter = v),
                onRefresh: _load,
              ),
              const SizedBox(height: 16),
            ],

            // Body
            Expanded(child: _buildBody(isDesktop)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_state.isInitial) {
      return EmptyInitialWidget(
        emoji: '📦',
        title: 'Chưa tải dữ liệu sản phẩm',
        subtitle: 'Nhấn "Tải dữ liệu" để kết nối server\nvà hiển thị danh sách sản phẩm',
        onRefresh: _load,
      );
    }
    if (_state.isLoading) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4F7FFA)),
          SizedBox(height: 12),
          Text('Đang tải sản phẩm...', style: TextStyle(color: Colors.grey)),
        ],
      ));
    }
    if (_state.isFailure) {
      return ErrorRetryWidget(
          message: _state.errorMessage!, onRetry: _load);
    }

    final list = _filtered;
    if (list.isEmpty) return const EmptySearchWidget();

    // FIX 7: Mobile dùng ListView card đẹp, Desktop dùng GridView
    return isDesktop
        ? _DesktopGrid(products: list, onRefresh: _load,
            onTap: (p) => _goToForm(context, p))
        : _MobileList(products: list, onRefresh: _load,
            onTap: (p) => _goToForm(context, p));
  }

  Future<void> _goToForm(BuildContext context, [Product? product]) async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => ProductFormScreen(product: product)));
    if (result == true) _load(); // Refresh sau khi lưu thành công
  }
}

// ── Desktop: Grid card ────────────────────────────────────
class _DesktopGrid extends StatelessWidget {
  final List<Product> products;
  final VoidCallback onRefresh;
  final ValueChanged<Product> onTap;

  const _DesktopGrid({required this.products,
      required this.onRefresh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        crossAxisSpacing: 16, mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _DesktopProductCard(
        product: products[i], onTap: () => onTap(products[i])),
    );
  }
}

class _DesktopProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _DesktopProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image
        AspectRatio(
          aspectRatio: 16 / 9,
          child: product.imageUrl != null
              ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                if (product.description != null) ...[
                  const SizedBox(height: 4),
                  Text(product.description!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const Spacer(),
                Text(fmt.format(product.price),
                  style: const TextStyle(
                      color: Color(0xFF2DBD8F),
                      fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                // Status chips
                Row(children: [
                  if (product.isOutOfStock)
                    _chip('Hết hàng', Colors.red),
                  if (product.isUnavailable)
                    _chip('Ẩn', Colors.grey),
                  if (!product.isOutOfStock && !product.isUnavailable)
                    _chip('Còn hàng', Colors.green),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F7FFA),
                      side: const BorderSide(color: Color(0xFF4F7FFA)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Chỉnh sửa', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey[100],
    child: const Center(child: Text('📦', style: TextStyle(fontSize: 36))),
  );

  Widget _chip(String text, Color color) => Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text,
        style: TextStyle(color: color, fontSize: 10,
            fontWeight: FontWeight.w600)),
  );
}

// ── FIX 7: Mobile – Beautiful List design ────────────────
class _MobileList extends StatelessWidget {
  final List<Product> products;
  final VoidCallback onRefresh;
  final ValueChanged<Product> onTap;

  const _MobileList({required this.products,
      required this.onRefresh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF4F7FFA),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final p = products[i];
          return GestureDetector(
            onTap: () => onTap(p),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                // Ảnh vuông
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                  child: SizedBox(
                    width: 90, height: 90,
                    child: p.imageUrl != null
                        ? Image.network(p.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey[100],
                                    child: const Center(
                                        child: Text('📦', style: TextStyle(fontSize: 28)))))
                        : Container(color: Colors.grey[100],
                            child: const Center(
                                child: Text('📦', style: TextStyle(fontSize: 28)))),
                  ),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (p.description != null) ...[
                          const SizedBox(height: 3),
                          Text(p.description!,
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(fmt.format(p.price),
                              style: const TextStyle(
                                  color: Color(0xFF2DBD8F),
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: p.isOutOfStock
                                    ? Colors.red.withOpacity(0.1)
                                    : p.isUnavailable
                                        ? Colors.grey.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.isOutOfStock ? 'Hết hàng'
                                    : p.isUnavailable ? 'Ẩn' : 'Còn hàng',
                                style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: p.isOutOfStock ? Colors.red
                                      : p.isUnavailable ? Colors.grey
                                          : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Arrow
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right,
                      color: Colors.grey[400], size: 20),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}