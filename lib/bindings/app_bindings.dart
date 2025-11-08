import 'package:get/get.dart';
import '../controllers/projects_controller.dart';
import '../controllers/team_controller.dart';
import '../controllers/admin_dashboard_ui_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProjectsController>(() => ProjectsController(), fenix: true);
    Get.lazyPut<TeamController>(() => TeamController(), fenix: true);
    Get.lazyPut<AdminDashboardUIController>(() => AdminDashboardUIController(), fenix: true);
  }
}