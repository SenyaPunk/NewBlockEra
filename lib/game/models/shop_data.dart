import 'package:flutter/material.dart';

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String type;
  final Map<String, dynamic> properties;
  bool isPurchased;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.properties,
    this.isPurchased = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'type': type,
    'properties': properties,
    'isPurchased': isPurchased,
  };

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    price: json['price'],
    type: json['type'],
    properties: Map<String, dynamic>.from(json['properties']),
    isPurchased: json['isPurchased'] ?? false,
  );
}

class PlayerData {
  Color playerColor;
  String currentSkinId;
  String skinType;
  String imagePath;

  PlayerData({
    required this.playerColor,
    required this.currentSkinId,
    required this.skinType,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'playerColor': playerColor.value,
    'currentSkinId': currentSkinId,
    'skinType': skinType,
    'imagePath': imagePath,
  };

  factory PlayerData.fromJson(Map<String, dynamic> json) => PlayerData(
    playerColor: Color(json['playerColor']),
    currentSkinId: json['currentSkinId'],
    skinType: json['skinType'] ?? 'color',
    imagePath: json['imagePath'] ?? '',
  );
}