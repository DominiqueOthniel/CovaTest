import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/cova_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/cova_panel.dart';

const statusLabels = <String, String>{
  'ALL': 'Tous',
  'TODO': 'A faire',
  'IN_PROGRESS': 'En cours',
  'DONE': 'Termine',
};

class TasksPage extends StatefulWidget {
  const TasksPage({
    super.key,
    required this.session,
    required this.onLogout,
  });

  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _api = ApiClient();
  final _search = TextEditingController();
  List<TaskItem> _tasks = [];
  String _statusFilter = 'ALL';
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _loadTasks);
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final data = await _api.listTasks(
        widget.session.token,
        status: _statusFilter,
        search: _search.text,
      );
      if (!mounted) return;
      setState(() => _tasks = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message, error: true);
      if (e.status == 401) await widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      _toast('Impossible de joindre l API', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? CovaColors.danger : CovaColors.accentStrong,
      ),
    );
  }

  Future<void> _openTaskSheet({TaskItem? task}) async {
    final result = await showModalBottomSheet<_TaskFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskFormSheet(initial: task),
    );
    if (result == null) return;

    try {
      if (task != null) {
        await _api.updateTask(
          widget.session.token,
          task.id,
          title: result.title,
          description: result.description,
          status: result.status,
        );
        _toast('Tache mise a jour');
      } else {
        await _api.createTask(
          widget.session.token,
          title: result.title,
          description: result.description,
          status: result.status,
        );
        _toast('Tache creee');
      }
      await _loadTasks();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
      if (e.status == 401) await widget.onLogout();
    }
  }

  Future<bool> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CovaColors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Supprimer cette tache ?'),
        content: const Text(
          'Cette action est definitive.',
          style: TextStyle(color: CovaColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: CovaColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: CovaColors.danger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deleteTask(TaskItem task) async {
    final ok = await _confirmDelete();
    if (!ok) return;
    try {
      await _api.deleteTask(widget.session.token, task.id);
      _toast('Tache supprimee');
      await _loadTasks();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
      if (e.status == 401) await widget.onLogout();
    }
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: CovaColors.accent,
            backgroundColor: CovaColors.elevated,
            onRefresh: _loadTasks,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                CovaPanel(
                  glow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: CovaColors.soft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: CovaColors.line),
                            ),
                            child: const BrandLogo(height: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COVATASK',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bonjour ${widget.session.fullName}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  widget.session.email,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Se deconnecter',
                            onPressed: widget.onLogout,
                            style: IconButton.styleFrom(
                              backgroundColor: CovaColors.soft,
                              side: const BorderSide(color: CovaColors.line),
                            ),
                            icon: const Icon(Icons.logout_rounded, color: CovaColors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openTaskSheet(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Nouvelle tache'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CovaPanel(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: 'Rechercher une tache...',
                          prefixIcon: const Icon(Icons.search_rounded, color: CovaColors.muted),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _search.clear();
                                    _loadTasks();
                                  },
                                  icon: const Icon(Icons.close_rounded, color: CovaColors.muted),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilterChipBar(
                        value: _statusFilter,
                        options: statusLabels,
                        onChanged: (value) {
                          setState(() => _statusFilter = value);
                          _loadTasks();
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: CircularProgressIndicator(color: CovaColors.accent),
                          ),
                        )
                      else if (_tasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: CovaColors.soft,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: CovaColors.line),
                                ),
                                child: const Icon(
                                  Icons.checklist_rounded,
                                  color: CovaColors.accent,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Aucune tache pour le moment.',
                                style: TextStyle(
                                  color: CovaColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () => _openTaskSheet(),
                                child: const Text('Creer ma premiere tache'),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._tasks.asMap().entries.map((entry) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 280 + (entry.key * 40).clamp(0, 240)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 12),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildTaskCard(_tasks[entry.key]),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskSheet(),
        backgroundColor: CovaColors.accent,
        foregroundColor: CovaColors.accentInk,
        elevation: 8,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nouvelle tache',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CovaColors.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CovaColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.5,
                    color: CovaColors.text,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: task.status),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description,
              style: const TextStyle(color: CovaColors.muted, height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Mise a jour : ${_formatDate(task.updatedAt)}',
            style: TextStyle(
              color: CovaColors.muted.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openTaskSheet(task: task),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteTask(task),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CovaColors.danger,
                    side: BorderSide(color: CovaColors.danger.withValues(alpha: 0.55)),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Supprimer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskFormResult {
  _TaskFormResult({
    required this.title,
    required this.description,
    required this.status,
  });

  final String title;
  final String description;
  final String status;
}

class _TaskFormSheet extends StatefulWidget {
  const _TaskFormSheet({this.initial});

  final TaskItem? initial;

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late String _status;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _description = TextEditingController(text: widget.initial?.description ?? '');
    _status = widget.initial?.status ?? 'TODO';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: CovaColors.elevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: CovaColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: CovaColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    editing ? 'Modifier la tache' : 'Nouvelle tache',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(backgroundColor: CovaColors.soft),
                  icon: const Icon(Icons.close_rounded, color: CovaColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Preparer la demo',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Details optionnels',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Statut',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: CovaColors.text,
                  ),
            ),
            const SizedBox(height: 8),
            FilterChipBar(
              value: _status,
              options: const {
                'TODO': 'A faire',
                'IN_PROGRESS': 'En cours',
                'DONE': 'Termine',
              },
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final title = _title.text.trim();
                  if (title.isEmpty) return;
                  Navigator.pop(
                    context,
                    _TaskFormResult(
                      title: title,
                      description: _description.text.trim(),
                      status: _status,
                    ),
                  );
                },
                child: Text(editing ? 'Mettre a jour' : 'Creer la tache'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
