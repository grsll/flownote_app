import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flownote/core/theme/app_theme.dart';
import 'package:flownote/features/notes/providers/note_provider.dart';
import 'package:flownote/widgets/common_widgets.dart';
import 'package:flownote/models/note_model.dart';
import 'package:intl/intl.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  bool _isGridView  = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(noteProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteState = ref.watch(noteProvider);
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            expandedHeight: 60,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: Text(
                'Catatan & Tugas',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
            ),
            actions: [
              // View toggle
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  icon: Icon(
                    _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: isDark ? AppColors.darkBackground : AppColors.background,
                child: TabBar(
                  key: const ValueKey('notes_tab_bar'),
                  controller: _tabCtrl,
                  tabs: [
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.sticky_note_2_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('Catatan (${noteState.notes.length})'),
                      ]),
                    ),
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.task_alt_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('Tugas (${noteState.tasks.length})'),
                      ]),
                    ),
                  ],
                  labelStyle: AppTextStyles.labelLarge,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: AppColors.primary,
                  unselectedLabelColor:
                      isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                  dividerColor: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Search bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    setState(() {}); // refresh clear button
                    ref.read(noteProvider.notifier).search(v);
                  },
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari catatan...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextSec : AppColors.textHint,
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 20,
                        color: isDark ? AppColors.darkTextSec : AppColors.textHint),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                              ref.read(noteProvider.notifier).search('');
                            },
                          )
                        : null,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // ── Tab Views ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // Notes tab
                  RefreshIndicator(
                    onRefresh: () =>
                        ref.read(noteProvider.notifier).loadAll(refresh: true),
                    child: noteState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : noteState.notes.isEmpty
                            ? EmptyState(
                                icon: Icons.sticky_note_2_rounded,
                                title: 'Belum ada catatan',
                                subtitle: 'Tekan + untuk membuat catatan baru',
                              )
                            : _isGridView
                                ? _NoteGrid(
                                    notes: noteState.notes,
                                    isDark: isDark,
                                    isTask: false,
                                    ref: ref,
                                    onTap: (note) =>
                                        _showNoteDetails(context, note, isDark),
                                  )
                                : _NoteList(
                                    notes: noteState.notes,
                                    isDark: isDark,
                                    isTask: false,
                                    ref: ref,
                                    onTap: (note) =>
                                        _showNoteDetails(context, note, isDark),
                                  ),
                  ),
                  // Tasks tab
                  RefreshIndicator(
                    onRefresh: () =>
                        ref.read(noteProvider.notifier).loadAll(refresh: true),
                    child: noteState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : noteState.tasks.isEmpty
                            ? EmptyState(
                                icon: Icons.task_alt_rounded,
                                title: 'Belum ada tugas',
                                subtitle: 'Buat tugas untuk melacak to-do kamu',
                              )
                            : _TaskList(
                                tasks: noteState.tasks,
                                isDark: isDark,
                                ref: ref,
                                onTap: (note) =>
                                    _showNoteDetails(context, note, isDark),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDetails(BuildContext context, NoteModel note, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _NoteDetailSheet(note: note, isDark: isDark),
    );
  }
}

// ── Grid view for notes ───────────────────────────────────────────────────────
class _NoteGrid extends StatelessWidget {
  final List<NoteModel> notes;
  final bool isDark;
  final bool isTask;
  final WidgetRef ref;
  final Function(NoteModel) onTap;

  const _NoteGrid({
    required this.notes,
    required this.isDark,
    required this.isTask,
    required this.ref,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: notes.length,
      itemBuilder: (_, i) {
        final note = notes[i];
        return _GridNoteCard(
          note: note,
          isDark: isDark,
          onTap: () => onTap(note),
          onDelete: () =>
              ref.read(noteProvider.notifier).deleteNote(note.id, isTask: isTask),
        );
      },
    );
  }
}

