import 'package:mobile_diplom/model/ModelCoordinates.dart';

abstract class AppLocation {
 Future<ModelCoordinates> getCurrentLocation();

 Future<bool> requestPermission();

 Future<bool> checkPermission();
}
