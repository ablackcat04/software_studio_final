import 'dart:convert';
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';

// lib/service/ai_suggestion_service.dart (or a new file)

// A custom exception to clearly identify cancellation events.
class CancellationException implements Exception {
  final String message;
  CancellationException(this.message);

  @override
  String toString() => 'CancellationException: $message';
}

// The token that will be passed around to signal cancellation.
class CancellationToken {
  bool _isCancelled = false;

  bool get isCancellationRequested => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

/// A data class to hold the result of the initial history analysis.
class AnalysisResult {
  /// True if the AI determines a new guide is needed based on the conversation's shift.
  final bool shouldRegenerateGuide;

  /// A brief summary of the user's current intention.
  /// - If `shouldRegenerateGuide` is `false`, this describes the ongoing intent.
  /// - If `shouldRegenerateGuide` is `true`, this explains WHY a new guide is needed.
  final String userIntention;

  AnalysisResult({
    required this.shouldRegenerateGuide,
    required this.userIntention,
  });
}

/// A data class to hold a single meme suggestion, including the reason.
class MemeSuggestion {
  /// The local asset path to the suggested meme image.
  final String imagePath;

  /// The AI-generated explanation for why this meme was suggested.
  final String reason;

  String getImagePath() {
    return imagePath;
  }

  String getReason() {
    return reason;
  }

  Map<String, dynamic> toJson() => {'imagePath': imagePath, 'reason': reason};

  factory MemeSuggestion.fromJson(Map<String, dynamic> json) {
    return MemeSuggestion(imagePath: json['imagePath'], reason: json['reason']);
  }

  MemeSuggestion({required this.imagePath, required this.reason});

  @override
  String toString() {
    return 'MemeSuggestion(imagePath: $imagePath, reason: $reason)';
  }
}

class AiSuggestionService {
  void _throwIfCancelled(CancellationToken token) {
    if (token.isCancellationRequested) {
      throw CancellationException('Operation was cancelled by the user.');
    }
  }

