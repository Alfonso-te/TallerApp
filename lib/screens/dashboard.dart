import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taller_mecanico/screens/vehicle_detail.screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  GoogleMapController? mapController;
  LatLng? currentLocation = LatLng(0, 0);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? user.email?.split('@').first ?? 'Usuario';
        });
      }
    }
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
    mapController = controller;
  }

  void _showVehicleForm({Vehicle? vehicleToEdit}) {
    final marcaController = TextEditingController(text: vehicleToEdit?.marca ?? '');
    final modeloController = TextEditingController(text: vehicleToEdit?.modelo ?? '');
    final anioController = TextEditingController(text: vehicleToEdit?.anio ?? '');
    final placaController = TextEditingController(text: vehicleToEdit?.placa ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vehicleToEdit == null ? 'NUEVO VEHÍCULO' : 'EDITAR VEHÍCULO',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                _buildFormField(marcaController, 'Marca', Icons.directions_car),
                SizedBox(height: 16),
                _buildFormField(modeloController, 'Modelo', Icons.model_training),
                SizedBox(height: 16),
                _buildFormField(anioController, 'Año', Icons.calendar_today),
                SizedBox(height: 16),
                _buildFormField(placaController, 'Placa', Icons.confirmation_number),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Color(0xFFD4AF37)),
                      ),
                      child: Text('CANCELAR'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                      ),
                      child: Text(vehicleToEdit == null ? 'GUARDAR' : 'ACTUALIZAR'),
                      onPressed: () async {
                        final marca = marcaController.text.trim();
                        final modelo = modeloController.text.trim();
                        final anio = anioController.text.trim();
                        final placa = placaController.text.trim();

                        if (marca.isEmpty || modelo.isEmpty || anio.isEmpty || placa.isEmpty) return;

                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final location = currentLocation ?? LatLng(0, 0);

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
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFFD4AF37)),
        prefixIcon: Icon(icon, color: Color(0xFFD4AF37)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD4AF37)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _deleteVehicle(String id) async {
    await FirebaseFirestore.instance.collection('vehiculos').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'DASHBOARD',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Color(0xFFD4AF37)),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
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
                color: Color(0xFFD4AF37),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No hay vehículos registrados.',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final vehicles = snapshot.data!;

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: screenSize.height * 0.03,
            ),
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFD4AF37), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: currentLocation!,
                      zoom: 2,
                    ),
                    markers: vehicles
                        .map((v) => Marker(
                              markerId: MarkerId(v.id),
                              position: v.location,
                              infoWindow: InfoWindow(
                                title: v.marca,
                                snippet: v.modelo,
                              ),
                            ))
                        .toSet(),
                  ),
                ),
              ),
              SizedBox(height: 24),
              ...vehicles.map((v) => _buildVehicleCard(v)),
            ],
          );
        },
      ),
    );
  }

 Widget _buildDrawer() {
  return Drawer(
    backgroundColor: Colors.grey[900],
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
         DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(bottom: BorderSide(color: Color(0xFFD4AF37), width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFD4AF37),
                child: Icon(Icons.person, size: 30, color: Colors.black),
              ),
              SizedBox(height: 10),
              Text(
                _userName ?? 'Usuario',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        _buildDrawerItem(Icons.dashboard, 'Dashboard'),
        _buildDrawerItem(Icons.directions_car, 'Mis Vehículos'),
        _buildDrawerItem(Icons.settings, 'Configuración'),
        Divider(color: Color(0xFFD4AF37).withOpacity(0.5)),
        _buildDrawerItem(Icons.logout, 'Cerrar sesión', isLogout: true),
      ],
    ),
  );
}

  Widget _buildDrawerItem(IconData icon, String title, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFFD4AF37)),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        if (isLogout) {
          FirebaseAuth.instance.signOut();
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Color(0xFFD4AF37), width: 1),
      ),
      elevation: 4,
      child: ListTile(
        title: Text(
          '${vehicle.marca} ${vehicle.modelo}',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${vehicle.anio} - ${vehicle.placa}',
          style: TextStyle(color: Colors.white70),
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
              icon: Icon(Icons.edit, color: Color(0xFFD4AF37)),
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