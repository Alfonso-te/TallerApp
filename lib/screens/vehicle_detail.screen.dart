// vehicle_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late Future<DocumentSnapshot> _vehicleFuture;
  final _observacionesController = TextEditingController();
  final _servicioController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _vehicleFuture = FirebaseFirestore.instance
        .collection('vehiculos')
        .doc(widget.vehicleId)
        .get();
  }

  Future<void> _selectDateTime(BuildContext context) async {
  // 1. Seleccionar fecha
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: _selectedDate ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (pickedDate != null) {
    // 2. Seleccionar hora
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }
}

  Future<void> _addMaintenance() async {
    if (_servicioController.text.isEmpty || _selectedDate == null) return;

    await FirebaseFirestore.instance
        .collection('vehiculos')
        .doc(widget.vehicleId)
        .collection('mantenimientos')
        .add({
      'servicio': _servicioController.text,
      'fecha': _selectedDate,
      'observaciones': _observacionesController.text,
      'fecha_registro': FieldValue.serverTimestamp(),
    });

    _servicioController.clear();
    _observacionesController.clear();
    setState(() {
      _selectedDate = null;
    });
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _servicioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Vehículo'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _vehicleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Vehículo no encontrado'));
          }

          final vehicle = snapshot.data!.data() as Map<String, dynamic>;
          final fechaCreacion = (vehicle['fecha_creacion'] as Timestamp?)?.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle['marca']} ${vehicle['modelo']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Año: ${vehicle['anio']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Placas: ${vehicle['placa']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (fechaCreacion != null)
                          Text(
                            'Registrado: ${DateFormat('dd/MM/yyyy').format(fechaCreacion)}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Observaciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: _observacionesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Agrega observaciones sobre el vehículo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Programar mantenimiento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _servicioController,
                  decoration: InputDecoration(
                    labelText: 'Servicio',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.build),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
              onTap: () => _selectDateTime(context), // Usa el nuevo método
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha y hora',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDate != null 
                      ? DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate!)
                      : 'Seleccionar fecha y hora',
                ),
              ),
            ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addMaintenance,
                  child: const Text('Agendar mantenimiento'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Historial de mantenimientos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                  
                      .collection('vehiculos')
                      .doc(widget.vehicleId)
                      .collection('mantenimientos')
                      .orderBy('fecha', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('No hay mantenimientos registrados');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final fecha = (data['fecha'] as Timestamp).toDate();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(data['servicio']),
                            subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(fecha)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => doc.reference.delete(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}