  Future<String> nameHistory({required String history}) async {
    if (_apiKey.isEmpty) {
      throw Exception("Gemini API key not found.");
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash-preview-05-20',
      apiKey: _apiKey,
    );

    final prompt = """
You are a '梗王' (Meme Lord), a master of creating witty and punchy one-liners.
Your job is to give this chat a funny, meme-worthy title in **繁體中文**.

The title must capture the essence or the punchline of the conversation.
No boring, generic names! Think like a viral social media post title.

- **Strictly** 10 characters or less.
- **繁體中文** only.
- Output the title directly.

Chat History:
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

    return aiResponseText;
  }

  static const String imageAnalysisPrompt = """
Your Role:

You are a specialized analysis component within an AI Meme Suggestion App's processing pipeline. Your primary function is to analyze a user-provided screenshot of a conversation and extract key contextual information. Your output will be a structured "Guide" used by a downstream Large Language Model (LLM) to select relevant memes.

Input:

You will receive a screenshot image of a conversation.

Your Tasks:

Analyze the Screenshot: Carefully examine both the visual elements and the text content of the screenshot.
Identify Platform: Determine the platform where the conversation is taking place (e.g., Discord, Facebook Messenger, LINE, Instagram DM, WhatsApp, Twitter/X, PTT, Dcard, 巴哈姆特動畫瘋, a generic web forum, SMS, etc.). If uncertain, state the most likely options.
Identify User: Infer who the 'user' is (the person who captured the screenshot and intends to reply). Look for indicators like "Me," message alignment (left/right), profile picture conventions, or other UI cues. If ambiguous, describe the participants neutrally (e.g., "User is Person A on the left").
Summarize Conversation Content: Briefly summarize the topic and tone of the recent conversation exchange shown in the screenshot. Focus on the last few messages to capture the immediate context for the user's potential reply. Note any strong emotions or key points being made.
Infer User Intentions (Categorized): Based specifically on the current state of the conversation in the screenshot, infer why the user might want to send a meme right now. Generate four distinct potential intentions for each of the following reply modes. These intentions should reflect plausible reasons for using a meme in that specific context and mode:
一般 (General/Normal): Standard conversational reactions (agreement, disagreement, humor, surprise, empathy, acknowledgement, topic change).
已讀亂回 (Read & Random Reply): Intentions focused on playful disruption, absurdity, non-sequiturs, ignoring the previous point humorously, or chaotic energy.
正經 (Serious/Formal): Intentions for more serious or formal replies (polite agreement/disagreement, concluding a point, emphasizing something seriously, expressing formal surprise or concern, perhaps even ironic use of a meme in a serious context).
關鍵字 (Keyword): Intentions directly related to specific nouns, verbs, concepts, or objects explicitly mentioned in the recent messages. Focus on the most salient keywords.
Output Format:

Structure your findings as a "Mindful Guide" using clear Markdown formatting. This guide will directly inform the next LLM.

Guide for Meme Suggestion LLM
1. Conversation Context Summary
Topic: [Brief summary of what's being discussed]
Recent Exchange: [Summary of the last 1-3 messages]
Tone/Emotion: [e.g., Casual, Humorous, Tense, Excited, Neutral, Argumentative]
2. Potential User Intentions (Why send a meme now?)
Mode: 一般 (General/Normal)
[Intention 1 - e.g., Express agreement with the last message]
[Intention 2 - e.g., Show amusement at the situation]
[Intention 3 - e.g., Lighten the mood]
[Intention 4 - e.g., Casually acknowledge the message]
Mode: 已讀亂回 (Read & Random Reply)
[Intention 1 - e.g., Completely change the subject absurdly]
[Intention 2 - e.g., Pretend to misunderstand the last message humorously]
[Intention 3 - e.g., Reply with something totally unrelated and chaotic]
[Intention 4 - e.g., Respond to an older message as if just seeing it]
Mode: 正經 (Serious/Formal)
[Intention 1 - e.g., Formally agree or disagree with a point made]
[Intention 2 - e.g., Emphasize the seriousness of their own previous point]
[Intention 3 - e.g., Politely signal the end of the discussion topic]
[Intention 4 - e.g., Express genuine concern or surprise in a non-casual way]
Mode: 關鍵字 (Keyword)
Identified Keywords: [List 1-3 key terms from recent messages, e.g., "cat", "exam", "dinner"]
[Intention 1 - e.g., React specifically to the mention of "cat"]
[Intention 2 - e.g., Show feelings about the upcoming "exam"]
[Intention 3 - e.g., Make a joke related to "dinner"]
[Intention 4 - e.g., Find a meme visually representing keyword X]
Important Considerations:

Be concise but informative.
Focus on the immediate context provided in the screenshot.
If information is ambiguous, acknowledge it.
Ensure the generated intentions are distinct within each category and plausible given the conversation summary.
""";

  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // --- UPDATED METHOD TO ANALYZE HISTORY ---

  /// Analyzes the chat history to decide if the suggestion guide needs regeneration.
  ///
  /// This is the first step in the suggestion pipeline.
  /// It returns an [AnalysisResult] indicating whether to regenerate the guide
  /// and providing a reason/summary of the user's current intention.
  Future<AnalysisResult> decideOnGuideRegeneration({
    required ChatHistoryNotifier notifier,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception("Gemini API key not found.");
    }

    final model = GenerativeModel(
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

    // *** PROMPT MODIFIED HERE ***
    final prompt = """
You are an intelligent chat history analyzer.
Your primary task is to analyze the conversation screenshot provided earlier and determine if the user's focus or intention has shifted enough to require generating a new "Meme Suggestion Guide".

**Important**: The conversation screenshot is the primary context for analysis. User input should only be used to refine or clarify the suggestions, not to override the original context.

Analyze the provided chat history.

- If the conversation's topic, sentiment, or goal has clearly changed (e.g., from happy topics to sad, from asking about one character to another), you must decide to regenerate the guide.
- If the conversation is just continuing along the same path, do not regenerate the guide.

You MUST respond in a valid JSON format only, with no other text before or after the JSON block.
The JSON object must have two keys:
1. "regenerate_guide": A boolean (true or false).
2. "intention": A string, which must ALWAYS be populated.
   - If "regenerate_guide" is `true`, this string should briefly explain WHY regeneration is needed (e.g., "Topic shifted from planning to expressing sadness.").
   - If "regenerate_guide" is `false`, this string should be a brief, one-sentence summary of the user's current intention (e.g., "User wants to express agreement and happiness.").

Example 1 (Regeneration needed):
{
  "regenerate_guide": true,
  "intention": "The topic has shifted from general greetings to a serious discussion about a problem."
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
    _throwIfCancelled(cancellationToken);
    final response = await model.generateContent(content);
    _throwIfCancelled(cancellationToken);
    final aiResponseText = response.text;

    if (aiResponseText == null || aiResponseText.trim().isEmpty) {
      throw Exception("AI analysis did not return a valid response.");
    }

    try {
      final jsonRegex = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonRegex.firstMatch(aiResponseText);
      if (match == null) {
        throw FormatException("No valid JSON object found in AI response.");
      }
      final jsonString = match.group(0)!;
      final Map<String, dynamic> parsedJson = jsonDecode(jsonString);

      // *** PARSING LOGIC UPDATED HERE ***
      return AnalysisResult(
        shouldRegenerateGuide: parsedJson['regenerate_guide'] ?? false,
        userIntention:
            parsedJson['intention'] ??
            "Analysis failed: No intention provided.",
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

  // This function is updated to instruct the AI to provide a reason in JSON format.
  Future<String> _buildSystemPrompt(String mode, int optionNumber) async {
    final memeDatabase = await _loadMemeDatabase();
    String databaseString = '';

    for (var entry in memeDatabase.entries) {
      databaseString += "${entry.key}: ${entry.value.toString()}\n\n";
    }

    print('現在的模式：$mode');

    return """
Your Role:
You are a specialized analysis component within an AI Meme Suggestion App's processing pipeline. Your task is to analyze the user's request and the provided guide to select the most suitable memes from a database. The database format is ID: description.

The current suggestion mode is '$mode'.

**CRITICAL: Your Output Format**
You MUST respond with a valid JSON array only. Do not include any text, notes, or markdown formatting before or after the JSON block.
The array should contain exactly $optionNumber objects.
Each object in the array represents a single meme suggestion and MUST have two keys:
1.  `"id"`: A string containing the exact ID of the meme from the database.
2.  `"reason"`: A concise, user-facing string (in Traditional Chinese) explaining WHY this meme is a good suggestion for the current context.

**Example of a valid response for 2 options:**
```json
[
  {
    "id": "mygo_01",
    "reason": "這張圖很適合用來表達對話中提到的困惑或不解。"
  },
  {
    "id": "mygo_25",
    "reason": "可以用這張迷因來輕鬆地表示同意，緩和氣氛。"
  }
]
You should think through your choices to ensure high quality. Your reasoning will be shown directly to the user, so make it clear, helpful, and concise.
Meme Database:
$databaseString
""";
  }

  Future<String?> generateGuide({
    required Uint8List? imageBytes,
    required String? mimeType,
    required String intension,
    required String selectedMode, // 新增參數
    required CancellationToken cancellationToken,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash-preview-05-20',
      apiKey: _apiKey,
    );

    final String imageAnalysisPrompt = """
Your Role:

You are a specialized analysis component within an AI Meme Suggestion App's processing pipeline. Your primary function is to analyze a user-provided screenshot of a conversation and extract key contextual information. Your output will be a structured "Guide" used by a downstream Large Language Model (LLM) to select relevant memes.

Input:

You will receive a screenshot image of a conversation.

Your Tasks:

Analyze the Screenshot: Carefully examine both the visual elements and the text content of the screenshot.
Identify Platform: Determine the platform where the conversation is taking place (e.g., Discord, Facebook Messenger, LINE, Instagram DM, WhatsApp, Twitter/X, PTT, Dcard, 巴哈姆特動畫瘋, a generic web forum, SMS, etc.). If uncertain, state the most likely options.
Identify User: Infer who the 'user' is (the person who captured the screenshot and intends to reply). Look for indicators like "Me," message alignment (left/right), profile picture conventions, or other UI cues. If ambiguous, describe the participants neutrally (e.g., "User is Person A on the left").
Summarize Conversation Content: Briefly summarize the topic and tone of the recent conversation exchange shown in the screenshot. Focus on the last few messages to capture the immediate context for the user's potential reply. Note any strong emotions or key points being made.
Infer User Intentions (Categorized): Based specifically on the current state of the conversation in the screenshot, infer why the user might want to send a meme right now. Generate four distinct potential intentions for the selected reply mode: '$selectedMode'. These intentions should reflect plausible reasons for using a meme in that specific context and mode.

Output Format:

Structure your findings as a "Mindful Guide" using clear Markdown formatting. This guide will directly inform the next LLM.

Guide for Meme Suggestion LLM
1. Conversation Context Summary
Topic: [Brief summary of what's being discussed]
Recent Exchange: [Summary of the last 1-3 messages]
Tone/Emotion: [e.g., Casual, Humorous, Tense, Excited, Neutral, Argumentative]
2. Potential User Intentions (Why send a meme now?)
Mode: $selectedMode
[Intention 1 - e.g., Express agreement with the last message]
[Intention 2 - e.g., Show amusement at the situation]
[Intention 3 - e.g., Lighten the mood]
[Intention 4 - e.g., Casually acknowledge the message]
Important Considerations:

Be concise but informative.
Focus on the immediate context provided in the screenshot.
If information is ambiguous, acknowledge it.
Ensure the generated intentions are distinct within each category and plausible given the conversation summary.
""";

    final content = [
      Content.multi([
        TextPart(
          '$imageAnalysisPrompt\n\nHere is some conclusion of the user\'s intention: \n$intension',
        ),
        DataPart(mimeType ?? 'image/jpeg', imageBytes!),
      ]),
    ];
    _throwIfCancelled(cancellationToken);
    final response = await model.generateContent(content);
    _throwIfCancelled(cancellationToken);
    return response.text;
  }

  Future<List<MemeSuggestion>> getMemeSuggestions({
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

    final history = notifier.currentChatHistory.toPromptString();
    final systemPrompt = await _buildSystemPrompt(aiMode, optionNumber);
    final userRequestPrompt =
        "This is the guide, $guide\nThe user typed: \"$userInput\". Current AI Mode: '$aiMode'. Provide $optionNumber meme suggestions based on this.\nThis is the current dialogue history: $history";

    final content = [
      Content.multi([TextPart(systemPrompt), TextPart(userRequestPrompt)]),
    ];

    final response = await model.generateContent(content);
    final aiResponseText = response.text;

    if (aiResponseText == null || aiResponseText.trim().isEmpty) {
      throw Exception("AI did not return any suggestions.");
    }

    try {
      // Find the JSON array within the response, stripping any surrounding text or markdown.
      final jsonRegex = RegExp(r'\[.*\]', dotAll: true);
      final match = jsonRegex.firstMatch(aiResponseText);
      if (match == null) {
        throw FormatException("No valid JSON array found in AI response.");
      }
      final jsonString = match.group(0)!;

      // Decode the JSON string into a List of dynamic objects
      final List<dynamic> parsedJson = jsonDecode(jsonString);

      // Map the parsed JSON objects into our MemeSuggestion data class
      final List<MemeSuggestion> suggestions =
          parsedJson
              .map((item) {
                if (item is Map<String, dynamic> &&
                    item.containsKey('id') &&
                    item.containsKey('reason')) {
                  final id = item['id'] as String;
                  final reason = item['reason'] as String;
                  return MemeSuggestion(
                    imagePath: 'assets/images/basic/$id.jpg',
                    reason: reason,
                  );
                } else {
                  // Handle cases where an item in the array is malformed
                  print("Warning: Malformed item in AI response: $item");
                  return null;
                }
              })
              .whereType<MemeSuggestion>()
              .toList(); // Filter out any nulls

      if (suggestions.isEmpty) {
        throw Exception(
          "Parsed suggestions list is empty, despite receiving a response.",
        );
      }

      return suggestions;
    } catch (e) {
      print(
        "Failed to parse JSON from AI suggestion response: $aiResponseText",
      );
      throw Exception(
        "Could not parse suggestions from AI response. Error: $e",
      );
    }
  }
}
