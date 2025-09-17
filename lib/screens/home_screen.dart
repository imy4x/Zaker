import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:zaker/providers/study_provider.dart';
import 'package:zaker/screens/study_material_screen.dart';
import 'package:zaker/widgets/loading_widget.dart';
import 'package:zaker/widgets/session_slot_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future<void> _startProcessing(int slotIndex) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && mounted) {
      final file = File(result.files.single.path!);
      
      final targetLanguage = await _showLanguageChoiceDialog();
      if (targetLanguage == null || !mounted) return;

      final provider = Provider.of<StudyProvider>(context, listen: false);
      
      final success = await provider.processPdf(file, slotIndex, targetLanguage);
      
      if (!mounted) return;

      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudyMaterialScreen(
              session: provider.sessions[slotIndex]!,
              slotIndex: slotIndex, // تمرير رقم الخانة
            ),
          ),
        );
        provider.resetState();
      } else {
        _showErrorDialog(provider.errorMessage);
        provider.resetState();
      }
    }
  }

  Future<String?> _showLanguageChoiceDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر لغة المذاكرة'),
        content: const Text('بأي لغة تريد إنشاء الملخص والأسئلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('Arabic'),
            child: const Text('العربية'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('English'),
            child: const Text('الإنجليزية'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حدث خطأ'),
        content: Text(message.replaceFirst("Exception: ", "")),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<StudyProvider>(
          builder: (context, provider, child) {
            if (provider.state == AppState.loading) {
              return const LoadingWidget();
            }
            return _buildInitialState(provider);
          },
        ),
      ),
    );
  }

  Widget _buildInitialState(StudyProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Image.asset('logo.png', height: 60),
          const SizedBox(height: 8),
          Text('أهلاً بك في ذاكر', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28)),
          Text('جلسات المذاكرة الخاصة بك', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                if (index < 3) {
                  final session = provider.sessions[index];
                  return SessionSlotWidget(
                    session: session,
                    isLocked: false,
                    onTap: () {
                      if (session != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StudyMaterialScreen(session: session, slotIndex: index)),
                        );
                      } else {
                        _startProcessing(index);
                      }
                    },
                    onDelete: () => provider.deleteSession(index),
                  );
                } 
                // else {
                //   return SessionSlotWidget(
                //     session: null,
                //     isLocked: true,
                //     onTap: () {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(content: Text('هذه الميزة متوفرة في الاشتراك المدفوع قريباً!')),
                //       );
                //     },
                //     onDelete: () {},
                //   );
                // }
              },
            ),
          ),
        ],
      ),
    );
  }
}