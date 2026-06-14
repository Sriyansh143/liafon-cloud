import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/health_provider.dart';

class HealthDashboardScreen extends StatelessWidget {
  const HealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Simulate data update (in real app, fetch from watch)
              _simulateDataUpdate(healthProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _simulateDataUpdate(healthProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health Score Card
              _buildHealthScoreCard(healthProvider),
              
              const SizedBox(height: 20),
              
              // Vitals Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildVitalCard(
                    context,
                    icon: Icons.favorite,
                    title: 'Heart Rate',
                    value: healthProvider.heartRate > 0 
                        ? '${healthProvider.heartRate}' 
                        : '--',
                    unit: 'bpm',
                    color: Colors.red,
                    status: _getHeartRateStatus(healthProvider.heartRate),
                  ),
                  _buildVitalCard(
                    context,
                    icon: Icons.air,
                    title: 'SpO2',
                    value: healthProvider.spo2 > 0 
                        ? '${healthProvider.spo2}' 
                        : '--',
                    unit: '%',
                    color: Colors.blue,
                    status: _getSpo2Status(healthProvider.spo2),
                  ),
                  _buildVitalCard(
                    context,
                    icon: Icons.thermometer,
                    title: 'Body Temp',
                    value: healthProvider.bodyTemp > 0 
                        ? healthProvider.bodyTemp.toStringAsFixed(1) 
                        : '--',
                    unit: '°C',
                    color: Colors.orange,
                    status: _getTempStatus(healthProvider.bodyTemp),
                  ),
                  _buildVitalCard(
                    context,
                    icon: Icons.directions_walk,
                    title: 'Steps',
                    value: healthProvider.steps > 0 
                        ? '${healthProvider.steps}' 
                        : '--',
                    unit: 'steps',
                    color: Colors.green,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Heart Rate Chart
              _buildSectionTitle('Heart Rate Trend (24h)'),
              const SizedBox(height: 12),
              _buildHeartRateChart(healthProvider),
              
              const SizedBox(height: 24),
              
              // Sleep Analysis
              _buildSectionTitle('Sleep Analysis'),
              const SizedBox(height: 12),
              _buildSleepCard(healthProvider),
              
              const SizedBox(height: 24),
              
              // Calories & Distance
              Row(
                children: [
                  Expanded(child: _buildStatCard('Calories', '${healthProvider.calories.round()}', 'kcal', Icons.local_fire_department, Colors.orange)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Distance', healthProvider.distance > 0 ? '${healthProvider.distance.toStringAsFixed(2)}' : '--', 'km', Icons.location_on, Colors.purple)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHealthScoreCard(HealthProvider provider) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              provider.healthScore >= 80 
                  ? Colors.green 
                  : provider.healthScore >= 60 
                      ? Colors.orange 
                      : Colors.red,
              provider.healthScore >= 80 
                  ? Colors.green.shade300 
                  : provider.healthScore >= 60 
                      ? Colors.orange.shade300 
                      : Colors.red.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Health Score',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${provider.healthScore}/100',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getHealthScoreMessage(provider.healthScore),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.favorite,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVitalCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
    String? status,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildHeartRateChart(HealthProvider provider) {
    // Cache chart spots to avoid regeneration on every build
    final spots = _getCachedHeartRateSpots(provider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Cached spots for heart rate chart - memoized
  List<FlSpot>? _cachedSpots;
  DateTime? _lastCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  List<FlSpot> _getCachedHeartRateSpots(HealthProvider provider) {
    final now = DateTime.now();
    
    // Return cached if still valid
    if (_cachedSpots != null && 
        _lastCacheTime != null && 
        now.difference(_lastCacheTime!) < _cacheDuration) {
      return _cachedSpots!;
    }
    
    // Generate new spots from actual provider data
    final metrics = provider.getMetricsByType('heart_rate');
    final spots = <FlSpot>[];
    
    if (metrics.isEmpty) {
      // Fallback to sample data if no real data
      for (int i = 0; i < 24; i++) {
        final hour = i.toDouble();
        final value = 60 + (i % 5).toDouble() * 5;
        spots.add(FlSpot(hour, value));
      }
    } else {
      // Use actual metric data
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      // Group by hour and average
      Map<int, List<double>> hourlyData = {};
      for (var metric in metrics) {
        if (metric.timestamp.isAfter(startOfDay)) {
          final hour = metric.timestamp.hour;
          hourlyData.putIfAbsent(hour, () => []);
          hourlyData[hour]!.add(metric.value);
        }
      }
      
      // Create spots from averaged hourly data
      for (int hour = 0; hour < 24; hour++) {
        final values = hourlyData[hour];
        double value;
        if (values != null && values.isNotEmpty) {
          value = values.reduce((a, b) => a + b) / values.length;
        } else {
          // Interpolate or use default
          value = 60 + (hour % 5) * 5;
        }
        spots.add(FlSpot(hour.toDouble(), value));
      }
    }
    
    // Cache the result
    _cachedSpots = spots;
    _lastCacheTime = now;
    
    return spots;
  }
  
  Widget _buildSleepCard(HealthProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Last Night\'s Sleep',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSleepScoreColor(provider.sleepScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Score: ${provider.sleepScore}',
                    style: TextStyle(
                      color: _getSleepScoreColor(provider.sleepScore),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSleepStage('Deep', provider.deepSleep.inMinutes, Colors.indigo),
                _buildSleepStage('Light', provider.lightSleep.inMinutes, Colors.blue),
                _buildSleepStage('REM', provider.remSleep.inMinutes, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSleepStage(String label, int minutes, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$minutes',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          'min',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getHeartRateStatus(int bpm) {
    if (bpm == 0) return '';
    if (bpm >= 60 && bpm <= 100) return 'Normal';
    if (bpm >= 50 && bpm < 60 || bpm > 100 && bpm <= 110) return 'Elevated';
    return 'Alert';
  }
  
  String _getSpo2Status(int percentage) {
    if (percentage == 0) return '';
    if (percentage >= 95) return 'Normal';
    if (percentage >= 90) return 'Low';
    return 'Critical';
  }
  
  String _getTempStatus(double temp) {
    if (temp == 0) return '';
    if (temp >= 36.1 && temp <= 37.2) return 'Normal';
    if (temp >= 35.5 && temp < 36.1 || temp > 37.2 && temp <= 38) return 'Elevated';
    return 'Alert';
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'elevated':
      case 'low':
        return Colors.orange;
      case 'alert':
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  Color _getSleepScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
  
  String _getHealthScoreMessage(int score) {
    if (score >= 80) return 'Excellent! Keep it up!';
    if (score >= 60) return 'Good, but room for improvement';
    if (score >= 40) return 'Fair, consider lifestyle changes';
    return 'Needs attention - consult a doctor';
  }
  
  void _simulateDataUpdate(HealthProvider provider) {
    // In real app, this would fetch from connected watch
    provider.updateHeartRate(72 + (DateTime.now().minute % 10));
    provider.updateSpo2(97 + (DateTime.now().minute % 3));
    provider.updateBodyTemp(36.5 + (DateTime.now().minute % 5) / 10);
    provider.updateSteps(5000 + (DateTime.now().minute * 10));
    provider.updateCalories(1200 + (DateTime.now().minute * 5));
    provider.updateDistance(5.5 + (DateTime.now().minute / 10));
  }
}
