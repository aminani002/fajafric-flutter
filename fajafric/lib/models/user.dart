class User {
  final int id;
  final String prenom;
  final String nom;
  final String email;
  final String role;
  final String? photo;
  final String? dateNaissance;
  final String? genre;
  final String? pays;
  final String? pathologie;

  User({
    required this.id, required this.prenom, required this.nom,
    required this.email, required this.role,
    this.photo, this.dateNaissance, this.genre, this.pays, this.pathologie,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'], prenom: j['prenom'] ?? '', nom: j['nom'] ?? '',
    email: j['email'] ?? '', role: j['role'] ?? 'patient',
    photo: j['photo_profil'], dateNaissance: j['date_naissance'],
    genre: j['genre'], pays: j['pays'], pathologie: j['pathologie'],
  );

  String get fullName => '$prenom $nom';
  String get initials => '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}';
}
