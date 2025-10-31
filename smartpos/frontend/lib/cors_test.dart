import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const CorsTestApp());
}

class CorsTestApp extends StatelessWidget {
  const CorsTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CORS Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CorsTestPage(),
    );
  }
}

class CorsTestPage extends StatefulWidget {
  const CorsTestPage({super.key});

  @override
  State<CorsTestPage> createState() => _CorsTestPageState();
}

class _CorsTestPageState extends State<CorsTestPage> {
  String _result = 'Press the button to test backend connection';
  bool _isLoading = false;

  Future<void> _testCors() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing connection...';
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/cors-test'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _result = 'Success: ${data['message']}';
        });
      } else {
        setState(() {
          _result = 'Error: Status ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Connection Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing login...';
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/auth/json-login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': 'test',
          'password': '1234',
        }),
      );

      setState(() {
        _result = 'Login Response: ${response.statusCode} - ${response.body}';
      });
    } catch (e) {
      setState(() {
        _result = 'Login Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testRegister() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing registration...';
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': 'testuser',
          'phone': '9876543210',
          'shop_name': 'Test Shop',
          'password': '1234',
          'language_preference': 'en',
        }),
      );

      setState(() {
        _result = 'Register Response: ${response.statusCode} - ${response.body}';
      });
    } catch (e) {
      setState(() {
        _result = 'Register Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CORS Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Backend Connection Test',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _testCors,
                          child: const Text('Test CORS Connection'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _testLogin,
                          child: const Text('Test Login API'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _testRegister,
                          child: const Text('Test Register API'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
