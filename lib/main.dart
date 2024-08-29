// Main
import 'package:app_mapeo/maps/google_maps_page.dart';
import 'package:flutter/material.dart';

// Función principal que inicia la aplicación
void main() {
  runApp(MyApp());
}

// Clase MyApp que extiende de StatelessWidget
class MyApp extends StatelessWidget {
  MyApp({super.key});
  
  // Método que devuelve el widget raíz de la aplicación
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título de la aplicación
      title: 'Enviaseo',
      // Tema de la aplicación (color primario naranja)
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      // Página de inicio de la aplicación
      home: MyHomePage(),
    );
  }
}

// Clase MyHomePage que extiende de StatelessWidget
class MyHomePage extends StatelessWidget {
  // Método que devuelve el widget de la página de inicio
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar con título y icono de pin de ubicación
      appBar: AppBar(
        backgroundColor: Colors.orange, // Color del AppBar es naranja
        title: Text(
          'Enviaseo - Página de inicio',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Icon(
            Icons.location_pin,
            size: 30,
          ),
        ),
      ),

      // Cuerpo de la página de inicio
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/map_pattern.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shadowColor: Colors.grey,
              elevation: 10,
            ),
            onPressed: () {
              // Navegar a la página del mapa
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapExample()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map),
                SizedBox(width: 10),
                Text('Ir al Mapa'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}