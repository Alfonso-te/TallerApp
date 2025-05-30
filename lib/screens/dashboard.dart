import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  GoogleMapController? mapController;
  Location location = Location();
  LatLng? currentLocation;
  bool isLoadingLocation = true;
  
  // Datos de ejemplo de vehículos
  List<Vehicle> vehicles = [
    Vehicle(
      id: '1',
      name: 'Volkswagen Golf',
      year: '2323',
      plate: '322423',
      location: LatLng(20.6597, -103.3496), // Guadalajara
    ),
    // Puedes agregar más vehículos aquí
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationData locationData = await location.getLocation();
      setState(() {
        currentLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        currentLocation = LatLng(20.6597, -103.3496); // Ubicación por defecto
        isLoadingLocation = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Set<Marker> _createMarkers() {
    Set<Marker> markers = {};
    
    // Marcador de ubicación actual
    if (currentLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId('mi_ubicacion'),
          position: currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Mi Ubicación',
            snippet: 'Taller Mecánico',
          ),
        ),
      );
    }

    // Marcadores de vehículos
    for (Vehicle vehicle in vehicles) {
      markers.add(
        Marker(
          markerId: MarkerId(vehicle.id),
          position: vehicle.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: vehicle.name,
            snippet: 'Placa: ${vehicle.plate}',
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            // Acción del menú
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error/Warning Card (como en tu imagen)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TypeError: Cannot read properties of undefined (reading \'maps\')',
                    style: TextStyle(
                      color: Colors.yellow[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'See also: https://docs.flutter.dev/testing/errors',
                    style: TextStyle(
                      color: Colors.yellow[300],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Mapa integrado
            Text(
              'Ubicación del Taller',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isLoadingLocation
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: currentLocation ?? LatLng(20.6597, -103.3496),
                          zoom: 14.0,
                        ),
                        markers: _createMarkers(),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.normal,
                      ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Vehículos registrados
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vehículos registrados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () {
                    // Acción para agregar nuevo vehículo
                  },
                ),
              ],
            ),
            
            SizedBox(height: 10),
            
            // Lista de vehículos
            ...vehicles.map((vehicle) => _buildVehicleCard(vehicle)).toList(),
            
            SizedBox(height: 20),
            
            // Botón para ver todos los vehículos en el mapa
            ElevatedButton.icon(
              onPressed: () {
                _showAllVehiclesOnMap();
              },
              icon: Icon(Icons.map),
              label: Text('Ver todos los vehículos en el mapa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.directions_car,
            color: Colors.blue[700],
            size: 24,
          ),
        ),
        title: Text(
          vehicle.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Año: ${vehicle.year} • Placa: ${vehicle.plate}'),
            SizedBox(height: 4),
            Text(
              'Ubicación: ${vehicle.location.latitude.toStringAsFixed(4)}, ${vehicle.location.longitude.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.location_on, color: Colors.green),
              onPressed: () {
                _showVehicleOnMap(vehicle);
              },
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                // Acción para editar
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Acción para eliminar
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleOnMap(Vehicle vehicle) {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(vehicle.location, 16.0),
      );
    }
  }

  void _showAllVehiclesOnMap() {
    if (mapController != null && vehicles.isNotEmpty) {
      // Calcular bounds para mostrar todos los vehículos
      double minLat = vehicles.first.location.latitude;
      double maxLat = vehicles.first.location.latitude;
      double minLng = vehicles.first.location.longitude;
      double maxLng = vehicles.first.location.longitude;

      for (Vehicle vehicle in vehicles) {
        minLat = minLat < vehicle.location.latitude ? minLat : vehicle.location.latitude;
        maxLat = maxLat > vehicle.location.latitude ? maxLat : vehicle.location.latitude;
        minLng = minLng < vehicle.location.longitude ? minLng : vehicle.location.longitude;
        maxLng = maxLng > vehicle.location.longitude ? maxLng : vehicle.location.longitude;
      }

      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0, // padding
        ),
      );
    }
  }
}

class Location {
  getLocation() {}
}

class LocationData {
  var longitude;

  get latitude => null;
}

// Clase modelo para vehículos
class Vehicle {
  final String id;
  final String name;
  final String year;
  final String plate;
  final LatLng location;

  Vehicle({
    required this.id,
    required this.name,
    required this.year,
    required this.plate,
    required this.location,
  });
}