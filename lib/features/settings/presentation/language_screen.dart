import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageModel {
  final String code;
  final String nativeName;
  final String englishName;
  final String countryCode;

  const LanguageModel({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.countryCode,
  });

  String get flagUrl => 'https://flagcdn.com/w160/${countryCode.toLowerCase()}.png';
}

const List<LanguageModel> kSupportedLanguages = [
  LanguageModel(code: 'en', nativeName: 'English', englishName: 'English', countryCode: 'us'),
  LanguageModel(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi', countryCode: 'in'),
  LanguageModel(code: 'es', nativeName: 'Español (Latinoamérica)', englishName: 'Spanish (Latin America)', countryCode: 'mx'),
  LanguageModel(code: 'fr', nativeName: 'Français', englishName: 'French', countryCode: 'fr'),
  LanguageModel(code: 'de', nativeName: 'Deutsch', englishName: 'German', countryCode: 'de'),
  LanguageModel(code: 'ar', nativeName: 'العربية', englishName: 'Arabic', countryCode: 'sa'),
  LanguageModel(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali', countryCode: 'bd'),
  LanguageModel(code: 'zh-CN', nativeName: '简体中文', englishName: 'Chinese (Simplified)', countryCode: 'cn'),
  LanguageModel(code: 'zh-TW', nativeName: '繁體中文', englishName: 'Chinese (Traditional)', countryCode: 'tw'),
  LanguageModel(code: 'nl', nativeName: 'Nederlands', englishName: 'Dutch', countryCode: 'nl'),
  LanguageModel(code: 'fil', nativeName: 'Filipino', englishName: 'Filipino', countryCode: 'ph'),
  LanguageModel(code: 'he', nativeName: 'עברית', englishName: 'Hebrew', countryCode: 'il'),
  LanguageModel(code: 'id', nativeName: 'Bahasa Indonesia', englishName: 'Indonesian', countryCode: 'id'),
  LanguageModel(code: 'it', nativeName: 'Italiano', englishName: 'Italian', countryCode: 'it'),
  LanguageModel(code: 'ja', nativeName: '日本語', englishName: 'Japanese', countryCode: 'jp'),
  LanguageModel(code: 'ko', nativeName: '한국어', englishName: 'Korean', countryCode: 'kr'),
  LanguageModel(code: 'ms', nativeName: 'Bahasa Melayu', englishName: 'Malay', countryCode: 'my'),
  LanguageModel(code: 'pl', nativeName: 'Polski', englishName: 'Polish', countryCode: 'pl'),
  LanguageModel(code: 'pt-BR', nativeName: 'Português (Brasil)', englishName: 'Portuguese (Brazil)', countryCode: 'br'),
  LanguageModel(code: 'ru', nativeName: 'Русский', englishName: 'Russian', countryCode: 'ru'),
  LanguageModel(code: 'th', nativeName: 'ไทย', englishName: 'Thai', countryCode: 'th'),
  LanguageModel(code: 'tr', nativeName: 'Türkçe', englishName: 'Turkish', countryCode: 'tr'),
  LanguageModel(code: 'vi', nativeName: 'Tiếng Việt', englishName: 'Vietnamese', countryCode: 'vn'),
];

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedCode = 'en';

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language_code') ?? 'en';
    setState(() {
      _selectedCode = saved;
    });
  }

  Future<void> _selectLanguage(LanguageModel lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', lang.code);
    await prefs.setString('app_language_native', lang.nativeName);
    if (mounted) {
      Navigator.of(context).pop(lang.nativeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Change Language',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: kSupportedLanguages.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
        itemBuilder: (context, index) {
          final lang = kSupportedLanguages[index];
          final isSelected = lang.code == _selectedCode;

          return Material(
            color: theme.cardColor,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  lang.flagUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      lang.code.toUpperCase().substring(0, 2),
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              title: Text(
                lang.nativeName,
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                lang.englishName,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 22)
                  : null,
              onTap: () => _selectLanguage(lang),
            ),
          );
        },
      ),
    );
  }
}
