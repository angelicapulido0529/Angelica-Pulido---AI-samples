import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../services/story_service.dart';
import '../theme.dart';

/// Vista previa de la foto + mensaje corto abajo, antes de mandarla.
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({
    super.key,
    required this.photo,
    required this.coupleId,
    required this.uid,
    required this.replacesExisting,
  });

  final File photo;
  final String coupleId;
  final String uid;
  final bool replacesExisting;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _message = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await StoryService.publish(
        coupleId: widget.coupleId,
        uid: widget.uid,
        photo: widget.photo,
        message: _message.text,
      );
      if (mounted) Navigator.of(context).pop();
    } on NoInternetException catch (e) {
      if (mounted) showMessage(context, e.toString());
    } catch (_) {
      if (mounted) showMessage(context, 'No se pudo subir. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(widget.photo, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.2, 0.6, 1],
                colors: [Color(0x88000000), Colors.transparent,
                  Colors.transparent, Color(0xCC000000)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: _sending ? null : () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                if (widget.replacesExisting)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Esta story reemplazará a la anterior',
                        style: TextStyle(color: Colors.white70)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _message,
                          enabled: !_sending,
                          maxLength: StoryService.maxMessageLength,
                          minLines: 1,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            hintText: 'Escribe un mensajito…',
                            counterText: '',
                            fillColor: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                              backgroundColor: AppColors.accent),
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
