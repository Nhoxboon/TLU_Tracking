import 'package:flutter/material.dart';
import 'package:android_app/utils/admin_utils.dart';

class AdminCard extends StatefulWidget {
  final String adminName;

  const AdminCard({super.key, required this.adminName});

  @override
  State<AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<AdminCard> {
  bool _isDropdownVisible = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isDropdownVisible) {
      _removeOverlay();
    } else {
      _showDropdown();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isDropdownVisible = false;
    });
  }

  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownVisible = true;
    });
  }

  OverlayEntry _createOverlayEntry() {
    // Get the render box from the context
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _removeOverlay,
            behavior: HitTestBehavior.translucent,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  // Position the dropdown below the admin card
                  Positioned(
                    right: 24, // Align with admin card
                    top: offset.dy + size.height,
                    child: Container(
                      width: 205,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 40,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Change Password option
                          InkWell(
                            onTap: () {
                              _removeOverlay();
                              // Navigate to change password screen
                            },
                            child: SizedBox(
                              width: 205,
                              height: 44,
                              child: Row(
                                children: [
                                  const SizedBox(width: 20),
                                  Icon(
                                    Icons.lock_outline,
                                    size: 14,
                                    color: Colors.pink.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 14),
                                  const Text(
                                    'Đổi mật khẩu',
                                    style: TextStyle(
                                      fontFamily: 'Nunito Sans',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF404040),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Divider
                          Opacity(
                            opacity: 0.25,
                            child: Container(
                              width: 205,
                              height: 1,
                              color: const Color(0xFFD8D8D8),
                            ),
                          ),

                          // Logout option
                          InkWell(
                            onTap: () {
                              _removeOverlay();

                              // Log out the admin user
                              AdminUtils.logoutAdmin();

                              // Hiển thị thông báo đã đăng xuất
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã đăng xuất thành công'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              // Chuyển hướng ngay lập tức tới admin login screen
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/admin/login',
                                (route) => false, // Xóa tất cả các route cũ
                              );
                            },
                            child: SizedBox(
                              width: 205,
                              height: 43,
                              child: Row(
                                children: [
                                  const SizedBox(width: 20),
                                  Icon(
                                    Icons.logout,
                                    size: 14,
                                    color: Colors.red.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Đăng xuất',
                                    style: TextStyle(
                                      fontFamily: 'Nunito Sans',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF404040),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleDropdown,
      child: Row(
        children: [
          // Admin profile section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.adminName,
                style: const TextStyle(
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF404040),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Dropdown icon
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF5C5C5C), width: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isDropdownVisible ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 14,
              color: const Color(0xFF565656),
            ),
          ),
        ],
      ),
    );
  }
}
