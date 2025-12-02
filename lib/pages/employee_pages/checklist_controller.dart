import 'package:get/get.dart';
import '../../services/http_client.dart';
import '../../services/stage_service.dart';
import '../../services/phase_checklist_service.dart';

class ChecklistController extends GetxService {
  late final StageService _stageService;
  late final PhaseChecklistService _checklistService;

  // Cache for loaded answers: projectId -> phase -> role -> subQuestion -> answer map
  final _cache = <String, Map<int, Map<String, Map<String, dynamic>>>>{}.obs;

  // Submission status cache: projectId -> phase -> role -> metadata
  final _submissionCache = <String, Map<int, Map<String, dynamic>>>{}.obs;

  // Loading state
  final _isLoading = <String, bool>{}.obs;

  // Pending saves (debouncing)
  final Map<String, Future<void>> _pendingSaves = {};

  // Cache of stageId and checklistId per project+phase
  final _stageIdCache = <String, String>{}; // key: projectId-phase
  final _checklistIdCache = <String, String>{}; // key: projectId-phase

  @override
  void onInit() {
    super.onInit();
    print('🎯 ChecklistController.onInit() called');
    // Initialize service
    try {
      final http = Get.find<SimpleHttp>();
      _stageService = StageService(http);
      _checklistService = PhaseChecklistService(http);
      print('✓ ChecklistController initialized successfully');
    } catch (e) {
      print('❌ Error initializing ChecklistController: $e');
      rethrow;
    }
  }

