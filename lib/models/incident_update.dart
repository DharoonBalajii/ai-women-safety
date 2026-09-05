import 'location_point.dart';

enum UpdateSource { voice, textInput, silentOption, system, responder }

class IncidentUpdate {
  final String id;
  final DateTime timestamp;
  final String text;
  final UpdateSource source;
  final LocationPoint? location;
  final String? rawTranscript;
  final String? detectedLanguage;

  const IncidentUpdate({
    required this.id,
    required this.timestamp,
    required this.text,
    required this.source,
    this.location,
    this.rawTranscript,
    this.detectedLanguage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'text': text,
        'source': source.name,
        'location': location?.toJson(),
        'rawTranscript': rawTranscript,
        'detectedLanguage': detectedLanguage,
      };

  factory IncidentUpdate.fromJson(Map<String, dynamic> json) => IncidentUpdate(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        text: json['text'] as String,
        source: UpdateSource.values.firstWhere(
          (s) => s.name == json['source'],
          orElse: () => UpdateSource.system,
        ),
        location: json['location'] != null
            ? LocationPoint.fromJson(json['location'] as Map<String, dynamic>)
            : null,
        rawTranscript: json['rawTranscript'] as String?,
        detectedLanguage: json['detectedLanguage'] as String?,
      );
}
