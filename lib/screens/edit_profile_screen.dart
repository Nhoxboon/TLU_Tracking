import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController(text: 'Vishal Khadok');
  final TextEditingController _emailController = TextEditingController(text: 'hello@halallab.co');
  final TextEditingController _birthdayController = TextEditingController(text: '12/02/2025');
  final TextEditingController _hometownController = TextEditingController(text: 'Hải Dương');
  final TextEditingController _phoneController = TextEditingController(text: '408-841-0926');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    _hometownController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar and top app bar
            _buildAppBar(context),
            
            // Form content (scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Name field
                      _buildTextField(
                        controller: _nameController,
                        label: 'Tên',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                      
                      // Email field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          if (!value.contains('@')) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                      
                      // Birthday field (date picker)
                      _buildDatePickerField(
                        controller: _birthdayController,
                        label: 'Ngày sinh',
                        context: context,
                      ),
                      const SizedBox(height: 25),
                      
                      // Hometown field (dropdown)
                      _buildDropdownField(
                        controller: _hometownController,
                        label: 'Quê quán',
                      ),
                      const SizedBox(height: 25),
                      
                      // Phone field
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Số điện thoại',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Save button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildSaveButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 16, right: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 24,
              height: 24,
              child: const Icon(
                Icons.arrow_back,
                size: 24,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Sửa thông tin',
            style: TextStyle(
              fontFamily: 'Sen',
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: Color(0xFF181C2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Sen',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF32343E),
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F5FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Sen',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF6B6E82),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Sen',
            fontSize: 13,
            letterSpacing: 0.02 * 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF32343E),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF2196F3),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              controller.text = '${picked.day.toString().padLeft(2, '0')}/'
                  '${picked.month.toString().padLeft(2, '0')}/'
                  '${picked.year}';
            }
          },
          child: Container(
            width: 148,
            height: 66,
            child: Stack(
              children: [
                Positioned(
                  top: 24,
                  child: Container(
                    width: 148,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Positioned(
                  top: 37,
                  left: 13,
                  child: Text(
                    controller.text,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      letterSpacing: -0.02 * 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xB3000000), // 0.7 opacity
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 37,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
  }) {
    final cities = ['Hà Nội', 'Hải Dương', 'Hải Phòng', 'TP Hồ Chí Minh', 'Đà Nẵng'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Sen',
            fontSize: 13,
            letterSpacing: 0.02 * 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF32343E),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                height: 250,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chọn $label',
                            style: const TextStyle(
                              fontFamily: 'Sen',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: cities.length,
                        itemBuilder: (context, index) {
                          final city = cities[index];
                          return ListTile(
                            title: Text(city),
                            onTap: () {
                              setState(() {
                                controller.text = city;
                              });
                              Navigator.of(context).pop();
                            },
                            selected: controller.text == city,
                            selectedTileColor: const Color(0xFFE3F2FD),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            width: 148,
            height: 66,
            child: Stack(
              children: [
                Positioned(
                  top: 24,
                  child: Container(
                    width: 148,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Positioned(
                  top: 37,
                  left: 13,
                  child: Text(
                    controller.text,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      letterSpacing: -0.02 * 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xB3000000), // 0.7 opacity
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 37,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thông tin đã được lưu thành công'),
              backgroundColor: Color(0xFF2196F3),
            ),
          );
          
          // Return to previous screen after saving
          Future.delayed(const Duration(milliseconds: 1500), () {
            Navigator.of(context).pop();
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2196F3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        child: const Text(
          'LƯU',
          style: TextStyle(
            fontFamily: 'Sen',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}