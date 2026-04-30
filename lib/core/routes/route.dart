import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nutri_guide/feature/home/view/home.dart';
import 'package:nutri_guide/feature/auth/view/forget_password.dart';
import 'package:nutri_guide/feature/auth/view/verify_email_page.dart';
import 'package:nutri_guide/feature/auth/view/login.dart';
import 'package:nutri_guide/feature/auth/view/signup_choose_role_page.dart';
import 'package:nutri_guide/feature/auth/view/signup_user_page.dart';
import 'package:nutri_guide/feature/auth/view/signup_doctor_page.dart';
import '../../doctorApp/feature/home/view/doctor_home.dart';
import '../../doctorApp/feature/home/view/doctor_welcome_page.dart';
import '../../doctorApp/feature/home/view/patient_details_view.dart';
import '../../feature/auth/middleware/GateMiddleware.dart';
import '../../feature/auth/middleware/auth_middleware.dart';
import '../../feature/auth/view/gate_page.dart';
import '../../feature/bmi/view/bmi_page.dart';
import '../../feature/calculations/view/doctor_patient_calculations_page.dart';
import '../../feature/calculations/view/calculations_history_page.dart';
import '../../feature/chat/view/chat_page.dart';
import '../../feature/chat/view/patient_profile_page.dart';
import '../../feature/doctor/view/doctor_details_page.dart';
import '../../feature/doctor/view/doctors_page.dart';
import '../../feature/doctor/view/payment_invoice_page.dart';
import '../../feature/doctor/subscription/subscription_info_page.dart';
import '../../feature/splash/view/splash.dart';
import '../../feature/welcome/view/welcome_page.dart';
import '../../feature/forum/view/forum_posts_page.dart';
import '../../feature/forum/view/forums_page.dart';
import '../../feature/tips/view/tips_main_page.dart';
import '../../feature/tips/view/tips_page.dart';
import '../../feature/athkar/view/spiritual_nutrition_page.dart';
import '../../feature/athkar/view/athkar_list_page.dart';
import '../../feature/ads/view/ad_details_page.dart';
import '../../feature/settings/view/settings_page.dart';
import '../../feature/settings/view/edit_profile_page.dart';
import '../../feature/settings/view/reminders_page.dart';
import '../../feature/settings/view/team_page.dart';
import '../../feature/consultations/view/consultations_page.dart';
import '../../feature/diet/view/diet_page.dart';
import '../../feature/diet/view/patient_diet_welcome_page.dart';
import '../../feature/diet/view/doctor_diets_page.dart';
import '../../feature/diet/view/diet_meals_page.dart';
import '../../feature/diet/view/create_diet_for_patient_page.dart';
import '../../feature/diet/view/diet_periods_page.dart';
import '../../feature/diet/view/diet_targets_page.dart';
import '../../feature/diet/view/portion_categories_page.dart';
import '../../feature/diet/view/diet_distribution_page.dart';
import '../../feature/diet/view/determine_meals_page.dart';
import '../../feature/diet/view/patient_diet_choice_page.dart';
import '../../feature/diet/view/patient_diets_list_page.dart';
import '../../feature/step_counter/view/step_counter_page.dart';
import '../../feature/medical_files/view/medical_files_page.dart';
import '../../feature/medical_tests/view/medical_tests_page.dart';
import 'app_route.dart';
import 'binding.dart';

