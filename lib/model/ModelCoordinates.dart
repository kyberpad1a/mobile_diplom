class ModelCoordinates {
 final double lat;
 final double long;

const ModelCoordinates({
   required this.lat,
   required this.long,
 });
}

class MoscowLocation extends ModelCoordinates {
 const MoscowLocation({
   super.lat = 55.7522200,
   super.long = 37.6155600,
 });
}