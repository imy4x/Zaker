import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:zaker/constants/app_constants.dart';
import 'package:zaker/models/study_list.dart';
import 'package:zaker/models/study_session.dart';
import 'package:zaker/providers/study_provider.dart';
import 'package:zaker/screens/study_material_screen.dart';
import 'package:zaker/utils/dialogs.dart';
import 'package:zaker/utils/responsive_utils.dart';
import 'package:zaker/widgets/loading_view.dart';
import 'package:zaker/providers/theme_provider.dart';
import 'package:zaker/widgets/session_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _createNewSession() async {
    final details = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _SessionOptionsDialog(),
    );
    if (details == null || !mounted) return;

    final provider = Provider.of<StudyProvider>(context, listen: false);
    final newSession = await provider.createSessionFromFiles(
      details['files'] as List<PlatformFile>,
      details['language'] as String,
      details['title'] as String,
      details['depth'] as AnalysisDepth,
      customNotes: details['notes'] as String?,
      listId: details['listId'] as String?,
    );

    if (!mounted) return;

    if (provider.state == AppState.success && newSession != null) {
      // Show warning if some components failed
      if (provider.warningMessage.isNotEmpty) {
        AppDialogs.showErrorDialog(context, provider.warningMessage,
            title: 'تنبيه');
      }
      provider.resetState();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => StudyMaterialScreen(session: newSession)),
      );
    } else if (provider.state == AppState.error) {
      AppDialogs.showErrorDialog(context, provider.errorMessage);
      provider.resetState();
    }
  }

  void _showCreateOrRenameListDialog({StudyList? existingList}) {
    showDialog(
      context: context,
      builder: (context) => _CreateListDialog(existingList: existingList),
    );
  }

  void _showRenameSessionDialog(StudySession session) {
    showDialog(
      context: context,
      builder: (context) => _RenameSessionDialog(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyProvider>(
      builder: (context, provider, child) {
        final themeProvider = context.watch<ThemeProvider>();
        return Scaffold(
          appBar: AppBar(
            title: const Text('جلساتي'),
            actions: [
              
              if (provider.state !=
                  AppState.loading) // Only show when not analyzing
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined),
                  onPressed: _showCreateOrRenameListDialog,
                  tooltip: 'إنشاء قائمة جديدة',
                )
            ],
          ),
          body: provider.state == AppState.loading
              ? const LoadingView()
              : _buildMainContent(provider),
          floatingActionButton: provider.state == AppState.loading
              ? const SizedBox.shrink()
              : FloatingActionButton.extended(
                  onPressed: _createNewSession,
                  label: const Text('جلسة جديدة'),
                  icon: const Icon(Icons.add_rounded),
                ),
        );
      },
    );
  }

  Widget _buildMainContent(StudyProvider provider) {
    final lists = provider.lists;
    final sessions = provider.sessions;
    final uncategorizedSessions =
        sessions.where((s) => s.listId == null).toList();

    if (lists.isEmpty && sessions.isEmpty) return _buildEmptyState();

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.getResponsivePadding(context),
        ResponsiveUtils.getResponsiveSpacing(context),
        ResponsiveUtils.getResponsivePadding(context),
        96,
      ),
      children: [
        ...lists.map((list) {
          final listSessions =
              sessions.where((s) => s.listId == list.id).toList();
          return _buildListTile(provider, list, listSessions);
        }),
        if (uncategorizedSessions.isNotEmpty)
          _buildListTile(provider, null, uncategorizedSessions),
      ],
    );
  }

  Widget _buildListTile(StudyProvider provider, StudyList? list,
      List<StudySession> listSessions) {
    final bool isUncategorized = list == null;
    final String title = isUncategorized ? 'غير مصنف' : list.name;
    final IconData icon =
        isUncategorized ? Icons.inventory_2_outlined : list.icon;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        key: PageStorageKey(list?.id ?? 'uncategorized'),
        leading: Icon(icon, color: isUncategorized ? Colors.grey : list.color),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text('${listSessions.length} جلسات'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent, width: 0)),
        collapsedShape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent, width: 0)),
        trailing: isUncategorized
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'rename') {
                    _showCreateOrRenameListDialog(existingList: list);
                  } else if (value == 'delete') {
                    final confirm = await AppDialogs.showConfirmDialog(context,
                        title: 'تأكيد الحذف',
                        content:
                            'هل أنت متأكد من حذف قائمة "${list!.name}"؟ سيتم نقل الجلسات التابعة لها إلى "غير مصنف".');
                    if (confirm) {
                      provider.deleteList(list.id);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'rename', child: Text('إعادة تسمية')),
                  const PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
        initiallyExpanded: true,
        children: listSessions
            .map((session) => SessionListItem(
                  session: session,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              StudyMaterialScreen(session: session))),
                  onDelete: () async {
                    final confirm = await AppDialogs.showConfirmDialog(context,
                        title: 'تأكيد الحذف',
                        content: 'هل أنت متأكد من حذف هذه الجلسة؟');
                    if (confirm) await provider.deleteSession(session.id);
                  },
                  onMove: () async {
                    final selectedListId =
                        await _showMoveDialog(provider.lists, session.listId);
                    if (selectedListId != 'NO_ACTION') {
                      await provider.moveSessionToList(
                          session.id, selectedListId);
                    }
                  },
                  onRename: () => _showRenameSessionDialog(session),
                ))
            .toList(),
      ),
    );
  }

  Future<String?> _showMoveDialog(
      List<StudyList> lists, String? currentListId) async {
    return showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('نقل إلى...'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    RadioListTile<String?>(
                      title: const Text('غير مصنف'),
                      value: null,
                      groupValue: currentListId,
                      onChanged: (val) => Navigator.of(context).pop(val),
                    ),
                    const Divider(),
                    ...lists.map((list) => RadioListTile<String?>(
                          title: Text(list.name),
                          value: list.id,
                          groupValue: currentListId,
                          onChanged: (val) => Navigator.of(context).pop(val),
                        )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('NO_ACTION'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
                  child: const Text('إلغاء'),
                ),
              ],
            ));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/empty.json', width: 250, height: 250),
          const SizedBox(height: 20),
          Text('لا توجد جلسات مذاكرة بعد',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          Text('اضغط على زر الإضافة لبدء المذاكرة',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _RenameSessionDialog extends StatefulWidget {
  final StudySession session;
  const _RenameSessionDialog({required this.session});

  @override
  State<_RenameSessionDialog> createState() => _RenameSessionDialogState();
}

class _RenameSessionDialogState extends State<_RenameSessionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.session.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إعادة تسمية الجلسة'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'عنوان الجلسة'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              context
                  .read<StudyProvider>()
                  .renameSession(widget.session.id, _controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _CreateListDialog extends StatefulWidget {
  final StudyList? existingList;
  const _CreateListDialog({this.existingList});

  @override
  State<_CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<_CreateListDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.existingList?.name ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingList != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 0,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: ResponsiveUtils.getMaxDialogWidth(context),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F2FF), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEditing
                      ? Icons.edit_rounded
                      : Icons.create_new_folder_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEditing ? 'إعادة تسمية القائمة' : 'إنشاء قائمة جديدة',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'اسم القائمة',
                  prefixIcon: Icon(Icons.folder_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                ),
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (_controller.text.isNotEmpty) {
                    final provider = context.read<StudyProvider>();
                    if (isEditing) {
                      provider.renameList(
                          widget.existingList!.id, _controller.text);
                    } else {
                      provider.createList(_controller.text);
                    }
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.outline),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          final provider = context.read<StudyProvider>();
                          if (isEditing) {
                            provider.renameList(
                                widget.existingList!.id, _controller.text);
                          } else {
                            provider.createList(_controller.text);
                          }
                          Navigator.pop(context);
                        }
                      },
                      // هنا التعديل: تم استبدال النمط المخصص بنمط الثيم الموحد
                      style: Theme.of(context).elevatedButtonTheme.style,
                      child: Text(
                        isEditing ? 'حفظ' : 'إنشاء',
                        // ملاحظة: تم إزالة النمط من هنا لأن نمط الزر في الثيم يعالجه تلقائياً
                      ),
                    ),
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

