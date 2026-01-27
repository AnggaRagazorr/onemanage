import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../shell/app_drawer.dart';
import 'patrol_store.dart';
import '../../services/patrol_service.dart';

class PatrolAreaPage extends StatefulWidget {
  const PatrolAreaPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.bannerColor,
  });

  final String title;
  final String subtitle;
  final Color bannerColor;

  @override
  State<PatrolAreaPage> createState() => _PatrolAreaPageState();
}

class _PatrolAreaPageState extends State<PatrolAreaPage> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = [];
  String? _barcodeValue;

  bool get _hasScanned => _barcodeValue != null;
  bool get _canSubmit => _photos.length == 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: const AppDrawer(currentPage: AppPage.patrol),
      body: Column(
        children: [
          // Premium Gradient Header
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 10, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D5AA5), Color(0xFF003377)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Area Patroli",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.bannerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: widget.bannerColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.bannerColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.location_on, color: widget.bannerColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Dokumentasi",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                _photoCard(index: 0),
                const SizedBox(height: 12),
                _photoCard(index: 1),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openScanner,
                        icon: Icon(_hasScanned ? Icons.check_circle : Icons.qr_code_scanner),
                        label: Text(_hasScanned ? "Terscan" : "Scan QR"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasScanned ? const Color(0xFF10B981) : const Color(0xFF0D5AA5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _hasScanned ? _takePhoto : null,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Ambil Foto"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D5AA5),
                          disabledBackgroundColor: const Color(0xFF9DBCE6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomSubmit(context),
    );
  }

  Widget _photoCard({required int index}) {
    final hasPhoto = _photos.length > index;
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E4FB)),
      ),
      child: hasPhoto
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(_photos[index].path),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          : const Text(
              "Belum ada foto",
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
    );
  }

  Widget _bottomSubmit(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _canSubmit ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D5AA5),
            disabledBackgroundColor: const Color(0xFF9DBCE6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            "Submit",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openScanner() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          height: 420,
          child: MobileScanner(
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) {
                return;
              }
              final value = capture.barcodes.first.rawValue;
              if (value != null && value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
          ),
        );
      },
    );

    if (value != null) {
      setState(() => _barcodeValue = value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Barcode berhasil dipindai.")),
      );
    }
  }

  Future<void> _takePhoto() async {
    if (!_hasScanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Scan barcode terlebih dahulu.")),
      );
      return;
    }
    if (_photos.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maksimal 2 foto.")),
      );
      return;
    }

    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      final lines = await _buildStampLines();
      final stamped = await _stampPhoto(photo, lines);
      setState(() => _photos.add(stamped ?? photo));
    }
  }

  void _submit() {
    _uploadPatrol();
  }

  Future<void> _uploadPatrol() async {
    try {
      final files = await Future.wait(
        _photos.map((photo) => MultipartFile.fromFile(photo.path)),
      );
      final saved = await PatrolService.instance.upload(
        area: widget.title,
        barcode: _barcodeValue ?? "-",
        photos: files,
      );
      patrolStore.add(saved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data patroli tersimpan.")),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal upload patroli.")),
        );
      }
    }
  }

  Future<XFile?> _stampPhoto(XFile photo, List<String> lines) async {
    try {
      final bytes = await File(photo.path).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return null;
      }

      final textColor = img.ColorRgba8(255, 255, 255, 255);
      final shadowColor = img.ColorRgba8(0, 0, 0, 160);
      final font = img.arial24;
      const int padding = 16;
      const int lineGap = 4;
      final lineHeight = font.lineHeight.round();
      final totalHeight = (lines.length * lineHeight) + ((lines.length - 1) * lineGap);
      final int x = padding;
      int y = image.height - totalHeight - padding;
      if (y < padding) {
        y = padding;
      }

      for (final line in lines) {
        img.drawString(
          image,
          line,
          font: font,
          x: x + 2,
          y: y + 2,
          color: shadowColor,
        );
        img.drawString(
          image,
          line,
          font: font,
          x: x,
          y: y,
          color: textColor,
        );
        y += lineHeight + lineGap;
      }

      final stampedBytes = img.encodeJpg(image, quality: 90);
      final stampedPath = _stampedPath(photo.path);
      final stampedFile = File(stampedPath);
      await stampedFile.writeAsBytes(stampedBytes);

      return XFile(stampedFile.path);
    } catch (_) {
      return null;
    }
  }

  String _stampedPath(String original) {
    final dotIndex = original.lastIndexOf('.');
    if (dotIndex == -1) {
      return '${original}_ts.jpg';
    }
    final base = original.substring(0, dotIndex);
    return '${base}_ts.jpg';
  }

  String _formatTimestamp(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$day $month $year $hour.$minute.$second';
  }

  Future<List<String>> _buildStampLines() async {
    final timestamp = _formatTimestamp(DateTime.now());
    final locationLines = await _getLocationLines();
    return [timestamp, ...locationLines];
  }

  Future<List<String>> _getLocationLines() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return ["Lokasi tidak tersedia"];
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return ["Lokasi tidak tersedia"];
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final coords =
          "Lat ${position.latitude.toStringAsFixed(6)}, Lng ${position.longitude.toStringAsFixed(6)}";

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [
            place.street,
            place.subLocality,
            place.locality,
            place.subAdministrativeArea,
            place.administrativeArea,
          ].where((value) => value != null && value.trim().isNotEmpty).cast<String>().toList();
          if (parts.isNotEmpty) {
            return [coords, parts.join(", ")];
          }
        }
      } catch (_) {
        // Ignore address failures.
      }

      return [coords];
    } catch (_) {
      return ["Lokasi tidak tersedia"];
    }
  }
}
