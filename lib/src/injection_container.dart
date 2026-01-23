import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'data/datasources/firebase_auth_datasource.dart';
import 'data/datasources/firestore_student_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';

import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/sign_in_usecase.dart';
import 'domain/usecases/sign_up_usecase.dart';
import 'domain/usecases/sign_out_usecase.dart';
import 'domain/usecases/forgot_password_usecase.dart';
import 'domain/usecases/send_verification_email_usecase.dart';
import 'domain/usecases/check_email_verified_usecase.dart';
import 'domain/usecases/get_current_user_usecase.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // -------------------------
  // FIREBASE (must be initialized before this)
  // -------------------------
  if (!sl.isRegistered<FirebaseAuth>()) {
    sl.registerLazySingleton<FirebaseAuth>(
      () => FirebaseAuth.instance,
    );
  }

  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }

  // -------------------------
  // DATA SOURCES
  // -------------------------
  if (!sl.isRegistered<FirebaseAuthDataSource>()) {
    sl.registerLazySingleton<FirebaseAuthDataSource>(
      () => FirebaseAuthDataSource(sl<FirebaseAuth>()),
    );
  }

  if (!sl.isRegistered<FirestoreStudentDataSource>()) {
    sl.registerLazySingleton<FirestoreStudentDataSource>(
      () => FirestoreStudentDataSource(sl<FirebaseFirestore>()),
    );
  }

  // -------------------------
  // REPOSITORY
  // -------------------------
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        authDataSource: sl<FirebaseAuthDataSource>(),
        firestoreDataSource: sl<FirestoreStudentDataSource>(),
      ),
    );
  }

  // -------------------------
  // USE CASES
  // -------------------------
  sl
    ..registerLazySingleton<SignInUseCase>(
      () => SignInUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton<SignUpUseCase>(
      () => SignUpUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton<SignOutUseCase>(
      () => SignOutUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton<ForgotPasswordUseCase>(
      () => ForgotPasswordUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton<SendVerificationEmailUseCase>(
      () => SendVerificationEmailUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton<CheckEmailVerifiedUseCase>(
      () => CheckEmailVerifiedUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(sl<AuthRepository>()),
    );
}
