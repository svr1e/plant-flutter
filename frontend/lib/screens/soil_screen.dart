import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/soil_provider.dart';
import '../widgets/glossy_widgets.dart';
import 'soil_detail_screen.dart';

class SoilScreen extends StatefulWidget {
  const SoilScreen({super.key});

  @override
  State<SoilScreen> createState() => _SoilScreenState();
}

class _SoilScreenState extends State<SoilScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 90);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    final provider = context.read<SoilProvider>();
    try {
      final lat = double.tryParse(_latController.text.trim());
      final lon = double.tryParse(_lonController.text.trim());
      await provider.predictImage(_image!, latitude: lat, longitude: lon);
      if (!mounted) return;
      if (provider.lastPrediction != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SoilDetailScreen(prediction: provider.lastPrediction!),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error analyzing soil: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Soil Analysis'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  const Color(0xFF8D6E63).withValues(alpha: 0.06),
                  const Color(0xFFDFF5E1).withValues(alpha: 0.4),
                  const Color(0xFFF8FAF5),
                ],
              ),
            ),
          ),
          Consumer<SoilProvider>(
            builder: (context, provider, child) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GlossyCard(
                        borderRadius: 32,
                        child: Container(
                          height: 350,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: _image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: Image.file(_image!, height: 350, width: double.infinity, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8D6E63).withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.landscape_rounded, size: 42, color: Color(0xFF8D6E63)),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Add a clear soil photo',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 24),
                                      child: Text(
                                        'Ensure the soil texture is clearly visible with good lighting',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 13, color: Colors.black38),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionBtn(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: Icons.camera_alt_rounded,
                              label: 'Camera',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionBtn(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: Icons.photo_library_rounded,
                              label: 'Gallery',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GlossyCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _latController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  decoration: InputDecoration(
                                    labelText: 'Latitude (optional)',
                                    hintText: 'e.g., 17.3850',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    filled: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _lonController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  decoration: InputDecoration(
                                    labelText: 'Longitude (optional)',
                                    hintText: 'e.g., 78.4867',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    filled: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlossyButton(
                        onPressed: _image != null && !provider.isLoading ? _analyze : null,
                        isLoading: provider.isLoading,
                        label: Text(provider.isLoading ? 'ANALYZING...' : 'ANALYZE SOIL'),
                        icon: Icons.science_rounded,
                        color: const Color(0xFF8D6E63),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({required VoidCallback onPressed, required IconData icon, required String label}) {
    return GlossyCard(
      fillOpacity: 0.1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF8D6E63), size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
