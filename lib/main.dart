import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const QueueTimeApp());
}

class QueueTimeApp extends StatelessWidget {
  const QueueTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QueueTime',
      theme: ThemeData(
        primaryColor: const Color(0xFF4A90E2),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(secondary: const Color(0xFFF5A623)),
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        fontFamily: 'Poppins',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 36),
            elevation: 5,
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreenContent(),
    const MapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Karte'),
        ],
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with SingleTickerProviderStateMixin {
  String locationText = 'Standort noch nicht ermittelt';
  bool firebaseInitialized = false;
  bool isLoading = false;
  final TextEditingController _waitTimeController = TextEditingController();

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _checkFirebase();

    _buttonAnimationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.05)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_buttonAnimationController);
  }

  @override
  void dispose() {
    _waitTimeController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkFirebase() async {
    setState(() {
      firebaseInitialized = Firebase.apps.isNotEmpty;
    });
  }

  Future<void> _getAndSaveQueueTime() async {
    try {
      _buttonAnimationController.forward().then((_) => _buttonAnimationController.reverse());
      setState(() => isLoading = true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationText = 'Location services disabled';
          isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            locationText = 'Location permission denied';
            isLoading = false;
          });
          return;
        }
      }

      Position pos = await Geolocator.getCurrentPosition();
      int waitMinutes = int.tryParse(_waitTimeController.text) ?? 15;

      await FirebaseFirestore.instance.collection('queue_times').add({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'wait_time_minutes': waitMinutes,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        locationText =
            'Lat: ${pos.latitude.toStringAsFixed(4)}, Lon: ${pos.longitude.toStringAsFixed(4)}\nWartezeit: $waitMinutes min gespeichert!';
        isLoading = false;
        _waitTimeController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standort & Wartezeit erfolgreich gespeichert!'),
          backgroundColor: Color(0xFF4A90E2),
        ),
      );
    } catch (e) {
      setState(() {
        locationText = 'Fehler: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildQueueList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('queue_times')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text('Noch keine Daten');

        return ListView.builder(
          shrinkWrap: true,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFF4A90E2)),
                title: Text(
                    'Lat: ${data['latitude']?.toStringAsFixed(4)}, Lon: ${data['longitude']?.toStringAsFixed(4)}'),
                subtitle: Text(
                    'Wartezeit: ${data['wait_time_minutes']} min\n${timestamp != null ? timestamp.toLocal().toString().split('.')[0] : ''}'),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QueueTime Home')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Firebase initialized: $firebaseInitialized',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _waitTimeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Wartezeit in Minuten',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      locationText,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ScaleTransition(
                            scale: _buttonAnimation,
                            child: ElevatedButton(
                              onPressed: _getAndSaveQueueTime,
                              child: const Text('Standort & Wartezeit speichern'),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Letzte Einträge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(child: _buildQueueList()),
          ],
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  Color _getMarkerColor(int waitTime) {
    if (waitTime <= 10) return Colors.green;
    if (waitTime <= 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QueueTime Karte')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('queue_times').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Noch keine Standorte'));

          final markers = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final waitTime = data['wait_time_minutes'] ?? 0;
            return Marker(
              point: LatLng(data['latitude'], data['longitude']),
              width: 80,
              height: 80,
              builder: (ctx) => TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      Icons.location_on,
                      color: _getMarkerColor(waitTime),
                      size: 40,
                    ),
                  );
                },
              ),
            );
          }).toList();

          final bounds = LatLngBounds.fromPoints(markers.map((m) => m.point).toList());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.fitBounds(bounds, options: const FitBoundsOptions(padding: EdgeInsets.all(50)));
          });

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: bounds.center,
              zoom: 6,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
