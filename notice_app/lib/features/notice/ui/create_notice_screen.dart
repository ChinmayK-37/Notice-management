import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notice_app/features/notice/providers/notice_provider.dart';

class CreateNoticeScreen extends ConsumerStatefulWidget {
  const CreateNoticeScreen({super.key});

  @override
  ConsumerState<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends ConsumerState<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _departmentController = TextEditingController(text: 'CSE');
  String _category = 'GENERAL';
  String _priority = 'MEDIUM';
  int _year = 1;
  String _division = 'ALL';
  String _batch = 'ALL';
  bool _pinned = false;
  bool _global = true;
  bool _saving = false;
  DateTime? _expiryDate;
  final List<Map<String, dynamic>> _targets = <Map<String, dynamic>>[];

  static const _categories = [
    'GENERAL',
    'EXAM',
    'ASSIGNMENT',
    'PLACEMENT',
    'WORKSHOP',
    'EVENT',
    'FINANCE',
    'HOLIDAY',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiryDate ?? now),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _expiryDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 17,
        time?.minute ?? 0,
      );
    });
  }

  void _addTarget() {
    final department = _departmentController.text.trim().toUpperCase();
    if (department.isEmpty) {
      return;
    }
    final exists = _targets.any(
      (target) =>
          target['department'] == department &&
          target['year'] == _year &&
          target['division'] == (_division == 'ALL' ? null : _division) &&
          target['batch'] == (_batch == 'ALL' ? null : _batch),
    );
    if (exists) {
      return;
    }
    setState(() {
      _global = false;
      _targets.add(<String, dynamic>{
        'department': department,
        'year': _year,
        'division': _division == 'ALL' ? null : _division,
        'batch': _batch == 'ALL' ? null : _batch,
      });
    });
  }

  String _targetLabel(Map<String, dynamic> target) {
    final refinements = <String>[
      if (target['division'] != null) 'Div ${target['division']}',
      if (target['batch'] != null) 'Batch ${target['batch']}',
    ];
    final suffix = refinements.isEmpty ? '' : ' (${refinements.join(', ')})';
    return '${target['department']} - Year ${target['year']}$suffix';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(noticeServiceProvider)
          .createNotice(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            priority: _priority,
            expiryDate: _expiryDate,
            pinned: _pinned,
            targets: _global ? <Map<String, dynamic>>[] : _targets,
          );
      await ref.read(noticeProvider.notifier).fetchNotices();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice created successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Create notice')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        child: const Icon(Icons.add_alert_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Publish targeted academic communication',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          enabled: !_saving,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Title is required'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            prefixIcon: Icon(Icons.title_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          enabled: !_saving,
                          minLines: 4,
                          maxLines: 7,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Description is required'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _DropdownBox(
                              label: 'Category',
                              value: _category,
                              values: _categories,
                              onChanged: _saving
                                  ? null
                                  : (value) =>
                                        setState(() => _category = value),
                            ),
                            _DropdownBox(
                              label: 'Priority',
                              value: _priority,
                              values: const ['HIGH', 'MEDIUM', 'LOW'],
                              onChanged: _saving
                                  ? null
                                  : (value) =>
                                        setState(() => _priority = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: _pinned,
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _pinned = value),
                          title: const Text('Pin notice to top'),
                          subtitle: const Text(
                            'Pinned notices appear first in student feeds.',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickExpiry,
                          icon: const Icon(Icons.event_outlined),
                          label: Text(
                            _expiryDate == null
                                ? 'Choose expiry date'
                                : DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(_expiryDate!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          value: _global,
                          onChanged: _saving
                              ? null
                              : (value) => setState(() {
                                  _global = value;
                                  if (value) {
                                    _targets.clear();
                                  }
                                }),
                          title: const Text('Global notice'),
                          subtitle: const Text(
                            'Turn off to target department/year groups.',
                          ),
                        ),
                        if (!_global) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _departmentController,
                                  enabled: !_saving,
                                  decoration: const InputDecoration(
                                    labelText: 'Department',
                                    prefixIcon: Icon(Icons.apartment_outlined),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 96,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _year,
                                  decoration: const InputDecoration(
                                    labelText: 'Year',
                                  ),
                                  items: const [1, 2, 3, 4]
                                      .map(
                                        (year) => DropdownMenuItem<int>(
                                          value: year,
                                          child: Text('$year'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _saving
                                      ? null
                                      : (value) => setState(
                                          () => _year = value ?? _year,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _DropdownBox(
                                label: 'Division',
                                value: _division,
                                values: const ['ALL', 'A', 'B', 'C'],
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(() {
                                        _division = value;
                                        if (value != 'ALL') {
                                          _batch = '${value}1';
                                        }
                                      }),
                              ),
                              _DropdownBox(
                                label: 'Batch',
                                value: _batch,
                                values: const [
                                  'ALL',
                                  'A1',
                                  'A2',
                                  'B1',
                                  'B2',
                                  'C1',
                                  'C2',
                                ],
                                onChanged: _saving
                                    ? null
                                    : (value) => setState(() => _batch = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _addTarget,
                            icon: const Icon(Icons.group_add_outlined),
                            label: const Text('Add target group'),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final target in _targets)
                                InputChip(
                                  label: Text(_targetLabel(target)),
                                  onDeleted: _saving
                                      ? null
                                      : () => setState(
                                          () => _targets.remove(target),
                                        ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish_outlined),
                  label: const Text('Publish notice'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownBox extends StatelessWidget {
  const _DropdownBox({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: onChanged == null
            ? null
            : (value) {
                if (value != null) {
                  onChanged!(value);
                }
              },
      ),
    );
  }
}
