import 'package:flutter/material.dart';
import 'package:gestion_locative/config/constants.dart';
import 'package:gestion_locative/data/repositories/maison_repository.dart';
import 'package:gestion_locative/data/repositories/paiement_repository.dart';
import 'package:gestion_locative/presentation/widgets/common/custom_drawer.dart';
import 'package:gestion_locative/presentation/widgets/common/loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final MaisonRepository _maisonRepository = MaisonRepository();
  final PaiementRepository _paiementRepository = PaiementRepository();
  final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);

  bool _isLoading = true;

  // Statistiques générales
  int _totalMaisons = 0;
  int _totalChambres = 0;
  int _totalLocataires = 0;
  double _occupationRate = 0;

  // Statistiques financières
  double _totalMontantPaye = 0;
  double _totalMontantDu = 0;
  int _totalPaiementsEnRetard = 0;

  // Données pour les graphiques
  List<MapEntry<String, num>> _occupationByMaison = [];
  List<MapEntry<String, double>> _revenueByMonth = [];
  List<PieChartSectionData> _paiementStatusData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les statistiques générales
      final maisonStats = await _maisonRepository.getMaisonStats();
      _totalMaisons = maisonStats['maisonCount'];
      _totalChambres = maisonStats['chambreCount'];
      _totalLocataires = maisonStats['locataireCount'];
      _occupationRate = double.tryParse(maisonStats['occupationRate']) ?? 0;

      // Charger les statistiques financières
      final paiementStats = await _paiementRepository.getPaiementStats();
      _totalMontantPaye = paiementStats['totalPaye'].toDouble();
      _totalMontantDu = paiementStats['totalEnCours'].toDouble();
      _totalPaiementsEnRetard = paiementStats['nombreRetard'];

      // Préparer les données pour le graphique d'occupation par maison
      final maisonsWithStats = await _maisonRepository.getMaisonsWithStats();
      _occupationByMaison =
          maisonsWithStats.map((m) {
            final chambreCount = m['nombre_chambres'] as int;
            final locataireCount = m['nombre_locataires'] as int;
            final rate =
                chambreCount > 0 ? (locataireCount / chambreCount) * 100 : 0;
            return MapEntry(m['nom'] as String, rate);
          }).toList();

      // Générer des données fictives pour les revenus mensuels (exemple)
      _revenueByMonth = _generateMonthlyRevenueData();

      // Préparation des données pour le graphique en camembert des statuts de paiement
      _paiementStatusData = [
        PieChartSectionData(
          title: 'Payés',
          value: _totalMontantPaye,
          color: AppColors.success,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        PieChartSectionData(
          title: 'En cours',
          value: _totalMontantDu,
          color: AppColors.warning,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        PieChartSectionData(
          title: 'En retard',
          value: _totalPaiementsEnRetard * 25000, // Estimation approximative
          color: AppColors.danger,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // Génère des données fictives pour les revenus mensuels
  List<MapEntry<String, double>> _generateMonthlyRevenueData() {
    final now = DateTime.now();
    final result = <MapEntry<String, double>>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthName = DateFormat('MMM').format(month);

      // Valeur fictive basée sur le nombre de locataires et un montant moyen
      double value = _totalLocataires * 25000 * (0.8 + (i * 0.05));

      result.add(MapEntry(monthName, value));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Chargement des analytiques...')
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader('Vue d\'ensemble', Icons.dashboard),
                      const SizedBox(height: 8),
                      _buildStatisticsCards(),
                      const SizedBox(height: 24),

                      _buildCardHeader('Taux d\'occupation', Icons.home_work),
                      const SizedBox(height: 8),
                      _buildOccupationChart(),
                      const SizedBox(height: 24),

                      _buildCardHeader(
                        'Revenus mensuels',
                        Icons.monetization_on,
                      ),
                      const SizedBox(height: 8),
                      _buildRevenueChart(),
                      const SizedBox(height: 24),

                      _buildCardHeader(
                        'Répartition des paiements',
                        Icons.pie_chart,
                      ),
                      const SizedBox(height: 8),
                      _buildPaiementStatusChart(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildCardHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Maisons',
          _totalMaisons.toString(),
          Icons.home,
          AppColors.primary,
        ),
        _buildStatCard(
          'Chambres',
          '$_totalChambres ($_totalLocataires occupées)',
          Icons.bedroom_parent,
          AppColors.info,
        ),
        _buildStatCard(
          'Occupation',
          '${_occupationRate.toStringAsFixed(1)}%',
          Icons.people,
          AppColors.success,
        ),
        _buildStatCard(
          'Paiements en retard',
          _totalPaiementsEnRetard.toString(),
          Icons.warning,
          AppColors.danger,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupationChart() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child:
          _occupationByMaison.isEmpty
              ? const Center(child: Text('Aucune donnée disponible'))
              : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${_occupationByMaison[groupIndex].key}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _occupationByMaison.length) {
                            return const SizedBox.shrink();
                          }
                          // Afficher le nom de la maison abrégé
                          final name = _occupationByMaison[value.toInt()].key;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              name.length > 6
                                  ? '${name.substring(0, 6)}...'
                                  : name,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        reservedSize: 38,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    _occupationByMaison.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _occupationByMaison[index].value.toDouble(),
                          color: _getBarColor(
                            _occupationByMaison[index].value.toDouble(),
                          ),
                          width: 22,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Color _getBarColor(double value) {
    if (value < 30) return AppColors.danger;
    if (value < 70) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child:
          _revenueByMonth.isEmpty
              ? const Center(child: Text('Aucune donnée disponible'))
              : LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _revenueByMonth.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _revenueByMonth[value.toInt()].key,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        reservedSize: 38,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 50000,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            formatter.format(value),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        _revenueByMonth.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          _revenueByMonth[index].value,
                        ),
                      ),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final month = _revenueByMonth[spot.x.toInt()].key;
                          return LineTooltipItem(
                            '$month\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '${formatter.format(spot.y)} FCFA',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildPaiementStatusChart() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child:
          _paiementStatusData.isEmpty
              ? const Center(child: Text('Aucune donnée disponible'))
              : Column(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 40,
                        sections: _paiementStatusData,
                        sectionsSpace: 2,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Payés', AppColors.success),
                      const SizedBox(width: 16),
                      _buildLegendItem('En cours', AppColors.warning),
                      const SizedBox(width: 16),
                      _buildLegendItem('En retard', AppColors.danger),
                    ],
                  ),
                ],
              ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
