import 'package:campusar/core/errors/app_failure.dart';

sealed class Result<T> {
  const Result();

  factory Result.success(T data) => Success<T>(data);
  factory Result.failure(AppFailure failure) => Failure<T>(failure);

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  AppFailure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final failure) => failure,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(failure: final failureValue) => failure(failureValue),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;
}