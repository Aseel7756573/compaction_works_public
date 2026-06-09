
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_compass/flutter_compass.dart';

abstract class CompassState extends Equatable {
  const CompassState();
}

class CompassInitial extends CompassState {
  @override
  List<Object?> get props => [];
}

class CompassReading extends CompassState {
  final double heading;
  final bool isLocked;
  const CompassReading({required this.heading, required this.isLocked});
  @override
  List<Object?> get props => [heading, isLocked];
}

class CompassError extends CompassState {
  final String message;
  const CompassError(this.message);
  @override
  List<Object?> get props => [message];
}

class CompassCubit extends Cubit<CompassState> {
  StreamSubscription<CompassEvent>? _sub;
  bool _locked = false;
  double _lockedHeading = 0.0;

  CompassCubit() : super(CompassInitial());

  void startListening() {
    if (FlutterCompass.events == null) {
      emit(const CompassError('البوصلة غير متاحة في هذا الجهاز'));
      return;
    }
    _sub = FlutterCompass.events!.listen((event) {
      if (!_locked && event.heading != null) {
        emit(CompassReading(heading: event.heading!, isLocked: false));
      }
    });
  }

  void lockHeading() {
    final current = state;
    if (current is CompassReading) {
      _locked = true;
      _lockedHeading = current.heading;
      emit(CompassReading(heading: _lockedHeading, isLocked: true));
    }
  }

  void setManualHeading(double heading) {
    _locked = true;
    _lockedHeading = heading;
    emit(CompassReading(heading: heading, isLocked: true));
  }

  void unlock() {
    _locked = false;
    emit(CompassInitial());
    startListening();
  }

  double get currentHeading {
    final s = state;
    return s is CompassReading ? s.heading : 0.0;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
