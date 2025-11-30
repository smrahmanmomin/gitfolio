import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Example Bloc events
abstract class AppEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Example Bloc states
abstract class AppState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppInitial extends AppState {}

// Example Bloc
class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(AppInitial()) {
    // Register event handlers here
  }
}
