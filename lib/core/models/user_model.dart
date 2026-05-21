class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String location;
  final String bloodType;
  final List<EmergencyContact> emergencyContacts;
  final List<String> medicalConditions;
  final int safetyScore;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.location,
    required this.bloodType,
    required this.emergencyContacts,
    required this.medicalConditions,
    required this.safetyScore,
  });

  static UserModel mock = UserModel(
    id: '1',
    name: 'Alex Morgan',
    email: 'alex.morgan@aegis.com',
    avatarUrl: '',
    location: 'Oak Ridge Canyon, CA',
    bloodType: 'O+',
    safetyScore: 92,
    medicalConditions: ['Mild Asthma'],
    emergencyContacts: [
      EmergencyContact(name: 'Dr. Sarah', relation: 'Physician', phone: '+1 (555) 012-3456', avatarInitial: 'S'),
      EmergencyContact(name: 'Mark', relation: 'Family', phone: '+1 (555) 789-0123', avatarInitial: 'M'),
      EmergencyContact(name: 'Lisa Chen', relation: 'Neighbor', phone: '+1 (555) 234-5678', avatarInitial: 'L'),
    ],
  );
}

class EmergencyContact {
  final String name;
  final String relation;
  final String phone;
  final String avatarInitial;

  const EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
    required this.avatarInitial,
  });
}

class SafeZone {
  final String id;
  final String name;
  final String type;
  final double distance;
  final int capacity;
  final int currentOccupancy;
  final String status;
  final String address;

  const SafeZone({
    required this.id,
    required this.name,
    required this.type,
    required this.distance,
    required this.capacity,
    required this.currentOccupancy,
    required this.status,
    required this.address,
  });

  double get occupancyPercent => currentOccupancy / capacity;
}

class MockSafeZones {
  static const List<SafeZone> zones = [
    SafeZone(
      id: '1', name: 'Safe Haven 4', type: 'shelter',
      distance: 1.2, capacity: 500, currentOccupancy: 340,
      status: 'ACCEPTING', address: '1400 Pine Ridge Rd',
    ),
    SafeZone(
      id: '2', name: 'Med Center Alpha', type: 'hospital',
      distance: 2.8, capacity: 200, currentOccupancy: 180,
      status: 'LIMITED', address: '800 Healthcare Blvd',
    ),
    SafeZone(
      id: '3', name: 'City Fire Station 7', type: 'rescue',
      distance: 0.9, capacity: 50, currentOccupancy: 12,
      status: 'ACTIVE', address: '220 Emergency Ave',
    ),
    SafeZone(
      id: '4', name: 'Safe Haven 9', type: 'shelter',
      distance: 4.1, capacity: 800, currentOccupancy: 120,
      status: 'ACCEPTING', address: '3000 Valley View Dr',
    ),
    SafeZone(
      id: '5', name: 'Community Center', type: 'shelter',
      distance: 3.3, capacity: 350, currentOccupancy: 350,
      status: 'FULL', address: '555 Oak Street',
    ),
  ];
}
