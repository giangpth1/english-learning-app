import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // Để quay lại màn hình đăng nhập
import 'difficulty_selection_screen.dart'; // Để điều hướng sau khi đăng ký thành công

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _username = '';
  String _email = '';
  String _password = '';
  String _password2 = '';
  String _firstName = '';
  String _lastName = '';
  bool _isLoading = false;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_password != _password2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }
      setState(() => _isLoading = true);
      try {
        bool success = await _authService.register(
          username: _username,
          email: _email,
          password: _password,
          password2: _password2,
          firstName: _firstName,
          lastName: _lastName,
        );
        if (success) {
          if (!mounted) return;
          // Giả sử API trả token khi đăng ký, hoặc bạn có thể điều hướng đến LoginScreen
          // Hiện tại, điều hướng đến DifficultySelectionScreen nếu API trả token
          // Hoặc hiển thị thông báo yêu cầu đăng nhập
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please login or app will auto-login if tokens provided.')),
          );
          // Nếu API đăng ký trả về token và lưu trữ, có thể điều hướng thẳng
           if (await _authService.isLoggedIn()) {
             Navigator.pushReplacement(
               context,
               MaterialPageRoute(builder: (context) => const DifficultySelectionScreen()),
             );
           } else {
            // Nếu API đăng ký không tự động đăng nhập, điều hướng đến màn hình đăng nhập
             Navigator.pushReplacement(
               context,
               MaterialPageRoute(builder: (context) => const LoginScreen()),
             );
           }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Sử dụng ListView để tránh overflow khi bàn phím hiện lên
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _username = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Required' : (!value.contains('@') ? 'Invalid email' : null),
                onSaved: (value) => _email = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _firstName = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _lastName = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length < 8 ? 'Password too short (min 8 chars)' : null,
                onSaved: (value) => _password = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _password2 = value!,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('Register'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
