import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../widgets/glossy_widgets.dart';
import 'detail_screen.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _diagnose() async {
    if (_image == null) return;

    final provider = context.read<PlantProvider>();
    try {
      await provider.predictImage(_image!);
      if (!mounted) return;
      if (provider.lastPrediction != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(prediction: provider.lastPrediction!),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error diagnosing plant: $e'),
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
        title: const Text('New Diagnosis'),
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
                  const Color(0xFF1F3D2B).withValues(alpha: 0.04),
                  const Color(0xFF8FBC8F).withValues(alpha: 0.20),
                  const Color(0xFFF8FAF5),
                ],
              ),
            ),
          ),
          Consumer<PlantProvider>(
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
                                  child: Image.file(
                                    _image!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 80,
                                      color: const Color(0xFF8FBC8F).withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Upload or Take a Photo',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                                      child: Text(
                                        'Please ensure the leaf is clearly visible for accurate results',
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
                      GlossyButton(
                        onPressed: _image != null && !provider.isLoading ? _diagnose : null,
                        isLoading: provider.isLoading,
                        label: Text(provider.isLoading ? 'ANALYZING AI...' : 'START DIAGNOSIS'),
                        icon: Icons.analytics_outlined,
                      ),
                      if (_image != null) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() => _image = null),
                          child: const Text('Clear Image', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
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
              Icon(icon, color: const Color(0xFF1F3D2B), size: 30),
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
