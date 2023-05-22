import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_diplom/model/ModelCoordinates.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart' as mapkit;
import 'package:http/http.dart' as http;
import 'orders.dart';
import 'utility/location_service.dart';
import 'package:yandex_geocoder/yandex_geocoder.dart';
import 'dart:convert';

class orderMap extends StatefulWidget {
  const orderMap({super.key, required this.iduser});
  static const routeName = "/orderMap";
  final int iduser;
  ///Инициализация состояния окна
  @override
  State<orderMap> createState() => _orderMapState();
}

class _orderMapState extends State<orderMap> {
  final YandexGeocoder geo =
      YandexGeocoder(apiKey: 'ae37c6c9-5a51-4d23-8c61-b93ce422d412');
  List data = [];
  List data2 = [];
  GeocodeResponse _latLong = new GeocodeResponse();
  final mapControllerCompleter = Completer<mapkit.YandexMapController>();
  late final List<mapkit.MapObject> mapObjects = [];
  final TextEditingController _textController = TextEditingController();
  ///Сборка виджетов текущего окна
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказ'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: mapkit.YandexMap(
              onMapCreated: (controller) {
                mapControllerCompleter.complete(controller);
                controller.toggleUserLayer(
                    visible: true, autoZoomEnabled: true);
              },
              mapObjects: mapObjects,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Адрес',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () async {
                int response = await UpdateStatus();
                if (response == 204) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Заказ доставлен'),
                  ));
                  sleep(Duration(seconds: 2));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => orders(iduser: widget.iduser),
                    ),
                  );
                }
              },
              child: Text('Подтвердить доставку'),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
  ///Инициализация Состояния окна и заполнение данных заказа
  @override
  void initState() {
    super.initState();
    _initPermission().ignore();
    getOrderData();
  }
  ///Получение разрешения на отслеживание геолокации
  Future<void> _initPermission() async {
    if (!await LocationService().checkPermission()) {
      await LocationService().requestPermission();
    }
    await _fetchCurrentLocation();
  }

  /// Получение текущей геопозиции пользователя
  Future<void> _fetchCurrentLocation() async {
    ModelCoordinates location;
    const defLocation = MoscowLocation();
    try {
      location = await LocationService().getCurrentLocation();
      final mapkit.PlacemarkMapObject startPlacemark =
          mapkit.PlacemarkMapObject(
              mapId: mapkit.MapObjectId('start_placemark'),
              point: mapkit.Point(
                  latitude: location.lat, longitude: location.long),
              icon: mapkit.PlacemarkIcon.single(mapkit.PlacemarkIconStyle(
                  image: mapkit.BitmapDescriptor.fromAssetImage(
                      'lib/assets/route_start.png'),
                  scale: 1.5)));
    } catch (_) {
      location = defLocation;
    }
    _moveToCurrentLocation(location);
  }
  ///Переход камеры к текущей геолокации пользователя
  Future<void> _moveToCurrentLocation(
    ModelCoordinates appLatLong,
  ) async {
    (await mapControllerCompleter.future).moveCamera(
      animation: const mapkit.MapAnimation(
          type: mapkit.MapAnimationType.linear, duration: 1),
      mapkit.CameraUpdate.newCameraPosition(
        mapkit.CameraPosition(
          target: mapkit.Point(
            latitude: appLatLong.lat,
            longitude: appLatLong.long,
          ),
          zoom: 12,
        ),
      ),
    );
  }
  ///Получение данных заказа
  Future<String> getOrderData() async {
    var map = new Map<String, dynamic>();
    
    map['user_iduser'] = widget.iduser;
    var response = await http.post(
        Uri.parse("https://192.168.0.109:44317/api/getorderdata"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json"
        },
        body: json.encode(map));

    data = json.decode(response.body);
    setState(() {
          _textController.text =
        data[0]['shipping_address'] + ', ' + data[0]['shipping_apartment'].toString();
    });

    _latLong = await geo.getGeocode(
      GeocodeRequest(
        geocode: AddressGeocode(
          address: data[0]['shipping_address'].toString(),
        ),
      ),
    );

    final mapkit.PlacemarkMapObject endPlacemark = mapkit.PlacemarkMapObject(
        mapId: mapkit.MapObjectId('end_placemark'),
        point: mapkit.Point(
            latitude: _latLong.firstPoint!.latitude,
            longitude: _latLong.firstPoint!.longitude),
        icon: mapkit.PlacemarkIcon.single(mapkit.PlacemarkIconStyle(
            image: mapkit.BitmapDescriptor.fromAssetImage(
                'lib/assets/route_start.png'),
            scale: 2)));
    setState(() {
      mapObjects.insert(0, endPlacemark);
    });

    return "Success";
  }
  ///Обновление статуса доставки заказа
  Future<int> UpdateStatus() async {
    var map = new Map<String, dynamic>();
    map['idshipping'] = data[0]['idshipping'];
    var response = await http.put(
        Uri.parse("https://192.168.0.109:44317/api/updatestatus"),
        headers: {
          "accept": "application/json",
          "content-type": "application/json"
        },
        body: jsonEncode(map));

    return response.statusCode;
  }
}
