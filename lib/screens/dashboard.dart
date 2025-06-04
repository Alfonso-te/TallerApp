import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taller_mecanico/screens/vehicle_detail.screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  GoogleMapController? mapController;
  LatLng? currentLocation = LatLng(0, 0);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
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
        return AlertDialog(
          title: Text(vehicleToEdit == null ? 'Nuevo Vehículo' : 'Editar Vehículo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: marcaController, decoration: InputDecoration(labelText: 'Marca')),
              TextField(controller: modeloController, decoration: InputDecoration(labelText: 'Modelo')),
              TextField(controller: anioController, decoration: InputDecoration(labelText: 'Año')),
              TextField(controller: placaController, decoration: InputDecoration(labelText: 'Placa')),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text(vehicleToEdit == null ? 'Guardar' : 'Actualizar'),
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
        );
      },
    );
  }

  Future<void> _deleteVehicle(String id) async {
    await FirebaseFirestore.instance.collection('vehiculos').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blue,
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
      ),
      drawer: _buildDrawer(),
      body: StreamBuilder<List<Vehicle>>(
        stream: _getVehiclesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay vehículos registrados.'));
          }

          final vehicles = snapshot.data!;

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Container(
                height: 300,
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
              SizedBox(height: 16),
              ...vehicles.map((v) => _buildVehicleCard(v)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 30),
                ),
                SizedBox(height: 10),
                Text(
                  'Usuario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.directions_car),
            title: Text('Mis Vehículos'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text('${vehicle.marca} ${vehicle.modelo}'),
        subtitle: Text('${vehicle.anio} - ${vehicle.placa}'),
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
              icon: Icon(Icons.edit),
              onPressed: () => _showVehicleForm(vehicleToEdit: vehicle),
            ),
            IconButton(
              icon: Icon(Icons.delete),
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