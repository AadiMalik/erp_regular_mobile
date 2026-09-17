import '../config/env.dart';
import '../models/branch.dart';
import 'api_client.dart';

class BranchService {
  static Future<List<Branch>> fetchBranches() async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/branches/${Env.businessId}');
      final body = res.data;
      if (body?['Success'] != true || body?['Data'] == null) return const [];
      return (body['Data'] as List).map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }
}
