import 'package:flutter/material.dart';

class EmptyInitialWidget extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onRefresh;

  const EmptyInitialWidget({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D2E))),
        const SizedBox(height: 8),
        Text(subtitle,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
          textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRefresh,
          icon: const Text('🔄', style: TextStyle(fontSize: 16)),
          label: const Text('Tải dữ liệu'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F7FFA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ]),
    );
  }
}

/// Widget hiển thị khi lỗi kết nối
class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetryWidget({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📡', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text('Không thể tải dữ liệu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(message,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
            textAlign: TextAlign.center),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Text('🔄', style: TextStyle(fontSize: 16)),
          label: const Text('Thử lại'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F7FFA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    );
  }
}

/// Widget rỗng khi có data nhưng kết quả tìm kiếm empty
class EmptySearchWidget extends StatelessWidget {
  const EmptySearchWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🔍', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('Không tìm thấy kết quả',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Thử tìm kiếm với từ khóa khác',
          style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ]),
    );
  }
}

/// Search + Filter bar dùng chung
class SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final List<String> filterOptions;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback? onRefresh;

  const SearchFilterBar({
    super.key,
    required this.controller,
    required this.hint,
    this.filterOptions = const [],
    this.selectedFilter = 'Tất cả',
    required this.onFilterChanged,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Search field
      Expanded(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('🔍', style: TextStyle(fontSize: 16)),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E4F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E4F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF4F7FFA), width: 1.5),
            ),
          ),
        ),
      ),

      // Filter dropdown
      if (filterOptions.isNotEmpty) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E4F0)),
          ),
          height: 48,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedFilter,
              items: filterOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => onFilterChanged(v!),
              icon: const Text('▼', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ),
        ),
      ],

      // Refresh button
      if (onRefresh != null) ...[
        const SizedBox(width: 8),
        Container(
          height: 48, width: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF4F7FFA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Text('🔄', style: TextStyle(fontSize: 18)),
            onPressed: onRefresh,
            tooltip: 'Làm mới dữ liệu',
          ),
        ),
      ],
    ]);
  }
}