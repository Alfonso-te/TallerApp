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
  final Color _goldColor = Color(0xFFD4AF37);
  final Color _darkColor = Colors.grey[900]!;

  @override
  void initState() {
    super.initState();
    _vehicleFuture = FirebaseFirestore.instance
        .collection('vehiculos')
        .doc(widget.vehicleId)
        .get();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _goldColor,
              onPrimary: Colors.black,
              surface: _darkColor,
              onSurface: _goldColor,
            ),
            dialogBackgroundColor: _darkColor,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: _goldColor,
                onPrimary: Colors.black,
                surface: _darkColor,
                onSurface: _goldColor,
              ),
              dialogBackgroundColor: _darkColor,
            ),
            child: child!,
          );
        },
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
    if (_servicioController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: _goldColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _goldColor),
          ),
        ),
      );
      return;
    }

    try {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mantenimiento agendado con éxito'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _goldColor),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agendar mantenimiento: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _goldColor),
          ),
        ),
      );
    }
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'DETALLES DEL VEHÍCULO',
          style: TextStyle(
            color: _goldColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: _goldColor),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: _goldColor),
            onPressed: () {
              // Implementar funcionalidad de compartir
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _vehicleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _goldColor),
                  SizedBox(height: 16),
                  Text(
                    'Cargando información del vehículo...',
                    style: TextStyle(color: _goldColor),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Vehículo no encontrado',
                    style: TextStyle(
                      color: _goldColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'El ID proporcionado no corresponde a ningún vehículo registrado',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          final vehicle = snapshot.data!.data() as Map<String, dynamic>;
          final fechaCreacion = (vehicle['fecha_creacion'] as Timestamp?)?.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de información del vehículo
                Card(
                  elevation: 4,
                  color: _darkColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _goldColor, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions_car, size: 32, color: _goldColor),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${vehicle['marca']} ${vehicle['modelo']}',
                                style: TextStyle(
                                  color: _goldColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildInfoRow('Año', '${vehicle['anio']}', Icons.calendar_today),
                        _buildInfoRow('Placas', '${vehicle['placa']}', Icons.confirmation_number),
                        if (fechaCreacion != null)
                          _buildInfoRow(
                            'Registrado', 
                            DateFormat('dd/MM/yyyy').format(fechaCreacion), 
                            Icons.date_range,
                            secondary: true,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Sección de observaciones
                Text(
                  'OBSERVACIONES',
                  style: TextStyle(
                    color: _goldColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _observacionesController,
                  maxLines: 3,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Agrega observaciones sobre el vehículo...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _goldColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _goldColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _goldColor, width: 2),
                    ),
                    filled: true,
                    fillColor: _darkColor,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                SizedBox(height: 24),

                // Sección de programar mantenimiento
                Text(
                  'PROGRAMAR MANTENIMIENTO',
                  style: TextStyle(
                    color: _goldColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _servicioController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Servicio',
                    labelStyle: TextStyle(color: _goldColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _goldColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _goldColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _goldColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.build, color: _goldColor),
                    filled: true,
                    fillColor: _darkColor,
                  ),
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDateTime(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha y hora',
                      labelStyle: TextStyle(color: _goldColor),
                      prefixIcon: Icon(Icons.calendar_today, color: _goldColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _goldColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _goldColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _goldColor, width: 2),
                      ),
                      filled: true,
                      fillColor: _darkColor,
                    ),
                    child: Text(
                      _selectedDate != null 
                          ? DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate!)
                          : 'Seleccionar fecha y hora',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addMaintenance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _goldColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'AGENDAR MANTENIMIENTO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),

                // Historial de mantenimientos
                Row(
                  children: [
                    Text(
                      'HISTORIAL DE MANTENIMIENTOS',
                      style: TextStyle(
                        color: _goldColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.refresh, color: _goldColor),
                      onPressed: () {
                        setState(() {
                          _vehicleFuture = FirebaseFirestore.instance
                              .collection('vehiculos')
                              .doc(widget.vehicleId)
                              .get();
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('vehiculos')
                      .doc(widget.vehicleId)
                      .collection('mantenimientos')
                      .orderBy('fecha', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(color: _goldColor),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _darkColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _goldColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: _goldColor),
                            SizedBox(width: 12),
                            Text(
                              'No hay mantenimientos registrados',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      separatorBuilder: (context, index) => Divider(
                        color: _goldColor.withOpacity(0.3),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final fecha = (data['fecha'] as Timestamp).toDate();

                        return Dismissible(
                          key: Key(doc.id),
                          background: Container(
                            color: Colors.red[900],
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: _darkColor,
                                title: Text(
                                  'Confirmar eliminación',
                                  style: TextStyle(color: _goldColor),
                                ),
                                content: Text(
                                  '¿Estás seguro de eliminar este mantenimiento?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text(
                                      'Cancelar',
                                      style: TextStyle(color: _goldColor),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) => doc.reference.delete(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _darkColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _goldColor.withOpacity(0.5)),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _goldColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.build,
                                  color: _goldColor,
                                ),
                              ),
                              title: Text(
                                data['servicio'],
                                style: TextStyle(
                                  color: _goldColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                                style: TextStyle(color: Colors.white70),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: _goldColor,
                              ),
                              onTap: () {
                                // Implementar vista detallada del mantenimiento
                              },
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

  Widget _buildInfoRow(String label, String value, IconData icon, {bool secondary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: secondary ? Colors.grey : _goldColor,
          ),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: secondary ? Colors.grey : _goldColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: secondary ? Colors.grey : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}