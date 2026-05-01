import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDemoPage extends StatefulWidget {
  const SupabaseDemoPage({super.key});

  @override
  State<SupabaseDemoPage> createState() => _SupabaseDemoPageState();
}

class _SupabaseDemoPageState extends State<SupabaseDemoPage> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _medicineNameController = TextEditingController();

  bool _isBusy = false;
  String _statusMessage = 'Ready to test Supabase.';
  List<Map<String, dynamic>> _medicines = const [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _medicineNameController.dispose();
    super.dispose();
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _isBusy = true;
      _statusMessage = 'Working...';
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await _runAction(() async {
      await _client.auth.signUp(email: email, password: password);

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Sign up complete. Check Supabase Auth for the user.';
      });
    });
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await _runAction(() async {
      await _client.auth.signInWithPassword(email: email, password: password);

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Sign in complete. Session is active.';
      });
    });
  }

  Future<void> _loadMedicines() async {
    await _runAction(() async {
      final rows = await _client.from('medicines').select();

      if (!mounted) {
        return;
      }

      setState(() {
        _medicines = List<Map<String, dynamic>>.from(rows);
        _statusMessage =
            'Database reachable. Loaded ${_medicines.length} medicines.';
      });
    });
  }

  Future<void> _insertMedicine() async {
    final medicineName = _medicineNameController.text.trim();

    if (medicineName.isEmpty) {
      setState(() {
        _statusMessage = 'Enter a medicine name first.';
      });
      return;
    }

    await _runAction(() async {
      await _client.from('medicines').insert({'name': medicineName});

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Inserted "$medicineName" into medicines.';
      });

      await _loadMedicines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Starter')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_statusMessage),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isBusy ? null : _signUp,
                      child: const Text('Sign up'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isBusy ? null : _signIn,
                      child: const Text('Sign in'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _medicineNameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine name for DB test',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isBusy ? null : _loadMedicines,
                      child: const Text('Load medicines'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isBusy ? null : _insertMedicine,
                      child: const Text('Insert medicine'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Medicines table',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_medicines.isEmpty)
                const Text(
                  'No rows loaded yet. Tap "Load medicines" to test the database.',
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medicines.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final medicine = _medicines[index];
                      return ListTile(
                        title: Text(
                          '${medicine['name'] ?? 'Unnamed medicine'}',
                        ),
                        subtitle: Text('id: ${medicine['id'] ?? '-'}'),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
