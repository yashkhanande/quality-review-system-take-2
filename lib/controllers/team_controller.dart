import 'package:get/get.dart';
import '../models/team_member.dart';

class TeamController extends GetxController {
  final RxList<TeamMember> members = <TeamMember>[].obs;

  void loadInitial(List<TeamMember> initial) {
    members.assignAll(initial);
  }

  void addMember(TeamMember m) => members.insert(0, m);
  void updateMember(String id, TeamMember updated) {
    final idx = members.indexWhere((e) => e.id == id);
    if (idx != -1) members[idx] = updated;
  }

  void deleteMember(String id) => members.removeWhere((e) => e.id == id);

  // Simple filters stored as reactive values
  final RxList<String> selectedRoles = <String>[].obs;
  final RxList<String> selectedStatuses = <String>[].obs;

  List<TeamMember> get filtered {
    // Work on a plain List derived from the reactive members to make filtering predictable.
    List<TeamMember> list = members.toList();
    if (selectedRoles.isNotEmpty) {
      list = list.where((m) => selectedRoles.contains(m.role)).toList();
    }
    if (selectedStatuses.isNotEmpty) {
      list = list.where((m) => selectedStatuses.contains(m.status)).toList();
    }
    return list;
  }

  void clearFilters() {
    selectedRoles.clear();
    selectedStatuses.clear();
  }
}
