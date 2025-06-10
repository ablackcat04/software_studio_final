import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:http/http.dart' as http;
import 'package:software_studio_final/state/settings_notifier.dart'; // Add this import at the top

/// Represents a single meme retrieved from the RAG (semantic search) step.
class _FilteredMemeResult {
  final String id;
  final String description;
  final String folderName;

  _FilteredMemeResult({
    required this.id,
    required this.description,
    required this.folderName,
  });

  factory _FilteredMemeResult.fromJson(Map<String, dynamic> json) {
    return _FilteredMemeResult(
      id: json['id'] as String,
      description: json['description'] as String,
      folderName: json['folderName'] as String,
    );
  }
}

// A custom exception to clearly identify cancellation events.
class CancellationException implements Exception {
  final String message;
  CancellationException(this.message);
  @override
  String toString() => 'CancellationException: $message';
}

/// An enhanced CancellationToken that can notify listeners upon cancellation.
class CancellationToken {
  bool _isCancelled = false;
  final List<VoidCallback> _onCancelCallbacks = [];

  bool get isCancellationRequested => _isCancelled;

  /// Registers a callback to be executed when cancel() is called.
  void onCancel(VoidCallback callback) {
    if (_isCancelled) {
      callback();
    } else {
      _onCancelCallbacks.add(callback);
    }
  }

  /// Sets the token to cancelled and invokes all registered callbacks.
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final callback in _onCancelCallbacks) {
      callback();
    }
    _onCancelCallbacks.clear();
  }

  /// Cleans up any registered listeners.
  void dispose() {
    _onCancelCallbacks.clear();
  }
}

/// A data class to hold the result of the initial history analysis.
class AnalysisResult {
  final bool shouldRegenerateGuide;
  final String userIntention;

  AnalysisResult({
    required this.shouldRegenerateGuide,
    required this.userIntention,
  });
}

/// A data class to hold a single meme suggestion, including the reason.
class MemeSuggestion {
  final String imagePath;
  final String reason;

  String getImagePath() => imagePath;
  String getReason() => reason;

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
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final String _ragFunctionUrl = dotenv.env['RAG_FUNCTION_URL'] ?? '';

  /// A reusable helper that converts a Gemini stream into a cancellable Future.
  /// It handles stream listening, cancellation, and parsing.
  Future<T> _generateFromStream<T>({
    required List<Content> content,
    required T Function(String) parser,
    required CancellationToken cancellationToken,
    String modelName = 'gemini-2.5-flash-preview-05-20',
  }) {
    if (_apiKey.isEmpty) {
      return Future.error(Exception("Gemini API key not found."));
    }

    final model = GenerativeModel(model: modelName, apiKey: _apiKey);
    final completer = Completer<T>();
    final buffer = StringBuffer();
    StreamSubscription<GenerateContentResponse>? subscription;

    // When the user clicks "Stop", this gets called immediately.
    cancellationToken.onCancel(() {
      subscription?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(
          CancellationException('Operation was cancelled by the user.'),
        );
      }
    });

    // Start listening to the stream of responses from the API.
    subscription = model
        .generateContentStream(content)
        .listen(
          (response) {
            // Append each chunk of text to our buffer.
            buffer.write(response.text);
          },
          onDone: () {
            if (!completer.isCompleted) {
              try {
                final fullText = buffer.toString();
                if (fullText.isEmpty) {
                  throw Exception("AI did not return any content.");
                }
                // Once the stream is finished, parse the full text.
                final result = parser(fullText);
                completer.complete(result);
              } catch (e) {
                completer.completeError(e);
              }
            }
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
          cancelOnError: true,
        );

    return completer.future;
  }

  /// Renames the history using a cancellable stream.
  Future<String> nameHistory({
    required String history,
    required CancellationToken cancellationToken,
  }) async {
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

    return _generateFromStream<String>(
      content: content,
      cancellationToken: cancellationToken,
      parser:
          (fullText) =>
              fullText.trim(), // The parser just returns the full text.
      modelName: 'gemini-2.0-flash',
    );
  }

