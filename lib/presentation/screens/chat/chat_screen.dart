import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/chat_message.dart';
import '../../providers/app_providers.dart';
import '../../../core/constants/place_categories.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll    = ScrollController();

  final _suggestions = const [
    'O que posso visitar proximo daqui?',
    'Qual o melhor restaurante proximo?',
    'Tem bares abertos agora?',
    'Sugira um passeio cultural',
    'Onde posso relaxar nessa regiao?',
  ];

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();

    final locState    = ref.read(locationNotifierProvider);
    final placesState = ref.read(placesNotifierProvider);

    String? locCtx;
    if (locState.currentLocation != null) {
      locCtx = '${locState.currentLocation!.latitude.toStringAsFixed(4)}, '
               '${locState.currentLocation!.longitude.toStringAsFixed(4)}';
    }

    String? placesCtx;
    if (placesState.places.isNotEmpty) {
      final list = placesState.places.take(8).map((p) {
        final distance = p.formattedDistance;
        final rating = p.rating != null ? " - Nota ${p.formattedRating}" : "";
        final openStatus = p.isOpen != null ? (p.isOpen! ? " - Aberto" : " - Fechado") : "";
        
        return '- ${p.name} ($distance)$rating$openStatus';
      }).join('\n');

      final categoryLabel = placesState.activeCategory?.label;
      placesCtx = 'Locais proximos em ${categoryLabel ?? "geral"}:\n$list';
    }

    await ref.read(chatNotifierProvider.notifier).send(text,
        locationContext: locCtx, placesContext: placesCtx);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatNotifierProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(children: [
          Container(width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Assistente Tour', style: TextStyle(fontSize: 14)),
            Text('Gemini AI', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textHint, fontSize: 10)),
          ]),
        ]),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context)),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Limpar conversa'),
                  content: const Text('Deseja apagar o historico de mensagens?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                    ElevatedButton(
                      onPressed: () { ref.read(chatNotifierProvider.notifier).clearChat(); Navigator.pop(context); },
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(children: [
        Expanded(child: state.messages.isEmpty ? _welcome() : _messages(state)),
        _input(state),
      ]),
    );
  }

  Widget _welcome() => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 28),
          Container(width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 40)),
          const SizedBox(height: 18),
          Text('Ola! Sou seu assistente de turismo',
              style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Posso ajudar voce a descobrir lugares incriveis proximos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Text('Sugestoes', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          ..._suggestions.map((s) => GestureDetector(
                onTap: () => _send(s),
                child: Container(
                  width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(13), border: Border.all(color: AppTheme.divider)),
                  child: Text(s, style: Theme.of(context).textTheme.bodyMedium),
                ),
              )),
        ]),
      );

  Widget _messages(ChatState state) => ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: state.messages.length,
        itemBuilder: (_, i) => _Bubble(message: state.messages[i]),
      );

  Widget _input(ChatState state) => Container(
        decoration: BoxDecoration(color: AppTheme.surface,
            boxShadow: [BoxShadow(color: AppTheme.shadow, blurRadius: 14, offset: const Offset(0, -4))]),
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _ctrl, maxLines: 4, minLines: 1,
            decoration: const InputDecoration(hintText: 'Pergunte sobre locais proximos...'),
            onSubmitted: state.isLoading ? null : _send,
          )),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: state.isLoading ? AppTheme.textHint : AppTheme.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            child: IconButton(
              onPressed: state.isLoading ? null : () => _send(_ctrl.text),
              icon: state.isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
      );
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(width: 28, height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 15)),
            const SizedBox(width: 7),
          ],
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primary : AppTheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(17), topRight: const Radius.circular(17),
                bottomLeft: Radius.circular(isUser ? 17 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 17),
              ),
              border: isUser ? null : Border.all(color: AppTheme.divider),
            ),
            child: message.isLoading
                ? const _Typing()
                : Text(message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : AppTheme.textPrimary, height: 1.5)),
          )),
          if (isUser) const SizedBox(width: 7),
        ],
      ),
    );
  }
}

class _Typing extends StatefulWidget {
  const _Typing();
  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final v = ((_ctrl.value - i * 0.2).clamp(0.0, 1.0));
              return Container(margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 7, height: 7 + v * 5,
                  decoration: BoxDecoration(color: AppTheme.textHint, borderRadius: BorderRadius.circular(4)));
            })));
}
