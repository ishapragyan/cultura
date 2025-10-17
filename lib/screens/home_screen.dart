import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/tts_service.dart';
import '../models/city_info.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CityInfo? _currentCityInfo;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    final locationService = context.read<LocationService>();
    final apiService = context.read<ApiService>();
    final historyService = context.read<HistoryService>();

    await locationService.initializeLocation();

    if (locationService.currentCity != 'Unknown') {
      // Fetch cultural info
      final cityInfo = await apiService.getCulturalInfo(
        locationService.currentCity,
        locationService.currentState,
      );

      if (cityInfo != null) {
        setState(() {
          _currentCityInfo = cityInfo;
        });

        // Add to history
        await historyService.addVisit(
          locationService.currentCity,
          locationService.currentState,
          ['cultural', 'exploration'],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final apiService = context.watch<ApiService>();
    final ttsService = context.watch<TtsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cultura'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeApp,
          ),
        ],
      ),
      body: _buildBody(locationService, apiService, ttsService),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody(LocationService location, ApiService api, TtsService tts) {
    if (location.isLoading) {
      return _buildLoading();
    }

    if (location.error.isNotEmpty) {
      return _buildError(location.error);
    }

    if (api.isLoading) {
      return _buildLoading();
    }

    if (api.error.isNotEmpty) {
      return _buildError(api.error);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationCard(location),
          const SizedBox(height: 20),
          _buildCulturalInfoCard(api, tts),
          const SizedBox(height: 20),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Discovering your cultural surroundings...'),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeApp,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(LocationService location) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Location',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    location.currentCity,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    location.currentState,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCulturalInfoCard(ApiService api, TtsService tts) {
    if (_currentCityInfo == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Cultural information not available',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'About ${_currentCityInfo!.cityName}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: Icon(
                    tts.ttsState == TtsState.playing
                        ? Icons.volume_up
                        : Icons.volume_down,
                  ),
                  onPressed: () {
                    tts.speak(_currentCityInfo!.culturalInfo ?? 'No information');
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currentCityInfo!.culturalInfo ?? 'No cultural information available.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildActionCard(
          Icons.auto_stories,
          'Folk Stories',
          Colors.purple,
              () => Navigator.pushNamed(context, '/stories'),
        ),
        _buildActionCard(
          Icons.translate,
          'Phrasebook',
          Colors.blue,
              () => Navigator.pushNamed(context, '/phrases'),
        ),
        _buildActionCard(
          Icons.history,
          'My Journey',
          Colors.green,
              () => Navigator.pushNamed(context, '/history'),
        ),
        _buildActionCard(
          Icons.settings,
          'Settings',
          Colors.orange,
              () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_stories),
          label: 'Stories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.translate),
          label: 'Phrases',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/home');
            break;
          case 1:
            Navigator.pushNamed(context, '/stories');
            break;
          case 2:
            Navigator.pushNamed(context, '/phrases');
            break;
          case 3:
            Navigator.pushNamed(context, '/history');
            break;
        }
      },
    );
  }
}