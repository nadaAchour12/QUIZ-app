
import 'package:get/get.dart';

class AuthController extends GetxController {
  final RxString userName = "Guest".obs;

  String getUserName() {
    return userName.value;
  }
}
