import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_project/l10n/app_localizations.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'login_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _token;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  List<Task> _filteredTasks() {
    if (_query.isEmpty) return _tasks;
    return _tasks.where((t) => t.title.toLowerCase().contains(_query)).toList();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }
      _token = token;
      final tasks = await _api.fetchTasks(token);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
      });
    } on ApiException catch (e, st) {
      debugPrint('Load tasks ApiException: ${e.message}, code: ${e.statusCode}');
      debugPrintStack(stackTrace: st);
      if (e.statusCode == 401) {
        await _logout();
        return;
      }
      _showError(e.message);
    } catch (e, st) {
      debugPrint('Load tasks unknown error: $e');
      debugPrintStack(stackTrace: st);
      _showError(AppLocalizations.of(context)!.networkError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle(Task task) async {
    final token = _token;
    if (token == null) return;
    final old = task;
    setState(() {
      _tasks = _tasks.map((t) {
        if (t.id == old.id) return t.copyWith(done: !t.done);
        return t;
      }).toList();
    });

    try {
      final updated = await _api.updateTaskStatus(token, old);
      if (!mounted) return;
      setState(() {
        _tasks = _tasks.map((t) => t.id == updated.id ? updated : t).toList();
      });
    } on ApiException catch (e, st) {
      debugPrint('Toggle task ApiException: ${e.message}, code: ${e.statusCode}');
      debugPrintStack(stackTrace: st);
      _showError(e.message);
      setState(() {
        _tasks = _tasks.map((t) => t.id == old.id ? old : t).toList();
      });
    } catch (e, st) {
      debugPrint('Toggle task unknown error: $e');
      debugPrintStack(stackTrace: st);
      _showError(AppLocalizations.of(context)!.networkError);
      setState(() {
        _tasks = _tasks.map((t) => t.id == old.id ? old : t).toList();
      });
    }
  }

  Future<void> _delete(Task task) async {
    final token = _token;
    if (token == null) return;
    final oldList = _tasks;
    setState(() {
      _tasks = _tasks.where((t) => t.id != task.id).toList();
    });

    try {
      await _api.deleteTask(token, task.id);
    } on ApiException catch (e, st) {
      debugPrint('Delete task ApiException: ${e.message}, code: ${e.statusCode}');
      debugPrintStack(stackTrace: st);
      _showError(e.message);
      setState(() => _tasks = oldList);
    } catch (e, st) {
      debugPrint('Delete task unknown error: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      _showError(AppLocalizations.of(context)!.networkError);
      setState(() => _tasks = oldList);
    }
  }

  Future<void> _addTask() async {
    final token = _token;
    if (token == null) return;
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddTaskScreen()));
    if (created == true) {
      await _load();
    }
  }

  Future<void> _editTask(Task task) async {
    final result = await Navigator.of(
      context,
    ).push<Task?>(
      MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
    );
    if (result == null || !mounted) return;
    setState(() {
      _tasks = _tasks.map((t) => t.id == result.id ? result : t).toList();
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filteredTasks();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _BackgroundGlow(
              top: -140,
              right: -60,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
            ),
            _BackgroundGlow(
              bottom: -180,
              left: -60,
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.16),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.myTasks,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.searchHint,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        tooltip: l10n.logout,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: filtered.isEmpty
                              ? ListView(
                                  children: [
                                    const SizedBox(height: 120),
                                    Center(child: Text(l10n.noTasks)),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    right: 12,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final task = filtered[index];
                                    return Dismissible(
                                      key: ValueKey(task.id),
                                      background: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade400,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (_) => _delete(task),
                                      child: Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 6,
                                        ),
                                        child: CheckboxListTile(
                                          title: Text(
                                            task.title,
                                            style: TextStyle(
                                              decoration: task.done
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                              color: task.done
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.onSurfaceVariant
                                                  : null,
                                            ),
                                          ),
                                          value: task.done,
                                          onChanged: (_) => _toggle(task),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          secondary: IconButton(
                                            tooltip: l10n.editTask,
                                            icon: const Icon(Icons.edit_outlined),
                                            onPressed: () => _editTask(task),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: Text(l10n.addTask),
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
