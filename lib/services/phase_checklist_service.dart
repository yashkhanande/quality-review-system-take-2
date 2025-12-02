import '../config/api_config.dart';
import 'http_client.dart';

class PhaseChecklistService {
  final SimpleHttp http;
  PhaseChecklistService(this.http);

  // List checklists for a stage
  Future<List<Map<String, dynamic>>> listForStage(String stageId) async {
    final uri = Uri.parse(
      '${ApiConfig.checklistBaseUrl}/stages/$stageId/checklists',
    );
    final json = await http.getJson(uri);
    final data = (json['data'] as List?) ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Create checklist for a stage
  Future<Map<String, dynamic>> createForStage(
    String stageId, {
    required String name,
    String? description,
    String status = 'draft',
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.checklistBaseUrl}/stages/$stageId/checklists',
    );
    final body = {
      'checklist_name': name,
      if (description != null) 'description': description,
      'status': status,
    };
    final json = await http.postJson(uri, body);
    return (json['data'] as Map<String, dynamic>);
  }

  // Get checklist by id
  Future<Map<String, dynamic>> getById(String id) async {
    final uri = Uri.parse('${ApiConfig.checklistBaseUrl}/checklists/$id');
    final json = await http.getJson(uri);
    return (json['data'] as Map<String, dynamic>);
  }

  // Update checklist (supports updating answers JSON)
  Future<Map<String, dynamic>> updateChecklist(
    String id,
    Map<String, dynamic> update,
  ) async {
    final uri = Uri.parse('${ApiConfig.checklistBaseUrl}/checklists/$id');
    final json = await http.putJson(uri, update);
    return (json['data'] as Map<String, dynamic>);
  }

  // Submit/approve/request-changes
  Future<void> submit(String id) async {
    final uri = Uri.parse(
      '${ApiConfig.checklistBaseUrl}/checklists/$id/submit',
    );
    await http.postJson(uri, {
      'user_id': 'self',
    }); // user is taken from token if backend uses it
  }

  Future<void> approve(String id) async {
    final uri = Uri.parse(
      '${ApiConfig.checklistBaseUrl}/checklists/$id/approve',
    );
    await http.postJson(uri, {'user_id': 'self'});
  }

  Future<void> requestChanges(String id, String message) async {
    final uri = Uri.parse(
      '${ApiConfig.checklistBaseUrl}/checklists/$id/request-changes',
    );
    await http.postJson(uri, {'user_id': 'self', 'message': message});
  }
}
