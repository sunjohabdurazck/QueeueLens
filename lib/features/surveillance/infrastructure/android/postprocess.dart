import 'dart:math';
import '../../domain/person_detection.dart';

class Detection {
  final String label;
  final double confidence;
  final double left;
  final double top;
  final double right;
  final double bottom;

  Detection({
    required this.label,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
}

List<PersonDetection> postprocessDetections(
  List<List<double>> boxes,
  List<List<double>> scores,
  List<String> labels, {
  double confidenceThreshold = 0.4,
  double iouThreshold = 0.5,
  int maxDetections = 10,
}) {
  final detections = <Detection>[];

  // SSD MobileNet output format: [num_detections, 4] for boxes, [num_detections, num_classes] for scores
  for (int i = 0; i < boxes.length; i++) {
    final classScores = scores[i];

    // Find best class
    double maxScore = 0;
    int bestClass = -1;
    for (int j = 1; j < classScores.length; j++) {
      // Skip background class (index 0)
      if (classScores[j] > maxScore) {
        maxScore = classScores[j];
        bestClass = j;
      }
    }

    if (maxScore >= confidenceThreshold && bestClass < labels.length) {
      detections.add(
        Detection(
          label: labels[bestClass],
          confidence: maxScore,
          left: boxes[i][1],
          top: boxes[i][0],
          right: boxes[i][3],
          bottom: boxes[i][2],
        ),
      );
    }
  }

  // Apply NMS
  detections.sort((a, b) => b.confidence.compareTo(a.confidence));
  final selected = <Detection>[];

  for (final det in detections) {
    if (selected.length >= maxDetections) break;

    bool keep = true;
    for (final sel in selected) {
      if (computeIoU(det, sel) > iouThreshold) {
        keep = false;
        break;
      }
    }

    if (keep) {
      selected.add(det);
    }
  }

  // Convert to PersonDetection
  return selected
      .map(
        (d) => PersonDetection(
          label: d.label,
          confidence: d.confidence,
          boundingBox: Rect(
            left: d.left,
            top: d.top,
            right: d.right,
            bottom: d.bottom,
          ),
        ),
      )
      .toList();
}

double computeIoU(Detection a, Detection b) {
  final x1 = max(a.left, b.left);
  final y1 = max(a.top, b.top);
  final x2 = min(a.right, b.right);
  final y2 = min(a.bottom, b.bottom);

  final intersection = max(0.0, x2 - x1) * max(0.0, y2 - y1);
  final areaA = (a.right - a.left) * (a.bottom - a.top);
  final areaB = (b.right - b.left) * (b.bottom - b.top);
  final union = areaA + areaB - intersection;

  return union > 0 ? intersection / union : 0;
}
