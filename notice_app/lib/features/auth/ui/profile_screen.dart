import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';
import 'package:notice_app/shared/models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  int _year = 1;
  String _division = 'A';
  String _batch = 'A1';
  UserModel? _user;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref.read(profileServiceProvider).fetchProfile();
      if (!mounted) {
        return;
      }
      setState(() {
        _user = user;
        _nameController.text = user.name;
        _departmentController.text = user.department;
        _year = user.year.clamp(1, 4);
        _division = _normalizeDivision(user.division);
        _batch = _normalizeBatch(user.batch, _division);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _save() async {
    final isAdmin = _user?.role.toUpperCase() == 'ADMIN';
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(profileServiceProvider)
          .updateProfile(
            name: _nameController.text.trim(),
            department: _departmentController.text.trim(),
            year: _year,
            division: isAdmin ? null : _division,
            batch: isAdmin ? null : _batch,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _user = updated;
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will return to the secure login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) {
      return;
    }
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  String _normalizeDivision(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    return const ['A', 'B', 'C'].contains(normalized) ? normalized : 'A';
  }

  String _normalizeBatch(String? value, String division) {
    final normalized = (value ?? '').trim().toUpperCase();
    const batches = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    return batches.contains(normalized) ? normalized : '${division}1';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = _user?.role.toUpperCase() == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_user != null) _ProfileHeader(user: _user!),
                      const SizedBox(height: 14),
                      if (_error != null) ...[
                        _ErrorBanner(message: _error!),
                        const SizedBox(height: 12),
                      ],
                      Card(
                        elevation: 0,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Edit academic profile',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _nameController,
                                enabled: !_saving,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _departmentController,
                                enabled: !_saving,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Department',
                                  prefixIcon: Icon(Icons.apartment_outlined),
                                ),
                              ),
                              if (!isAdmin) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'Academic year',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    for (final y in <int>[1, 2, 3, 4])
                                      ChoiceChip(
                                        label: Text('Year $y'),
                                        selected: _year == y,
                                        onSelected: _saving
                                            ? null
                                            : (_) => setState(() => _year = y),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Division and batch',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _ProfileDropdown<String>(
                                      label: 'Division',
                                      value: _division,
                                      values: const ['A', 'B', 'C'],
                                      enabled: !_saving,
                                      onChanged: (value) => setState(() {
                                        _division = value;
                                        _batch = '${value}1';
                                      }),
                                    ),
                                    _ProfileDropdown<String>(
                                      label: 'Batch',
                                      value: _batch,
                                      values: const [
                                        'A1',
                                        'A2',
                                        'B1',
                                        'B2',
                                        'C1',
                                        'C2',
                                      ],
                                      enabled: !_saving,
                                      onChanged: (value) =>
                                          setState(() => _batch = value),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: _saving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: const Text('Save profile'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: authState.isLoading ? null : _confirmLogout,
                        icon: const Icon(Icons.logout_outlined),
                        label: const Text('Log out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = user.role.toUpperCase() == 'ADMIN';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: Text(
                  user.name.trim().isEmpty
                      ? '?'
                      : user.name.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileChip(
                icon: isAdmin
                    ? Icons.admin_panel_settings_outlined
                    : Icons.school_outlined,
                label: user.role,
              ),
              _ProfileChip(
                icon: Icons.apartment_outlined,
                label: user.department,
              ),
              if (!isAdmin)
                _ProfileChip(
                  icon: Icons.timeline_outlined,
                  label: 'Year ${user.year}',
                ),
              if (!isAdmin && (user.division ?? '').isNotEmpty)
                _ProfileChip(
                  icon: Icons.view_module_outlined,
                  label: 'Div ${user.division}',
                ),
              if (!isAdmin && (user.batch ?? '').isNotEmpty)
                _ProfileChip(
                  icon: Icons.group_work_outlined,
                  label: 'Batch ${user.batch}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileDropdown<T> extends StatelessWidget {
  const _ProfileDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final bool enabled;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: values
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              ),
            )
            .toList(),
        onChanged: enabled && values.isNotEmpty
            ? (value) {
                if (value != null) {
                  onChanged(value);
                }
              }
            : null,
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
