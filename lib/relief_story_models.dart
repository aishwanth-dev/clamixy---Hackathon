import 'package:flutter/material.dart';

class ReliefStepModel {
  final String type; // breathing, mindfulness, activity, journaling, reflection
  final String title;
  final int durationSec;
  final String instruction;

  ReliefStepModel({
    required this.type,
    required this.title,
    required this.durationSec,
    required this.instruction,
  });
}

class ReliefPackageModel {
  final String mood;
  final String title;
  final int points;
  final List<ReliefStepModel> steps;

  ReliefPackageModel({
    required this.mood,
    required this.title,
    required this.points,
    required this.steps,
  });

  factory ReliefPackageModel.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List<dynamic>).map((e) => ReliefStepModel(
      type: e['type']?.toString() ?? 'step',
      title: e['title']?.toString() ?? 'Step',
      durationSec: (e['durationSec'] as num?)?.toInt() ?? 60,
      instruction: e['instruction']?.toString() ?? '',
    )).toList();
    return ReliefPackageModel(
      mood: json['mood']?.toString() ?? 'other',
      title: json['title']?.toString() ?? 'Relief Session',
      points: (json['points'] as num?)?.toInt() ?? 20,
      steps: steps,
    );
  }
}

class StoryRecord {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? mood;

  StoryRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.mood,
  });
}
