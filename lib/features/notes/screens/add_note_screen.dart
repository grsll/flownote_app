import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/core/theme/app_theme.dart';
import 'package:flownote/features/notes/providers/note_provider.dart';
import 'package:flownote/widgets/common_widgets.dart';

const _noteColors = [
  '#FFFFFF', '#FEF9C3', '#DCFCE7', '#DBEAFE', '#FCE7F3', '#FEE2E2', '#EDE9FE',
];

class AddNoteSheet extends ConsumerStatefulWidget {
  const AddNoteSheet({super.key});

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _color      = '#FFFFFF';
  bool _isTask       = false;
  bool _isLoading    = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(noteProvider.notifier).createNote(
      title:   _titleCtrl.text.trim(),
      content: _contentCtrl.text.isEmpty ? null : _contentCtrl.text.trim(),
      isTask:  _isTask,
      color:   _color,
    );
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '${_isTask ? 'Task' : 'Note'} created!' : 'Failed'),
          backgroundColor: ok ? AppColors.income : AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.textHint, borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(_isTask ? 'Tugas Baru' : 'Catatan Baru', style: AppTextStyles.titleLarge),
                  const Spacer(),
                  // Task switch
                  Row(children: [
                    Text('Tugas', style: AppTextStyles.bodyMedium),
                    Switch(
                      value: _isTask,
                      onChanged: (v) => setState(() => _isTask = v),
                      activeColor: AppColors.primary,
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Judul',
                hint: _isTask ? 'Apa yang perlu dikerjakan?' : 'Judul catatan...',
                controller: _titleCtrl,
                prefixIcon: _isTask ? Icons.task_alt_rounded : Icons.sticky_note_2_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Konten (opsional)',
                hint: _isTask ? 'Detail tugas...' : 'Tulis catatanmu di sini...',
                controller: _contentCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Color picker
              Text('Warna', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _noteColors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final hex = _noteColors[i];
                    final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                    final selected = _color == hex;
                    return GestureDetector(
                      onTap: () => setState(() => _color = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                            width: selected ? 2.5 : 1,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check, size: 16, color: AppColors.primary)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Simpan ${_isTask ? 'Tugas' : 'Catatan'}',
                isLoading: _isLoading,
                onTap: _submit,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
