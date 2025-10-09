import 'package:device_player/entity/list_filter_item.dart';

class DevicesModel extends ListFilterItem {
  String brand;
  String model;
  String id;

  DevicesModel(this.brand, this.model, this.id)
      : super(brand + " " + model + " " + id);
}
