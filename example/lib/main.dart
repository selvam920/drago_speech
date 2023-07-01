import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drago_speech_recognition/speech.dart';

void main() {
  runApp(MyApp());
}

const languages = const [
  const Language('india', 'ta_IN'),
  const Language('English', 'en_US'),
  const Language('Pусский', 'ru_RU'),
  const Language('Italiano', 'it_IT'),
  const Language('Español', 'es_ES'),
];

class Language {
  final String name;
  final String code;

  const Language(this.name, this.code);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late DragoSpeechRecognition _speech;

  bool _speechRecognitionAvailable = false;
  bool _isListening = false;

  String transcription = '';

  String _currentLocale = 'en_IN';
  Language selectedLang = languages.first;

  @override
  initState() {
    super.initState();
    activateSpeechRecognizer();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void activateSpeechRecognizer() {
    print('_MyAppState.activateSpeechRecognizer... ');
    _speech = DragoSpeechRecognition();
    _speech.setAvailabilityHandler(onSpeechAvailability);
    _speech.setRecognitionStartedHandler(onRecognitionStarted);
    _speech.setRecognitionResultHandler(onRecognitionResult);
    _speech.setRecognitionCompleteHandler(onRecognitionComplete);
    _speech.setErrorHandler(errorHandler);
    _speech.activate(_currentLocale).then((res) {
      setState(() => _speechRecognitionAvailable = res);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Shortcuts(
      shortcuts: const <SingleActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
      },
      child: FocusScope(
        onKey: (node, event) {
          print(event);
          return KeyEventResult.handled;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('SpeechRecognition'),
            actions: [
              PopupMenuButton<Language>(
                onSelected: _selectLangHandler,
                itemBuilder: (BuildContext context) => _buildLanguagesWidgets,
              )
            ],
          ),
          body: Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                        child: Container(
                            padding: const EdgeInsets.all(8.0),
                            color: Colors.grey.shade200,
                            child: Text(transcription))),
                    _buildButton(
                      onPressed: _speechRecognitionAvailable && !_isListening
                          ? () => start()
                          : null,
                      label: _isListening
                          ? 'Listening...'
                          : 'Listen (${selectedLang.code})',
                    ),
                    _buildButton(
                      onPressed: _isListening ? () => cancel() : null,
                      label: 'Cancel',
                    ),
                    _buildButton(
                      onPressed: _isListening ? () => stop() : null,
                      label: 'Stop',
                    ),
                  ],
                ),
              )),
        ),
      ),
    ));
  }

  List<CheckedPopupMenuItem<Language>> get _buildLanguagesWidgets => languages
      .map((l) => CheckedPopupMenuItem<Language>(
            value: l,
            checked: selectedLang == l,
            child: Text(l.name),
          ))
      .toList();

  void _selectLangHandler(Language lang) {
    setState(() => selectedLang = lang);
  }

  Widget _buildButton({required String label, VoidCallback? onPressed}) =>
      Padding(
          padding: EdgeInsets.all(12.0),
          child: ElevatedButton(
            onPressed: onPressed,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ));

  void start() => _speech.activate(_currentLocale).then((_) {
        return _speech.listen().then((result) {
          print('_MyAppState.start => result $result');
          setState(() {
            _isListening = result;
          });
        });
      });

  void cancel() =>
      _speech.cancel().then((_) => setState(() => _isListening = false));

  void stop() => _speech.stop().then((_) {
        setState(() => _isListening = false);
      });

  void onSpeechAvailability(bool result) =>
      setState(() => _speechRecognitionAvailable = result);

  void onCurrentLocale(String locale) {
    print('_MyAppState.onCurrentLocale... $locale');
    setState(
        () => selectedLang = languages.firstWhere((l) => l.code == locale));
  }

  void onRecognitionStarted() {
    setState(() => _isListening = true);
  }

  void onRecognitionResult(String text) {
    print('_MyAppState.onRecognitionResult... $text');
    setState(() => transcription = text);
  }

  void onRecognitionComplete(String text) {
    print('_MyAppState.onRecognitionComplete... $text');
    setState(() => _isListening = false);
  }

  void errorHandler() {
    activateSpeechRecognizer();
  }
}