abstract class AppPages {
  static final pages = [
    // Splash: no middleware here. Splash should only route to /gate
    GetPage(
      name: AppRoute.splash,
      page: () => const SplashScreen(),
      bindings: [InitBinding()],
    ),

    // Guest pages: prevent opening when logged in (will redirect to home/doctorHome)
    GetPage(
      name: AppRoute.login,
      page: () => const Login(),
      binding: LoginBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: AppRoute.signUp,
      page: () => const SignupChooseRolePage(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: AppRoute.signUpChooseRole,
      page: () => const SignupChooseRolePage(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: AppRoute.signUpUser,
      page: () => const SignupUserPage(),
      binding: SignupBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: AppRoute.signUpDoctor,
      page: () => const SignupDoctorPage(),
      binding: SignupBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: AppRoute.forgotPassword,
      page: () => const ForgotPasswordPage(),
      bindings: [ForgotBinding()],
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: AppRoute.verifyEmail,
      page: () => const VerifyEmailPage(),
      binding: VerifyEmailBinding(),
      middlewares: [GuestMiddleware()],
    ),

    // Gate: decides where to go (welcome when not logged in / home or doctorHome when logged in)
    GetPage(
      name: AppRoute.gate,
      page: () => const GatePage(),
      middlewares: [GateMiddleware()],
    ),

    // Welcome: shown before login (logo + text + Exit, Create Account, Login)
    GetPage(
      name: AppRoute.welcome,
      page: () => const WelcomePage(),
    ),

    // Protected pages
    GetPage(
      name: AppRoute.home,
      page: () => const HomePage(),
      bindings: [HomeBinding()],
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoute.adDetails,
      page: () => const AdDetailsPage(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: "/tips",
      page: () => const TipsMainPage(),
      binding: TipsMainBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/tips-list",
      page: () => const TipsPage(),
      binding: TipsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/spiritual-nutrition",
      page: () => const SpiritualNutritionPage(),
      binding: SpiritualNutritionBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/athkar-list",
      page: () => const AthkarListPage(),
      binding: AthkarListBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/settings",
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/edit-profile",
      page: () => const EditProfilePage(),
      binding: EditProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/reminders",
      page: () => const RemindersPage(),
      binding: RemindersBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/team",
      page: () => const TeamPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/doctors",
      page: () => const DoctorsPage(),
      binding: DoctorsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: "/bmi",
      page: () => const BmiPage(),
      binding: BmiBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoute.calculationsHistory,
      page: () => const CalculationsHistoryPage(),
      binding: CalculationsHistoryBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoute.medicalFiles,
      page: () => const MedicalFilesPage(),
      binding: MedicalFilesBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoute.medicalTests,
      page: () => const MedicalTestsPage(),
      binding: MedicalTestsBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: "/doctor-details",
      page: () => const DoctorDetailsPage(),
      binding: DoctorDetailsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoute.subscriptionInfo,
      page: () => const SubscriptionInfoPage(),
      binding: SubscriptionInfoBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoute.paymentInvoice,
      page: () => const PaymentInvoicePage(),
      binding: PaymentInvoiceBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoute.doctorWelcome,
      page: () => const DoctorWelcomePage(),
      middlewares: [DoctorOnlyMiddleware()],
      bindings: [HomeDoctorBinding()],
    ),
    GetPage(
      name: AppRoute.doctorHome,
      page: () => const DoctorPatientsPage(),
      middlewares: [DoctorOnlyMiddleware()],
      bindings: [HomeDoctorBinding()],
    ),
    GetPage(
      name: AppRoute.doctorPatientCalculations,
      page: () => const DoctorPatientCalculationsPage(),
      binding: DoctorPatientCalculationsBinding(),
      middlewares: [DoctorOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoute.chat,
      page: () => const ChatPage(),
      binding: ChatBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: "/patient-details",
      page: () => const PatientDetailsPage(),
      binding: PatientDetailsBinding(),
      middlewares: [DoctorOnlyMiddleware()], // Only doctors can view patient details
    ),

    GetPage(
      name: AppRoute.patientProfile,
      page: () => const PatientProfilePage(),
      binding: PatientProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoute.forums,
      page: () => const ForumsPage(),
      binding: ForumsBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoute.forumPosts,
      page: () => const ForumPostsPage(),
      binding: ForumPostsBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoute.consultations,
      page: () => const ConsultationsPage(),
      binding: ConsultationsBinding(),
      middlewares: [AuthMiddleware()], // Patients and doctors can access
    ),

    GetPage(
      name: AppRoute.patientDietWelcome,
      page: () => const PatientDietWelcomePage(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoute.diet,
      page: () => const DietPage(),
      binding: DietBinding(),
      middlewares: [AuthMiddleware()], // Patients can view, doctors can create
    ),

    GetPage(
      name: AppRoute.doctorDiets,
      page: () => const DoctorDietsPage(),
      binding: DietBinding(),
      middlewares: [DoctorOnlyMiddleware()],
    ),

    GetPage(
      name: AppRoute.dietMeals,
      page: () => const DietMealsPage(),
      binding: DietBinding(),
      middlewares: [PatientOnlyMiddleware()], // Only patients can view their meals
    ),

    GetPage(
      name: AppRoute.dietPeriods,
      page: () => const DietPeriodsPage(),
      binding: DietPeriodsBinding(),
      middlewares: [DoctorOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoute.dietTargets,
      page: () => const DietTargetsPage(),
      binding: DietTargetsBinding(),
      middlewares: [DoctorOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoute.dietPortionCategories,
      page: () => const PortionCategoriesPage(),
      binding: PortionCategoriesBinding(),
      middlewares: [DoctorOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoute.dietDistribution,
      page: () => const DietDistributionPage(),
      binding: DietDistributionBinding(),
      middlewares: [DoctorOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoute.dietDetermineMeals,
      page: () => const DetermineMealsPage(),
      binding: DetermineMealsBinding(),
      middlewares: [DoctorOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoute.createDietForPatient,
      page: () => const CreateDietForPatientPage(),
      binding: DietBinding(),
      middlewares: [DoctorOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoute.patientDietChoice,
      page: () => const PatientDietChoicePage(),
      binding: DietBinding(),
      middlewares: [DoctorOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoute.patientDietsList,
      page: () => const PatientDietsListPage(),
      binding: DietBinding(),
      middlewares: [DoctorOnlyMiddleware()],
    ),

    GetPage(
      name: "/step-counter",
      page: () => const StepCounterPage(),
      binding: StepCounterBinding(),
      middlewares: [AuthMiddleware()],
    ),

  ];
}