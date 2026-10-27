library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_user.dart';

part 'update_user.dart';

part 'delete_user.dart';

part 'get_user.dart';

part 'list_users.dart';

part 'create_course.dart';

part 'update_course.dart';

part 'delete_course.dart';

part 'get_course.dart';

part 'list_courses.dart';

part 'create_lesson.dart';

part 'update_lesson.dart';

part 'delete_lesson.dart';

part 'get_lesson.dart';

part 'list_lessons.dart';

part 'create_quiz.dart';

part 'update_quiz.dart';

part 'delete_quiz.dart';

part 'get_quiz.dart';

part 'list_quizzes.dart';

part 'create_enrollment.dart';

part 'update_enrollment.dart';

part 'delete_enrollment.dart';

part 'get_enrollment.dart';

part 'list_enrollments.dart';

part 'create_submission.dart';

part 'update_submission.dart';

part 'delete_submission.dart';

part 'get_submission.dart';

part 'list_submissions.dart';







class ExampleConnector {
  
  
  CreateUserVariablesBuilder createUser () {
    return CreateUserVariablesBuilder(dataConnect, );
  }
  
  
  UpdateUserVariablesBuilder updateUser () {
    return UpdateUserVariablesBuilder(dataConnect, );
  }
  
  
  DeleteUserVariablesBuilder deleteUser () {
    return DeleteUserVariablesBuilder(dataConnect, );
  }
  
  
  GetUserVariablesBuilder getUser () {
    return GetUserVariablesBuilder(dataConnect, );
  }
  
  
  ListUsersVariablesBuilder listUsers () {
    return ListUsersVariablesBuilder(dataConnect, );
  }
  
  
  CreateCourseVariablesBuilder createCourse () {
    return CreateCourseVariablesBuilder(dataConnect, );
  }
  
  
  UpdateCourseVariablesBuilder updateCourse () {
    return UpdateCourseVariablesBuilder(dataConnect, );
  }
  
  
  DeleteCourseVariablesBuilder deleteCourse () {
    return DeleteCourseVariablesBuilder(dataConnect, );
  }
  
  
  GetCourseVariablesBuilder getCourse () {
    return GetCourseVariablesBuilder(dataConnect, );
  }
  
  
  ListCoursesVariablesBuilder listCourses () {
    return ListCoursesVariablesBuilder(dataConnect, );
  }
  
  
  CreateLessonVariablesBuilder createLesson () {
    return CreateLessonVariablesBuilder(dataConnect, );
  }
  
  
  UpdateLessonVariablesBuilder updateLesson () {
    return UpdateLessonVariablesBuilder(dataConnect, );
  }
  
  
  DeleteLessonVariablesBuilder deleteLesson () {
    return DeleteLessonVariablesBuilder(dataConnect, );
  }
  
  
  GetLessonVariablesBuilder getLesson () {
    return GetLessonVariablesBuilder(dataConnect, );
  }
  
  
  ListLessonsVariablesBuilder listLessons () {
    return ListLessonsVariablesBuilder(dataConnect, );
  }
  
  
  CreateQuizVariablesBuilder createQuiz () {
    return CreateQuizVariablesBuilder(dataConnect, );
  }
  
  
  UpdateQuizVariablesBuilder updateQuiz () {
    return UpdateQuizVariablesBuilder(dataConnect, );
  }
  
  
  DeleteQuizVariablesBuilder deleteQuiz () {
    return DeleteQuizVariablesBuilder(dataConnect, );
  }
  
  
  GetQuizVariablesBuilder getQuiz () {
    return GetQuizVariablesBuilder(dataConnect, );
  }
  
  
  ListQuizzesVariablesBuilder listQuizzes () {
    return ListQuizzesVariablesBuilder(dataConnect, );
  }
  
  
  CreateEnrollmentVariablesBuilder createEnrollment () {
    return CreateEnrollmentVariablesBuilder(dataConnect, );
  }
  
  
  UpdateEnrollmentVariablesBuilder updateEnrollment () {
    return UpdateEnrollmentVariablesBuilder(dataConnect, );
  }
  
  
  DeleteEnrollmentVariablesBuilder deleteEnrollment () {
    return DeleteEnrollmentVariablesBuilder(dataConnect, );
  }
  
  
  GetEnrollmentVariablesBuilder getEnrollment () {
    return GetEnrollmentVariablesBuilder(dataConnect, );
  }
  
  
  ListEnrollmentsVariablesBuilder listEnrollments () {
    return ListEnrollmentsVariablesBuilder(dataConnect, );
  }
  
  
  CreateSubmissionVariablesBuilder createSubmission () {
    return CreateSubmissionVariablesBuilder(dataConnect, );
  }
  
  
  UpdateSubmissionVariablesBuilder updateSubmission () {
    return UpdateSubmissionVariablesBuilder(dataConnect, );
  }
  
  
  DeleteSubmissionVariablesBuilder deleteSubmission () {
    return DeleteSubmissionVariablesBuilder(dataConnect, );
  }
  
  
  GetSubmissionVariablesBuilder getSubmission () {
    return GetSubmissionVariablesBuilder(dataConnect, );
  }
  
  
  ListSubmissionsVariablesBuilder listSubmissions () {
    return ListSubmissionsVariablesBuilder(dataConnect, );
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'user',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds:0),
      storage: CacheStorage.persistent,
    );
    
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            cacheSettings: cacheSettings,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
