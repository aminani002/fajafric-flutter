import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

// ── Message model ─────────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime time;
  ChatMessage({required this.text, required this.isBot, DateTime? time})
    : time = time ?? DateTime.now();
}

// ── Knowledge base ────────────────────────────────────────────────────────────
const _kb = [
  // Urgences
  _QA(k: ['urgence', 'douleur poitrine', 'infarctus', 'crise cardiaque', 'évanouissement'],
      r: 'Ceci semble urgent. Appelez le 15 (SAMU) ou le 18 (Pompiers) immédiatement. Ne prenez aucun médicament sans avis médical.'),

  // Fièvre
  _QA(k: ['fièvre', 'température', 'chaud', 'frisson'],
      r: 'Pour une fièvre légère (< 38,5 °C), restez hydraté·e et reposez-vous. Si la fièvre dépasse 39 °C ou dure plus de 48 h, consultez un médecin. Le paracétamol peut aider à faire baisser la fièvre.'),

  // Maux de tête
  _QA(k: ['maux de tête', 'mal de tête', 'migraine', 'céphalée'],
      r: 'Pour les maux de tête courants : hydratez-vous, reposez-vous dans une pièce sombre et silencieuse. Évitez les écrans. Si les douleurs sont intenses, soudaines, ou accompagnées de vomissements ou troubles visuels, consultez rapidement.'),

  // Tension / Hypertension
  _QA(k: ['tension', 'hypertension', 'pression artérielle', 'ta', 'mmhg'],
      r: 'Une tension normale est ≤ 120/80 mmHg. Entre 130-139/80-89 c\'est une hypertension légère. Au-delà de 140/90, consultez votre médecin. Réduisez le sel, l\'alcool, le stress, et faites de l\'exercice régulièrement.'),

  // Diabète / Glycémie
  _QA(k: ['diabète', 'glycémie', 'sucre', 'insuline', 'hypoglycémie'],
      r: 'La glycémie à jeun doit être entre 0,70 et 1,10 g/L. En cas d\'hypoglycémie (< 0,70), prenez du sucre rapide (jus de fruit, sucre). En cas d\'hyperglycémie persistante, consultez votre médecin. Évitez les sucres rapides et pratiquez une activité physique régulière.'),

  // Médicaments
  _QA(k: ['médicament', 'dosage', 'paracétamol', 'ibuprofène', 'antibiotique'],
      r: 'Je ne peux pas donner de conseils sur les médicaments ou leur dosage. Seul un médecin ou pharmacien peut vous orienter. Ne modifiez jamais votre traitement sans avis médical.'),

  // Poids / BMI
  _QA(k: ['poids', 'imc', 'bmi', 'obésité', 'surpoids', 'minceur'],
      r: 'L\'IMC (Indice de Masse Corporelle) = poids (kg) ÷ taille² (m). Entre 18,5 et 24,9 c\'est normal. Au-delà de 25 : surpoids. Au-delà de 30 : obésité. Une alimentation équilibrée et l\'activité physique sont essentielles.'),

  // Sommeil
  _QA(k: ['sommeil', 'insomnie', 'dormir', 'fatigue', 'épuisement'],
      r: 'Les adultes ont besoin de 7 à 9 heures de sommeil par nuit. Pour améliorer votre sommeil : couchez-vous à heures fixes, évitez les écrans avant de dormir, limitez la caféine l\'après-midi. Si l\'insomnie persiste, consultez un médecin.'),

  // Stress / Anxiété
  _QA(k: ['stress', 'anxiété', 'angoisse', 'panique', 'depression', 'dépression'],
      r: 'Le stress et l\'anxiété peuvent être gérés par des techniques de respiration, la méditation, et l\'exercice physique. N\'hésitez pas à consulter un professionnel de santé mentale si ces symptômes persistent ou s\'aggravent.'),

  // Alimentation
  _QA(k: ['alimentation', 'nutrition', 'régime', 'manger', 'nourriture', 'vitamines'],
      r: 'Une alimentation saine comprend : des fruits et légumes (5 portions/jour), des protéines maigres, des céréales complètes, et une bonne hydratation (1,5 à 2 L d\'eau/jour). Limitez les graisses saturées, le sucre et le sel.'),

  // Exercice
  _QA(k: ['sport', 'exercice', 'activité physique', 'marche', 'cardio'],
      r: 'L\'OMS recommande au moins 150 minutes d\'activité modérée par semaine (marche rapide, natation, vélo). Commencez progressivement et consultez votre médecin avant de démarrer un programme intensif.'),

  // Covid / Virus
  _QA(k: ['covid', 'coronavirus', 'grippe', 'rhume', 'virus', 'toux', 'essoufflement'],
      r: 'En cas de fièvre, toux persistante ou difficultés respiratoires, consultez un médecin ou appelez le 15. Restez chez vous pour éviter de contaminer d\'autres personnes. Portez un masque si vous devez sortir.'),

  // RDV Fajafric
  _QA(k: ['rendez-vous', 'médecin', 'rdv', 'consultation', 'prendre rdv', 'booking'],
      r: 'Pour prendre un rendez-vous avec l\'un de nos médecins, rendez-vous dans l\'onglet "Médecins" ou "RDV" de l\'application. Vous pouvez choisir un type de consultation : cabinet, téléconsultation, déplacement ou chat médical.'),

  // Accueil / Bonjour
  _QA(k: ['bonjour', 'salut', 'bonsoir', 'hello', 'hi', 'aide', 'help'],
      r: 'Bonjour ! Je suis votre assistant santé Fajafric. Je peux vous conseiller sur des sujets comme la fièvre, la tension, le sommeil, l\'alimentation, ou vous aider à naviguer dans l\'application. Comment puis-je vous aider ?'),

  // Merci
  _QA(k: ['merci', 'thanks', 'ok', 'super', 'bien', 'bonne'],
      r: 'Avec plaisir ! N\'hésitez pas si vous avez d\'autres questions. Pour tout problème médical sérieux, consultez toujours un professionnel de santé.'),
];

