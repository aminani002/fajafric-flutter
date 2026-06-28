class Rapport {
  final int id;
  final int rdvId;
  final String diagnostic;
  final String? recommandations;
  final String createdAt;
  final String? medecinNom;

  Rapport({
    required this.id, required this.rdvId, required this.diagnostic,
    this.recommandations, required this.createdAt, this.medecinNom,
  });

  factory Rapport.fromJson(Map<String, dynamic> j) => Rapport(
    id: j['id'], rdvId: j['rdv_id'] ?? 0,
    diagnostic: j['diagnostic'] ?? '',
    recommandations: j['recommandations'],
    createdAt: j['created_at'] ?? '',
    medecinNom: j['medecin_nom'],
  );
}

class Ordonnance {
  final int id;
  final int rdvId;
  final dynamic medicaments;
  final String createdAt;
  final String? medecinNom;

  Ordonnance({
    required this.id, required this.rdvId, required this.medicaments,
    required this.createdAt, this.medecinNom,
  });

  factory Ordonnance.fromJson(Map<String, dynamic> j) => Ordonnance(
    id: j['id'], rdvId: j['rdv_id'] ?? 0,
    medicaments: j['medicaments'],
    createdAt: j['created_at'] ?? '',
    medecinNom: j['medecin_nom'],
  );
}
