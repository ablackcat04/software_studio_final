import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiSuggestionService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // Private helper to load the meme database from JSON
  Future<Map<String, dynamic>> _loadMemeDatabase() async {
    String jsonString = await rootBundle.loadString(
      'assets/images/basic/description/mygo.json',
    );
    return jsonDecode(jsonString);
  }

  // Private helper to build the system prompt
  Future<String> _buildSystemPrompt(String mode, int optionNumber) async {
    final memeDatabase = await _loadMemeDatabase();
    String databaseString = '';

    // Convert the database map to a string format for the prompt
    for (var entry in memeDatabase.entries) {
      databaseString += "${entry.key}: ${entry.value.toString()}\n\n";
    }

    return """
Your Role:

You are a specialized analysis component within an AI Meme Suggestion App's 
processing pipeline. Your primary function is to follow a provided meme 
suggestion guide and find suitable meme from the database, 
the database is in ID: description. 
Your output will only consist $optionNumber ID, separated by a newline. 
The suggestion mode now is $mode. The database is provided below. 
Thinking should be concise since speed is critical in this task.

------------------------------------------------------------------------------
$databaseString
""";
  }

  /// Fetches meme suggestions from the AI based on context.
  ///
  /// Throws an exception if the API call fails or returns no content.
  Future<List<String>> getMemeSuggestions({
    required String guide,
    required String userInput,
    required String aiMode,
    required int optionNumber,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception("Gemini API key not found.");
    }

    if (guide.isEmpty) {
      throw Exception("AI Guide is empty. Cannot get suggestions.");
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash-preview-05-20',
      apiKey: _apiKey,
    );

    // Build the two parts of our prompt
    final systemPrompt = await _buildSystemPrompt(aiMode, optionNumber);
    final userRequestPrompt =
        "This is the guide, $guide\nThe user typed: \"$userInput\". Current AI Mode: '$aiMode'. Provide $optionNumber image IDs based on this.";

    final content = [
      Content.multi([TextPart(systemPrompt), TextPart(userRequestPrompt)]),
    ];

    final response = await model.generateContent(content);
    final aiResponseText = response.text;

    if (aiResponseText == null || aiResponseText.trim().isEmpty) {
      throw Exception("AI did not return any suggestions.");
    }

    // Parse the response to get image paths
    final lines =
        aiResponseText
            .trim()
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();

    if (lines.isEmpty) {
      throw Exception(
        "Could not parse image IDs from AI response: $aiResponseText",
      );
    }

    final List<String> imagePaths =
        lines.map((id) => 'images/basic/$id.jpg').toList();

    return imagePaths;
  }
}