  /// Analyzes chat history to decide on guide regeneration using a cancellable stream.
  Future<AnalysisResult> decideOnGuideRegeneration({
    required ChatHistoryNotifier notifier,
    required CancellationToken cancellationToken,
  }) async {
    final history = notifier.currentChatHistory.toPromptString();

    if (notifier.currentChatHistory.messages.length < 2) {
      return AnalysisResult(
        shouldRegenerateGuide: false,
        userIntention: "Continuing the initial conversation.",
      );
    }

    final prompt = """
You are an intelligent chat history analyzer.
Your task is to determine if the user's focus or intention in the conversation has shifted enough to require generating a new "Meme Suggestion Guide".
Your primary task is to analyze the conversation screenshot provided earlier and determine if the user's focus or intention has shifted enough to require generating a new "Meme Suggestion Guide".

**Impartant**: This should be fast since speed is crucial in this task.
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

    return _generateFromStream<AnalysisResult>(
      content: content,
      cancellationToken: cancellationToken,
      parser: (fullText) {
        final jsonRegex = RegExp(r'\{.*\}', dotAll: true);
        final match = jsonRegex.firstMatch(fullText);
        if (match == null) {
          throw FormatException("No valid JSON object found in AI response.");
        }
        final jsonString = match.group(0)!;
        final Map<String, dynamic> parsedJson = jsonDecode(jsonString);
        return AnalysisResult(
          shouldRegenerateGuide: parsedJson['regenerate_guide'] ?? false,
          userIntention:
              parsedJson['intention'] ??
              "Analysis failed: No intention provided.",
        );
      },
      modelName: 'gemini-2.0-flash',
    );
  }

  /// Generates a new guide based on an image using a cancellable stream.
  Future<String?> generateGuide({
    required Uint8List? imageBytes,
    required String? mimeType,
    required String intension,
    required String selectedMode,
    required CancellationToken cancellationToken,
  }) async {
    final imageAnalysisPrompt = """
Your Role:
You are a specialized analysis component within an AI Meme Suggestion App's processing pipeline. Your primary function is to infer potential user intentions based on the provided screenshot and selected mode.

Infer User Intentions (Categorized):
Based specifically on the current state of the conversation in the screenshot, infer why the user might want to send a meme right now. Generate four distinct potential intentions for the selected reply mode: '$selectedMode'. These intentions should reflect plausible reasons for using a meme in that specific context and mode.

Output Format:
[List of four distinct intentions]
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

    return _generateFromStream<String?>(
      content: content,
      cancellationToken: cancellationToken,
      parser: (fullText) => fullText.isEmpty ? null : fullText.trim(),
    );
  }

