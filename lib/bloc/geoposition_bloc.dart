import 'package:flutter_bloc/flutter_bloc.dart';

class GeopositionBloc extends Cubit<Map<String, bool>> {
  GeopositionBloc() : super({'isFound': false, 'tileIsVisible': false});

  void updateIsFound(bool isFound) {
    emit(state..['isFound'] = isFound);
  }
}
