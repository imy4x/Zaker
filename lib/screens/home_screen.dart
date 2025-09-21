import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:zaker/constants/app_constants.dart';
import 'package:zaker/providers/study_provider.dart';
import 'package:zaker/screens/study_material_screen.dart';
import 'package:zaker/services/text_extraction_service.dart';
import 'package:zaker/utils/dialogs.dart';
import 'package:zaker/widgets/file_type_picker_sheet.dart';
import 'package:zaker/widgets/loading_view.dart';
import 'package:zaker/widgets/session_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _titleController = TextEditingController();

  Future<void> _createNewSession() async {
    final provider = Provider.of<StudyProvider>(context, listen: false);

    if (!provider.usageService.canUse()) {
      final timeUntilReset = provider.usageService.getTimeUntilReset();
      final hours = timeUntilReset.inHours;
      final minutes = timeUntilReset.inMinutes.remainder(60);
      AppDialogs.showErrorDialog(
        context, 
        'لقد استهلكت رصيدك اليومي (محاولتان).\n\nستتم إعادة التعيين بعد: ${hours} ساعة و ${minutes} دقيقة.'
      );
      return;
    }

    final selectedType = await showModalBottomSheet<FileTypeOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const FileTypePickerSheet(),
    );
    if (selectedType == null) return;

    final sessionDetails = await _showSessionOptionsDialog();
    if (sessionDetails == null || !mounted) return;

    final newSession = await provider.createSessionFromFile(
      selectedType,
      sessionDetails['language'] as String,
      sessionDetails['title'] as String,
      sessionDetails['depth'] as AnalysisDepth,
    );

    if (!mounted) return;

    if (provider.state == AppState.success && newSession != null) {
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

  Future<Map<String, dynamic>?> _showSessionOptionsDialog() {
    final formKey = GlobalKey<FormState>();
    _titleController.text =
        'جلسة مذاكرة ${DateTime.now().day}/${DateTime.now().month}';

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        String selectedLanguage = 'العربية';
        AnalysisDepth selectedDepth = AnalysisDepth.medium;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Center(child: Text('خيارات الجلسة')),
              content: Consumer<StudyProvider>(
                builder: (context, provider, _) {
                  final remaining = provider.usageService.getRemainingUses();
                  final canUse = remaining > 0;
                  final timeUntilReset = provider.usageService.getTimeUntilReset();

                  return SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration:
                                const InputDecoration(labelText: 'عنوان الجلسة'),
                            validator: (value) =>
                                value!.isEmpty ? 'العنوان مطلوب' : null,
                          ),
                          const SizedBox(height: 20),

                          const Text('لغة التحليل', style: TextStyle(fontWeight: FontWeight.bold)),
                          // --- تعديل: تحسين تناسق أزرار الاختيار ---
                          Row(
                            children: [
                              Flexible(
                                child: RadioListTile<String>(
                                  title: const Text('العربية'),
                                  value: 'العربية',
                                  groupValue: selectedLanguage,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (v) => setState(() => selectedLanguage = v!),
                                ),
                              ),
                              Flexible(
                                child: RadioListTile<String>(
                                  title: const Text('English'),
                                  value: 'English',
                                  groupValue: selectedLanguage,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (v) => setState(() => selectedLanguage = v!),
                                ),
                              ),
                            ],
                          ),
                          
                          const Divider(height: 20),
                          
                          const Text('اختر عمق التحليل',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'عمق التحليل يؤثر فقط على تفصيل الملخص والبطاقات، ولا يستهلك رصيداً مختلفاً.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),

                          ...AnalysisDepth.values.map((depth) {
                            return RadioListTile<AnalysisDepth>(
                              title: Text(depth.nameAr),
                              subtitle: Text(
                                depth.descriptionAr,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                              ),
                              value: depth,
                              groupValue: selectedDepth,
                              onChanged: (v) => setState(() => selectedDepth = v!),
                            );
                          }).toList(),
                          
                          const Divider(height: 20),
                          Center(
                            child: Chip(
                              label: Text(
                                'المحاولات المتبقية اليوم: $remaining',
                                style: TextStyle(
                                  color: canUse ? Colors.green.shade800 : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: canUse ? Colors.green.shade100 : Colors.red.shade100,
                            ),
                          ),

                          if (!canUse)
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
                  );
                },
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء')),
                Consumer<StudyProvider>(
                  builder: (context, provider, _) {
                    final bool canUse = provider.usageService.canUse();
                    return ElevatedButton(
                      onPressed: canUse
                          ? () {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(context, {
                                  'title': _titleController.text,
                                  'language': selectedLanguage,
                                  'depth': selectedDepth,
                                });
                              }
                            }
                          : null,
                      child: const Text('ابدأ التحليل'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جلساتي'),
      ),
      body: Consumer<StudyProvider>(
        builder: (context, provider, child) {
          if (provider.state == AppState.loading) {
            return const LoadingView();
          }
          return _buildSessionList(provider);
        },
      ),
      // --- تعديل: إخفاء الزر العائم أثناء التحميل ---
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

  Widget _buildSessionList(StudyProvider provider) {
    if (provider.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/empty.json',
                width: 250, height: 250),
            const SizedBox(height: 20),
            Text(
              'لا توجد جلسات مذاكرة بعد',
              style:
                  Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على زر الإضافة لبدء المذاكرة',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          Provider.of<StudyProvider>(context, listen: false).reloadSessions(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: provider.sessions.length,
        itemBuilder: (context, index) {
          final session = provider.sessions[index];
          return SessionListItem(
            session: session,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => StudyMaterialScreen(session: session)),
              );
            },
            onDelete: () async {
              final confirm = await AppDialogs.showConfirmDialog(context);
              if (confirm) {
                await provider.deleteSession(session.id);
              }
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
extension StudyProviderExtension on StudyProvider {
  Future<void> reloadSessions() async {
    // await _loadSessions();
  }
}

