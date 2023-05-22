import '../model/ModelCoordinates.dart';
import 'app_location.dart';
import 'package:geolocator/geolocator.dart';

class LocationService implements AppLocation {
  final defLocation = const MoscowLocation();
  ///Получение текущей локации пользователя
  @override
  Future<ModelCoordinates> getCurrentLocation() async {
    return Geolocator.getCurrentPosition().then((value) {
      return ModelCoordinates(lat: value.latitude, long: value.longitude);
    }).catchError(
      (_) => defLocation,
    );
  }
  ///Запрос разрешения на отслеживание геолокации
  @override
  Future<bool> requestPermission() {
    return Geolocator.requestPermission()
        .then((value) =>
            value == LocationPermission.always ||
            value == LocationPermission.whileInUse)
        .catchError((_) => false);
  }
  ///Проверка состояния разрешения отслеживания
  @override
  Future<bool> checkPermission() {
    return Geolocator.checkPermission()
        .then((value) =>
            value == LocationPermission.always ||
            value == LocationPermission.whileInUse)
        .catchError((_) => false);
  }
}