import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'game/models/shop_data.dart';

class ShopPage extends StatefulWidget {
  final int currentCoins;
  final Function(int) onCoinsUpdated;

  ShopPage({
    required this.currentCoins,
    required this.onCoinsUpdated,
  });

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ShopItem> shopItems = [];
  late PlayerData playerData;
  int coins = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    coins = widget.currentCoins;
    _loadShopData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShopData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final shopFile = File('${directory.path}/shop_data.json');
      final playerFile = File('${directory.path}/player_data.json');

      // Initialize default shop items
      shopItems = [
        ShopItem(
          id: 'blue_default',
          name: 'База',
          description: 'Классический синий куб - ваш первый скин',
          price: 0,
          type: 'skin',
          properties: {
            'color': Colors.blue.value,
            'skinType': 'color'
          },
          isPurchased: true,
        ),
        ShopItem(
          id: 'green_skin',
          name: 'Green куб',
          description: 'Зелененький рядовой',
          price: 20,
          type: 'skin',
          properties: {
            'color': Colors.green.value,
            'skinType': 'color'
          },
        ),
        ShopItem(
          id: 'image_skin',
          name: 'DarkCat',
          description: 'Четкий кот',
          price: 100,
          type: 'skin',
          properties: {
            'imagePath': 'assets/skin/skin1.jpg',
            'skinType': 'image'
          },
        ),
      ];

      if (await shopFile.exists()) {
        final shopData = json.decode(await shopFile.readAsString());
        final loadedItems = shopData.map<ShopItem>((item) => ShopItem.fromJson(item)).toList();
        
        // Update existing items with saved purchase status
        for (var loadedItem in loadedItems) {
          final index = shopItems.indexWhere((item) => item.id == loadedItem.id);
          if (index != -1) {
            shopItems[index].isPurchased = loadedItem.isPurchased;
          }
        }
      }

      if (!await playerFile.exists()) {
        playerData = PlayerData(
          playerColor: Colors.blue,
          currentSkinId: 'blue_default',
          skinType: 'color',
          imagePath: '',
        );
      } else {
        final data = json.decode(await playerFile.readAsString());
        playerData = PlayerData.fromJson(data);
      }

      await _saveShopData();
      setState(() {});
    } catch (e) {
      print('Error loading shop data: $e');
    }
  }

  Future<void> _saveShopData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final shopFile = File('${directory.path}/shop_data.json');
      final playerFile = File('${directory.path}/player_data.json');

      await shopFile.writeAsString(json.encode(
        shopItems.map((item) => item.toJson()).toList(),
      ));
      await playerFile.writeAsString(json.encode(playerData.toJson()));
    } catch (e) {
      print('Error saving shop data: $e');
    }
  }

  Future<void> _purchaseItem(ShopItem item) async {
    if (coins >= item.price && !item.isPurchased) {
      setState(() {
        coins -= item.price;
        item.isPurchased = true;
      });
      widget.onCoinsUpdated(coins);
      await _saveShopData();
    }
  }

  void _selectSkin(ShopItem item) async {
    if (item.isPurchased) {
      setState(() {
        playerData.currentSkinId = item.id;
        if (item.properties['skinType'] == 'color') {
          playerData.playerColor = Color(item.properties['color']);
          playerData.skinType = 'color';
          playerData.imagePath = '';
        } else if (item.properties['skinType'] == 'image') {
          playerData.skinType = 'image';
          playerData.imagePath = item.properties['imagePath'];
        }
      });
      await _saveShopData();
    }
  }

  Widget _buildShopItem(ShopItem item) {
    bool isSelected = playerData.currentSkinId == item.id;
    double cardSize = MediaQuery.of(context).size.width * 0.4;

    return Container(
      width: cardSize,
      height: cardSize * 1.4,
      margin: EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        color: Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected ? BorderSide(color: Colors.yellow, width: 2) : BorderSide.none,
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: cardSize * 0.4,
                height: cardSize * 0.4,
                decoration: BoxDecoration(
                  color: item.properties['skinType'] == 'color'
                      ? Color(item.properties['color'])
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white24,
                    width: 1,
                  ),
                ),
                child: item.properties['skinType'] == 'image'
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.asset(
                          item.properties['imagePath'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.broken_image,
                              color: Colors.red,
                              size: cardSize * 0.3,
                            );
                          },
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              if (!item.isPurchased)
                ElevatedButton.icon(
                  onPressed: coins >= item.price
                      ? () => _purchaseItem(item)
                      : null,
                  icon: Icon(Icons.monetization_on, size: 16),
                  label: Text('${item.price}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    minimumSize: Size(100, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _selectSkin(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.green : Colors.blue,
                    minimumSize: Size(100, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    isSelected ? 'Выбран' : 'Выбрать',
                    style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 255, 255, 255)), 
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Магазин',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 59, 59, 102),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  '$coins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: Color(0xFF1a1a2e),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Скины'),
                Tab(text: 'Улучшения'),
                Tab(text: 'Валюта'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Skins tab
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.start,
                children: shopItems
                    .where((item) => item.type == 'skin')
                    .map(_buildShopItem)
                    .toList(),
              ),
            ),
            // Upgrades tab
            Center(
              child: Text(
                'Улучшения скоро будут доступны',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            // Currency tab
            Center(
              child: Text(
                'Валюта скоро будет доступна',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}