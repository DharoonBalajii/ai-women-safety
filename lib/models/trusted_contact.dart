class TrustedContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  const TrustedContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship = 'Contact',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };

  factory TrustedContact.fromJson(Map<String, dynamic> json) => TrustedContact(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        relationship: json['relationship'] as String? ?? 'Contact',
      );

  TrustedContact copyWith({String? name, String? phone, String? relationship}) {
    return TrustedContact(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
    );
  }
}
