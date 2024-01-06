import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:replicate_json/replicate_json.dart';

// Make sure to change the API key to yours
void main() => runApp(const MaterialApp(home: MyImageWidget()));

class MyImageWidget extends StatefulWidget {
  const MyImageWidget({super.key});

  @override
  _MyImageWidgetState createState() => _MyImageWidgetState();
}

class _MyImageWidgetState extends State<MyImageWidget> {
  String? _imageUrl;
  String? _errorMessage;
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    String? savedApiUrl = _prefs.getString('apiUrl');
    if (savedApiUrl != null) {
      _urlController.text = savedApiUrl;
    }
  }

  Future<void> _saveSettings() async {
    String apiUrl = _urlController.text.trim();
    if (apiUrl.isNotEmpty) {
      await _prefs.setString('apiUrl', apiUrl);
    }
  }

  Future<void> _generateImage(String query) async {
    String? apiUrl = _urlController.text.trim();
    await _saveSettings();

    setState(() {
      _imageUrl = null;
      _errorMessage = null;
    });
    try {
      String modelVersion =
          "a7e8fa2f96b01d02584de2b3029a8452b9bf0c8fa4127a6d1cfd406edfad54fb"; // model version for replicate api

      String apiKey =
          "r8_LwNPVVpFExFT1D7d8T07dRk4MVkaOK60FAJyD"; //replace with your api key
      Map<String, Object> input = {
        // input is specific to replicate model, adjust to fit your use
        "prompt": query,
        "cn_type1": "ImagePrompt",
        "cn_type2": "ImagePrompt",
        "cn_type3": "ImagePrompt",
        "cn_type4": "ImagePrompt",
        "sharpness": 10,
        "image_seed": -1,
        "uov_method": "Disabled",
        "image_number": 1,
        "guidance_scale": 4,
        "refiner_switch": 0.5,
        "negative_prompt": "",
        "style_selections": "Fooocus V2,Fooocus Enhance,Fooocus Sharp",
        "uov_upscale_value": 0,
        "outpaint_selections": "",
        "outpaint_distance_top": 0,
        "performance_selection": "Speed",
        "outpaint_distance_left": 0,
        "aspect_ratios_selection": "1152*896",
        "outpaint_distance_right": 0,
        "outpaint_distance_bottom": 0,
        "inpaint_additional_prompt": ""
      };
      String jsonString = await createAndGetJson(modelVersion, apiKey, input);
      var responseJson =
          jsonDecode(jsonString); //converts string to json object

      // then you can parse the json file to get whatever value you need
      // For this example, I want the 'output', which is a png link
      String pngLink = responseJson['output'][0];
      setState(() {
        _imageUrl = pngLink;
      });
    } catch (e) {
      setState(() {
        print(e);
        _errorMessage = 'Failed to generate image: $e';
      });
    }
  }

  Future<void> _showSettingsDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Enter API URL',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _generateImage(_queryController.text.trim());
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 199, 136, 10),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: const Color.fromARGB(255, 203, 139, 11)),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fooocus'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _showSettingsDialog();
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _queryController,
                decoration: const InputDecoration(
                  labelText: 'Enter Query',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  String query = _queryController.text.trim();
                  if (query.isNotEmpty) {
                    _generateImage(query);
                  }
                },
                child: const Text('Generate'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: _imageUrl != null
                      ? Image.network(_imageUrl!)
                      : _errorMessage != null
                          ? Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            )
                          : const CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
