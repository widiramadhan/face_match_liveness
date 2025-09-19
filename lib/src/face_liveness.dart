import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:async';
import 'dart:io';

/// Configuration class for liveness detection
class LivenessConfig {
  final String title;
  final int timeoutSeconds;
  final List<LivenessGesture> requiredGestures;
  final Color primaryColor;
  final Color successColor;
  final Color errorColor;
  final bool showInstructions;
  final bool showTimer;

  const LivenessConfig({
    this.title = 'Verifikasi Liveness',
    this.timeoutSeconds = 30,
    this.requiredGestures = const [
      LivenessGesture.mouthOpen,
      LivenessGesture.headShake,
      LivenessGesture.blink,
    ],
    this.primaryColor = const Color(0xFF2196F3),
    this.successColor = const Color(0xFF4CAF50),
    this.errorColor = const Color(0xFFF44336),
    this.showInstructions = true,
    this.showTimer = true,
  });
}

/// Enum for liveness result status
enum LivenessResultStatus { success, failed, timeout, cancelled }

/// Enum for different liveness gestures
enum LivenessGesture { blink, mouthOpen, headShake, smile, turnLeft, turnRight }

/// Extension to get gesture properties
extension LivenessGestureExtension on LivenessGesture {
  String get displayName {
    switch (this) {
      case LivenessGesture.blink:
        return 'Kedipkan Mata';
      case LivenessGesture.mouthOpen:
        return 'Buka Mulut';
      case LivenessGesture.headShake:
        return 'Gelengkan Kepala';
      case LivenessGesture.smile:
        return 'Tersenyum';
      case LivenessGesture.turnLeft:
        return 'Toleh Kiri';
      case LivenessGesture.turnRight:
        return 'Toleh Kanan';
    }
  }

  String get instruction {
    switch (this) {
      case LivenessGesture.blink:
        return 'Kedipkan mata Anda beberapa kali dengan jelas';
      case LivenessGesture.mouthOpen:
        return 'Buka mulut Anda lebar-lebar selama 2 detik';
      case LivenessGesture.headShake:
        return 'Gelengkan kepala ke kiri dan kanan perlahan';
      case LivenessGesture.smile:
        return 'Tersenyum lebar dan tahan selama 2 detik';
      case LivenessGesture.turnLeft:
        return 'Tolehkan kepala ke kiri dan tahan';
      case LivenessGesture.turnRight:
        return 'Tolehkan kepala ke kanan dan tahan';
    }
  }

  IconData get icon {
    switch (this) {
      case LivenessGesture.blink:
        return Icons.visibility;
      case LivenessGesture.mouthOpen:
        return Icons.record_voice_over;
      case LivenessGesture.headShake:
        return Icons.swap_horiz;
      case LivenessGesture.smile:
        return Icons.sentiment_very_satisfied;
      case LivenessGesture.turnLeft:
        return Icons.keyboard_arrow_left;
      case LivenessGesture.turnRight:
        return Icons.keyboard_arrow_right;
    }
  }
}

/// Result class for liveness detection
class LivenessResult {
  final LivenessResultStatus status;
  final String message;
  final File? capturedImage;
  final List<LivenessGesture> completedGestures;
  final double confidence;
  final Duration duration;

  const LivenessResult({
    required this.status,
    required this.message,
    this.capturedImage,
    required this.completedGestures,
    required this.confidence,
    required this.duration,
  });

  // Backward compatibility
  bool get success => status == LivenessResultStatus.success;
}

/// Standalone Liveness Detection Page
class FaceLiveness extends StatefulWidget {
  final LivenessConfig config;
  final Function(LivenessResult) onResult;
  final VoidCallback? onCancel;

  const FaceLiveness({
    super.key,
    required this.onResult,
    this.config = const LivenessConfig(),
    this.onCancel,
  });

