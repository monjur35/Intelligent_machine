import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server connection error occurred.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Device is offline. Changes kept in local queue.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local database persistence failure.']);
}

class CameraFailure extends Failure {
  const CameraFailure([super.message = 'Hardware camera operation failed.']);
}