class _GridNoteCard extends StatelessWidget {
  final NoteModel note;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GridNoteCard({
    required this.note,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  Color _noteColor() {
    if (note.color == '#FFFFFF') {
      return isDark ? AppColors.darkSurface : AppColors.surface;
    }
    final hex = note.color.replaceAll('#', '');
    final col = Color(int.parse('FF$hex', radix: 16));
    return isDark ? col.withValues(alpha: 0.25) : col.withValues(alpha: 0.65);
  }

  @override
  Widget build(BuildContext context) {
    final bg = _noteColor();
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Hapus Catatan?'),
            content: Text('Catatan "${note.title}" akan dihapus.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                onPressed: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sticky_note_2_rounded,
                    size: 11,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Catatan',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                note.title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (note.content != null && note.content!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note.content!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              DateFormat('d MMM').format(note.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextSec : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── List view for notes ───────────────────────────────────────────────────────
class _NoteList extends StatelessWidget {
  final List<NoteModel> notes;
  final bool isDark;
  final bool isTask;
  final WidgetRef ref;
  final Function(NoteModel) onTap;

  const _NoteList({
    required this.notes,
    required this.isDark,
    required this.isTask,
    required this.ref,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      itemCount: notes.length,
      itemBuilder: (_, i) {
        final note = notes[i];
        return NoteCard(
          title:       note.title,
          content:     note.content,
          isTask:      false,
          isCompleted: false,
          color:       note.color,
          onDelete:    () => ref.read(noteProvider.notifier).deleteNote(note.id, isTask: false),
          onTap:       () => onTap(note),
        );
      },
    );
  }
}

// ── Task list ─────────────────────────────────────────────────────────────────
class _TaskList extends StatelessWidget {
  final List<NoteModel> tasks;
  final bool isDark;
  final WidgetRef ref;
  final Function(NoteModel) onTap;

  const _TaskList({
    required this.tasks,
    required this.isDark,
    required this.ref,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pending   = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        if (pending.isNotEmpty) ...[
          _TaskSectionHeader(
            title: 'Perlu Dikerjakan',
            count: pending.length,
            color: AppColors.primary,
            isDark: isDark,
          ),
          ...pending.map((task) => _TaskTile(
                task: task,
                isDark: isDark,
                ref: ref,
                onTap: () => onTap(task),
              )),
          const SizedBox(height: 12),
        ],
        if (completed.isNotEmpty) ...[
          _TaskSectionHeader(
            title: 'Selesai',
            count: completed.length,
            color: AppColors.income,
            isDark: isDark,
          ),
          ...completed.map((task) => _TaskTile(
                task: task,
                isDark: isDark,
                ref: ref,
                onTap: () => onTap(task),
              )),
        ],
      ],
    );
  }
}

class _TaskSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final bool isDark;

  const _TaskSectionHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final NoteModel task;
  final bool isDark;
  final WidgetRef ref;
  final VoidCallback onTap;

  const _TaskTile({
    required this.task,
    required this.isDark,
    required this.ref,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ref.read(noteProvider.notifier).deleteNote(task.id, isTask: true),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(noteProvider.notifier).toggleTask(task),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted ? AppColors.income : Colors.transparent,
                    border: Border.all(
                      color:
                          task.isCompleted ? AppColors.income : AppColors.textHint,
                      width: 2,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted
                            ? (isDark ? AppColors.darkTextSec : AppColors.textSecondary)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.content != null && task.content!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        task.content!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('d MMM').format(task.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSec : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Note Detail Bottom Sheet ──────────────────────────────────────────────────
class _NoteDetailSheet extends StatelessWidget {
  final NoteModel note;
  final bool isDark;
  const _NoteDetailSheet({required this.note, required this.isDark});

  Color _noteColor() {
    if (note.color == '#FFFFFF') {
      return isDark ? AppColors.darkSurface : AppColors.surface;
    }
    final hex = note.color.replaceAll('#', '');
    final col = Color(int.parse('FF$hex', radix: 16));
    return isDark ? col.withValues(alpha: 0.25) : col.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final accent = note.isTask ? AppColors.accent : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: _noteColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark
            ? Border.all(color: AppColors.darkBorder)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  note.isTask ? Icons.task_alt_rounded : Icons.sticky_note_2_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                note.isTask ? 'Tugas' : 'Catatan',
                style: AppTextStyles.labelLarge.copyWith(color: accent),
              ),
              const Spacer(),
              if (note.isTask)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (note.isCompleted ? AppColors.income : AppColors.expense)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (note.isCompleted ? AppColors.income : AppColors.expense)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    note.isCompleted ? '✓ Selesai' : '⏳ Belum',
                    style: TextStyle(
                      fontSize: 12,
                      color: note.isCompleted ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              // Date
              if (!note.isTask) ...[
                Text(
                  DateFormat('d MMM yyyy').format(note.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Text(
            note.title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          if (note.content != null && note.content!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  note.content!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSec : AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
