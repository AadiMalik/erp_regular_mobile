/// Saved delivery address — mirrors CustomerAccountService::mapAddress.
class Address {
  final String id;
  final String? label;
  final String fullName;
  final String? phone, email, city, state, zip, country;
  final String address;
  final bool isDefault;

  const Address({
    required this.id,
    this.label,
    required this.fullName,
    this.phone,
    this.email,
    required this.address,
    this.city,
    this.state,
    this.zip,
    this.country,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: '${json['id']}',
        label: json['label'],
        fullName: json['fullName'] ?? '',
        phone: json['phone'],
        email: json['email'],
        address: json['address'] ?? '',
        city: json['city'],
        state: json['state'],
        zip: json['zip'],
        country: json['country'],
        isDefault: json['isDefault'] == true,
      );

  String get summary => [address, city, state, country].where((s) => s != null && s.isNotEmpty).join(', ');
}
