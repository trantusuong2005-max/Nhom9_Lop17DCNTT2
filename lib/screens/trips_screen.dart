import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/db_helper.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _itineraryCtrl = TextEditingController();

  List<Trip> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final data = await DBHelper.getTrips();
    if (!mounted) return;
    setState(() {
      _trips = data;
      _isLoading = false;
    });
  }

  Future<void> _pickDate(TextEditingController targetController) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      targetController.text = '$day/$month/${picked.year}';
    }
  }

  Future<void> _addTrip() async {
    final name = _nameCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    if (name.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên chuyến đi và địa điểm')),
      );
      return;
    }

    final trip = Trip(
      name: name,
      location: location,
      startDate: _dateCtrl.text.trim(),
      budget: double.tryParse(_budgetCtrl.text.trim()) ?? 0,
      itinerary: _itineraryCtrl.text.trim(),
    );

    await DBHelper.insertTrip(trip);
    _nameCtrl.clear();
    _locationCtrl.clear();
    _dateCtrl.clear();
    _budgetCtrl.clear();
    _itineraryCtrl.clear();
    await _loadTrips();
  }

  Future<void> _showEditDialog(Trip trip) async {
    final editName = TextEditingController(text: trip.name);
    final editLocation = TextEditingController(text: trip.location);
    final editDate = TextEditingController(text: trip.startDate);
    final editBudget = TextEditingController(
      text: trip.budget == 0 ? '' : trip.budget.toStringAsFixed(0),
    );
    final editItinerary = TextEditingController(text: trip.itinerary);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa thông tin chuyến đi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editName,
                decoration: const InputDecoration(labelText: 'Tên chuyến đi'),
              ),
              TextField(
                controller: editLocation,
                decoration: const InputDecoration(labelText: 'Địa điểm'),
              ),
              TextField(
                controller: editDate,
                readOnly: true,
                onTap: () => _pickDate(editDate),
                decoration: const InputDecoration(
                  labelText: 'Ngày khởi hành (bấm để chọn)',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              TextField(
                controller: editBudget,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Chi phí dự trù'),
              ),
              TextField(
                controller: editItinerary,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Lịch trình chi tiết'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = Trip(
                id: trip.id,
                name: editName.text.trim().isEmpty
                    ? trip.name
                    : editName.text.trim(),
                location: editLocation.text.trim().isEmpty
                    ? trip.location
                    : editLocation.text.trim(),
                startDate: editDate.text.trim(),
                budget: double.tryParse(editBudget.text.trim()) ?? trip.budget,
                itinerary: editItinerary.text.trim(),
              );
              await DBHelper.updateTrip(updated);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _loadTrips();
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTrip(int id) async {
    await DBHelper.deleteTrip(id);
    await _loadTrips();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _dateCtrl.dispose();
    _budgetCtrl.dispose();
    _itineraryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sổ tay Chuyến đi (Offline)')),
      body: Column(
        children: [
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text(
              'Tạo chuyến đi mới',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên chuyến đi *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Địa điểm *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dateCtrl,
                            readOnly: true,
                            onTap: () => _pickDate(_dateCtrl),
                            decoration: const InputDecoration(
                              labelText: 'Ngày khởi hành',
                              hintText: 'Chọn ngày',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _budgetCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Chi phí dự trù',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _itineraryCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Lịch trình chi tiết',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _addTrip,
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu chuyến đi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trips.isEmpty
                    ? const Center(
                        child: Text('Chưa có chuyến đi nào được lưu.'),
                      )
                    : ListView.builder(
                        itemCount: _trips.length,
                        itemBuilder: (context, index) {
                          final t = _trips[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text(
                                '${t.name} — ${t.location}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Ngày đi: ${t.startDate.isEmpty ? "Chưa rõ" : t.startDate} | '
                                'Dự trù: ${t.budget.toStringAsFixed(0)}đ\n'
                                'Lịch trình: ${t.itinerary.isEmpty ? "Chưa cập nhật" : t.itinerary}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.teal,
                                    ),
                                    tooltip: 'Sửa chuyến đi / ngày đi',
                                    onPressed: () => _showEditDialog(t),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Xóa',
                                    onPressed: () => _deleteTrip(t.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}