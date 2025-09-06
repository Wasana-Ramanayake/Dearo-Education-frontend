
const String baseUrl = "http://10.49.126.105:5000/api"; 

class Api {
  // ─── Auth ───────────────────────────────
  static String signup = "$baseUrl/auth/signup";
  static String login = "$baseUrl/auth/login";

  // ─── Profile ────────────────────────────
  static String profile = "$baseUrl/profile";

  // ─── Courses ───────────────────────────
  static String courses = "$baseUrl/courses";
  static String courseModules = "$baseUrl/course-modules";
  static String courseSubModules = "$baseUrl/course-sub-modules";

  // ─── Quizzes ───────────────────────────
  static String quizzes = "$baseUrl/quizzes";
  static String quizQuestions = "$baseUrl/quiz-questions";
  static String quizAnswers = "$baseUrl/quiz-answers";
  static String quizMarks = "$baseUrl/quiz-marks";

  // ─── Activities ────────────────────────
  static String activities = "$baseUrl/activities";

  // ─── Past Papers ───────────────────────
  static String pastPapers = "$baseUrl/papers";

  // ─── Password (Forgot / Reset / Verify) ─
  static String password = "$baseUrl/password";

  // ─── Uploads (Static Files) ────────────
  static String uploads = "$baseUrl/uploads";

  // ─── Example helper methods (optional) ─
  static String courseModuleById(String id) => "$courseModules/$id";
  static String courseSubModuleById(String id) => "$courseSubModules/$id";
  static String quizById(String id) => "$quizzes/$id";
  static String quizQuestionById(String id) => "$quizQuestions/$id";
  static String activityById(String id) => "$activities/$id";
  static String paperById(String id) => "$pastPapers/$id";
}
