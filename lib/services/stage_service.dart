import '../config/api_config.dart';
import 'http_client.dart';

class StageService {
  final SimpleHttp http;
  StageService(this.http);

  Future<List<Map<String, dynamic>>> listStages(String projectId) async {
    final uri = Uri.parse(
      '${ApiConfig.checklistBaseUrl}/projects/$projectId/stages',
    );
    final json = await http.getJson(uri);
    final data = (json['data'] as List?) ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createStage(
    String projectId, {
    required String name,
    String? description,
    String status = 'pending',
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.checklistBaseUrl}/projects/$projectId/stages',
    );
    final body = {
      'stage_name': name,
      if (description != null) 'description': description,
      'status': status,
    };
    final json = await http.postJson(uri, body);
    return (json['data'] as Map<String, dynamic>);
  }
}
