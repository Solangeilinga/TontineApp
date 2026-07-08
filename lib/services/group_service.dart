// lib/services/group_service.dart
import 'package:dio/dio.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/contribution.dart';
import 'api_service.dart';

class GroupService {
  final ApiService _api = ApiService();
  Dio get _dio => _api.dio;

  Future<Group> createGroup({
    required String name,
    required String type,
    required String frequency,
    required double amount,
    String currency = 'XOF',
    String? description,
    int? maxMembers,
  }) async {
    final res = await _dio.post('/groups', data: {
      'name': name,
      'type': type,
      'frequency': frequency,
      'amount': amount,
      'currency': currency,
      if (description != null) 'description': description,
      if (maxMembers != null) 'maxMembers': maxMembers,
    });
    return Group.fromJson(res.data['data']);
  }

  Future<List<Group>> getGroups() async {
    final res = await _dio.get('/groups');
    final list = res.data['data'] as List;
    return list.map((j) => Group.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> getGroupDetail(String id) async {
    final res = await _dio.get('/groups/$id');
    return res.data['data'];
  }

  Future<Group> updateGroup({
    required String id,
    required String name,
    required String frequency,
    required double amount,
    required String currency,
    String? description,
    int? maxMembers,
  }) async {
    final res = await _dio.put('/groups/$id', data: {
      'name': name,
      'frequency': frequency,
      'amount': amount,
      'currency': currency,
      if (description != null) 'description': description,
      'maxMembers': maxMembers,
    });
    return Group.fromJson(res.data['data']);
  }

  Future<void> archiveGroup(String id) async {
    await _dio.patch('/groups/$id/archive');
  }

  Future<void> unarchiveGroup(String id) async {
    await _dio.patch('/groups/$id/unarchive');
  }

  // ── MEMBRES ───────────────────────────────────────────────────────────────

  Future<List<GroupMember>> getMembers(String groupId) async {
    final res = await _dio.get('/groups/$groupId/members');
    final list = res.data['data'] as List;
    return list.map((j) => GroupMember.fromJson(j)).toList();
  }

  Future<GroupMember> addMember({
    required String groupId,
    required String name,
    required String phone,
  }) async {
    final res = await _dio.post('/groups/$groupId/members', data: {
      'name': name,
      'phone': phone,
    });
    return GroupMember.fromJson(res.data['data']);
  }

  Future<void> updateMember({
    required String groupId,
    required String userId,
    String? name,
    String? phone,
  }) async {
    await _dio.put('/groups/$groupId/members/$userId', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    });
  }

  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    await _dio.delete('/groups/$groupId/members/$userId');
  }

  Future<void> updateTurnOrder({
    required String groupId,
    required List<Map<String, dynamic>> orders,
  }) async {
    await _dio.put('/groups/$groupId/members/turn-order', data: {
      'orders': orders,
    });
  }

  // ── COTISATIONS ───────────────────────────────────────────────────────────

  Future<List<Contribution>> getContributions(String groupId,
      {String? status}) async {
    final res = await _dio.get(
      '/groups/$groupId/contributions',
      queryParameters: status != null ? {'status': status} : null,
    );
    final list = res.data['data'] as List;
    return list.map((j) => Contribution.fromJson(j)).toList();
  }

  Future<void> createCycle({
    required String groupId,
    required DateTime dueDate,
  }) async {
    await _dio.post('/groups/$groupId/contributions/cycle', data: {
      'dueDate': dueDate.toIso8601String(),
    });
  }

  Future<void> markReceived(String contributionId, {String? note}) async {
    await _dio.patch('/groups/contributions/$contributionId/received', data: {
      if (note != null) 'note': note,
    });
  }

  Future<void> markLate(String contributionId, {String? note}) async {
    await _dio.patch('/groups/contributions/$contributionId/late', data: {
      if (note != null) 'note': note,
    });
  }

  Future<Map<String, dynamic>> getCycleRecap(String groupId) async {
    final res = await _dio.get('/groups/$groupId/recap');
    return res.data['data'];
  }

  // ── VUE MEMBRE ────────────────────────────────────────────────────────────

  Future<List<Group>> getMemberGroups() async {
    final res = await _dio.get('/groups/member/my-groups');
    final list = res.data['data'] as List;
    return list.map((j) => Group.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> getMemberTurns(String groupId) async {
    final res = await _dio.get('/groups/$groupId/member/turns');
    return res.data['data'];
  }

  Future<List<Contribution>> getMemberContributions(String groupId) async {
    final res = await _dio.get('/groups/$groupId/member/contributions');
    final list = res.data['data'] as List;
    return list.map((j) => Contribution.fromJson(j)).toList();
  }
}