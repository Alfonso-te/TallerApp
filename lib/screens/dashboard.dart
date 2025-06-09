import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taller_mecanico/screens/profile_screen.dart';
import 'package:taller_mecanico/screens/vehicle_detail.screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Completer<GoogleMapController> _mapController = Completer();
  LatLng _defaultLocation = const LatLng(0, 0);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _userName;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkLocationPermission();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? user.email?.split('@').first ?? 'Usuario';
        });
      }
    }
  }

  Future<void> _checkLocationPermission() async {
   
  }

  Stream<List<Vehicle>> _getVehiclesStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('vehiculos')
        .where('uid_usuario', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Vehicle.fromFirestore(doc)).toList());
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!mounted) return;
    
    _mapController.complete(controller);
    setState(() {
    });
  }

  Future<void> _showVehicleForm({Vehicle? vehicleToEdit}) async {
    final marcaController = TextEditingController(text: vehicleToEdit?.marca ?? '');
    final modeloController = TextEditingController(text: vehicleToEdit?.modelo ?? '');
    final anioController = TextEditingController(text: vehicleToEdit?.anio ?? '');
    final placaController = TextEditingController(text: vehicleToEdit?.placa ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vehicleToEdit == null ? 'NUEVO VEHÍCULO' : 'EDITAR VEHÍCULO',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildFormField(marcaController, 'Marca', Icons.directions_car),
                const SizedBox(height: 16),
                _buildFormField(modeloController, 'Modelo', Icons.model_training),
                const SizedBox(height: 16),
                _buildFormField(anioController, 'Año', Icons.calendar_today),
                const SizedBox(height: 16),
                _buildFormField(placaController, 'Placa', Icons.confirmation_number),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD4AF37)),
                      ),
                      child: const Text('CANCELAR'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                      ),
                      child: Text(vehicleToEdit == null ? 'GUARDAR' : 'ACTUALIZAR'),
                      onPressed: () async {
                        final marca = marcaController.text.trim();
                        final modelo = modeloController.text.trim();
                        final anio = anioController.text.trim();
                        final placa = placaController.text.trim();

                        if (marca.isEmpty || modelo.isEmpty || anio.isEmpty || placa.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor complete todos los campos'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final location = _defaultLocation;

                        try {
                          if (vehicleToEdit == null) {
                            await FirebaseFirestore.instance.collection('vehiculos').add({
                              'marca': marca,
                              'modelo': modelo,
                              'anio': anio,
                              'placa': placa,
                              'location': GeoPoint(location.latitude, location.longitude),
                              'uid_usuario': uid,
                              'fecha_creacion': FieldValue.serverTimestamp(),
                            });
                          } else {
                            await FirebaseFirestore.instance.collection('vehiculos').doc(vehicleToEdit.id).update({
                              'marca': marca,
                              'modelo': modelo,
                              'anio': anio,
                              'placa': placa,
                            });
                          }
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _deleteVehicle(String id) async {
    try {
      await FirebaseFirestore.instance.collection('vehiculos').doc(id).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDrawer() {
    final goldColor = const Color(0xFFD4AF37);
    final darkColor = Colors.grey[900]!;

    return Drawer(
      backgroundColor: darkColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(bottom: BorderSide(color: goldColor, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: goldColor,
                  child: const Icon(Icons.person, size: 30, color: Colors.black),
                ),
                const SizedBox(height: 10),
                Text(
                  _userName ?? 'Usuario',
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: goldColor),
            title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/dashboard') {
                Navigator.pushReplacementNamed(context, '/dashboard');
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: goldColor),
            title: Text('Mi Perfil', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const Divider(color: Color(0xFFD4AF37)),
          ListTile(
            leading: Icon(Icons.logout, color: goldColor),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
      ),
      elevation: 4,
      child: ListTile(
        title: Text(
          '${vehicle.marca} ${vehicle.modelo}',
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${vehicle.anio} - ${vehicle.placa}',
          style: const TextStyle(color: Colors.white70),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailScreen(vehicleId: vehicle.id),
            ),
          );
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFD4AF37)),
              onPressed: () => _showVehicleForm(vehicleToEdit: vehicle),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[400]),
              onPressed: () => _deleteVehicle(vehicle.id),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'DASHBOARD',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showVehicleForm(),
          ),
        ],
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: StreamBuilder<List<Vehicle>>(
        stream: _getVehiclesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: const Color(0xFFD4AF37),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No hay vehículos registrados.',
                style: TextStyle(
                  color: const Color(0xFFD4AF37),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final vehicles = snapshot.data!;
          _markers = vehicles.map((v) => Marker(
            markerId: MarkerId(v.id),
            position: v.location,
            infoWindow: InfoWindow(
              title: v.marca,
              snippet: v.modelo,
            ),
          )).toSet();

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: screenSize.height * 0.03,
            ),
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _defaultLocation,
                      zoom: 2,
                    ),
                    markers: _markers,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ...vehicles.map((v) => _buildVehicleCard(v)),
            ],
          );
        },
      ),
    );
  }
}

class Vehicle {
  final String id;
  final String marca;
  final String modelo;
  final String anio;
  final String placa;
  final LatLng location;
  final String uidUsuario;

  Vehicle({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.placa,
    required this.location,
    required this.uidUsuario,
  });

  factory Vehicle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geo = data['location'] as GeoPoint;
    return Vehicle(
      id: doc.id,
      marca: data['marca'] ?? '',
      modelo: data['modelo'] ?? '',
      anio: data['anio']?.toString() ?? '',
      placa: data['placa'] ?? '',
      location: LatLng(geo.latitude, geo.longitude),
      uidUsuario: data['uid_usuario'] ?? '',
    );
  }
}