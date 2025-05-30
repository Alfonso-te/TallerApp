// conexion/vehiculo_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehiculoService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<List<Map<String, dynamic>>> obtenerVehiculosUsuario() async {
    final userId = _auth.currentUser?.uid;

    final snapshot = await _db
        .collection('vehiculos')
        .where('usuario_id', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
  }

  static Future<void> agregarVehiculo(Map<String, dynamic> datos) async {
    final userId = _auth.currentUser?.uid;

    await _db.collection('vehiculos').add({
      ...datos,
      'usuario_id': userId,
      'fecha_creacion': Timestamp.now(),
    });
  }

  static Future<void> eliminarVehiculo(String idVehiculo) async {
    await _db.collection('vehiculos').doc(idVehiculo).delete();
  }

  static Future<void> editarVehiculo(String idVehiculo, Map<String, dynamic> datos) async {
    await _db.collection('vehiculos').doc(idVehiculo).update(datos);
  }
}
