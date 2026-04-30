class AppRoute {
  static String splash = '/';
  static String login = '/login';
  static String signUp = '/signup';
  static String signUpChooseRole = '/signup-choose-role';
  static String signUpUser = '/signup-user';
  static String signUpDoctor = '/signup-doctor';
  static String home = '/home';
  static String forgotPassword = '/forgot_password';
  static String verifyEmail = '/verify-email';
  static String gate = '/gate';
  static String patientDetails = '/patient-details';
  static const patientProfile = "/patient-profile";
  static const forums = "/forums";
  static const forumPosts = "/forum-posts";
  static const chat = "/chat";
  static const consultations = "/consultations";
  static const diet = "/diet";
  static const patientDietWelcome = "/patient-diet-welcome";
  static const doctorDiets = "/doctor-diets";
  static const dietMeals = "/diet-meals";
  static const createDietForPatient = "/create-diet-for-patient";
  static const patientDietChoice = "/patient-diet-choice";
  static const patientDietsList = "/patient-diets-list";
  static const dietPeriods = "/diet-periods";
  static const dietTargets = "/diet-targets";
  static const dietPortionCategories = "/diet-portion-categories";
  static const dietDistribution = "/diet-distribution";
  static const dietDetermineMeals = "/diet-determine-meals";
  static const welcome = "/welcome";
  static const medicalFiles = "/medical-files";
  static const medicalTests = "/medical-tests";
  static const calculationsHistory = "/calculations-history";
  static const doctorPatientCalculations = "/doctor-patient-calculations";

  /// Public ad details (from home banner)
  static const adDetails = "/ad-details";

//   doctor
  static const doctorWelcome = "/doctor-welcome";
  static const doctorHome = "/doctor-home";

  /// Subscribe flow: info form → payment invoice
  static const subscriptionInfo = "/subscription-info";
  static const paymentInvoice = "/payment-invoice";
}
