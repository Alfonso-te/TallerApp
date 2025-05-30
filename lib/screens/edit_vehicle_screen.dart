import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditVehicleScreen extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> currentData;

  const EditVehicleScreen({
    super.key,
    required this.vehicleId,
    required this.currentData,
  });

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _anioController;
  late TextEditingController _placaController;

  @override
  void initState() {
    super.initState();
    _marcaController = TextEditingController(text: widget.currentData['marca']);
    _modeloController = TextEditingController(text: widget.currentData['modelo']);
    _anioController = TextEditingController(text: widget.currentData['año'].toString());
    _placaController = TextEditingController(text: widget.currentData['placa']);
  }

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _actualizarVehiculo() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('vehiculos')
            .doc(widget.vehicleId)
            .update({
          'marca': _marcaController.text,
          'modelo': _modeloController.text,
          'año': int.tryParse(_anioController.text) ?? 0,
          'placa': _placaController.text,
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehículo actualizado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Vehículo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(labelText: 'Marca'),
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: 'Modelo'),
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _anioController,
                decoration: const InputDecoration(labelText: 'Año'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(labelText: 'Placa'),
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _actualizarVehiculo,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Actualizar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
