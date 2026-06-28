class Medecin {
  final int id;
  final String prenom;
  final String nom;
  final String? specialite;
  final String? photo;

  Medecin({required this.id, required this.prenom, required this.nom, this.specialite, this.photo});

  factory Medecin.fromJson(Map<String, dynamic> j) => Medecin(
    id: j['id'], prenom: j['prenom'] ?? '', nom: j['nom'] ?? '',
    specialite: j['specialite'], photo: j['photo_profil'],
  );

  String get fullName => 'Dr. $prenom $nom';
  String get initials => '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}';
}

class Appointment {
  final int id;
  final Medecin medecin;
  final String dateHeure;
  final String type;
  final String statut;
  final String? motif;
  final bool hasReport;
  final bool hasOrdonnance;

  Appointment({
    required this.id, required this.medecin, required this.dateHeure,
    required this.type, required this.statut,
    this.motif, this.hasReport = false, this.hasOrdonnance = false,
  });

  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
    id: j['id'],
    medecin: Medecin.fromJson(j['medecin'] ?? {}),
    dateHeure: j['date_heure'] ?? '',
    type: j['type'] ?? 'cabinet',
    statut: j['statut'] ?? 'en_attente',
    motif: j['motif'],
    hasReport: j['has_report'] ?? false,
    hasOrdonnance: j['has_ordonnance'] ?? false,
  );

  String get typeLabel => {
    'cabinet': 'En cabinet', 'teleconsultation': 'Téléconsultation',
    'deplacement': 'Déplacement', 'chat': 'Chat médical',
  }[type] ?? type;

  StatutConfig get statutConfig {
    switch (statut) {
      case 'confirme': return StatutConfig('Confirmé', 0xFF10B981, 0xFFD1FAE5);
      case 'en_attente': return StatutConfig('En attente', 0xFFF59E0B, 0xFFFEF3C7);
      case 'termine': return StatutConfig('Terminé', 0xFF6B7280, 0xFFF3F4F6);
      case 'annule': return StatutConfig('Annulé', 0xFFEF4444, 0xFFFEE2E2);
      default: return StatutConfig(statut, 0xFF6B7280, 0xFFF3F4F6);
    }
  }
}

class StatutConfig {
  final String label;
  final int color;
  final int bg;
  StatutConfig(this.label, this.color, this.bg);
}