  /// Load answers from backend for a specific project/phase/role
  Future<void> loadAnswers(String projectId, int phase, String role) async {
    print(
      '🔵 loadAnswers CALLED: projectId=$projectId, phase=$phase, role=$role',
    );
    final key = '$projectId-$phase-$role';
    if (_isLoading[key] == true) {
      print('⚠️ Already loading $key, skipping...');
      return; // Already loading
    }

    _isLoading[key] = true;
    print('📥 Loading answers for $role in project $projectId phase $phase...');

    try {
      // Resolve stage and checklist
      final answers = await _loadRoleAnswersFromStageApi(
        projectId,
        phase,
        role,
      );
      print('✓ Received ${answers.length} answers from stage API for $role');

      // Store in cache
      final proj = _cache.putIfAbsent(projectId, () => {});
      final phaseMap = proj.putIfAbsent(phase, () => {});
      phaseMap[role] = answers;
      _cache.refresh();

      // Also load submission status
      await _loadSubmissionStatus(projectId, phase, role);
    } catch (e) {
      print('❌ Error loading checklist answers: $e');
    } finally {
      _isLoading[key] = false;
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadRoleAnswersFromStageApi(
    String projectId,
    int phase,
    String role,
  ) async {
    // Find or create stage "Phase {phase}"
    final stageKey = '$projectId-$phase';
    String? stageId = _stageIdCache[stageKey];
    if (stageId == null) {
      final stages = await _stageService.listStages(projectId);
      final phaseName = 'Phase $phase';
      final found = stages.firstWhere(
        (s) =>
            (s['stage_name']?.toString().trim().toLowerCase() ?? '') ==
            phaseName.toLowerCase(),
        orElse: () => {},
      );
      if (found.isNotEmpty) {
        stageId = found['_id']?.toString();
      }
      stageId ??= (await _stageService.createStage(
        projectId,
        name: phaseName,
        description: 'Auto-created for checklist',
      ))['_id']?.toString();
      if (stageId != null) _stageIdCache[stageKey] = stageId;
    }

    if (stageId == null) return {};

    // Find or create checklist for this stage
    String? checklistId = _checklistIdCache[stageKey];
    if (checklistId == null) {
      final list = await _checklistService.listForStage(stageId);
      final checklistName = 'Phase $phase Checklist';
      final existing = list.firstWhere(
        (c) =>
            (c['checklist_name']?.toString().trim().toLowerCase() ?? '') ==
            checklistName.toLowerCase(),
        orElse: () => {},
      );
      if (existing.isNotEmpty) {
        checklistId = existing['_id']?.toString();
      }
      checklistId ??= (await _checklistService.createForStage(
        stageId,
        name: checklistName,
        description: 'Auto-created from app',
        status: 'draft',
      ))['_id']?.toString();
      if (checklistId != null) _checklistIdCache[stageKey] = checklistId;
    }

    if (checklistId == null) return {};

    // Fetch checklist and extract answers for role
    final checklist = await _checklistService.getById(checklistId);
    final answers =
        (checklist['answers'] as Map?)?.cast<String, dynamic>() ?? {};
    final roleMap = (answers[role] as Map?)?.cast<String, dynamic>() ?? {};
    return roleMap.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
  }

  /// Get a specific answer from cache
  Map<String, dynamic>? getAnswers(
    String projectId,
    int phase,
    String role,
    String subQ,
  ) {
    return _cache[projectId]?[phase]?[role]?[subQ];
  }

  /// Get all answers for a role (entire role sheet)
  Map<String, Map<String, dynamic>> getRoleSheet(
    String projectId,
    int phase,
    String role,
  ) {
    return Map<String, Map<String, dynamic>>.from(
      _cache[projectId]?[phase]?[role] ?? {},
    );
  }

  /// Set/update a single answer and save to backend
  Future<void> setAnswer(
    String projectId,
    int phase,
    String role,
    String subQ,
    Map<String, dynamic> ans,
  ) async {
    // Update cache immediately for responsive UI
    final proj = _cache.putIfAbsent(projectId, () => {});
    final phaseMap = proj.putIfAbsent(phase, () => {});
    final roleMap = phaseMap.putIfAbsent(role, () => {});
    roleMap[subQ] = ans;
    _cache.refresh();

    // Debounce save to backend (wait for user to finish typing)
    final saveKey = '$projectId-$phase-$role';
    _pendingSaves[saveKey]?.ignore(); // Cancel pending save if exists

    _pendingSaves[saveKey] = Future.delayed(
      const Duration(milliseconds: 500),
      () => _saveToBackend(projectId, phase, role),
    );
  }

  /// Save all answers for a role to backend
  Future<bool> _saveToBackend(String projectId, int phase, String role) async {
    try {
      final answers = getRoleSheet(projectId, phase, role);
      print(
        '💾 Saving ${answers.length} answers for $role via stage checklist...',
      );

      // Ensure we have a checklistId cached
      final stageKey = '$projectId-$phase';
      if (!_checklistIdCache.containsKey(stageKey)) {
        // Trigger a load to populate caches
        await _loadRoleAnswersFromStageApi(projectId, phase, role);
      }
      final checklistId = _checklistIdCache[stageKey];
      if (checklistId == null) {
        print('❌ No checklistId resolved for project=$projectId phase=$phase');
        return false;
      }

      // Fetch existing answers to merge
      final checklist = await _checklistService.getById(checklistId);
      final existing =
          (checklist['answers'] as Map?)?.cast<String, dynamic>() ?? {};
      existing[role] = answers; // replace role sheet with latest

      await _checklistService.updateChecklist(checklistId, {
        'answers': existing,
      });
      print('✓ Saved checklist answers for $role');
      return true;
    } catch (e) {
      print('❌ Error saving checklist answers: $e');
      return false;
    }
  }

  /// Submit checklist (mark as submitted on backend)
  Future<bool> submitChecklist(String projectId, int phase, String role) async {
    try {
      // First ensure all answers are saved
      await _saveToBackend(projectId, phase, role);

      // Then submit the stage-checklist entity
      final stageKey = '$projectId-$phase';
      if (!_checklistIdCache.containsKey(stageKey)) {
        await _loadRoleAnswersFromStageApi(projectId, phase, role);
      }
      final checklistId = _checklistIdCache[stageKey];
      if (checklistId == null) {
        print('❌ Cannot submit: checklistId not resolved');
        return false;
      }

      await _checklistService.submit(checklistId);
      final success = true;

      if (success) {
        // Update submission cache
        final proj = _submissionCache.putIfAbsent(projectId, () => {});
        final phaseMap = proj.putIfAbsent(phase, () => {});
        phaseMap[role] = {
          'is_submitted': true,
          'submitted_at': DateTime.now(),
          'answer_count': getRoleSheet(projectId, phase, role).length,
        };
        _submissionCache.refresh();
        print('✓ Submitted checklist for $role');
      }

      return success;
    } catch (e) {
      print('Error submitting checklist: $e');
      return false;
    }
  }

  /// Get submission info from cache
  Map<String, dynamic>? submissionInfo(
    String projectId,
    int phase,
    String role,
  ) {
    return _submissionCache[projectId]?[phase]?[role];
  }

  /// Load submission status from backend
  Future<void> _loadSubmissionStatus(
    String projectId,
    int phase,
    String role,
  ) async {
    try {
      final status = await _service.getSubmissionStatus(projectId, phase, role);

      final proj = _submissionCache.putIfAbsent(projectId, () => {});
      final phaseMap = proj.putIfAbsent(phase, () => {});
      phaseMap[role] = status;
      _submissionCache.refresh();
    } catch (e) {
      print('Error loading submission status: $e');
    }
  }

  /// Check if currently loading
  bool isLoading(String projectId, int phase, String role) {
    return _isLoading['$projectId-$phase-$role'] ?? false;
  }

  /// Clear cache for a specific project to force reload from backend
  void clearProjectCache(String projectId) {
    print('🗑️ Clearing cache for project: $projectId');
    _cache.remove(projectId);
    _submissionCache.remove(projectId);
    _cache.refresh();
    _submissionCache.refresh();
  }

  /// Clear all cache
  void clearAllCache() {
    print('🗑️ Clearing all checklist cache');
    _cache.clear();
    _submissionCache.clear();
    _cache.refresh();
    _submissionCache.refresh();
  }
}
