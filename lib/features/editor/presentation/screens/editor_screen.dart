import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/editor_provider.dart';
import '../widgets/grammar_text_controller.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with WidgetsBindingObserver {
  late final GrammarTextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _textController = GrammarTextEditingController(
      text: "Welcome to AI Checker! Start typing your notes, essays, or emails here. "
          "Try typing teh word or thier grammar mistakes to see real-time squiggly underlines.",
    );

    // Initial pass of mock highlights
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorProvider>().injectSampleErrors(_textController);
    });

    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    context.read<EditorProvider>().injectSampleErrors(_textController);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-verify permissions when user returns from system settings
      context.read<EditorProvider>().checkPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showPermissionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Consumer<EditorProvider>(
          builder: (context, editorProvider, _) {
            final colorScheme = Theme.of(context).colorScheme;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'System Permissions & Overlay',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To enable Grammarly-style floating AI suggestions over WhatsApp, Chrome, and other apps, configure permissions below:',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // Overlay Permission Tile
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: editorProvider.isOverlayPermissionGranted
                          ? Colors.green.shade100
                          : Colors.amber.shade100,
                      child: Icon(
                        editorProvider.isOverlayPermissionGranted
                            ? Icons.check
                            : Icons.layers_outlined,
                        color: editorProvider.isOverlayPermissionGranted
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                      ),
                    ),
                    title: const Text('Display Over Other Apps'),
                    subtitle: Text(
                      editorProvider.isOverlayPermissionGranted
                          ? 'Granted. Floating logo is authorized to appear.'
                          : 'Required to draw the floating "G" assistant logo.',
                    ),
                    trailing: editorProvider.isOverlayPermissionGranted
                        ? const Icon(Icons.done, color: Colors.green)
                        : FilledButton.tonal(
                            onPressed: () async {
                              await editorProvider.requestOverlayPermission();
                            },
                            child: const Text('Grant'),
                          ),
                  ),
                  const Divider(height: 24),

                  // Accessibility Service Tile
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: editorProvider.isAccessibilityEnabled
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      child: Icon(
                        editorProvider.isAccessibilityEnabled
                            ? Icons.check
                            : Icons.accessibility_new_rounded,
                        color: editorProvider.isAccessibilityEnabled
                            ? Colors.green.shade800
                            : Colors.blue.shade900,
                      ),
                    ),
                    title: const Text('Accessibility Text Inspection'),
                    subtitle: Text(
                      editorProvider.isAccessibilityEnabled
                          ? 'Enabled. AI monitors active text inputs globally.'
                          : 'Required to detect when you type in external apps.',
                    ),
                    trailing: editorProvider.isAccessibilityEnabled
                        ? const Icon(Icons.done, color: Colors.green)
                        : FilledButton.tonal(
                            onPressed: () async {
                              await editorProvider.openAccessibilitySettings();
                            },
                            child: const Text('Enable'),
                          ),
                  ),
                  const Divider(height: 24),

                  // Global Overlay Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Global Floating Assistant'),
                    subtitle: const Text(
                      'Automatically popup when text field is active in other apps.',
                    ),
                    value: editorProvider.isGlobalOverlayEnabled,
                    onChanged: (val) {
                      editorProvider.setGlobalOverlayEnabled(val);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final editorProvider = context.watch<EditorProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AI DOC',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Untitled Document'),
          ],
        ),
        actions: [
          // Overlay & Permission Status Pill
          IconButton(
            tooltip: 'System Permissions & Overlay Settings',
            icon: Badge(
              isLabelVisible: !editorProvider.hasAllPermissions,
              backgroundColor: Colors.amber.shade700,
              child: Icon(
                editorProvider.hasAllPermissions
                    ? Icons.shield_rounded
                    : Icons.shield_outlined,
                color: editorProvider.hasAllPermissions
                    ? colorScheme.primary
                    : Colors.amber.shade800,
              ),
            ),
            onPressed: () => _showPermissionsBottomSheet(context),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Banner if permissions missing
            if (!editorProvider.hasAllPermissions)
              MaterialBanner(
                backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                content: const Text(
                  'Global Assistant is inactive. Enable Overlay and Accessibility to suggest corrections across other apps.',
                  style: TextStyle(fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => _showPermissionsBottomSheet(context),
                    child: const Text('Configure'),
                  ),
                ],
              ),


            // Writing Canvas
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.7,
                    fontSize: 18,
                    letterSpacing: 0.2,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Start writing or paste text here...',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),

            // Editor Bottom Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(

                children: [
                  // Error count chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _textController.errors.isEmpty
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _textController.errors.isEmpty
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _textController.errors.isEmpty
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: _textController.errors.isEmpty
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _textController.errors.isEmpty
                              ? 'All clear'
                              : '${_textController.errors.length} suggestions',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textController.errors.isEmpty
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Word count
                  Text(
                    '${_getWordCount(_textController.text)} words',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
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

  int _getWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
}
