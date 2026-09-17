/// A pickup/delivery store location, scopes cart pricing/stock/checkout.
/// Mirrors the site's branch store shape (src/stores/branch.js).
class Branch {
  final String id, name;
  final String? address, phone, openTime, closeTime;

  const Branch({required this.id, required this.name, this.address, this.phone, this.openTime, this.closeTime});

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: '${json['branch_id'] ?? json['id']}',
        name: json['name'] ?? '',
        address: json['address'],
        phone: json['phone'],
        openTime: json['open_time'],
        closeTime: json['close_time'],
      );

  String? get hours => (openTime != null && closeTime != null) ? '$openTime - $closeTime' : null;
}
