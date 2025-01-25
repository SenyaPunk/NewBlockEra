import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'settings_page.dart';
import 'shop_page.dart';
import 'game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: MainMenuPage(),
    );
  }
}

class MainMenuPage extends StatefulWidget {
  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int highScore = 0;
  int coins = 0;

  @override
  void initState() {
    super.initState();
    loadGameData();
  }

  Future<void> loadGameData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/gamedata.json');
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = json.decode(contents);
        setState(() {
          highScore = data['highScore'] ?? 0;
          coins = data['coins'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading game data: $e');
    }
  }

  Future<void> saveGameData(int newHighScore, int newCoins) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/gamedata.json');
      await file.writeAsString(json.encode({
        'highScore': newHighScore,
        'coins': newCoins,
      }));
    } catch (e) {
      print('Error saving game data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 50),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ).createShader(bounds),
                        child: Text(
                          'NewBlockEra',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 49,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Рекорд: $highScore',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 20),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Монеты: $coins',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 60),
                      Container(
                        width: 200,
                        child: Column(
                          children: [
                            _buildMenuButton(
                              'Играть',
                              Colors.blue[700]!,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => GamePage(
                                    currentHighScore: highScore,
                                    currentCoins: coins,
                                    onGameEnd: (newHighScore, newCoins) async {
                                      if (newHighScore > highScore || newCoins > coins) {
                                        setState(() {
                                          highScore = newHighScore > highScore ? newHighScore : highScore;
                                          coins = newCoins;
                                        });
                                        await saveGameData(highScore, coins);
                                      }
                                    },
                                  )),
                                );
                              },
                            ),
                            SizedBox(height: 16),
                            _buildMenuButton(
                              'Настройки',
                              Colors.green[700]!,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SettingsPage()),
                                );
                              },
                            ),
                            SizedBox(height: 16),
                            _buildMenuButton(
                              'Магазин',
                              Colors.green[700]!,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShopPage(
                                      currentCoins: coins,
                                      onCoinsUpdated: (newCoins) {
                                        setState(() {
                                          coins = newCoins;
                                        });
                                        saveGameData(highScore, coins);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 16),
                            _buildMenuButton(
                              'Выход',
                              Colors.red[700]!,
                              () {
                                exit(0);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Арсений Кубинский',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'v 1.0.2',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
          shadowColor: color.withOpacity(0.5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}