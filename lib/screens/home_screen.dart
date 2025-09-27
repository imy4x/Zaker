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
import 'package:zaker/widgets/loading_view.dart';
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
    );

    if (!mounted) return;

    if (provider.state == AppState.success && newSession != null) {
      // Show warning if some components failed
      if (provider.warningMessage.isNotEmpty) {
        AppDialogs.showErrorDialog(context, provider.warningMessage, title: 'تنبيه');
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
    final isEditing = existingList != null;
    final controller = TextEditingController(text: isEditing ? existingList.name : '');

    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(isEditing ? 'إعادة تسمية القائمة' : 'إنشاء قائمة جديدة'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'اسم القائمة'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () {
          if (controller.text.isNotEmpty) {
            final provider = context.read<StudyProvider>();
            if (isEditing) {
              provider.renameList(existingList.id, controller.text);
            } else {
              provider.createList(controller.text);
            }
            Navigator.pop(context);
          }
        }, child: Text(isEditing ? 'حفظ' : 'إنشاء')),
      ],
    )).whenComplete(() => controller.dispose());
  }

  void _showRenameSessionDialog(StudySession session) {
    final controller = TextEditingController(text: session.title);
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('إعادة تسمية الجلسة'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'عنوان الجلسة'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () {
          if (controller.text.isNotEmpty) {
            context.read<StudyProvider>().renameSession(session.id, controller.text);
            Navigator.pop(context);
          }
        }, child: const Text('حفظ')),
      ],
    )).whenComplete(() => controller.dispose());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جلساتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _showCreateOrRenameListDialog,
            tooltip: 'إنشاء قائمة جديدة',
          )
        ],
      ),
      body: Consumer<StudyProvider>(
        builder: (context, provider, child) {
          if (provider.state == AppState.loading) return const LoadingView();
          
          final lists = provider.lists;
          final sessions = provider.sessions;
          final uncategorizedSessions = sessions.where((s) => s.listId == null).toList();

          if (lists.isEmpty && sessions.isEmpty) return _buildEmptyState();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              ...lists.map((list) {
                final listSessions = sessions.where((s) => s.listId == list.id).toList();
                return _buildListTile(provider, list, listSessions);
              }),
              if(uncategorizedSessions.isNotEmpty)
                _buildListTile(provider, null, uncategorizedSessions),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<StudyProvider>(
        builder: (context, provider, child) {
          return provider.state == AppState.loading
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                onPressed: _createNewSession,
                label: const Text('جلسة جديدة'),
                icon: const Icon(Icons.add_rounded),
              );
        }
      ),
    );
  }

  Widget _buildListTile(StudyProvider provider, StudyList? list, List<StudySession> listSessions) {
    final bool isUncategorized = list == null;
    final String title = isUncategorized ? 'غير مصنف' : list.name;
    final IconData icon = isUncategorized ? Icons.inventory_2_outlined : list.icon;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        key: PageStorageKey(list?.id ?? 'uncategorized'),
        leading: Icon(icon, color: isUncategorized ? Colors.grey : list.color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text('${listSessions.length} جلسات'),
        trailing: isUncategorized ? null : PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'rename') {
              _showCreateOrRenameListDialog(existingList: list);
            } else if (value == 'delete') {
              final confirm = await AppDialogs.showConfirmDialog(
                context, 
                title: 'تأكيد الحذف',
                content: 'هل أنت متأكد من حذف قائمة "${list!.name}"؟ سيتم نقل الجلسات التابعة لها إلى "غير مصنف".'
              );
              if (confirm) {
                provider.deleteList(list.id);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'rename', child: Text('إعادة تسمية')),
            const PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: listSessions.map((session) => SessionListItem(
          session: session,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudyMaterialScreen(session: session))),
          onDelete: () async {
            final confirm = await AppDialogs.showConfirmDialog(context, title: 'تأكيد الحذف', content: 'هل أنت متأكد من حذف هذه الجلسة؟');
            if (confirm) await provider.deleteSession(session.id);
          },
          onMove: () async {
             final selectedListId = await _showMoveDialog(provider.lists, session.listId);
             if (selectedListId != 'NO_ACTION') {
                await provider.moveSessionToList(session.id, selectedListId);
             }
          },
          onRename: () => _showRenameSessionDialog(session),
        )).toList(),
      ),
    );
  }

  Future<String?> _showMoveDialog(List<StudyList> lists, String? currentListId) async {
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
          TextButton(onPressed: () => Navigator.of(context).pop('NO_ACTION'), child: const Text('إلغاء')),
        ],
      )
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/empty.json', width: 250, height: 250),
          const SizedBox(height: 20),
          Text('لا توجد جلسات مذاكرة بعد', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          Text('اضغط على زر الإضافة لبدء المذاكرة', style: Theme.of(context).textTheme.bodyMedium),
        ],
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
      if(mounted) AppDialogs.showErrorDialog(context, 'لقد استهلكت رصيدك بالكامل لهذا اليوم.');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
    );
    if (result != null) {
      final totalSelection = _selectedFiles.length + result.files.length;
      if (totalSelection > remaining) {
         if(mounted) AppDialogs.showErrorDialog(context, 'لا يمكنك اختيار أكثر من $remaining ملفات.');
      } else {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyProvider>();
    final remaining = provider.usageService.getRemainingUses();
    final timeUntilReset = provider.usageService.getTimeUntilReset();
    
    return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text('إنشاء جلسة جديدة')),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الملفات', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_selectedFiles.isEmpty)
                        const Center(child: Text('لم يتم اختيار أي ملفات بعد.')),
                      ..._selectedFiles.map((file) => ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(file.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis,),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() => _selectedFiles.remove(file)),
                        ),
                      )),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: const Text('اختيار ملفات'),
                          onPressed: _pickFiles,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'عنوان الجلسة'),
                  validator: (value) =>
                      value!.isEmpty ? 'العنوان مطلوب' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات إضافية (اختياري)',
                    hintText: 'مثال: ركز على الفصل الثالث أو اشرح المصطلحات بالتفصيل',
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 20),
                const Text('لغة التحليل', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Flexible(
                      child: RadioListTile<String>(
                        title: const Text('العربية'), value: 'العربية', groupValue: _selectedLanguage,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(() => _selectedLanguage = v!),
                      ),
                    ),
                    Flexible(
                      child: RadioListTile<String>(
                        title: const Text('English'), value: 'English', groupValue: _selectedLanguage,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(() => _selectedLanguage = v!),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const Text('اختر عمق التحليل', style: TextStyle(fontWeight: FontWeight.bold)),
                ...AnalysisDepth.values.map((depth) {
                  return RadioListTile<AnalysisDepth>(
                    title: Text(depth.nameAr),
                    subtitle: Text(depth.descriptionAr, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                    value: depth, groupValue: _selectedDepth,
                    onChanged: (v) => setState(() => _selectedDepth = v!),
                  );
                }).toList(),
                const Divider(height: 20),
                Center(
                  child: Chip(
                    label: Text(
                      'سيتم استهلاك ${_selectedFiles.length} من $remaining محاولات متبقية',
                      style: TextStyle(
                        color: _selectedFiles.length <= remaining ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: _selectedFiles.length <= remaining ? Colors.green.shade100 : Colors.red.shade100,
                  ),
                ),
                if (remaining == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      'ستتم إعادة التعيين بعد: ${timeUntilReset.inHours}h ${timeUntilReset.inMinutes.remainder(60)}m',
                      style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  )
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: (_selectedFiles.isNotEmpty && _selectedFiles.length <= remaining)
                ? () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, {
                        'files': _selectedFiles,
                        'title': _titleController.text,
                        'language': _selectedLanguage,
                        'depth': _selectedDepth,
                        'notes': _notesController.text.trim(),
                      });
                    }
                  }
                : null,
            child: const Text('ابدأ التحليل'),
          ),
        ],
    );
  }
}

