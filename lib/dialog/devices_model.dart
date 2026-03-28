import 'package:device_player/entity/list_filter_item.dart';

class DevicesModel extends ListFilterItem {
  String brand;
  String model;
  String id;

  DevicesModel(this.brand, this.model, this.id)
      : super(brand + " " + model + " " + id);

  /// 是否为无线连接设备（ID 格式为 ip:port）
  bool get isWireless => RegExp(r'^\d+\.\d+\.\d+\.\d+:\d+$').hasMatch(id);
}
