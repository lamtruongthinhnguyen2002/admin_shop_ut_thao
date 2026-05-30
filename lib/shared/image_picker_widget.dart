import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget chọn ảnh hoạt động đúng trên cả Web + Mobile
/// Fix Slide 2: click vào vùng ảnh → mở file picker thực sự
class ImagePickerWidget extends StatefulWidget {
  final String? initialUrl;
  final ValueChanged<String?> onImageSelected;

  const ImagePickerWidget({
    super.key,
    this.initialUrl,
    required this.onImageSelected,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final _picker = ImagePicker();
  Uint8List? _webBytes;     // Web: lưu bytes
  String?    _mobileFile;  // Mobile: lưu path
  String?    _networkUrl;  // Đã có URL từ server
  bool       _loading = false;

  @override
  void initState() {
    super.initState();
    _networkUrl = widget.initialUrl;
  }

  // FIX: thực sự gọi ImagePicker + upload lên server
  Future<void> _pick() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() => _loading = true);

      if (kIsWeb) {
        // Web: đọc bytes → hiển thị preview
        final bytes = await file.readAsBytes();
        setState(() {
          _webBytes   = bytes;
          _networkUrl = null;
          _loading    = false;
        });
        // Upload lên server (nếu có backend)
        // final url = await _uploadToServer(bytes, file.name);
        // widget.onImageSelected(url);
        widget.onImageSelected(file.name); // Tạm trả tên file
      } else {
        // Mobile: dùng file path
        setState(() {
          _mobileFile = file.path;
          _networkUrl = null;
          _loading    = false;
        });
        widget.onImageSelected(file.path);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Không thể chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _remove() {
    setState(() {
      _webBytes   = null;
      _mobileFile = null;
      _networkUrl = null;
    });
    widget.onImageSelected(null);
  }

  bool get _hasImage =>
      _webBytes != null || _mobileFile != null || _networkUrl != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Container ảnh – LUÔN có GestureDetector wrap cả vùng
        GestureDetector(
          onTap: _loading ? null : _pick,
          child: Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              border: Border.all(
                color: _hasImage
                    ? const Color(0xFF4F7FFA)
                    : const Color(0xFFE0E4F0),
                width: _hasImage ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFF4F7FFA)))
                : _hasImage
                    ? _ImagePreview(
                        bytes: _webBytes,
                        filePath: _mobileFile,
                        networkUrl: _networkUrl,
                      )
                    : _EmptyPicker(),
          ),
        ),

        // Nút xoá ảnh (chỉ hiện khi đã có ảnh)
        if (_hasImage) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Spacer(),
            TextButton.icon(
              onPressed: _remove,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Xoá ảnh', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Đổi ảnh', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4F7FFA)),
            ),
          ]),
        ],
      ],
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF4F7FFA).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(child: Text('📷', style: TextStyle(fontSize: 24))),
      ),
      const SizedBox(height: 12),
      const Text('Nhấn để chọn ảnh',
        style: TextStyle(fontWeight: FontWeight.w600,
            color: Color(0xFF4F7FFA), fontSize: 14)),
      const SizedBox(height: 4),
      Text('JPG, PNG – Dung lượng tối đa 2MB',
        style: TextStyle(color: Colors.grey[400], fontSize: 12)),
    ],
  );
}

class _ImagePreview extends StatelessWidget {
  final Uint8List? bytes;
  final String?   filePath;
  final String?   networkUrl;

  const _ImagePreview({this.bytes, this.filePath, this.networkUrl});

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return Stack(fit: StackFit.expand, children: [
        Image.memory(bytes!, fit: BoxFit.cover),
        _EditOverlay(),
      ]);
    }
    if (filePath != null && !kIsWeb) {
      return Stack(fit: StackFit.expand, children: [
        Image.file(File(filePath!), fit: BoxFit.cover),
        _EditOverlay(),
      ]);
    }
    if (networkUrl != null) {
      return Stack(fit: StackFit.expand, children: [
        Image.network(networkUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
              child: Text('📦', style: TextStyle(fontSize: 48)))),
        _EditOverlay(),
      ]);
    }
    return const SizedBox.shrink();
  }
}

class _EditOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned(
    right: 10, bottom: 10,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.edit, color: Colors.white, size: 14),
        SizedBox(width: 4),
        Text('Thay đổi', style: TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    ),
  );
}