  Future<List<_FilteredMemeResult>> _findRelevantMemesViaRAG({
    required String query,
    required CancellationToken cancellationToken,
    required int amount,
    required List<String> enabledFolders, // <<< ADD THIS PARAMETER
  }) async {
    if (_ragFunctionUrl.isEmpty) {
      throw Exception("RAG_FUNCTION_URL not found in .env file.");
    }

    final completer = Completer<List<_FilteredMemeResult>>();
    final client = http.Client();

    cancellationToken.onCancel(() {
      client.close();
      if (!completer.isCompleted) {
        completer.completeError(
          CancellationException("RAG search was cancelled."),
        );
      }
    });

    try {
      final response = await client.post(
        Uri.parse(_ragFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'top_k': amount,
          'enabled_folders': enabledFolders, // <<< ADD THIS LINE
        }),
      );

      if (cancellationToken.isCancellationRequested) {
        return completer.future;
      }

      if (response.statusCode == 200) {
        // Use utf8.decode to handle non-ASCII characters correctly
        final List<dynamic> resultsJson = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final results =
            resultsJson.map((json) {
              // The json from python will have 'folderName', so this will now work.
              return _FilteredMemeResult.fromJson(json);
            }).toList();
        completer.complete(results);
      } else {
        throw Exception(
          'RAG search failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    } finally {
      client.close();
    }

    return completer.future;
  }

  Future<List<MemeSuggestion>> getMemeSuggestions({
    required String guide,
    required String userInput,
    required String aiMode,
    required int optionNumber,
    required ChatHistoryNotifier notifier,
    required CancellationToken cancellationToken,
    required SettingsNotifier settingsNotifier,
  }) async {
    if (guide.isEmpty) {
      throw Exception("AI Guide is empty. Cannot get suggestions.");
    }

    final ragQuery =
        "Based on this context: $guide\nThe user's immediate request is: $userInput";

    // <<< CHANGE >>> Pass the enabled folders to the RAG function.
    final List<_FilteredMemeResult> relevantMemes =
        await _findRelevantMemesViaRAG(
          query: ragQuery,
          cancellationToken: cancellationToken,
          amount: optionNumber * 4,
          enabledFolders:
              settingsNotifier.enabledFolders.toList(), // <<< PASS FOLDERS HERE
        );

    if (relevantMemes.isEmpty) {
      throw Exception(
        "Semantic search (RAG) did not find any relevant memes. Try rephrasing your request.",
      );
    }

    final systemPrompt = await _buildSystemPrompt(
      mode: aiMode,
      optionNumber: optionNumber,
      relevantMemes: relevantMemes,
    );

    final history = notifier.currentChatHistory.toPromptString();
    final userRequestPrompt =
        "This is the guide: $guide\nThe user typed: \"$userInput\". Current AI Mode: '$aiMode'.\nFrom the provided database of relevant memes, select the best $optionNumber options.\nThis is the current dialogue history: $history";

    final content = [
      Content.multi([TextPart(systemPrompt), TextPart(userRequestPrompt)]),
    ];

    return _generateFromStream<List<MemeSuggestion>>(
      content: content,
      cancellationToken: cancellationToken,
      parser: (fullText) {
        final jsonRegex = RegExp(r'\[.*\]', dotAll: true);
        final match = jsonRegex.firstMatch(fullText);
        if (match == null) {
          throw FormatException(
            "No valid JSON array found in AI response. Response: $fullText",
          );
        }
        final jsonString = match.group(0)!;
        final List<dynamic> parsedJson = jsonDecode(jsonString);

        // <<< NEW LOGIC TO BUILD DYNAMIC PATHS >>>
        // Create a lookup map to find the folder name for a given meme ID.
        // This is efficient and robust.
        final memeFolderMap = {
          for (var meme in relevantMemes) meme.id: meme.folderName,
        };

        final List<MemeSuggestion> suggestions =
            parsedJson
                .map((item) {
                  if (item is Map<String, dynamic> &&
                      item.containsKey('id') &&
                      item.containsKey('reason')) {
                    final String id = item['id'];
                    // Look up the folder name using the ID from the AI's response.
                    final String? folderName = memeFolderMap[id];

                    // If the folder is found, construct the dynamic path.
                    // Otherwise, fall back to a default path to prevent errors.
                    String imagePath;
                    if (folderName != null) {
                      imagePath =
                          (folderName == 'mygo')
                              ? 'assets/images/$folderName/$id.jpg'
                              : 'assets/images/$folderName/$id.png';
                    } else {
                      imagePath = 'assets/images/basic/$id.jpg';
                    }

                    return MemeSuggestion(
                      imagePath: imagePath,
                      reason: item['reason'],
                    );
                  }
                  return null;
                })
                .whereType<MemeSuggestion>()
                .toList();

        if (suggestions.isEmpty) {
          throw Exception(
            "Parsed suggestions list is empty, despite receiving a response.",
          );
        }
        return suggestions;
      },
    );
  }

  Future<String> _buildSystemPrompt({
    required String mode,
    required int optionNumber,
    required List<_FilteredMemeResult>
    relevantMemes, // It now accepts the filtered list
  }) async {
    // Convert the list of relevant memes into a string for the prompt.
    String databaseString = relevantMemes
        .map((meme) {
          // Use a consistent format that the LLM can easily parse.
          return "${meme.id}: ${jsonEncode({'description': meme.description})}";
        })
        .join("\n\n");

    // The prompt is now much shorter and more focused.
    return """
Your Role:
You are a specialized analysis component within an AI Meme Suggestion App. Your task is to analyze the provided guide and the user's request(mainly on the provided guide,because you are still analything the conversation scrrenshot) to select the most suitable memes from a pre-filtered, highly relevant database.
The current suggestion mode is '$mode'.
**CRITICAL: Your Output Format**
You MUST respond with a valid JSON array only. Do not include any text, notes, or markdown formatting before or after the JSON block.
The array should contain exactly $optionNumber objects.
Each object represents a single meme suggestion and MUST have two keys:
1.  `"id"`: A string containing the exact ID of the meme from the provided database.
2.  `"reason"`: A concise, user-facing string (in Traditional Chinese) explaining WHY this meme is a good suggestion for the current context.
**Example of a valid response for 2 options:**
```json
[
  {
    "id": "1",
    "reason": "這張圖很適合用來表達對話中提到的困惑或不解。"
  },
  {
    "id": "25",
    "reason": "可以用這張迷因來輕鬆地表示同意，緩和氣氛。"
  }
]
You must think through your choices to ensure high quality. Your reasoning will be shown directly to the user, so make it clear, helpful, and concise.
**Relevant Meme Database (pre-filtered by semantic search):**
$databaseString
""";
  }
}
