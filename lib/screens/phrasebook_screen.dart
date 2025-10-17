import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';
import '../models/phrase.dart';

class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({super.key});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  final List<Phrase> _phrases = [
    Phrase(
      english: "Hello",
      local: "Namaste",
      localScript: "नमस्ते",
      language: "Hindi",
      pronunciation: "nuh-muh-stay",
    ),
    Phrase(
      english: "Thank you",
      local: "Dhanyavaad",
      localScript: "धन्यवाद",
      language: "Hindi",
      pronunciation: "dhun-yuh-vaad",
    ),
    Phrase(
      english: "How are you?",
      local: "Kaise hain aap?",
      localScript: "कैसे हैं आप?",
      language: "Hindi",
      pronunciation: "kai-se hain aap",
    ),
    Phrase(
      english: "What is your name?",
      local: "Aapka naam kya hai?",
      localScript: "आपका नाम क्या है?",
      language: "Hindi",
      pronunciation: "aap-ka naam kya hai",
    ),
    Phrase(
      english: "I don't understand",
      local: "Mujhe samajh nahi aaya",
      localScript: "मुझे समझ नहीं आया",
      language: "Hindi",
      pronunciation: "muj-he su-mujh na-hee a-ya",
    ),
    Phrase(
      english: "Hello",
      local: "Nomoskar",
      localScript: "নমস্কার",
      language: "Bengali",
      pronunciation: "no-moh-shkar",
    ),
    Phrase(
      english: "Thank you",
      local: "Dhonnobad",
      localScript: "ধন্যবাদ",
      language: "Bengali",
      pronunciation: "dhon-no-bad",
    ),
    Phrase(
      english: "Hello",
      local: "Vanakkam",
      localScript: "வணக்கம்",
      language: "Tamil",
      pronunciation: "va-nuh-kum",
    ),
    Phrase(
      english: "Thank you",
      local: "Nandri",
      localScript: "நன்றி",
      language: "Tamil",
      pronunciation: "nun-dree",
    ),
  ];

  String _selectedLanguage = "Hindi";

  List<String> get _availableLanguages {
    return _phrases.map((phrase) => phrase.language).toSet().toList();
  }

  List<Phrase> get _filteredPhrases {
    return _phrases.where((phrase) => phrase.language == _selectedLanguage).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ttsService = context.watch<TtsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regional Phrasebook'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildLanguageSelector(),
          Expanded(
            child: _buildPhraseList(ttsService),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              items: _availableLanguages.map((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhraseList(TtsService tts) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _filteredPhrases.length,
      itemBuilder: (context, index) {
        final phrase = _filteredPhrases[index];
        return _buildPhraseCard(phrase, tts);
      },
    );
  }

  Widget _buildPhraseCard(Phrase phrase, TtsService tts) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phrase.english,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phrase.local,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (phrase.localScript != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          phrase.localScript!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontFamily: 'NotoSans',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => tts.speak(phrase.local),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pronunciation: ${phrase.pronunciation}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}