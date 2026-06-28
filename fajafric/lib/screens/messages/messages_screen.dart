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
    if (mounted) {
      setState(() {
      _chats = apts.where((a) => ['chat','teleconsultation'].contains(a.type)).toList();
      _loading = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _chats.isEmpty
          ? const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chat_bubble_outline, size: 52, color: AppTheme.line),
                SizedBox(height: 12),
                Text('Aucune conversation', style: TextStyle(color: AppTheme.inkSoft, fontSize: 15)),
              ]),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _chats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final apt = _chats[i];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.line)),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.teal,
                    child: Text(apt.medecin.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(apt.medecin.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(apt.typeLabel, style: const TextStyle(fontSize: 12.5)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(appointment: apt),
                  )),
                );
              },
            ),
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
  String? _myRole;
  bool _sending = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final msgs = await ApiService.getMessages(widget.appointment.id);
    final user = await AuthService.getUser();
    if (mounted) setState(() { _messages = msgs; _myRole = user?.role; });
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.appointment.medecin.fullName, style: const TextStyle(fontSize: 16)),
            Text(widget.appointment.typeLabel, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
          ],
        ),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
              ? const Center(child: Text('Aucun message', style: TextStyle(color: AppTheme.inkSoft)))
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
                              color: isMe ? AppTheme.teal : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                              border: Border.all(color: isMe ? AppTheme.teal : AppTheme.line),
                            ),
                            child: Text(msg.contenu, style: TextStyle(
                              fontSize: 14, color: isMe ? Colors.white : AppTheme.ink,
                            )),
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
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.line)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      decoration: const InputDecoration(hintText: 'Votre message...', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: AppTheme.teal, shape: BoxShape.circle),
                      child: _sending
                        ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
