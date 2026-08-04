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
    required int frequencyValue,
    required String frequencyUnit,
    required double amount,
    String currency = 'XOF',
    String? description,
    int? maxMembers,
  }) async {
    final res = await _dio.post('/groups', data: {
      'name': name,
      'type': type,
      'frequencyValue': frequencyValue,
      'frequencyUnit': frequencyUnit,
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
    required int frequencyValue,
    required String frequencyUnit,
    required double amount,
    required String currency,
    String? description,
    int? maxMembers,
  }) async {
    final res = await _dio.put('/groups/$id', data: {
      'name': name,
      'frequencyValue': frequencyValue,
      'frequencyUnit': frequencyUnit,
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

  // ── CYCLES (tours de rotation) ────────────────────────────────────────────

  /// Démarre un nouveau cycle : génère automatiquement tout le calendrier
  /// des tours (un par membre) ainsi que les cotisations correspondant à
  /// chaque date de tour.
  Future<Map<String, dynamic>> startCycle({
    required String groupId,
    required DateTime startDate,
  }) async {
    final res = await _dio.post('/groups/$groupId/cycles/start', data: {
      'startDate': startDate.toIso8601String(),
    });
    return res.data;
  }

  Future<Map<String, dynamic>> closeCycle(String groupId) async {
    final res = await _dio.post('/groups/$groupId/cycles/close');
    return res.data;
  }

  Future<List<Map<String, dynamic>>> getCycleHistory(String groupId) async {
    final res = await _dio.get('/groups/$groupId/cycles');
    final list = res.data['data'] as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// Reprogramme la date d'un tour. Répercute automatiquement le changement
  /// sur les cotisations de ce même tour (même date d'échéance).
  Future<void> rescheduleTurn({
    required String groupId,
    required String turnId,
    required DateTime scheduledDate,
  }) async {
    await _dio.patch('/groups/$groupId/turns/$turnId/reschedule', data: {
      'scheduledDate': scheduledDate.toIso8601String(),
    });
  }

  // ── JOURNAL D'AUDIT ────────────────────────────────────────────────────────

  /// Retourne les entrées du journal, plus les infos de troncature côté
  /// plan (voir `isTruncated`/`totalCount` — le backend limite l'historique
  /// visible pour les plans FREE/STARTER, journal complet réservé au Pro).
  Future<Map<String, dynamic>> getAuditLog(String groupId) async {
    final res = await _dio.get('/groups/$groupId/audit-log');
    final data = res.data['data'] as Map<String, dynamic>;
    return {
      'logs': (data['logs'] as List).cast<Map<String, dynamic>>(),
      'isTruncated': data['isTruncated'] as bool? ?? false,
      'totalCount': data['totalCount'] as int? ?? 0,
    };
  }

  /// Télécharge l'export CSV des cotisations d'un groupe (fonctionnalité
  /// réservée au plan Pro — le backend renvoie 402 sinon).
  /// Retourne le contenu CSV brut (String) à écrire sur le disque par
  /// l'appelant (voir subscription_screen ou group_detail_screen).
  Future<String> exportContributionsCsv(String groupId) async {
    final res = await _dio.get(
      '/groups/$groupId/contributions/export',
      options: Options(responseType: ResponseType.plain),
    );
    return res.data as String;
  }

  // ── ACTIVITÉS ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getActivity(String groupId) async {
    final res = await _dio.get('/groups/$groupId/activity');
    final list = res.data['data'] as List;
    return list.cast<Map<String, dynamic>>();
  }

  /// Supprime une activité de la liste (suppression douce — l'entrée reste
  /// visible dans le Journal d'audit complet).
  Future<void> dismissActivity({
    required String groupId,
    required String activityId,
  }) async {
    await _dio.delete('/groups/$groupId/activity/$activityId');
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

  /// Retire une cotisation de l'historique personnel du membre (suppression
  /// douce — reste intacte et comptée côté gérant).
  Future<void> hideMemberContribution({
    required String groupId,
    required String contributionId,
  }) async {
    await _dio.delete('/groups/$groupId/member/contributions/$contributionId');
  }
}