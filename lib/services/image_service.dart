import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';

/// Service for handling image operations
///
/// Provides image resizing and EXIF metadata extraction
class ImageService {
  static const int maxWidth = 720;

  /// Resize image to max width of 720px while maintaining aspect ratio
  ///
  /// Returns the resized image as bytes
  Future<Uint8List> resizeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Only resize if image is wider than maxWidth
      if (image.width <= maxWidth) {
        return bytes;
      }

      // Calculate new height maintaining aspect ratio
      final ratio = maxWidth / image.width;
      final newHeight = (image.height * ratio).round();

      // Resize image
      final resized = img.copyResize(
        image,
        width: maxWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG with quality 85
      final resizedBytes = img.encodeJpg(resized, quality: 85);
      return Uint8List.fromList(resizedBytes);
    } catch (e) {
      debugPrint('[ImageService] Failed to resize image: $e');
      rethrow;
    }
  }

  /// Extract EXIF metadata from image
  ///
  /// Returns a map containing GPS coordinates and capture time if available
  Future<ImageMetadata> extractMetadata(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isEmpty) {
        debugPrint('[ImageService] No EXIF data found');
        return ImageMetadata();
      }

      // Extract GPS coordinates
      double? latitude;
      double? longitude;
      DateTime? capturedAt;

      // GPS Latitude
      if (data.containsKey('GPS GPSLatitude') &&
          data.containsKey('GPS GPSLatitudeRef')) {
        final latValues = data['GPS GPSLatitude']!.values;
        final latRef = data['GPS GPSLatitudeRef']!.printable;
        latitude = _convertGPSCoordinate(latValues, latRef);
      }

      // GPS Longitude
      if (data.containsKey('GPS GPSLongitude') &&
          data.containsKey('GPS GPSLongitudeRef')) {
        final lonValues = data['GPS GPSLongitude']!.values;
        final lonRef = data['GPS GPSLongitudeRef']!.printable;
        longitude = _convertGPSCoordinate(lonValues, lonRef);
      }

      // Capture time
      if (data.containsKey('EXIF DateTimeOriginal')) {
        final dateTimeStr = data['EXIF DateTimeOriginal']!.printable;
        capturedAt = _parseExifDateTime(dateTimeStr);
      } else if (data.containsKey('Image DateTime')) {
        final dateTimeStr = data['Image DateTime']!.printable;
        capturedAt = _parseExifDateTime(dateTimeStr);
      }

      debugPrint('[ImageService] Extracted metadata - lat: $latitude, lon: $longitude, time: $capturedAt');

      return ImageMetadata(
        latitude: latitude,
        longitude: longitude,
        capturedAt: capturedAt,
      );
    } catch (e) {
      debugPrint('[ImageService] Failed to extract metadata: $e');
      return ImageMetadata();
    }
  }

  /// Save image to Documents directory
  ///
  /// Returns the saved file path
  Future<String> saveToDocuments(Uint8List imageBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final diaryDir = Directory(path.join(directory.path, 'diary'));

      // Create diary directory if it doesn't exist
      if (!await diaryDir.exists()) {
        await diaryDir.create(recursive: true);
      }

      final filePath = path.join(diaryDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      debugPrint('[ImageService] Image saved to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('[ImageService] Failed to save image: $e');
      rethrow;
    }
  }

  /// Convert GPS coordinate from EXIF format to decimal degrees
  double? _convertGPSCoordinate(IfdValues values, String ref) {
    try {
      final ratios = values.toList();
      if (ratios.length < 3) return null;

      // GPS coordinates are stored as [degrees, minutes, seconds]
      final degrees = ratios[0].toDouble();
      final minutes = ratios[1].toDouble();
      final seconds = ratios[2].toDouble();

      var decimal = degrees + (minutes / 60.0) + (seconds / 3600.0);

      // Apply reference (N/S for latitude, E/W for longitude)
      if (ref == 'S' || ref == 'W') {
        decimal = -decimal;
      }

      return decimal;
    } catch (e) {
      debugPrint('[ImageService] Failed to convert GPS coordinate: $e');
      return null;
    }
  }

  /// Parse EXIF datetime string (format: "YYYY:MM:DD HH:MM:SS")
  DateTime? _parseExifDateTime(String dateTimeStr) {
    try {
      // Remove quotes if present
      final cleaned = dateTimeStr.replaceAll('"', '').trim();

      // EXIF format: "YYYY:MM:DD HH:MM:SS"
      final parts = cleaned.split(' ');
      if (parts.length != 2) return null;

      final dateParts = parts[0].split(':');
      final timeParts = parts[1].split(':');

      if (dateParts.length != 3 || timeParts.length != 3) return null;

      return DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
        int.parse(timeParts[2]), // second
      );
    } catch (e) {
      debugPrint('[ImageService] Failed to parse EXIF datetime: $e');
      return null;
    }
  }
}

/// Image metadata extracted from EXIF
class ImageMetadata {
  final double? latitude;
  final double? longitude;
  final DateTime? capturedAt;

  ImageMetadata({
    this.latitude,
    this.longitude,
    this.capturedAt,
  });

  bool get hasGPS => latitude != null && longitude != null;
  bool get hasTimestamp => capturedAt != null;
}
