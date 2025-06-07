import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:js' as js;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) {
      await _initializeWebNotifications();
    } else {
      await _initializeMobileNotifications();
    }
  }

  Future<void> _initializeWebNotifications() async {
    print('Inicializando notificaciones web...');
    
    // Pedir permisos para notificaciones web
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['''
          if ('Notification' in window && Notification.permission === 'default') {
            Notification.requestPermission();
          }
        ''']);
      } catch (e) {
        print('Error pidiendo permisos web: $e');
      }
    }
  }

  Future<void> _initializeMobileNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        selectNotification(response.payload);
      },
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> selectNotification(String? payload) async {
    if (payload != null) {
      print('Notificación seleccionada: $payload');
    }
  }

  Future<void> showMantenimientoRegistradoNotification({
    required String vehiculo,
    required String tipo,
    required DateTime fecha,
  }) async {
    if (kIsWeb) {
      _showWebNotification(
        title: '✅ Mantenimiento Registrado',
        body: '$tipo para $vehiculo programado para ${_formatDate(fecha)}',
      );
    } else {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'mantenimiento_channel',
        'Notificaciones de Mantenimiento',
        channelDescription: 'Notificaciones cuando se registra un mantenimiento',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Mantenimiento registrado',
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3),
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        '✅ Mantenimiento Registrado',
        '$tipo para $vehiculo programado para ${_formatDate(fecha)}',
        platformChannelSpecifics,
        payload: 'mantenimiento_${vehiculo}_$tipo',
      );
    }
  }

  Future<void> showProximoMantenimientoNotification({
    required String vehiculo,
    required String tipo,
    required DateTime fecha,
  }) async {
    if (kIsWeb) {
      _showWebNotification(
        title: '🔔 Próximo Mantenimiento',
        body: '$tipo para $vehiculo programado para ${_formatDate(fecha)}',
      );
    } else {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'recordatorio_channel',
        'Recordatorios de Mantenimiento',
        channelDescription: 'Recordatorios de próximos mantenimientos',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Próximo mantenimiento',
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF9800),
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000) + 1,
        '🔔 Próximo Mantenimiento',
        '$tipo para $vehiculo programado para ${_formatDate(fecha)}',
        platformChannelSpecifics,
        payload: 'recordatorio_${vehiculo}_$tipo',
      );
    }
  }

  void _showWebNotification({
    required String title,
    required String body,
  }) {
    if (kIsWeb) {
      try {
        // Intentar usar la función JavaScript personalizada si existe
        js.context.callMethod('showWebNotification', [title, body, 'icons/Icon-192.png']);
      } catch (e) {
        print('Función JavaScript personalizada no encontrada, usando nativa...');
        // Fallback: usar API nativa de notificaciones web
        try {
          js.context.callMethod('eval', ['''
            if ('Notification' in window) {
              if (Notification.permission === 'granted') {
                new Notification('$title', { 
                  body: '$body',
                  icon: 'icons/Icon-192.png'
                });
              } else if (Notification.permission !== 'denied') {
                Notification.requestPermission().then(function(permission) {
                  if (permission === 'granted') {
                    new Notification('$title', { 
                      body: '$body',
                      icon: 'icons/Icon-192.png'
                    });
                  }
                });
              } else {
                console.log('Notificaciones denegadas por el usuario');
              }
            } else {
              console.log('Este navegador no soporta notificaciones');
            }
          ''']);
        } catch (e2) {
          print('Error con notificación web nativa: $e2');
          // Último fallback: mostrar en consola
          print('NOTIFICACIÓN: $title - $body');
        }
      }
    }
  }

  Future<void> showVehiculoRegistradoNotification({
    required String marca,
    required String modelo,
    required String placa,
  }) async {
    if (kIsWeb) {
      _showWebNotification(
        title: '🚗 Vehículo Registrado',
        body: '$marca $modelo (Placa: $placa) registrado exitosamente',
      );
    } else {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'vehiculo_channel',
        'Notificaciones de Vehículos',
        channelDescription: 'Notificaciones cuando se registra un vehículo',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Vehículo registrado',
        icon: '@mipmap/ic_launcher',
        color: Color.fromARGB(255, 126, 34, 168),
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(1) + 2,
        '🚗 Vehículo Registrado',
        '$marca $modelo (Placa: $placa) registrado exitosamente',
        platformChannelSpecifics,
        payload: 'vehiculo_${placa}',
      );
    }
  }

  String _formatDate(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}