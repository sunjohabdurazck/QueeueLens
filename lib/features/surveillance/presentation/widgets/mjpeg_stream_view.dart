import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class MjpegStreamView extends StatefulWidget {
  final String streamUrl;
  final Duration timeout;
  final bool autoReconnect;
  final Duration reconnectDelay;
  final Function(Uint8List)? onFrame; // Add this callback

  const MjpegStreamView({
    super.key,
    required this.streamUrl,
    this.timeout = const Duration(seconds: 10),
    this.autoReconnect = true,
    this.reconnectDelay = const Duration(seconds: 3),
    this.onFrame, // Add this
  });

  @override
  State<MjpegStreamView> createState() => _MjpegStreamViewState();
}

class _MjpegStreamViewState extends State<MjpegStreamView> {
  late http.StreamedResponse _response;
  late StreamController<Uint8List> _imageStreamController;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    _imageStreamController = StreamController<Uint8List>();

    // Listen to the stream controller and forward frames to the callback
    _imageStreamController.stream.listen((frame) {
      if (widget.onFrame != null) {
        widget.onFrame!(frame);
      }
    });

    try {
      final request = http.Request('GET', Uri.parse(widget.streamUrl));
      final client = http.Client();

      _response = await client.send(request).timeout(widget.timeout);

      if (_response.statusCode == 200) {
        setState(() {
          _isConnected = true;
          _isLoading = false;
          _errorMessage = null;
        });

        _subscription = _response.stream.listen(
          _processChunk,
          onError: _handleError,
          onDone: _handleDone,
        );
      } else {
        throw Exception('HTTP ${_response.statusCode}');
      }
    } catch (e) {
      _handleError(e);
    }
  }

  // MJPEG boundary detection
  final List<int> _buffer = [];
  static const List<int> _jpegStart = [0xFF, 0xD8];
  static const List<int> _jpegEnd = [0xFF, 0xD9];

  void _processChunk(List<int> chunk) {
    _buffer.addAll(chunk);

    // Find JPEG frames in the buffer
    while (_buffer.length > 2) {
      final startIndex = _findSequence(_buffer, _jpegStart);
      if (startIndex == -1) break;

      final searchFrom = startIndex + 2;
      if (searchFrom >= _buffer.length) break;

      final endIndex = _findSequence(_buffer.sublist(searchFrom), _jpegEnd);
      if (endIndex == -1) break;

      final absoluteEndIndex = searchFrom + endIndex + 1;

      if (absoluteEndIndex <= _buffer.length) {
        final frame = _buffer.sublist(startIndex, absoluteEndIndex + 1);
        final frameBytes = Uint8List.fromList(frame);

        // Add frame to stream
        _imageStreamController.add(frameBytes);

        _buffer.removeRange(0, absoluteEndIndex + 1);
      }
    }
  }

  int _findSequence(List<int> buffer, List<int> sequence) {
    for (int i = 0; i < buffer.length - sequence.length + 1; i++) {
      bool match = true;
      for (int j = 0; j < sequence.length; j++) {
        if (buffer[i + j] != sequence[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  void _handleError(Object error) {
    setState(() {
      _isConnected = false;
      _isLoading = false;
      _errorMessage = error.toString();
    });

    _imageStreamController.addError(error);
    _subscription?.cancel();

    if (widget.autoReconnect) {
      _scheduleReconnect();
    }
  }

  void _handleDone() {
    setState(() {
      _isConnected = false;
      _isLoading = false;
    });

    _imageStreamController.close();

    if (widget.autoReconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(widget.reconnectDelay, _initializeStream);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _reconnectTimer?.cancel();
    _imageStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 8),
            Text(
              'Connecting to camera...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 8),
            Text(
              'Camera connection failed',
              style: TextStyle(color: Colors.red.shade300),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (widget.autoReconnect) ...[
              const SizedBox(height: 16),
              const Text(
                'Reconnecting...',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ],
        ),
      );
    }

    return StreamBuilder<Uint8List>(
      stream: _imageStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Stream error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              'Waiting for stream...',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Image.memory(
          snapshot.data!,
          gaplessPlayback: true,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'Failed to decode frame',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        );
      },
    );
  }
}
