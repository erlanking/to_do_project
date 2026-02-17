import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_project/l10n/app_localizations.dart';
import '../services/api_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _api = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final title = _titleController.text.trim();
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        _showError(l10n.tokenMissing);
        return;
      }
      await _api.createTask(token, title);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(l10n.networkError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newTask)),
      body: SafeArea(
        child: Stack(
          children: [
            _BackgroundGlow(
              top: -120,
              right: -40,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
            ),
            _BackgroundGlow(
              bottom: -160,
              left: -60,
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.16),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.addTask,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            textInputAction: TextInputAction.done,
                            minLines: 3,
                            maxLines: 6,
                            decoration: InputDecoration(
                              labelText: l10n.taskText,
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.enterTask;
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) =>
                                _isLoading ? null : _save(),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _save,
                            icon: const Icon(Icons.save_outlined),
                            label: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.save),
                          ),
                        ],
                      ),
                    ),
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

class _BackgroundGlow extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Color color;

  const _BackgroundGlow({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
