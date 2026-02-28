import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_care.dart';
import '../providers/plant_care_provider.dart';
import '../widgets/glossy_widgets.dart';

class AddPlantCareScreen extends StatefulWidget {
  const AddPlantCareScreen({super.key});

  @override
  State<AddPlantCareScreen> createState() => _AddPlantCareScreenState();
}

class _AddPlantCareScreenState extends State<AddPlantCareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plantNameController = TextEditingController();
  final _plantIdController = TextEditingController();
  final _notesController = TextEditingController();
  
  final List<Map<String, dynamic>> _presets = [
    {
      'name': 'Succulent 🌵',
      'water': 14,
      'fertilize': 60,
      'prune': 180,
    },
    {
      'name': 'Rose 🌹',
      'water': 3,
      'fertilize': 14,
      'prune': 30,
    },
    {
      'name': 'Mint 🌿',
      'water': 2,
      'fertilize': 30,
      'prune': 14,
    },
    {
      'name': 'Snake Plant 🐍',
      'water': 21,
      'fertilize': 90,
      'prune': 365,
    },
    {
      'name': 'Orchid 🌸',
      'water': 7,
      'fertilize': 14,
      'prune': 60,
    },
  ];

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _plantNameController.text = (preset['name'] as String).split(' ').first;
      _wateringFrequency = preset['water'];
      _fertilizingFrequency = preset['fertilize'];
      _pruningFrequency = preset['prune'];
    });
  }

  int _wateringFrequency = 7;
  int _fertilizingFrequency = 30;
  int _pruningFrequency = 90;
  final int _repottingFrequency = 365;
  
  DateTime? _lastWatered;
  DateTime? _lastFertilized;
  DateTime? _lastPruned;
  DateTime? _lastRepotted;

  @override
  void dispose() {
    _plantNameController.dispose();
    _plantIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'New Plant Care',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F3D2B),
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // Gradient Background to match HomeScreen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1F3D2B).withValues(alpha: 0.04),
                  const Color(0xFF8FBC8F).withValues(alpha: 0.20),
                  const Color(0xFFF8FAF5),
                ],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Text(
                    'Add New Plant',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F3D2B),
                        ),
                  ),
                  Text(
                    'Select a preset or enter details below',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Presets Section
                  Text(
                    'Quick Presets',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF1F3D2B),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presets.length,
                      itemBuilder: (context, index) {
                        final preset = _presets[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(preset['name']),
                            backgroundColor: const Color(0xFF1F3D2B).withValues(alpha: 0.08),
                            side: BorderSide.none,
                            labelStyle: const TextStyle(
                              color: Color(0xFF1F3D2B),
                              fontWeight: FontWeight.bold,
                            ),
                            onPressed: () => _applyPreset(preset),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  GlossyCard(
                    fillOpacity: 0.08,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🪴 Plant Details',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F3D2B),
                                  ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Plant Name
                            TextFormField(
                              controller: _plantNameController,
                              style: const TextStyle(color: Color(0xFF1F3D2B)),
                              decoration: InputDecoration(
                                labelText: 'What is your plant called?',
                                labelStyle: TextStyle(color: Colors.grey.shade600),
                                prefixIcon: const Icon(Icons.local_florist_rounded, color: Color(0xFF1F3D2B)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.5),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            
                            Text(
                              '💧 Care Intervals',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F3D2B),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'How often does your plant need care?',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildSmartFrequency('Watering', _wateringFrequency, Icons.water_drop_rounded, Colors.blue, (val) => setState(() => _wateringFrequency = val)),
                            const SizedBox(height: 20),
                            _buildSmartFrequency('Fertilizing', _fertilizingFrequency, Icons.eco_rounded, Colors.orange, (val) => setState(() => _fertilizingFrequency = val)),
                            const SizedBox(height: 20),
                            _buildSmartFrequency('Pruning', _pruningFrequency, Icons.content_cut_rounded, Colors.green, (val) => setState(() => _pruningFrequency = val)),
                            
                            const SizedBox(height: 40),
                            
                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F3D2B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Start Care Schedule',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.rocket_launch_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartFrequency(String label, int currentValue, IconData icon, Color color, Function(int) onChanged) {
    final options = [
      {'label': '2 Days', 'value': 2},
      {'label': 'Weekly', 'value': 7},
      {'label': 'Bi-weekly', 'value': 14},
      {'label': 'Monthly', 'value': 30},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F3D2B),
                  ),
            ),
            const Spacer(),
            Text(
              'Every $currentValue days',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: options.map((opt) {
            final isSelected = currentValue == opt['value'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onChanged(opt['value'] as int),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      opt['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? color : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.1),
            thumbColor: Colors.white,
            overlayColor: color.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: currentValue.toDouble(),
            min: 1,
            max: 365,
            onChanged: (val) => onChanged(val.round()),
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<PlantCareProvider>(context, listen: false);
    
    final plantCare = PlantCareCreate(
      plantId: _plantIdController.text.isEmpty 
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : _plantIdController.text,
      plantName: _plantNameController.text,
      wateringFrequencyDays: _wateringFrequency,
      fertilizingFrequencyDays: _fertilizingFrequency,
      pruningFrequencyDays: _pruningFrequency,
      repottingFrequencyDays: _repottingFrequency,
      lastWatered: _lastWatered,
      lastFertilized: _lastFertilized,
      lastPruned: _lastPruned,
      lastRepotted: _lastRepotted,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    final success = await provider.createPlantCare(plantCare);
    
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('🌿 ${plantCare.plantName} added successfully!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}