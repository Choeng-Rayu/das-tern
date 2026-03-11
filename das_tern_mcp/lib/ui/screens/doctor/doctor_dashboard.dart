import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// TOP CARDS
            Row(
              children: [
                Expanded(
                  child: statCard(
                    "អ្នកជំងឺសរុប",
                    "20",
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: statCard(
                    "អ្នកត្រូវការត្រួតពិនិត្យ",
                    "04",
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ALERT SECTION
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Column(
                children: [
                  /// TITLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            "ស្ថានភាពថ្នាំ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Text(
                          "4 មុខ",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// LIST
                  medicineTile("សុីប៉ាម", "១ម៉ោងមុន"),
                  medicineTile("សុរ", "១ម៉ោងមុន"),
                  medicineTile("ដុល", "១ម៉ោងមុន"),
                  medicineTile("ប៉ារ៉ា", "១ម៉ោងមុន"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// CHART CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                // boxShadow: const [
                //   BoxShadow(color: Colors.black12, blurRadius: 6),
                // ],
              ),
              child: Column(
                children: [
                  const Text(
                    "ក្រាបទិន្នន័យ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        barGroups: [
                          makeGroup(0, 12, 4),
                          makeGroup(1, 15, 6),
                          makeGroup(2, 10, 1),
                          makeGroup(3, 7, 4),
                          makeGroup(4, 15, 1),
                          makeGroup(5, 12, 6),
                          makeGroup(6, 10, 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// STAT CARD
  Widget statCard(String title, String number, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              Icon(icon, color: color),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            number,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// MEDICINE TILE
  Widget medicineTile(String name, String time) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication, color: Colors.red),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text("អត្រាការប្រើប្រាស់ថ្នាំ"),
              ],
            ),
          ),

          Text(time),
        ],
      ),
    );
  }

  /// BAR GROUP
  BarChartGroupData makeGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: Colors.blue, width: 8),
        BarChartRodData(toY: y2, color: Colors.red, width: 8),
      ],
    );
  }
}