class _SessionOptionsDialog extends StatefulWidget {
  const _SessionOptionsDialog();

  @override
  State<_SessionOptionsDialog> createState() => _SessionOptionsDialogState();
}

class _SessionOptionsDialogState extends State<_SessionOptionsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  List<PlatformFile> _selectedFiles = [];
  String _selectedLanguage = 'العربية';
  AnalysisDepth _selectedDepth = AnalysisDepth.medium;
  String? _selectedListId; // null means no folder (uncategorized)

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: 'جلسة مذاكرة ${DateTime.now().day}/${DateTime.now().month}',
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final provider = context.read<StudyProvider>();
    final remaining = provider.usageService.getRemainingUses();

    if (remaining - _selectedFiles.length <= 0) {
      if (mounted)
        AppDialogs.showErrorDialog(
            context, 'لقد استهلكت رصيدك بالكامل لهذا اليوم.');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
    );
    if (result != null) {
      final totalSelection = _selectedFiles.length + result.files.length;
      if (totalSelection > remaining) {
        if (mounted)
          AppDialogs.showErrorDialog(
              context, 'لا يمكنك اختيار أكثر من $remaining ملفات.');
      } else {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    }
  }

  Widget _buildStepCard({
    required BuildContext context,
    required int stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            stepNumber.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        icon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildFileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFiles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'لم يتم اختيار أي ملفات بعد',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اختر ملفات PDF، Word أو صور',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _selectedFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Container(
                margin: EdgeInsets.only(
                    bottom: index < _selectedFiles.length - 1 ? 8 : 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getFileIcon(file.extension),
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (file.size != null)
                            Text(
                              _formatFileSize(file.size!),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _selectedFiles.removeAt(index)),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              _selectedFiles.isEmpty ? 'اختر الملفات' : 'إضافة ملفات أخرى',
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              foregroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'عنوان الجلسة',
            prefixIcon: const Icon(Icons.title_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          validator: (value) => value!.isEmpty ? 'العنوان مطلوب' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'ملاحظات إضافية (اختياري)',
            hintText: 'مثال: ركز على الفصل الثالث أو اشرح المصطلحات بالتفصيل',
            prefixIcon: const Icon(Icons.notes_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          maxLines: 3,
          minLines: 2,
        ),
      ],
    );
  }

  Widget _buildAISettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language Selection
        Text(
          'لغة التحليل',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildLanguageOption('العربية', Icons.language_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLanguageOption('English', Icons.translate_rounded),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Analysis Depth
        Text(
          'عمق التحليل',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Column(
          children: AnalysisDepth.values.map((depth) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: _buildDepthOption(depth),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageOption(String language, IconData icon) {
    final isSelected = _selectedLanguage == language;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = language),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                language,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepthOption(AnalysisDepth depth) {
    final isSelected = _selectedDepth == depth;
    return GestureDetector(
      onTap: () => setState(() => _selectedDepth = depth),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getDepthIcon(depth),
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    depth.nameAr,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    depth.descriptionAr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageInfo(int remaining, Duration timeUntilReset) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _selectedFiles.length <= remaining
                ? Colors.green.shade50
                : Colors.red.shade50,
            _selectedFiles.length <= remaining
                ? Colors.green.shade100
                : Colors.red.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedFiles.length <= remaining
              ? Colors.green.shade200
              : Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedFiles.length <= remaining
                      ? Colors.green
                      : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _selectedFiles.length <= remaining
                      ? Icons.check_rounded
                      : Icons.warning_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الرصيد المتاح',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: (_selectedFiles.length <= remaining
                                ? Colors.green.shade800
                                : Colors.red.shade800),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'سيتم استهلاك ${_selectedFiles.length} من $remaining محاولات متبقية',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: (_selectedFiles.length <= remaining
                                ? Colors.green.shade700
                                : Colors.red.shade700),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (remaining == 0)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ستتم إعادة التعيين بعد: ${timeUntilReset.inHours}س ${timeUntilReset.inMinutes.remainder(60)}د',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'docx':
      case 'doc':
        return Icons.description_rounded; // أيقونة Word
      case 'pptx':
      case 'ppt':
        return Icons.slideshow_rounded; // أيقونة PowerPoint
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Widget _buildFolderSelectionSection() {
    final provider = context.watch<StudyProvider>();
    final availableLists = provider.lists;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حدد مجلد لحفظ الجلسة',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 16),

        // Option for no folder (uncategorized)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildFolderOption(
            title: 'غير مصنف',
            subtitle: 'لا حاجة لمجلد',
            icon: Icons.inventory_2_outlined,
            isSelected: _selectedListId == null,
            onTap: () => setState(() => _selectedListId = null),
          ),
        ),

        // Available folders
        ...availableLists
            .map((list) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: _buildFolderOption(
                    title: list.name,
                    subtitle: 'مجلد موجود',
                    icon: list.icon,
                    color: list.color,
                    isSelected: _selectedListId == list.id,
                    onTap: () => setState(() => _selectedListId = list.id),
                  ),
                ))
            .toList(),

        const SizedBox(height: 12),

        // Create new folder hint
        if (availableLists.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'يمكنك إنشاء مجلدات جديدة من الصفحة الرئيسية',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFolderOption({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (color ??
                    (isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.1))),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getDepthIcon(AnalysisDepth depth) {
    switch (depth) {
      case AnalysisDepth.light:
        return Icons.speed_rounded;
      case AnalysisDepth.medium:
        return Icons.balance_rounded;
      case AnalysisDepth.deep:
        return Icons.psychology_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyProvider>();
    final remaining = provider.usageService.getRemainingUses();
    final timeUntilReset = provider.usageService.getTimeUntilReset();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: ResponsiveUtils.getMaxDialogWidth(context),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إنشاء جلسة جديدة',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'حوّل ملفاتك إلى جلسة مذاكرة ذكية',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step 1: Files
                      _buildStepCard(
                        context: context,
                        stepNumber: 1,
                        title: 'اختر الملفات',
                        subtitle: 'PDF، Word أو صور',
                        icon: Icons.upload_file_rounded,
                        child: _buildFileSection(),
                      ),

                      const SizedBox(height: 20),

                      // Step 2: Session Details
                      _buildStepCard(
                        context: context,
                        stepNumber: 2,
                        title: 'تفاصيل الجلسة',
                        subtitle: 'عنوان وملاحظات إضافية',
                        icon: Icons.edit_note_rounded,
                        child: _buildSessionDetailsSection(),
                      ),

                      const SizedBox(height: 20),

                      // Step 3: Folder Selection
                      _buildStepCard(
                        context: context,
                        stepNumber: 3,
                        title: 'اختيار المجلد',
                        subtitle: 'حدد مكان حفظ الجلسة (اختياري)',
                        icon: Icons.folder_outlined,
                        child: _buildFolderSelectionSection(),
                      ),

                      const SizedBox(height: 20),

                      // Step 4: AI Settings
                      _buildStepCard(
                        context: context,
                        stepNumber: 4,
                        title: 'إعدادات الذكاء الاصطناعي',
                        subtitle: 'اللغة وعمق التحليل',
                        icon: Icons.settings_suggest_rounded,
                        child: _buildAISettingsSection(context),
                      ),

                      const SizedBox(height: 20),

                      // Usage Info
                      _buildUsageInfo(remaining, timeUntilReset),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.outline),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                        decoration: BoxDecoration(
                          gradient: _selectedFiles.isNotEmpty &&
                                  _selectedFiles.length <= remaining
                              ? LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.8),
                                  ],
                                )
                              : null,
                          color: _selectedFiles.isEmpty ||
                                  _selectedFiles.length > remaining
                              ? Colors.grey.shade300
                              : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: // قم باستبدال الكود الحالي لـ ElevatedButton.icon بهذا الكود المعدل
// هذا الكود يستخدم التصميم الموحد من الثيم الرئيسي للتطبيق

                            ElevatedButton.icon(
                          onPressed: (_selectedFiles.isNotEmpty &&
                                  _selectedFiles.length <= remaining)
                              ? () {
                                  if (_formKey.currentState!.validate()) {
                                    Navigator.pop(context, {
                                      'files': _selectedFiles,
                                      'title': _titleController.text,
                                      'language': _selectedLanguage,
                                      'depth': _selectedDepth,
                                      'notes': _notesController.text.trim(),
                                      'listId': _selectedListId,
                                    });
                                  }
                                }
                              : null,
                          icon:
                              const Icon(Icons.auto_awesome_rounded, size: 20),
                          label: const Text('ابدأ التحليل'),
                          // هنا التعديل: تم استخدام تصميم الثيم مباشرة
                          style: Theme.of(context).elevatedButtonTheme.style,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
