class AppBrand {
  const AppBrand._();

  static const String name = 'HEICFlow';
  static const String subtitle = 'HEIC to JPG/PNG/PDF — on-device';
}

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

class AppLimits {
  const AppLimits._();

  static const int historyRetention = 20;
  static const int defaultJpgQuality = 92;
  static const int minJpgQuality = 60;
  static const int maxJpgQuality = 100;
  static const int thumbLongestSide = 480;
}

class AppDirectories {
  const AppDirectories._();

  static const String root = 'heicflow';
  static const String thumbs = 'thumbs';
  static const String output = 'output';
  static const String temp = 'temp';
}

const Set<String> kSupportedInputExtensions = {
  'heic',
  'heif',
  'jpg',
  'jpeg',
  'png',
};

const int kTabletBreakpoint = 900;
const int kLargeTabletBreakpoint = 1200;
