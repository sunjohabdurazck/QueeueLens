import 'package:equatable/equatable.dart';

class PersonDetection extends Equatable {
  final String label;
  final double confidence;
  final Rect boundingBox;

  const PersonDetection({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  @override
  List<Object?> get props => [label, confidence, boundingBox];
}

class Rect extends Equatable {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;

  @override
  List<Object?> get props => [left, top, right, bottom];
}
