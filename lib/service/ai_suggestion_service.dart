import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';

/// A data class to hold the result of the initial history analysis.
class AnalysisResult {
  /// True if the AI determines a new guide is needed based on the conversation's shift.
  final bool shouldRegenerateGuide;

  /// A brief summary of the user's current intention if a new guide is NOT needed.
  /// This can be null if regeneration is required.
  final String? userIntention;

  AnalysisResult({required this.shouldRegenerateGuide, this.userIntention});
}

class AiSuggestionService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // --- NEW METHOD TO ANALYZE HISTORY ---

  /// Analyzes the chat history to decide if the suggestion guide needs regeneration.
  ///
  /// This is the first step in the suggestion pipeline.
  /// It returns an [AnalysisResult] indicating whether to regenerate the guide
  /// and, if not, a summary of the user's current intention.
  Future<AnalysisResult> decideOnGuideRegeneration({
    required ChatHistoryNotifier notifier,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception("Gemini API key not found.");
    }

    final model = GenerativeModel(
      // Using the same fast model as requested
      model: 'gemini-2.5-flash-preview-05-20',
      apiKey: _apiKey,
    );

    final history = notifier.currentChatHistory.toPromptString();

    // If history is too short, it's not worth analyzing. Default to not regenerating.
    if (notifier.currentChatHistory.messages.length < 2) {
      return AnalysisResult(
        shouldRegenerateGuide: false,
        userIntention: "Continuing the initial conversation.",
      );
    }

    final prompt = """
You are an intelligent chat history analyzer.
Your task is to determine if the user's focus or intention in the conversation has shifted enough to require generating a new "Meme Suggestion Guide".

Analyze the provided chat history.

- If the conversation's topic, sentiment, or goal has clearly changed (e.g., from happy topics to sad, from asking about one character to another), you must decide to regenerate the guide.
- If the conversation is just continuing along the same path, do not regenerate the guide.
- If the history is very short (2-3 messages), it's usually too early to tell, so do not regenerate the guide unless there's a very sharp, explicit turn.

You MUST respond in a valid JSON format only, with no other text before or after the JSON block.
The JSON object must have two keys:
1. "regenerate_guide": A boolean (true or false).
2. "intention": A string. If "regenerate_guide" is true, this should be null. If false, provide a very brief, one-sentence summary of the user's current intention.

Example 1 (Regeneration needed):
{
  "regenerate_guide": true,
  "intention": null
}

Example 2 (Continuation):
{
  "regenerate_guide": false,
  "intention": "User is feeling happy and wants celebratory memes."
}

Here is the chat history:
---
$history
---
""";

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    final aiResponseText = response.text;

    if (aiResponseText == null || aiResponseText.trim().isEmpty) {
      throw Exception("AI analysis did not return a valid response.");
    }

    try {
      // Find the JSON block in case the model adds extra text like ```json
      final jsonRegex = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonRegex.firstMatch(aiResponseText);
      if (match == null) {
        throw FormatException("No valid JSON object found in AI response.");
      }
      final jsonString = match.group(0)!;
      final Map<String, dynamic> parsedJson = jsonDecode(jsonString);

      return AnalysisResult(
        shouldRegenerateGuide: parsedJson['regenerate_guide'] ?? false,
        userIntention: parsedJson['intention'],
      );
    } catch (e) {
      print("Failed to parse JSON from AI analysis: $aiResponseText");
      throw Exception("Could not parse analysis from AI response. Error: $e");
    }
  }

  // --- EXISTING METHODS (UNCHANGED) ---

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
  /// This is the second step in the suggestion pipeline, executed after a
  /// guide has been chosen (either a new one or an existing one).
  /// Throws an exception if the API call fails or returns no content.
  Future<List<String>> getMemeSuggestions({
    required String guide,
    required String userInput,
    required String aiMode,
    required int optionNumber,
    required ChatHistoryNotifier notifier,
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

    // Get chat history for better suggestion
    final history = notifier.currentChatHistory.toPromptString();

    // Build the two parts of our prompt
    final systemPrompt = await _buildSystemPrompt(aiMode, optionNumber);
    final userRequestPrompt =
        "This is the guide, $guide\nThe user typed: \"$userInput\". Current AI Mode: '$aiMode'. Provide $optionNumber image IDs based on this.\nThis is the current dialogue history: $history";

    final content = [
      Content.multi([TextPart(systemPrompt), TextPart(userRequestPrompt)]),
    ];

    print(systemPrompt);
    print(userRequestPrompt);

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

    print(lines);

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
