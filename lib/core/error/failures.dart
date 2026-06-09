
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class GpsFailure extends Failure {
  const GpsFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class CalibrationFailure extends Failure {
  const CalibrationFailure(super.message);
}

class ExportFailure extends Failure {
  const ExportFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
