import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/network/dio_client.dart';
import 'core/network/network_info.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/datasources/local/complaint_local_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/complaint_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/complaint_repository.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/complaint/complaint_bloc.dart';
import 'presentation/bloc/submit_complaint/submit_complaint_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Hive for offline drafts
  await Hive.initFlutter();
  Hive.registerAdapter(ComplaintDraftAdapter());

  // TODO: Prabhava — Initialize Firebase here
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await NotificationService.initialize();

  // Core services
  final dioClient = DioClient();
  final networkInfo = NetworkInfo();

  // Data sources
  final authRemote = AuthRemoteDataSource(dioClient: dioClient);
  final authLocal = AuthLocalDataSource();
  final complaintRemote = ComplaintRemoteDataSource(dioClient: dioClient);
  final complaintLocal = ComplaintLocalDataSource();

  // Repositories
  final authRepo = AuthRepository(
    remoteDataSource: authRemote,
    localDataSource: authLocal,
    networkInfo: networkInfo,
  );
  final complaintRepo = ComplaintRepository(
    remoteDataSource: complaintRemote,
    localDataSource: complaintLocal,
    networkInfo: networkInfo,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: authRepo)..add(AppStarted()),
        ),
        BlocProvider<ComplaintBloc>(
          create: (_) => ComplaintBloc(repository: complaintRepo),
        ),
        BlocProvider<SubmitComplaintCubit>(
          create: (_) => SubmitComplaintCubit(repository: complaintRepo),
        ),
        // TODO: Prabhava — Add AnalyticsCubit and SrReviewBloc here
      ],
      child: const ScmsApp(),
    ),
  );
}
