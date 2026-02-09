import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/design_tokens.dart';
import '../../../services/google_auth_service.dart';
import '../../../services/api_service.dart';

class TestAuthScreen extends StatefulWidget {
  const TestAuthScreen({super.key});

  @override
  State<TestAuthScreen> createState() => _TestAuthScreenState();
}

class _TestAuthScreenState extends State<TestAuthScreen> {
  String _result = '';
  bool _isLoading = false;

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing Google Sign-In...';
    });

    try {
      final account = await GoogleAuthService.instance.signIn();
      
      if (account != null) {
        setState(() {
          _result = '''
✅ Google Sign-In Success!

Email: ${account.email}
Name: ${account.displayName}
ID: ${account.id}

Photo: ${account.photoUrl ?? 'No photo'}
          ''';
        });
      } else {
        setState(() => _result = '❌ Google Sign-In cancelled or failed');
      }
    } catch (e) {
      setState(() => _result = '❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testBackendConnection() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing backend connection...';
    });

    try {
      final baseUrl = ApiService.instance.baseUrl;
      setState(() {
        _result = '''
✅ Backend Configuration

Base URL: $baseUrl

Status: Backend is configured
Note: Email sending requires backend implementation
        ''';
      });
    } catch (e) {
      setState(() => _result = '❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testEmailSending() async {
    setState(() {
      _isLoading = true;
      _result = 'Sending test email...';
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiService.instance.baseUrl}/email/test'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': 'choengrayu307@gmail.com'}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = '''
✅ Test Email Sent Successfully!

To: ${data['email']}
Status: ${data['message']}

Check your inbox at choengrayu307@gmail.com
          ''';
        });
      } else {
        setState(() => _result = '❌ Failed: ${response.body}');
      }
    } catch (e) {
      setState(() => _result = '❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testOTPEmail() async {
    setState(() {
      _isLoading = true;
      _result = 'Sending OTP email...';
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiService.instance.baseUrl}/email/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': 'choengrayu307@gmail.com'}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = '''
✅ OTP Email Sent Successfully!

To: choengrayu307@gmail.com
OTP Code: ${data['otp']}

Check your inbox for the verification code.
          ''';
        });
      } else {
        setState(() => _result = '❌ Failed: ${response.body}');
      }
    } catch (e) {
      setState(() => _result = '❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Authentication'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Authentication Tests',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGoogleSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Test Google Sign-In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testBackendConnection,
              icon: const Icon(Icons.cloud),
              label: const Text('Test Backend Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testEmailSending,
              icon: const Icon(Icons.email),
              label: const Text('Test Email Sending'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testOTPEmail,
              icon: const Icon(Icons.lock),
              label: const Text('Test OTP Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_result.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _result,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
