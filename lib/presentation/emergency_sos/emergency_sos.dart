import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/countdown_timer.dart';
import './widgets/emergency_contacts_list.dart';
import './widgets/emergency_type_selector.dart';
import './widgets/location_sharing_toggle.dart';
import './widgets/network_status_indicator.dart';
import './widgets/sos_button.dart';
import './widgets/voice_activation_indicator.dart';

class EmergencySos extends StatefulWidget {
  const EmergencySos({super.key});

  @override
  State<EmergencySos> createState() => _EmergencySosState();
}

class _EmergencySosState extends State<EmergencySos>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundAnimation;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isListening = false;
  bool _showCountdown = false;
  bool _showTypeSelector = false;
  bool _locationSharingEnabled = true;
  final bool _isNetworkConnected = true;
  String _selectedEmergencyType = '';

  // Mock data
  final List<Map<String, dynamic>> _emergencyContacts = [
    {
      "id": 1,
      "name": "Priya Sharma",
      "relationship": "Family",
      "phone": "+91 98765 43210",
      "avatar": "https://images.unsplash.com/photo-1617593461584-4d51cc5cff4c",
      "semanticLabel":
          "Portrait of an elderly Indian woman with gray hair wearing a traditional saree, smiling warmly at the camera",
      "isVerified": true,
    },
    {
      "id": 2,
      "name": "Dr. Rajesh Kumar",
      "relationship": "Doctor",
      "phone": "+91 98765 43211",
      "avatar": "https://images.unsplash.com/photo-1666886573583-9839aafe43cf",
      "semanticLabel":
          "Professional headshot of a middle-aged Indian doctor in white coat with stethoscope around neck",
      "isVerified": true,
    },
    {
      "id": 3,
      "name": "Amit Patel",
      "relationship": "Neighbor",
      "phone": "+91 98765 43212",
      "avatar": "https://images.unsplash.com/photo-1715031841460-e979ebd28597",
      "semanticLabel":
          "Friendly portrait of a young Indian man with short black hair wearing a blue shirt, standing outdoors",
      "isVerified": false,
    },
    {
      "id": 4,
      "name": "Sunita Devi",
      "relationship": "Friend",
      "phone": "+91 98765 43213",
      "avatar": null,
      "semanticLabel": "",
      "isVerified": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestPermissions();
    _startVoiceListening();

    // Keep screen active and at maximum brightness
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _backgroundAnimation = ColorTween(
      begin: AppTheme.lightTheme.scaffoldBackgroundColor,
      end: AppTheme.emergencyLight,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.location.request();
  }

  Future<void> _startVoiceListening() async {
    if (await _audioRecorder.hasPermission()) {
      setState(() {
        _isListening = true;
      });

      try {
        await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.wav,
            ),
            path: 'emergency_recording.wav');

        // Simulate voice command detection after 3 seconds for demo
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isListening) {
            _onVoiceCommandDetected();
          }
        });
      } catch (e) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  void _onVoiceCommandDetected() {
    HapticFeedback.heavyImpact();
    _activateEmergency(bypassCountdown: true);
  }

  void _onSosButtonPressed() {
    HapticFeedback.heavyImpact();
    _activateEmergency(bypassCountdown: false);
  }

  void _activateEmergency({required bool bypassCountdown}) {
    _stopVoiceListening();

    if (bypassCountdown) {
      _proceedToTypeSelection();
    } else {
      setState(() {
        _showCountdown = true;
      });
      _backgroundController.forward();
    }
  }

  void _onCountdownComplete() {
    _proceedToTypeSelection();
  }

  void _onCountdownCancel() {
    setState(() {
      _showCountdown = false;
    });
    _backgroundController.reverse();
    _startVoiceListening();
  }

  void _proceedToTypeSelection() {
    setState(() {
      _showCountdown = false;
      _showTypeSelector = true;
    });
  }

  void _onEmergencyTypeSelected(String type) {
    setState(() {
      _selectedEmergencyType = type;
      _showTypeSelector = false;
    });

    // Navigate to neighbor response tracking
    Navigator.pushReplacementNamed(context, '/neighbor-response-tracking');
  }

  void _onTypeSelectorCancel() {
    setState(() {
      _showTypeSelector = false;
    });
    _backgroundController.reverse();
    _startVoiceListening();
  }

  void _stopVoiceListening() async {
    if (_isListening) {
      await _audioRecorder.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  void _onMicrophonePressed() {
    if (_isListening) {
      _stopVoiceListening();
    } else {
      _startVoiceListening();
    }
  }

  void _onLocationToggle(bool enabled) {
    setState(() {
      _locationSharingEnabled = enabled;
    });
    HapticFeedback.lightImpact();
  }

  void _onContactCall(Map<String, dynamic> contact) {
    HapticFeedback.heavyImpact();
    // Simulate calling contact
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${contact['name']}...'),
        backgroundColor: AppTheme.emergencyLight,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_showCountdown || _showTypeSelector) {
      // Show confirmation dialog for emergency situations
      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(
                'Cancel Emergency?',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                'Are you sure you want to cancel the emergency activation?',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Stay'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emergencyLight,
                  ),
                  child: Text('Cancel Emergency'),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _audioRecorder.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Scaffold(
            backgroundColor: _backgroundAnimation.value,
            body: Stack(
              children: [
                // Main content
                if (!_showCountdown) _buildMainContent(),

                // Countdown overlay
                if (_showCountdown)
                  CountdownTimer(
                    onCountdownComplete: _onCountdownComplete,
                    onCancel: _onCountdownCancel,
                  ),

                // Emergency type selector
                if (_showTypeSelector)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: EmergencyTypeSelector(
                          onTypeSelected: _onEmergencyTypeSelected,
                          onCancel: _onTypeSelectorCancel,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: CustomIconWidget(
                      iconName: 'arrow_back_ios',
                      color: colorScheme.onSurface,
                      size: 6.w,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Emergency SOS',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 12.w), // Balance the back button
                ],
              ),
            ),
            SizedBox(height: 4.h),

            // Network status
            NetworkStatusIndicator(
              isConnected: _isNetworkConnected,
              connectionType: '4G',
              signalStrength: 3,
            ),
            SizedBox(height: 4.h),

            // Main SOS button
            SosButton(
              onPressed: _onSosButtonPressed,
              isActive: !_showCountdown && !_showTypeSelector,
            ),
            SizedBox(height: 4.h),

            // Voice activation
            VoiceActivationIndicator(
              isListening: _isListening,
              onMicrophonePressed: _onMicrophonePressed,
            ),
            SizedBox(height: 6.h),

            // Location sharing toggle
            LocationSharingToggle(
              isEnabled: _locationSharingEnabled,
              onToggle: _onLocationToggle,
              currentAddress: 'Sector 15, Dwarka, New Delhi, 110075',
              gpsAccuracy: 'Accurate to 5m',
            ),
            SizedBox(height: 4.h),

            // Emergency contacts
            EmergencyContactsList(
              contacts: _emergencyContacts,
              onContactCall: _onContactCall,
            ),
            SizedBox(height: 4.h),

            // Emergency info
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryLight.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'info_outline',
                        color: AppTheme.primaryLight,
                        size: 5.w,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'Emergency Help Information',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'When you activate SOS, nearby neighbors will be notified and can provide immediate assistance. Your location will be shared with trusted contacts and emergency responders.',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
