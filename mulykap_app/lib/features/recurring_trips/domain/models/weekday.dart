/// Représente les jours de la semaine
enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    switch (this) {
      case Weekday.monday:
        return 'Lundi';
      case Weekday.tuesday:
        return 'Mardi';
      case Weekday.wednesday:
        return 'Mercredi';
      case Weekday.thursday:
        return 'Jeudi';
      case Weekday.friday:
        return 'Vendredi';
      case Weekday.saturday:
        return 'Samedi';
      case Weekday.sunday:
        return 'Dimanche';
    }
  }

  static Weekday fromInt(int value) {
    return Weekday.values[value - 1]; // 1=monday, 7=sunday
  }
  
  int toInt() {
    return index + 1; // 1=monday, 7=sunday
  }
} 