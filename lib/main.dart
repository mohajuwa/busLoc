import 'package:flutter/material.dart';

import 'screens/order_traking_page.dart';
import 'package:firebase_core/firebase_core.dart';

// ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ModWir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const OrderTrackingPage(),
    );
  }
}

// import 'package:flutter/material.dart';

// import 'navigation_screen.dart';

// main() {
//   runApp(const MaterialApp(
//     home: MyApp(),
//   ));
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   TextEditingController latController = TextEditingController();
//   TextEditingController lngController = TextEditingController();
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Flutter uber'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(18.0),
//         child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//           const Text(
//             'Enter your location',
//             style: TextStyle(fontSize: 40),
//           ),
//           const SizedBox(
//             height: 30,
//           ),
//           TextField(
//             controller: latController,
//             decoration: const InputDecoration(
//               border: OutlineInputBorder(),
//               labelText: 'latitude',
//             ),
//           ),
//           const SizedBox(
//             height: 20,
//           ),
//           TextField(
//             controller: lngController,
//             decoration: const InputDecoration(
//               border: OutlineInputBorder(),
//               labelText: 'longitute',
//             ),
//           ),
//           const SizedBox(
//             height: 20,
//           ),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).push(MaterialPageRoute(
//                       builder: (context) => NavigationScreen(
//                           double.parse(latController.text),
//                           double.parse(lngController.text))));
//                 },
//                 child: const Text('Get Directions')),
//           ),
//         ]),
//       ),
//     );
//   }
// }
