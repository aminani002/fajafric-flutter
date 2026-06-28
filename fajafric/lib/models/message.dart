class Message {
  final int id;
  final int rdvId;
  final String expediteur;
  final String contenu;
  final bool lu;
  final String createdAt;

  Message({
    required this.id, required this.rdvId, required this.expediteur,
    required this.contenu, required this.lu, required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id: j['id'], rdvId: j['rdv_id'] ?? 0,
    expediteur: j['expediteur'] ?? 'patient',
    contenu: j['contenu'] ?? '', lu: j['lu'] ?? false,
    createdAt: j['created_at'] ?? '',
  );
}
