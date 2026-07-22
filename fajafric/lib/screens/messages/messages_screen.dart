import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/appointment.dart';
import '../../models/message.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Appointment> _chats = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final apts = await ApiService.getAppointments();
    if (mounted) setState(() {
      // Grouper par médecin — une seule conversation par médecin (style WhatsApp)
      final Map<int, Appointment> byDoctor = {};
      for (final apt in apts) {
        final existing = byDoctor[apt.medecin.id];
        if (existing == null || apt.dateHeure.compareTo(existing.dateHeure) > 0) {
          byDoctor[apt.medecin.id] = apt;
        }
      }
      _chats = byDoctor.values.toList()
        ..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 110, pinned: true,
          backgroundColor: AppTheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: const Text('Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            background: Container(decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.tealMid], begin: Alignment.topLeft, end: Alignment.bottomRight),
            )),
          ),
        ),
        if (_loading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.teal)))
        else if (_chats.isEmpty)
          SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Aucune conversation', style: TextStyle(color: AppTheme.inkSoft, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Vos échanges avec les médecins\napparaîtront ici', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ])))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) {
                final apt = _chats[i];
                final initials = apt.medecin.initials;
                final spec = apt.medecin.specialite ?? 'Médecin généraliste';
                final colors = [AppTheme.teal, const Color(0xFF6366F1), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFFEC4899)];
                final colorIdx = apt.medecin.fullName.codeUnits.fold(0, (a, b) => a + b) % colors.length;
                final c = colors[colorIdx];
                final dt = DateTime.tryParse(apt.dateHeure);
                final dateStr = dt != null ? DateFormat('d MMM', 'fr_FR').format(dt) : '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  color: Colors.white,
                  child: Column(children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text(initials, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 17))),
                      ),
                      title: Text(apt.medecin.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(spec,
                          style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(dateStr, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                        const SizedBox(height: 4),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.border, size: 18),
                      ]),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(appointment: apt))),
                    ),
                    const Divider(height: 1, indent: 86),
                  ]),
                );
              },
              childCount: _chats.length,
            )),
          ),
      ]),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Appointment appointment;
  const ChatScreen({super.key, required this.appointment});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  List<Message> _messages = [];
  bool _sending = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    final msgs = await ApiService.getMessages(widget.appointment.id);
    if (mounted) setState(() => _messages = msgs);
    _scrollBottom();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() => _sending = true);
    await ApiService.sendMessage(widget.appointment.id, text);
    await _load();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: const BackButton(),
        title: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: Colors.white24,
            child: Text(widget.appointment.medecin.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.appointment.medecin.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(widget.appointment.typeLabel, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text('Aucun message', style: TextStyle(color: AppTheme.inkSoft)),
              ]))
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final msg = _messages[i];
                  final isMe = msg.expediteur == 'patient';
                  final dt = DateTime.tryParse(msg.createdAt);
                  final time = dt != null ? DateFormat('HH:mm').format(dt) : '';
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 18),
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
                          ),
                          child: Text(msg.contenu, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppTheme.textPrimary)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                          child: Text(time, style: const TextStyle(fontSize: 10.5, color: AppTheme.inkSoft)),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
        Container(
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
                    hintText: 'Votre message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46, height: 46,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.tealMid]),
                  shape: BoxShape.circle,
                ),
                child: _sending
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ])),
        ),
      ]),
    );
  }
}
