 class ApiLinks {
   // static const String baseUrl =
   //     "https://health-system-backend-c9pb.onrender.com/api";
   static const String baseUrl =
          "https://health-system-backend-l7m5.onrender.com/api";

   /// Base URL for static assets (images) - strip /api from baseUrl
   static String get storageBase =>
       baseUrl.replaceFirst(RegExp(r'/api$'), '').replaceFirst(RegExp(r'/$'), '');
  // static const String baseUrl =
  //      "http://10.0.2.2:8000/api";
   
   // auth url
   static const String register = "$baseUrl/register";
   static const String login = "$baseUrl/login";
   static const String forgotPassword = "$baseUrl/forgot-password";
   static const String verifyEmail = "$baseUrl/verify-email";
   static const String resendVerificationCode = "$baseUrl/resend-verification-code";
   static const String subscriptions = "$baseUrl/subscriptions";
  /// Patient subscription status by user id (returns object)
  static String usersSubscribedByUserId(int userId) => "$baseUrl/users-subscribed/$userId";
   static const String chatMessages = "$baseUrl/chat/messages";
   static const String chatHistory = "$baseUrl/chat/history"; // + /{doctorId} — patient's view
   static String chatConversationMessages(int patientId) => "$baseUrl/chat/conversations/$patientId/messages"; // doctor's view: messages with this patient
   static const String doctorPatients = "$baseUrl/doctor/patients";
   static const String doctorProfile = "$baseUrl/doctor/profile"; // GET current doctor (auth)
  static String doctorPatient(int patientId) => "$baseUrl/doctor/patients/$patientId"; // GET single patient (doctor app)
   static String patient(int patientId) => "$baseUrl/patients/$patientId/"; // GET single patient with subscription info
  static String doctorPatientMacros(int patientId) => "$baseUrl/doctor/patients/$patientId/macros"; // GET + PUT (doctor app)
  static String doctorPatientCalculations(int patientId) => "$baseUrl/doctor/patients/$patientId/calculations"; // GET latest calculations for patient (doctor app)
   static const String patientProfile = "$baseUrl/patients/profile";
   static const String patientMyDoctors = "$baseUrl/patients/my-doctors"; // GET subscribed doctors for patient

   // forums (per API doc: GET /forums, POST /forums/{id}/join, GET /forums/{id}/posts, POST /forums/{id}/posts)
   static const String forumsBase   = "$baseUrl/forums";               // GET list, POST /{id}/join, GET /{id}/posts, POST /{id}/posts
   static const String postsBase   = "$baseUrl/posts";                 // POST /{id}/like, POST /{id}/unlike

   // consultations (sessions)
   static const String consultations = "$baseUrl/consultations";        // POST to request, GET to list

   // diet
   static const String diets = "$baseUrl/diets";                      // GET all
   static const String dietPlans = "$baseUrl/diet-plans";              // POST create
   static String diet(int id) => "$baseUrl/diets/$id";                // GET, PUT, DELETE
   static String dietPlan(int id) => "$baseUrl/diet-plans/$id";       // GET single diet plan (full details)
   static String dietStatus(int id) => "$baseUrl/diets/$id/status";   // PUT change status
   static const String myDiet = "$baseUrl/my-diet";                   // GET current patient diet
   static const String myDietMeals = "$baseUrl/my-diet/meals";        // GET diet meals
   static const String dietPeriods = "$baseUrl/diet-periods";         // GET diet periods
   static const String dietComponents = "$baseUrl/diet-components";   // GET diet components
   static const String dietNotes = "$baseUrl/diet-notes";             // GET diet notes
   static const String dietTypes = "$baseUrl/diet-types";             // GET diet types

  // medical files (الملفات المساعدة)
  static const String medicalFiles = "$baseUrl/medical-files";
  static String medicalFileDownload(int id) => "$baseUrl/medical-files/$id/download";

  // medical tests (الفحص الطبي) - patient uploads from chat
  static const String medicalTests = "$baseUrl/medical-tests";
  static String medicalTestDownload(int id) => "$baseUrl/medical-tests/$id/download";

   // doctors (auth for rate)
   static String doctorRate(int doctorId) => "$baseUrl/doctors/$doctorId/rate"; // POST to rate
   static String doctorRates(int doctorId) => "$baseUrl/doctors/$doctorId/rates"; // GET doctor's aggregate rating
   static String get myRates => "$baseUrl/my-rates"; // GET my rating (query: doctor_id)

   // public (no auth - no token required)
   static const String publicAds = "$baseUrl/public/ads";
   static const String publicDoctors = "$baseUrl/public/doctors";     // GET list of doctors (no auth)
   static const String publicAthkar = "$baseUrl/public/athkar";

   // developer_api_guide: calculations, references, meals
   static const String calculationsHistory = "$baseUrl/calculations/history"; // GET - history for current patient
   static String patientCalculations(int patientId) => "$baseUrl/patients/$patientId/calculations"; // GET - history for specific patient (doctor)
   static const String calculationsNutrition = "$baseUrl/calculations/nutrition"; // POST - BMI, BMR, TEF, TDEE, macros
   static const String referencesNutritionManuals = "$baseUrl/references/nutrition-manuals"; // GET - for doctors
   static const String mealsApi = "$baseUrl/meals"; // POST - meal with serving, carbo, protin, fat

   // user profile update
   static String updateUser(int userId) => "$baseUrl/users/$userId";

 }
