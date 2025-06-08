
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear/Actualizar perfil
  Future<void> actualizarPerfil(String uid, Map<String, dynamic> datos) async {
    await _firestore.collection('perfiles').doc(uid).set(datos, SetOptions(merge: true));
  }

  // Obtener rol del usuario
  Future<String> obtenerRol(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('perfiles').doc(uid).get();
    return doc.exists ? doc['rol'] : 'usuario'; 
  }
}
