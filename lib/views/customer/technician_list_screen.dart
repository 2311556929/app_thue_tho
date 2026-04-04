import 'package:appthuetho/views/customer/chat_detail_screen.dart';
import 'package:flutter/material.dart';

class TechnicianListScreen extends StatelessWidget {
  final List<dynamic> suggestedTechnicians;

  const TechnicianListScreen({super.key, required this.suggestedTechnicians});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thợ gợi ý gần bạn')),
      body: suggestedTechnicians.isEmpty
          ? const Center(child: Text('Không tìm thấy thợ phù hợp'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: suggestedTechnicians.length,
        itemBuilder: (context, index) {
          final tech = suggestedTechnicians[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(tech['avatar'] ?? 'https://i.pravatar.cc/150'),
              ),
              title: Text(tech['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${tech['distance']} km • ⭐ ${tech['rating']} • ${tech['serviceTypes'].join(', ')}',
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        technicianName: tech['name'],
                        technicianId: tech['id'] ?? 'tech_001',
                      ),
                    ),
                  );
                },
                child: const Text('Chat ngay'),
              ),
            ),
          );
        },
      ),
    );
  }
}