class _QA {
  final List<String> k;
  final String r;
  const _QA({required this.k, required this.r});
}

String _getResponse(String input) {
  final q = input.toLowerCase().trim();
  for (final qa in _kb) {
    if (qa.k.any((k) => q.contains(k))) return qa.r;
  }
  return 'Je n\'ai pas de réponse précise à cette question. Je vous recommande de consulter un médecin pour tout problème de santé. Vous pouvez prendre un rendez-vous directement dans l\'application Fajafric.';
}

// ── Écran chatbot ─────────────────────────────────────────────────────────────
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  static const _suggestions = [
    'J\'ai de la fièvre',
    'Comment gérer ma tension ?',
    'Prendre un rendez-vous',
    'Conseils pour dormir mieux',
    'Mon poids et IMC',
  ];

  @override
  void initState() {
    super.initState();
    // Message d'accueil
    _messages.add(ChatMessage(
      text: 'Bonjour ! Je suis votre assistant santé Fajafric. Je peux répondre à vos questions sur la santé, les symptômes courants, ou vous aider à naviguer dans l\'application.\n\nQue puis-je faire pour vous ?',
      isBot: true,
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _isTyping) return;
    _ctrl.clear();
    setState(() {
      _messages.add(ChatMessage(text: q, isBot: false));
      _isTyping = true;
    });
    _scrollBottom();

    // Simulate thinking delay
    final delay = 600 + Random().nextInt(800);
    await Future.delayed(Duration(milliseconds: delay));
    if (!mounted) return;

    final response = _getResponse(q);
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(text: response, isBot: true));
    });
    _scrollBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        leading: const BackButton(),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Chatbot Médical', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text('Assistant Fajafric IA', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {
              _messages.clear();
              _messages.add(ChatMessage(
                text: 'Conversation réinitialisée. Comment puis-je vous aider ?',
                isBot: true,
              ));
            }),
          ),
        ],
      ),
      body: Column(children: [
        // Avertissement
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFFFF8E1),
          child: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Cet assistant ne remplace pas un avis médical professionnel.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            )),
          ]),
        ),

        // Messages
        Expanded(child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length + (_isTyping ? 1 : 0) + (_messages.length == 1 ? 1 : 0),
          itemBuilder: (_, i) {
            // Suggestions après premier message
            if (_messages.length == 1 && i == 1) return _buildSuggestions();
            final msgIdx = (_messages.length == 1 && i > 1) ? i - 1 : i;
            if (_isTyping && msgIdx == _messages.length) return _buildTyping();
            if (msgIdx >= _messages.length) return const SizedBox.shrink();
            return _buildBubble(_messages[msgIdx]);
          },
        )),

        // Input
        _buildInput(),
      ]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isBot = msg.isBot;
    final time  = DateFormat('HH:mm').format(msg.time);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF7C3AED), size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
                  decoration: BoxDecoration(
                    color: isBot ? Colors.white : const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isBot ? 4 : 18),
                      bottomRight: Radius.circular(isBot ? 18 : 4),
                    ),
                    border: isBot ? Border.all(color: AppTheme.border) : null,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  child: Text(msg.text, style: TextStyle(
                    fontSize: 13.5, height: 1.5,
                    color: isBot ? AppTheme.textPrimary : Colors.white,
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(time, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                ),
              ],
            ),
          ),
          if (!isBot) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF7C3AED), size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: const _TypingDots(),
        ),
      ]),
    );
  }

  Widget _buildSuggestions() => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Suggestions :', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _suggestions.map((s) => GestureDetector(
          onTap: () => _send(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.25)),
            ),
            child: Text(s, style: const TextStyle(fontSize: 12.5, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
          ),
        )).toList(),
      ),
    ]),
  );

  Widget _buildInput() => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
    ),
    child: SafeArea(top: false, child: Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(24)),
          child: TextField(
            controller: _ctrl,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Posez votre question de santé…',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onSubmitted: _send,
          ),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => _send(_ctrl.text),
        child: Container(
          width: 46, height: 46,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9333EA)]),
            shape: BoxShape.circle,
          ),
          child: _isTyping
            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    ])),
  );
}

// ── Dots animation ─────────────────────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
          final offset = sin((_ctrl.value * 2 * 3.1416) - (i * 1.2));
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.5 + 0.5 * offset.abs()),
              shape: BoxShape.circle,
            ),
          );
        }));
      },
    );
  }
}
