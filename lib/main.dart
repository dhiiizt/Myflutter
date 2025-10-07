import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFFFF4E4E), // 🔴 Warna utama
      onPrimary: Colors.white,
      secondary: const Color(0xFFFF7373),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF222222),
      surfaceContainerHighest: const Color(0xFFFFFFFF),
      background: const Color(0xFFFFF5F5), // 🎀 Background lembut
      onBackground: const Color(0xFF444444),
      error: Colors.red.shade400,
      onError: Colors.white,
      primaryContainer: const Color(0xFFFFE9E9),
      onPrimaryContainer: const Color(0xFF222222),
    );

    return MaterialApp(
      title: 'Neru Injector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onBackground,
          elevation: 0,
        ),
        cardColor: colorScheme.surface,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            elevation: 4,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF555555),
          ),
        ),
        useMaterial3: true,
      ),
      home: const CollapsiblePage(),
    );
  }
}

class CollapsiblePage extends StatelessWidget {
  const CollapsiblePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> sliderImages = [
      'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg',
      'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Alpha_(Revenant_of_Roses).jpg',
      'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Alucard_(Obsidian_Blade).jpg',
    ];

    final List<Map<String, String>> features = [
      {
        'title': 'Unlock All Skins',
        'subtitle': 'All skin role unlock',
        'icon':
            'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg'
      },
      {
        'title': 'Unlock Emotes',
        'subtitle': '33 Available Emotes',
        'icon':
            'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg'
      },
      {
        'title': 'Unlock Recalls',
        'subtitle': '25 Available Recalls',
        'icon':
            'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg'
      },
      {
        'title': 'Drone View',
        'subtitle': 'Vertical/Horizontal Available',
        'icon':
            'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg'
      },
      {
        'title': 'Configuration',
        'subtitle': 'Games mode api',
        'icon':
            'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg'
      },
    ];

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colorScheme.primary),
              child: const Text(
                'Neru Tools Menu',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('About'),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // 🔹 AppBar Collapsible
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            backgroundColor: colorScheme.primaryContainer,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: colorScheme.onBackground),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.shopping_bag_outlined,
                    color: colorScheme.primary),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cart opened')),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colorScheme.onBackground),
                onSelected: (value) {
                  if (value == 'permission') {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                        title: Text(
                          'Permission',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        message: const Text(
                          'Pilih satu izin yang ingin digunakan',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        actions: [
                          CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Default permission dipilih')),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.settings,
                                    size: 20, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Default Permission',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Shizuku permission dipilih')),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield,
                                    size: 20, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Shizuku Permission',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else if (value == 'about') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App by EsaNeru')),
                    );
                  } else if (value == 'exit') {
                    SystemNavigator.pop();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'permission', child: Text('Permission')),
                  PopupMenuItem(value: 'about', child: Text('About')),
                  PopupMenuItem(value: 'exit', child: Text('Exit')),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'NERU Injector',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Image.network(
                sliderImages[0],
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🔹 Carousel Slider
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 180.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  aspectRatio: 16 / 9,
                  autoPlayInterval: const Duration(seconds: 4),
                ),
                items: sliderImages.map((item) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      item,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 🔹 List Fitur
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final feature = features[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: colorScheme.surface,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(feature['icon']!),
                        radius: 26,
                      ),
                      title: Text(
                        feature['title']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        feature['subtitle']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: colorScheme.primary,
                              content: Text(
                                'Opening ${feature['title']}...',
                                style: TextStyle(color: colorScheme.onPrimary),
                              ),
                            ),
                          );
                        },
                        child: const Text('OPEN'),
                      ),
                    ),
                  ),
                );
              },
              childCount: features.length,
            ),
          ),
        ],
      ),
    );
  }
}
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
