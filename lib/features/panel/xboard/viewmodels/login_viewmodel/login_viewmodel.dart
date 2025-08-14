// viewmodels/login_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/services/auth_provider.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Placeholder for savedUsername
  String? get savedUsername => null;

  bool _isRememberMe = false;
  bool get isRememberMe => _isRememberMe;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginViewModel({required AuthService authService})
      : _authService = authService {
    _loadSavedCredentials();
    _attemptSilentLogin();
  }

  // Placeholder for _attemptSilentLogin
  void _attemptSilentLogin() {
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
 final savedPassword = prefs.getString('saved_password');
 final savedRememberMe = prefs.getBool('is_remember_me') ?? false;
 final savedTimestamp = prefs.getString('saved_timestamp');

    if (savedUsername != null && savedPassword != null && savedRememberMe && savedTimestamp != null) {
      final savedDateTime = DateTime.parse(savedTimestamp);
      final now = DateTime.now();
      final difference = now.difference(savedDateTime);

      if (difference.inDays < 7) {
 usernameController.text = savedUsername;
 passwordController.text = savedPassword;
 _isRememberMe = savedRememberMe;
      } else {
 _clearSavedCredentials();
      }
    } else {
 _clearSavedCredentials();
    }

    notifyListeners();
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isRememberMe) {
      await prefs.setString('saved_username', usernameController.text);
      await prefs.setString('saved_password', passwordController.text);
 await prefs.setString('saved_timestamp', DateTime.now().toIso8601String());
    } else {
 _clearSavedCredentials();
    }
    await prefs.setBool('is_remember_me', _isRememberMe);
  }

  Future<void> _clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_username');
    await prefs.remove('saved_password');
    await prefs.remove('saved_timestamp');
    _isRememberMe = false;
    // No need to notifyListeners here, _loadSavedCredentials or the initial UI build will handle the state
  }

  void toggleRememberMe(bool value) {
    _isRememberMe = value;
    notifyListeners();
  }

  Future<void> login(
    String email,
    String password,
    BuildContext context,
    WidgetRef ref,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);

      String? authData;
      String? token;

      // 查找 authData 和 token 的方法
      void findAuthData(Map<String, dynamic> json) {
        json.forEach((key, value) {
          if (key == 'auth_data' && value is String) {
            authData = value;
          }
          if (key == 'token' && value is String) {
            token = value;
          }
          if (value is Map<String, dynamic>) {
            findAuthData(value);
          }
        });
      }

      findAuthData(result);

      if (authData != null && token != null) {
        await storeToken(authData!);
        await _saveCredentials();

        // 使用封装好的 Subscription 来更新订阅
        // ignore: use_build_context_synchronously
        await Subscription.updateSubscription(context, ref);
        // 更新 authProvider 状态为已登录
        ref.read(authProvider.notifier).state = true;
      } else {
        throw Exception("Invalid authentication data.");
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
