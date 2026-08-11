enum AgeRatingAndroid {
  age3,
  age12,
  age16,
  age18;

  /// Path images
  String get imagePath {
    switch (this) {
      case AgeRatingAndroid.age3:
        return 'assets/age_android/age3.svg';
      case AgeRatingAndroid.age12:
        return 'assets/age_android/age12.svg';
      case AgeRatingAndroid.age16:
        return 'assets/age_android/age16.svg';
      case AgeRatingAndroid.age18:
        return 'assets/age_android/age18.svg';
    }
  }

  /// Buat dari angka usia
  static AgeRatingAndroid fromAge(int age) {
    if (age <= 3) return AgeRatingAndroid.age3;
    if (age <= 12) return AgeRatingAndroid.age12;
    if (age <= 16) return AgeRatingAndroid.age16;
    return AgeRatingAndroid.age18;
  }
}

enum AgeRatingIos {
  age4,
  age9,
  age13,
  age16,
  age18;

  /// Path images
  String get imagePath {
    switch (this) {
      case AgeRatingIos.age4:
        return 'assets/age_ios/age4.png';
      case AgeRatingIos.age9:
        return 'assets/age_ios/age9.png';
      case AgeRatingIos.age13:
        return 'assets/age_ios/age13.png';
      case AgeRatingIos.age16:
        return 'assets/age_ios/age16.png';
      case AgeRatingIos.age18:
        return 'assets/age_ios/age18.png';
    }
  }

  /// Buat dari angka usia
  static AgeRatingIos fromAge(int age) {
    if (age == 18) return AgeRatingIos.age18;
    if (age == 16) return AgeRatingIos.age16;
    if (age == 13) return AgeRatingIos.age13;
    if (age == 9) return AgeRatingIos.age9;
    return AgeRatingIos.age4;
  }
}
