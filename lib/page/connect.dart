import 'package:flutter/material.dart';
import 'package:health/health.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final HealthFactory _health =
      HealthFactory(useHealthConnectIfAvailable: true);
  final List<HealthDataType> _types = [HealthDataType.ELECTROCARDIOGRAM];
  bool _isAuthorized = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    final isAuthorized = await _health.hasPermissions(_types);
    setState(() {
      _isAuthorized = isAuthorized!;
    });
  }

  Future<void> _requestAuthorization() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final isAuthorized = await _health.requestAuthorization(_types);
      setState(() {
        _isAuthorized = isAuthorized;
        _isRequesting = false;
      });

      if (isAuthorized) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authorization denied. Please try again.'),
          ),
        );
      }
    } catch (e) {
      print('Error requesting authorization: $e');
      setState(() {
        _isRequesting = false;
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Connect',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(
              height: 20,
            ),
            if (_isAuthorized)
              const Text(
                'You are already connected!',
                style: TextStyle(color: Colors.green),
              )
            else if (_isRequesting)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _requestAuthorization,
                child: const Text('Connect Health App'),
              ),
            if (!_isRequesting && !_isAuthorized)
              const Text(
                'If you denied the permission, please try again.',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              )
          ],
        ),
      ),
    );
  }
}
