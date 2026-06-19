import 'package:firebase_core/firebase_core.dart';
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
import 'data/datasources/remote/sr_review_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/complaint_repository.dart';
import 'data/repositories/sr_review_repository.dart';
import 'domain/usecases/get_analytics_usecase.dart';
import 'domain/usecases/sr_approve_complaint_usecase.dart';
import 'domain/usecases/sr_reject_complaint_usecase.dart';
import 'firebase_options.dart';
import 'presentation/bloc/analytics/analytics_cubit.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/complaint/complaint_bloc.dart';
import 'presentation/bloc/sr_review/sr_review_bloc.dart';
import 'presentation/bloc/submit_complaint/submit_complaint_cubit.dart';
import 'services/notification_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Hive for offline drafts
  await Hive.initFlutter();
  Hive.registerAdapter(ComplaintDraftAdapter());

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization skipped or failed: $e');
  }

  // Initialize notification service (FCM + local notifications)
  try {
    await NotificationService.instance.initialize(navigatorKey: _navigatorKey);
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
  }

  // Core services
  final dioClient = DioClient();
  final networkInfo = NetworkInfo();

  // Data sources
  final authRemote = AuthRemoteDataSource(dioClient: dioClient);
  final authLocal = AuthLocalDataSource();
  final complaintRemote = ComplaintRemoteDataSource(dioClient: dioClient);
  final complaintLocal = ComplaintLocalDataSource();
  final srReviewRemote = SrReviewRemoteDataSource(dioClient: dioClient);

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
  final srReviewRepo = SrReviewRepository(
    remoteDataSource: srReviewRemote,
    networkInfo: networkInfo,
  );

  // Use-cases (Prabhava)
  final srApproveUseCase = SrApproveComplaintUseCase(repository: srReviewRepo);
  final srRejectUseCase = SrRejectComplaintUseCase(repository: srReviewRepo);
  final getAnalyticsUseCase = GetAnalyticsUseCase(repository: complaintRepo);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => authRepo),
        RepositoryProvider<ComplaintRepository>(create: (_) => complaintRepo),
        RepositoryProvider<SrReviewRepository>(create: (_) => srReviewRepo),
      ],
      child: MultiBlocProvider(
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
          // Prabhava — SR review workflow
          BlocProvider<SrReviewBloc>(
            create: (_) => SrReviewBloc(
              repository: srReviewRepo,
              approveUseCase: srApproveUseCase,
              rejectUseCase: srRejectUseCase,
            ),
          ),
          // Prabhava — Analytics dashboard
          BlocProvider<AnalyticsCubit>(
            create: (_) => AnalyticsCubit(getAnalyticsUseCase: getAnalyticsUseCase),
          ),
        ],
        child: ScmsApp(navigatorKey: _navigatorKey),
      ),
    ),
  );
}
