import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/glossy_widgets.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  final List<Map<String, dynamic>> products = const [
    {
      'name': 'Neem Oil Spray',
      'category': 'Pest Control',
      'description': 'Natural organic insecticide for plants.',
      'icon': '🌿',
      'price': '₹299',
      'url': 'https://www.amazon.in/s?k=organic+neem+oil+for+plants',
    },
    {
      'name': 'Organic Fertilizer',
      'category': 'Nutrients',
      'description': 'Seaweed liquid fertilizer for all plants.',
      'icon': '🌱',
      'price': '₹350',
      'url': 'https://www.amazon.in/s?k=organic+liquid+fertilizer+for+plants',
    },
    {
      'name': 'Pruning Shears',
      'category': 'Tools',
      'description': 'Professional garden pruning scissors.',
      'icon': '✂️',
      'price': '₹450',
      'url': 'https://www.amazon.in/s?k=garden+pruning+shears',
    },
    {
      'name': 'Watering Can',
      'category': 'Equipment',
      'description': 'Indoor and outdoor plant watering pot.',
      'icon': '💧',
      'price': '₹250',
      'url': 'https://www.amazon.in/s?k=watering+can+for+plants',
    },
    {
      'name': 'Plant Growth Promoter',
      'category': 'Nutrients',
      'description': 'Essential nutrients for faster growth.',
      'icon': '🚀',
      'price': '₹199',
      'url': 'https://www.amazon.in/s?k=plant+growth+promoter',
    },
    {
      'name': 'Fungicide Powder',
      'category': 'Medicine',
      'description': 'Controls fungal diseases in plants.',
      'icon': '🧪',
      'price': '₹150',
      'url': 'https://www.amazon.in/s?k=fungicide+for+plants',
    },
  ];

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Plant Shop',
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
          // Gradient Background
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
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Garden Essentials',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F3D2B),
                            ),
                      ),
                      Text(
                        'Find everything your plants need',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(context, product);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    return GlossyCard(
      fillOpacity: 0.08,
      child: InkWell(
        onTap: () => _launchURL(product['url']),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  product['icon'],
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const Spacer(),
              Text(
                product['category'],
                style: TextStyle(
                  color: const Color(0xFF1F3D2B).withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product['name'],
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F3D2B),
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                product['description'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product['price'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3D2B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F3D2B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
