import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/geoposition_bloc.dart';
import 'pages/geoposition_page.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geoposition App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider<GeopositionBloc>(
        create: (_) => GeopositionBloc(),
        child: GeopositionPage(),
      ),
    );
  }
}