import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';

class SessionWatcher extends StatefulWidget {
  final Widget child;
  const SessionWatcher({super.key, required this.child});

  @override
  State<SessionWatcher> createState() => _SessionWatcherState();
}

class _SessionWatcherState extends State<SessionWatcher> {
  Timer? _inactivityTimer;
  
  // Thiết lập thời gian chờ tối đa (Ví dụ ở đây là 5 phút không thao tác)
  final Duration _timeoutDuration = const Duration(minutes: 5); 

  void _startTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, _handleLogout);
  }

  void _handleLogout() {
    if (apiService.token != null) {
      apiService.logout(); // Xóa Token
      _inactivityTimer?.cancel();
      
      // Đưa hướng người dùng quay lại màn hình đăng nhập
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phiên làm việc hết hạn do bạn không tương tác lâu.')),
        );
        context.go('/login');
      }
    }
  }

  // Khi có bất kì hành động chạm, click, cuộn chuột nào, reset lại bộ đếm giờ
  void _handleUserInteraction([_]) {
    if (apiService.token != null) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerHover: _handleUserInteraction, // Bắt sự kiện di chuột trên Desktop/Web
      child: widget.child,
    );
  }
}