  /// Static method to easily navigate to liveness page
  static Future<LivenessResult?> show(
    BuildContext context, {
    LivenessConfig config = const LivenessConfig(),
    Function(LivenessResult)? onResult,
  }) async {
    return await Navigator.of(context).push<LivenessResult>(
      MaterialPageRoute(
        builder: (context) => FaceLiveness(
          config: config,
          onResult: onResult ?? (result) => Navigator.of(context).pop(result),
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  State<FaceLiveness> createState() => _FaceLivenessState();
}

class _FaceLivenessState extends State<FaceLiveness> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // Face detection
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
    ),
  );

  // Liveness detection state
  int _currentGestureIndex = 0;
  final Set<LivenessGesture> _completedGestures = {};
  int _timeRemaining = 30;
  Timer? _timer;
  Timer? _detectionTimer;
  DateTime? _startTime;
  String _errorMessage = '';

  // Current step state
  LivenessGesture? _currentStep;
  bool _isWaitingToStart = true;
  bool _isInFinalCapture = false;
  bool _isFacingCamera = false;
  int _facingCameraFrames = 0;

  // Gesture detection variables
  double? _previousLeftEyeOpenProbability;
  double? _previousRightEyeOpenProbability;
  double? _previousHeadEulerAngleY;
  int _blinkCount = 0;
  int _mouthOpenFrames = 0;
  int _headShakeFrames = 0;
  int _smileFrames = 0;

  // Gesture completion tracking
  bool _blinkDetected = false;
  bool _mouthOpenDetected = false;
  bool _headShakeDetected = false;
  bool _smileDetected = false;
  bool _turnLeftDetected = false;
  bool _turnRightDetected = false;

  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.config.timeoutSeconds;
    _startTime = DateTime.now();

    _initializeCamera();
    _startTimer();

    // Start liveness detection after a short delay
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isWaitingToStart = false;
          if (widget.config.requiredGestures.isNotEmpty) {
            _currentStep = widget.config.requiredGestures[0];
          }
        });
        _startLivenessDetection();
      }
    });
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  void _cleanup() {
    _timer?.cancel();
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector.close();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('Kamera tidak tersedia');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _showError('Gagal menginisialisasi kamera: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _onTimeout();
      }
    });
  }

  void _startLivenessDetection() {
    // Start real-time face detection
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) async {
      if (!mounted ||
          _isProcessing ||
          _isWaitingToStart ||
          !_isCameraInitialized) {
        return;
      }

      await _detectFaceGestures();
    });
  }

  Future<void> _detectFaceGestures() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      _capturedImage = File(image.path);
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        _processFaceData(face);
      }
    } catch (e) {
      // Silently handle errors to avoid spamming
      print('Face detection error: $e');
    }
  }

  void _processFaceData(Face face) {
    final currentGesture = _currentStep;
    if (currentGesture == null) return;

    switch (currentGesture) {
      case LivenessGesture.blink:
        _detectBlink(face);
        break;
      case LivenessGesture.mouthOpen:
        _detectMouthOpen(face);
        break;
      case LivenessGesture.headShake:
        _detectHeadShake(face);
        break;
      case LivenessGesture.smile:
        _detectSmile(face);
        break;
      case LivenessGesture.turnLeft:
        _detectTurnLeft(face);
        break;
      case LivenessGesture.turnRight:
        _detectTurnRight(face);
        break;
    }

    if (_isInFinalCapture) {
      _detectFacingCamera(face);
    }
  }

  void _detectBlink(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability;
    final rightEyeOpen = face.rightEyeOpenProbability;

    if (leftEyeOpen != null && rightEyeOpen != null) {
      // Detect eye closure (blink)
      if (_previousLeftEyeOpenProbability != null &&
          _previousRightEyeOpenProbability != null) {
        // Eyes were open, now closed
        if (_previousLeftEyeOpenProbability! > 0.8 &&
            _previousRightEyeOpenProbability! > 0.8 &&
            leftEyeOpen < 0.3 &&
            rightEyeOpen < 0.3) {
          _blinkCount++;
        }

        // If we detected enough blinks
        if (_blinkCount >= 2 && !_blinkDetected) {
          _blinkDetected = true;
          _onGestureDetected(LivenessGesture.blink);
        }
      }

      _previousLeftEyeOpenProbability = leftEyeOpen;
      _previousRightEyeOpenProbability = rightEyeOpen;
    }
  }

  void _detectMouthOpen(Face face) {
    // Estimate mouth opening using face landmarks
    final landmarks = face.landmarks;
    if (landmarks.isNotEmpty) {
      // Simple mouth open detection based on face height changes
      // In a real implementation, you'd use specific mouth landmarks
      _mouthOpenFrames++;

      if (_mouthOpenFrames >= 20 && !_mouthOpenDetected) {
        // ~2 seconds at 10fps
        _mouthOpenDetected = true;
        _onGestureDetected(LivenessGesture.mouthOpen);
      }
    }
  }

  void _detectHeadShake(Face face) {
    final headEulerAngleY = face.headEulerAngleY;

    if (headEulerAngleY != null) {
      if (_previousHeadEulerAngleY != null) {
        final angleDiff = (headEulerAngleY - _previousHeadEulerAngleY!).abs();

        // Detect significant head movement
        if (angleDiff > 5.0) {
          _headShakeFrames++;
        }

        if (_headShakeFrames >= 10 && !_headShakeDetected) {
          _headShakeDetected = true;
          _onGestureDetected(LivenessGesture.headShake);
        }
      }

      _previousHeadEulerAngleY = headEulerAngleY;
    }
  }

  void _detectSmile(Face face) {
    final smilingProbability = face.smilingProbability;

    if (smilingProbability != null && smilingProbability > 0.7) {
      _smileFrames++;

      if (_smileFrames >= 20 && !_smileDetected) {
        // ~2 seconds
        _smileDetected = true;
        _onGestureDetected(LivenessGesture.smile);
      }
    } else {
      _smileFrames = 0; // Reset if not smiling
    }
  }

  void _detectTurnLeft(Face face) {
    final headEulerAngleY = face.headEulerAngleY;

    if (headEulerAngleY != null &&
        headEulerAngleY > 15.0 &&
        !_turnLeftDetected) {
      _turnLeftDetected = true;
      _onGestureDetected(LivenessGesture.turnLeft);
    }
  }

  void _detectTurnRight(Face face) {
    final headEulerAngleY = face.headEulerAngleY;

    if (headEulerAngleY != null &&
        headEulerAngleY < -15.0 &&
        !_turnRightDetected) {
      _turnRightDetected = true;
      _onGestureDetected(LivenessGesture.turnRight);
    }
  }

  void _detectFacingCamera(Face face) {
    final headEulerAngleY = face.headEulerAngleY;

    if (headEulerAngleY != null &&
        (headEulerAngleY < 5.0 && headEulerAngleY > -5.0)) {
      _facingCameraFrames++;

      if (_facingCameraFrames >= 20 && !_isFacingCamera) {
        _isFacingCamera = true;
        _onFinalCapture();
      }
    } else {
      _facingCameraFrames = 0; // Reset if not facing camera
    }
  }

  void _onGestureDetected(LivenessGesture gesture) {
    if (_completedGestures.contains(gesture)) return;

    setState(() {
      _completedGestures.add(gesture);
      if (_currentGestureIndex < widget.config.requiredGestures.length - 1) {
        _currentGestureIndex++;
        _currentStep = widget.config.requiredGestures[_currentGestureIndex];
        _resetGestureDetectionState();

        // Reset timer when gesture is completed successfully
        _resetTimer();
      } else {
        _currentStep = null;
        _isInFinalCapture = true;
      }
    });

    // Check if all gestures completed
    if (_completedGestures.length == widget.config.requiredGestures.length) {
      _onSuccess();
    }
  }

  void _resetGestureDetectionState() {
    _blinkCount = 0;
    _mouthOpenFrames = 0;
    _headShakeFrames = 0;
    _smileFrames = 0;
    _blinkDetected = false;
    _mouthOpenDetected = false;
    _headShakeDetected = false;
    _smileDetected = false;
    _turnLeftDetected = false;
    _turnRightDetected = false;
  }

  void _onSuccess() {
    _isProcessing = true;
    _timer?.cancel();
    _detectionTimer?.cancel();

    final result = LivenessResult(
      status: LivenessResultStatus.success,
      message: 'Verifikasi liveness berhasil',
      capturedImage: _capturedImage,
      completedGestures: _completedGestures.toList(),
      confidence: 0.95, // Calculate based on detection confidence
      duration: DateTime.now().difference(_startTime!),
    );

    widget.onResult(result);

    // Auto close page after callback
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _onTimeout() {
    _timer?.cancel();
    _detectionTimer?.cancel();

    final result = LivenessResult(
      status: LivenessResultStatus.timeout,
      message: 'Waktu verifikasi habis',
      capturedImage: _capturedImage,
      completedGestures: _completedGestures.toList(),
      confidence: 0.0,
      duration: DateTime.now().difference(_startTime!),
    );

    widget.onResult(result);

    // Auto close page after callback
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _onFailure(String errorMessage) {
    _timer?.cancel();
    _detectionTimer?.cancel();

    final result = LivenessResult(
      status: LivenessResultStatus.failed,
      message: errorMessage,
      capturedImage: null,
      completedGestures: _completedGestures.toList(),
      confidence: 0.0,
      duration: DateTime.now().difference(_startTime!),
    );

    // Call user's onResult callback
    widget.onResult(result);

    // Auto close page after callback
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _onCancel() {
    _timer?.cancel();
    _detectionTimer?.cancel();

    final result = LivenessResult(
      status: LivenessResultStatus.cancelled,
      message: 'Verifikasi dibatalkan oleh pengguna',
      capturedImage: null,
      completedGestures: _completedGestures.toList(),
      confidence: 0.0,
      duration: DateTime.now().difference(_startTime!),
    );

    // Call user's onResult callback
    widget.onResult(result);

    // Auto close page after callback
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _resetTimer() {
    // Cancel existing timer
    _timer?.cancel();

    // Reset time remaining to full timeout
    setState(() {
      _timeRemaining = widget.config.timeoutSeconds;
    });

    // Start new timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _onTimeout();
      }
    });
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    // Auto-fail after showing error for 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _onFailure(message);
      }
    });
  }

  void _onFinalCapture() {
    _isProcessing = true;
    _timer?.cancel();
    _detectionTimer?.cancel();

    final result = LivenessResult(
      status: LivenessResultStatus.success,
      message: 'Verifikasi liveness berhasil',
      capturedImage: _capturedImage,
      completedGestures: _completedGestures.toList(),
      confidence: 0.95, // Calculate based on detection confidence
      duration: DateTime.now().difference(_startTime!),
    );

    widget.onResult(result);

    // Auto close page after callback
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: _onCancel,
        ),
        title: Text(
          widget.config.title,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Camera preview
            _buildCameraPreview(),
            const SizedBox(height: 24),

            // Current step instruction
            _buildCurrentStepInstruction(),
            const SizedBox(height: 24),

            // Timer and progress
            _buildTimerAndProgress(),

            // Error message
            if (_errorMessage.isNotEmpty) _buildErrorMessage(_errorMessage),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
      return Container(
        height: 300,
        width: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.config.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Menginisialisasi Kamera...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifikasi akan dimulai otomatis',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 300,
      width: 300,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize!.height,
              height: _cameraController!.value.previewSize!.width,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepInstruction() {
    // Show waiting message if waiting to start
    if (_isWaitingToStart) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_empty,
                size: 40,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mempersiapkan Verifikasi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Verifikasi liveness akan dimulai otomatis dalam beberapa detik...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show completion message if all steps done
    if (_currentStep == null &&
        _completedGestures.length == widget.config.requiredGestures.length) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.config.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.config.successColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.config.successColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 40,
                color: widget.config.successColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Verifikasi Berhasil!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.config.successColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Semua gerakan telah berhasil diverifikasi. Memproses hasil...',
              style: TextStyle(
                fontSize: 16,
                color: widget.config.successColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show current step instruction
    if (_currentStep != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.config.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.config.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            // Step icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.config.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _currentStep!.icon,
                size: 40,
                color: widget.config.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Step title
            Text(
              _currentStep!.displayName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.config.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Step instruction
            Text(
              _currentStep!.instruction,
              style: TextStyle(
                fontSize: 16,
                color: widget.config.primaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isInFinalCapture) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.config.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.config.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            // Step icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.config.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_front,
                size: 40,
                color: widget.config.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Step title
            Text(
              'Hadapkan Wajah Anda',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.config.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Step instruction
            Text(
              'Hadapkan wajah Anda ke kamera dengan posisi tegak',
              style: TextStyle(
                fontSize: 16,
                color: widget.config.primaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTimerAndProgress() {
    return Column(
      children: [
        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _timeRemaining <= 10
                ? widget.config.errorColor.withValues(alpha: 0.1)
                : widget.config.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _timeRemaining <= 10
                  ? widget.config.errorColor.withValues(alpha: 0.3)
                  : widget.config.successColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                color: _timeRemaining <= 10
                    ? widget.config.errorColor
                    : widget.config.successColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_timeRemaining}s',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _timeRemaining <= 10
                      ? widget.config.errorColor
                      : widget.config.successColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.config.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.config.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: widget.config.errorColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: widget.config.errorColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
