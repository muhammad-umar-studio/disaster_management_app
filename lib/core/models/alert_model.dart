class AlertModel {
  final String id;
  final String type;
  final String title;
  final String location;
  final String severity;
  final String description;
  final String time;
  final double riskScore;
  final List<String> instructions;
  final String evacuationRoute;
  final bool isActive;
  final Map<String, String> aiAnalysis;

  const AlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.location,
    required this.severity,
    required this.description,
    required this.time,
    required this.riskScore,
    required this.instructions,
    required this.evacuationRoute,
    required this.isActive,
    required this.aiAnalysis,
  });
}

class MockAlerts {
  static const List<AlertModel> alerts = [
    AlertModel(
      id: '1',
      type: 'WILDFIRE',
      title: 'Wildfire — Oak Ridge Canyon',
      location: 'Oak Ridge Canyon, CA',
      severity: 'CRITICAL',
      description: 'Rapidly spreading wildfire driven by 45mph NW winds. Estimated 2.5 acres per minute spread rate. Air quality index: Hazardous.',
      time: '14 min ago',
      riskScore: 88,
      isActive: true,
      evacuationRoute: 'Proceed to Safe Haven K via Highway 12. Avoid Route 7 — smoke obstruction reported.',
      instructions: [
        'Evacuate immediately via Highway 12 North',
        'Wear N95 masks if available',
        'Do NOT use Route 7 — smoke obstruction',
        'Proceed to Safe Haven K (1.2 km)',
        'Alert neighbors and assist those with mobility issues',
        'Take emergency kit: water, documents, medications',
      ],
      aiAnalysis: {
        'Wind Dynamics': 'Sustained 45mph winds from NW. Topography creating unpredictable updrafts.',
        'Spread Rate': 'Estimated 2.5 acres per min. Critically fast — evacuation window: 12 min.',
        'Atmospheric': 'Humidity at 8%. Temperature 102°F. Fire weather index: Extreme.',
      },
    ),
    AlertModel(
      id: '2',
      type: 'FLOOD',
      title: 'Flash Flood Warning',
      location: 'Riverside District',
      severity: 'HIGH',
      description: 'Heavy rainfall upstream causing rapid water level rise. River expected to exceed flood stage within 30 minutes.',
      time: '32 min ago',
      riskScore: 74,
      isActive: true,
      evacuationRoute: 'Move to higher ground immediately. Use Bridge Street to reach Hillside Shelter.',
      instructions: [
        'Move to higher ground immediately',
        'Avoid crossing flooded roads',
        'Do not walk in moving water',
        'Proceed to Hillside Shelter via Bridge Street',
        'Turn off electricity at the breaker',
      ],
      aiAnalysis: {
        'Water Level': 'Rising at 0.3 m/hr. Flood stage expected in 28 min at current rate.',
        'Drainage Capacity': 'Storm drains at 94% capacity. Overflow imminent.',
        'Precipitation': '3.2 inches in last hour. Upstream dam releasing controlled flow.',
      },
    ),
    AlertModel(
      id: '3',
      type: 'EARTHQUAKE',
      title: 'Seismic Activity Detected',
      location: 'Central Metro Area',
      severity: 'MEDIUM',
      description: 'Magnitude 4.2 earthquake detected. Aftershocks possible in the next 6 hours. Structural inspection recommended.',
      time: '1 hr ago',
      riskScore: 45,
      isActive: false,
      evacuationRoute: 'Stay in open areas away from buildings. Avoid bridges and overpasses.',
      instructions: [
        'Stay away from damaged structures',
        'Check for gas leaks — do not use open flames',
        'Inspect your home for structural damage',
        'Expect aftershocks — remain cautious',
        'Keep emergency radio accessible',
      ],
      aiAnalysis: {
        'Magnitude': 'M4.2 at depth 12km. Shallow focus — higher surface impact expected.',
        'Aftershock Risk': '73% probability of M3.0+ aftershock within 6 hours.',
        'Infrastructure': 'Bridge integrity monitoring active. 3 overpasses under inspection.',
      },
    ),
    AlertModel(
      id: '4',
      type: 'STORM',
      title: 'Category 2 Hurricane Approach',
      location: 'Coastal Zones A-D',
      severity: 'HIGH',
      description: 'Hurricane approaching coastal zones. Expected landfall in 18 hours with 110 mph sustained winds.',
      time: '2 hr ago',
      riskScore: 81,
      isActive: true,
      evacuationRoute: 'Mandatory evacuation for Zones A & B. Use Interstate 40 West.',
      instructions: [
        'Zones A & B: Mandatory evacuation NOW',
        'Board up windows and secure outdoor items',
        'Stock 72-hour emergency supplies',
        'Identify nearest shelter — Pine Ridge Community Center',
        'Charge all devices and download offline maps',
      ],
      aiAnalysis: {
        'Storm Path': 'Tracking NNW at 14 mph. Landfall window: 16-20 hours from now.',
        'Wind Speed': '110 mph sustained, gusts to 135 mph. Category 2 intensity.',
        'Storm Surge': '8-12 ft surge expected in Zones A & B. Life-threatening coastal flooding.',
      },
    ),
  ];
}
