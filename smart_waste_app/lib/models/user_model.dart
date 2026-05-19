class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'user', 'petugas', 'admin'
  final String? profileImage;
  final int points;
  final int wasteCollected;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    this.points = 0,
    this.wasteCollected = 0,
  });
}

class WastePickup {
  final String id;
  final String userId;
  final String address;
  final String wasteType;
  final String volume;
  final String status; // 'pending', 'completed', 'cancelled'
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final int pointsEarned;

  WastePickup({
    required this.id,
    required this.userId,
    required this.address,
    required this.wasteType,
    required this.volume,
    required this.status,
    required this.scheduledDate,
    this.completedDate,
    this.pointsEarned = 0,
  });
}

class WasteType {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int pointsValue;

  WasteType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.pointsValue,
  });
}

class SchedulePickup {
  final String id;
  final String area;
  final DateTime date;
  final String startTime;
  final String endTime;

  SchedulePickup({
    required this.id,
    required this.area,
    required this.date,
    required this.startTime,
    required this.endTime,
  });
}
