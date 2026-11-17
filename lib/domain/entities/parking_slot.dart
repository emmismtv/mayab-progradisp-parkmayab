enum SlotStatus { free, occupied, reserved }

/// Cajón de estacionamiento del edificio.
class ParkingSlot {
  final int id;
  final int floor;
  final String wing;
  final int number;
  final SlotStatus status;

  const ParkingSlot({
    required this.id,
    required this.floor,
    required this.wing,
    required this.number,
    required this.status,
  });

  /// Código visible, por ejemplo "B-04".
  String get code => '$wing-${number.toString().padLeft(2, '0')}';
}
