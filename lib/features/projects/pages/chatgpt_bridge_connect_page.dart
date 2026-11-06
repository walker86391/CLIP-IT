import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/chatgpt_bridge_service.dart';

/// Screen allowing the user to connect ClipIt to their browser-based ChatGPT extension.
///
/// Workflow Position:
/// Home -> Video Selected -> Next -> [ChatGptBridgeConnectPage] -> Continue -> [GenreSelectionPage]
class ChatGptBridgeConnectPage extends ConsumerStatefulWidget {
  const ChatGptBridgeConnectPage({
    this.onContinue,
    this.onBack,
    super.key,
  });

  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  @override
  ConsumerState<ChatGptBridgeConnectPage> createState() =>
      _ChatGptBridgeConnectPageState();
}

class _ChatGptBridgeConnectPageState
    extends ConsumerState<ChatGptBridgeConnectPage> {
  final ScrollController _responseScrollController = ScrollController();
  bool _hasSentTest = false;
  bool _isHoveringConnect = false;
  bool _isPressingConnect = false;
  bool _isHoveringSend = false;
  bool _isPressingSend = false;
  bool _isHoveringCopy = false;
  bool _isPressingCopy = false;
  bool _isHoveringBack = false;
  bool _isPressingBack = false;
  bool _isHoveringContinue = false;
  bool _isPressingContinue = false;
  bool _copiedToClipboard = false;
  Timer? _copiedFeedbackTimer;

  @override
  void dispose() {
    _responseScrollController.dispose();
    _copiedFeedbackTimer?.cancel();
    super.dispose();
  }

  void _handleConnectPress(ChatGptBridgeState bridgeState) {
    if (bridgeState.isConnected) return;
    ref.read(chatGptBridgeProvider.notifier).startConnection();
  }

  void _handleSendTestPress() {
    final state = ref.read(chatGptBridgeProvider);
    if (state.isSending) return;
    setState(() => _hasSentTest = true);
    ref.read(chatGptBridgeProvider.notifier).sendPrompt('hi there');
  }

  void _showCopiedFeedback() {
    _copiedFeedbackTimer?.cancel();
    setState(() => _copiedToClipboard = true);
    _copiedFeedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copiedToClipboard = false);
    });
  }

  void _copyResponseToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showCopiedFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final bridgeState = ref.watch(chatGptBridgeProvider);

    // Auto-copy response to clipboard when new response arrives
    ref.listen<ChatGptBridgeState>(chatGptBridgeProvider, (previous, next) {
      if (next.lastResponse != null &&
          next.lastResponse!.isNotEmpty &&
          next.lastResponse != previous?.lastResponse) {
        Clipboard.setData(ClipboardData(text: next.lastResponse!));
        _showCopiedFeedback();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: SafeArea(
        child: Stack(
          children: [
            // Main scrollable content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header step tag & back button
                      Row(
                        children: [
                          if (widget.onBack != null) ...[
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) => setState(() => _isHoveringBack = true),
                              onExit: (_) => setState(() => _isHoveringBack = false),
                              child: GestureDetector(
                                onTapDown: (_) => setState(() => _isPressingBack = true),
                                onTapUp: (_) => setState(() => _isPressingBack = false),
                                onTapCancel: () => setState(() => _isPressingBack = false),
                                onTap: widget.onBack,
                                child: AnimatedScale(
                                  scale: _isPressingBack
                                      ? 0.92
                                      : (_isHoveringBack ? 1.08 : 1.0),
                                  duration: const Duration(milliseconds: 120),
                                  curve: Curves.easeOutCubic,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _isHoveringBack
                                          ? const Color(0xFF222438)
                                          : const Color(0xFF161726),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _isHoveringBack
                                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                                            : const Color(0xFF262838),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 16,
                                      color: Color(0xFF9EA1B5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1D33),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.extension_rounded,
                                  size: 13,
                                  color: Color(0xFFA78BFA),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'AI BROWSER BRIDGE',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: Color(0xFFDDD6FE),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Main Title
                      const Text(
                        'Connect to your AI chatbot',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      const Text(
                        'Connect ClipIt to your browser-based AI chatbot to enable automated AI processing.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF8E92A6),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Primary Connection Control Card
                      _buildConnectionControlCard(bridgeState),

                      const SizedBox(height: 20),

                      // How To Connect Card
                      _buildHowToConnectCard(),

                      // Test Chat Box Section (Only visible after connection)
                      if (bridgeState.isConnected) ...[
                        const SizedBox(height: 24),
                        _buildTestChatBoxSection(bridgeState),
                      ],

                      // Bottom spacing so content doesn't collide with continue button
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Bottom Bar with Continue Button
            Positioned(
              bottom: 24,
              right: 40,
              child: _buildContinueButton(bridgeState),
            ),
          ],
        ),
      ),
    );
  }

  /// The main connection card with the Connect / Connecting / Connected / Retry button.
  Widget _buildConnectionControlCard(ChatGptBridgeState bridgeState) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF141522),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bridgeState.isConnected
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : bridgeState.isConnecting
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                  : const Color(0xFF222434),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: bridgeState.isConnected
                ? const Color(0x1F10B981)
                : const Color(0x1A000000),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status Indicator Dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bridgeState.isConnected
                      ? const Color(0xFF10B981)
                      : bridgeState.isConnecting
                          ? const Color(0xFFFBBF24)
                          : bridgeState.isTimeout
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF6B7280),
                  boxShadow: bridgeState.isConnected || bridgeState.isConnecting
                      ? [
                          BoxShadow(
                            color: (bridgeState.isConnected
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFFBBF24))
                                .withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                bridgeState.isConnected
                    ? 'Connected to Chrome Extension'
                    : bridgeState.isConnecting
                        ? 'Connecting to browser (${bridgeState.timeoutRemainingSeconds}s remaining)...'
                        : bridgeState.isTimeout
                            ? 'Connection Timed Out'
                            : 'Bridge Disconnected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: bridgeState.isConnected
                      ? const Color(0xFF34D399)
                      : bridgeState.isConnecting
                          ? const Color(0xFFFDE68A)
                          : bridgeState.isTimeout
                              ? const Color(0xFFF87171)
                              : const Color(0xFF9CA3AF),
                ),
              ),
              const Spacer(),
              if (bridgeState.isConnected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFA78BFA)),
                      const SizedBox(width: 4),
                      Text(
                        bridgeState.effectivePlatform,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDDD6FE),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (bridgeState.connectedUrl != null)
                Text(
                  bridgeState.connectedUrl!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Action Button (Connect / Connecting... / Connected / Retry)
          _buildActionButton(bridgeState),

          if (bridgeState.lastError != null && !bridgeState.isConnected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C151B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Color(0xFFF87171),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bridgeState.lastError!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFFCA5A5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The dynamic button matching ClipIt's design tokens.
  Widget _buildActionButton(ChatGptBridgeState bridgeState) {
    if (bridgeState.isConnected) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF34D399)),
            SizedBox(width: 8),
            Text(
              'Connected',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF34D399),
              ),
            ),
          ],
        ),
      );
    }

    if (bridgeState.isConnecting) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF261D42),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA78BFA)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Connecting to browser... (${bridgeState.timeoutRemainingSeconds}s)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDDD6FE),
              ),
            ),
          ],
        ),
      );
    }

    // Connect or Retry button
    final isRetry = bridgeState.isTimeout || bridgeState.connectionStatus == BridgeConnectionStatus.error;
    final label = isRetry ? 'Retry' : 'Connect';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHoveringConnect = true),
      onExit: (_) => setState(() => _isHoveringConnect = false),
      child: GestureDetector(
        key: const Key('chatgpt_bridge_connect_button'),
        onTapDown: (_) => setState(() => _isPressingConnect = true),
        onTapUp: (_) => setState(() => _isPressingConnect = false),
        onTapCancel: () => setState(() => _isPressingConnect = false),
        onTap: () => _handleConnectPress(bridgeState),
        child: AnimatedScale(
          scale: _isPressingConnect
              ? 0.96
              : (_isHoveringConnect ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 26),
            decoration: BoxDecoration(
              color: isRetry
                  ? const Color(0xFFDC2626) // Amber-red for retry
                  : const Color(0xFF8B5CF6), // Royal Purple for Connect
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: (isRetry ? const Color(0xFFDC2626) : const Color(0xFF8B5CF6))
                      .withValues(alpha: _isHoveringConnect ? 0.45 : 0.25),
                  blurRadius: _isHoveringConnect ? 16 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRetry ? Icons.refresh_rounded : Icons.link_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "How to connect" instruction card.
  Widget _buildHowToConnectCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13141F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF222434),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: Color(0xFFA78BFA),
              ),
              SizedBox(width: 8),
              Text(
                'How to connect',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF3F4F8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInstructionStep(
            '1',
            'Press Start in the ClipIt Chrome extension while on ChatGPT, Claude, Gemini, or Arena AI (Direct Chat).',
          ),
          const SizedBox(height: 8),
          _buildInstructionStep('2', 'Return to ClipIt.'),
          const SizedBox(height: 8),
          _buildInstructionStep('3', 'Press Connect here.'),
          const SizedBox(height: 8),
          _buildInstructionStep(
            '4',
            'Wait while ClipIt establishes the local connection bridge.',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String stepNumber, String instruction) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF202234),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF353952),
              width: 0.8,
            ),
          ),
          child: Text(
            stepNumber,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFA78BFA),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            instruction,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFFB0B4C8),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  /// Test Chat Box revealed strictly after bridge connection.
  Widget _buildTestChatBoxSection(ChatGptBridgeState bridgeState) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF141524),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: Color(0xFFA78BFA),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Test browser connection',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Test the end-to-end bridge connection with a single test message before continuing.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7E8299),
            ),
          ),
          const SizedBox(height: 16),

          // Non-editable message display & Send/Retry button row
          Builder(
            builder: (context) {
              final isCompleted = bridgeState.promptStatus == BridgePromptStatus.completed &&
                  bridgeState.lastResponse != null &&
                  bridgeState.lastResponse!.isNotEmpty;
              final isError = bridgeState.promptStatus == BridgePromptStatus.error;
              final isSent = isCompleted ||
                  (_hasSentTest && !isError && !bridgeState.isSending && bridgeState.lastResponse != null);
              final isButtonDisabled = (isCompleted && !isError) || bridgeState.isSending;

              return Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1C2C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF2C2F45),
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 15,
                            color: Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'hi there',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF3F4F8),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF232538),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Test message',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8E92A6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  MouseRegion(
                    cursor: isButtonDisabled
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isHoveringSend = true),
                    onExit: (_) => setState(() => _isHoveringSend = false),
                    child: GestureDetector(
                      key: const Key('chatgpt_test_send_button'),
                      onTapDown: isButtonDisabled
                          ? null
                          : (_) => setState(() => _isPressingSend = true),
                      onTapUp: isButtonDisabled
                          ? null
                          : (_) => setState(() => _isPressingSend = false),
                      onTapCancel: isButtonDisabled
                          ? null
                          : () => setState(() => _isPressingSend = false),
                      onTap: isButtonDisabled ? null : _handleSendTestPress,
                      child: AnimatedScale(
                        scale: isButtonDisabled
                            ? 1.0
                            : (_isPressingSend
                                ? 0.95
                                : (_isHoveringSend ? 1.03 : 1.0)),
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOutCubic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          decoration: BoxDecoration(
                            color: isSent
                                ? const Color(0xFF232536) // Greyed out once sent
                                : bridgeState.isSending
                                    ? const Color(0xFF383254)
                                    : isError
                                        ? const Color(0xFFDC2626) // Red retry
                                        : const Color(0xFF2563EB), // Royal Blue
                            borderRadius: BorderRadius.circular(10),
                            border: isSent
                                ? Border.all(
                                    color: const Color(0xFF35384E),
                                    width: 0.8,
                                  )
                                : null,
                            boxShadow: isButtonDisabled
                                ? null
                                : [
                                    BoxShadow(
                                      color: isError
                                          ? const Color(0x40DC2626)
                                          : const Color(0x402563EB),
                                      blurRadius: _isHoveringSend ? 14 : 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              if (bridgeState.isSending) ...[
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white70,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Sending...',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ] else if (isSent) ...[
                                const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Color(0xFF8E92A6),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Sent',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8E92A6),
                                  ),
                                ),
                              ] else if (isError) ...[
                                const Icon(
                                  Icons.refresh_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Send',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.send_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Error display during prompt execution
          if (bridgeState.promptStatus == BridgePromptStatus.error &&
              bridgeState.lastError != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2C151B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: Color(0xFFF87171),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bridgeState.lastError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFCA5A5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Response display area with rich Copy button and feedback
          if (bridgeState.lastResponse != null || bridgeState.isSending) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFA78BFA)),
                    const SizedBox(width: 6),
                    Text(
                      'Response from ${bridgeState.effectivePlatform}:',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFFA78BFA),
                      ),
                    ),
                    if (bridgeState.lastResponse != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        key: const Key('chatgpt_response_displayed_badge'),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x3310B981),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0x8810B981),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text(
                              'RESPONSE DISPLAYED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (bridgeState.lastResponse != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isHoveringCopy = true),
                    onExit: (_) => setState(() => _isHoveringCopy = false),
                    child: GestureDetector(
                      key: const Key('chatgpt_copy_response_button'),
                      onTapDown: (_) => setState(() => _isPressingCopy = true),
                      onTapUp: (_) => setState(() => _isPressingCopy = false),
                      onTapCancel: () => setState(() => _isPressingCopy = false),
                      onTap: () => _copyResponseToClipboard(bridgeState.lastResponse!),
                      child: AnimatedScale(
                        scale: _isPressingCopy
                            ? 0.94
                            : (_isHoveringCopy ? 1.04 : 1.0),
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _copiedToClipboard
                                ? const Color(0xFF064E3B)
                                : _isHoveringCopy
                                    ? const Color(0xFF33364E)
                                    : const Color(0xFF26283B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _copiedToClipboard
                                  ? const Color(0xFF10B981)
                                  : _isHoveringCopy
                                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                                      : const Color(0xFF3B3E5B),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _copiedToClipboard ? Icons.check_rounded : Icons.copy_rounded,
                                size: 13,
                                color: _copiedToClipboard
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFCBD5E1),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _copiedToClipboard ? 'Copied!' : 'Copy Response',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _copiedToClipboard
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF2C2E42),
                  width: 0.8,
                ),
              ),
              child: bridgeState.isSending
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Waiting for ${bridgeState.effectivePlatform} to generate response in browser...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E92A6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      constraints: const BoxConstraints(
                        minHeight: 120,
                        maxHeight: 420,
                      ),
                      child: RawScrollbar(
                        controller: _responseScrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        thickness: 6,
                        radius: const Radius.circular(3),
                        thumbColor: const Color(0xFF8B5CF6).withValues(alpha: 0.65),
                        trackColor: const Color(0xFF222436),
                        child: SingleChildScrollView(
                          controller: _responseScrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(right: 12),
                          child: SelectableText(
                            bridgeState.lastResponse!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFF3F4F8),
                              height: 1.55,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  /// Continue button at the bottom-right to advance to the 10 AI option screen.
  Widget _buildContinueButton(ChatGptBridgeState bridgeState) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHoveringContinue = true),
      onExit: (_) => setState(() => _isHoveringContinue = false),
      child: GestureDetector(
        key: const Key('bridge_continue_button'),
        onTapDown: (_) => setState(() => _isPressingContinue = true),
        onTapUp: (_) => setState(() => _isPressingContinue = false),
        onTapCancel: () => setState(() => _isPressingContinue = false),
        onTap: widget.onContinue,
        child: AnimatedScale(
          scale: _isPressingContinue
              ? 0.95
              : (_isHoveringContinue ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB), // Signature blue
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHoveringContinue
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF3B82F6),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x402563EB),
                  blurRadius: _isHoveringContinue ? 18 : 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
