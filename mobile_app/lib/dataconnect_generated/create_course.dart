part of 'generated.dart';

class CreateCourseVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  CreateCourseVariablesBuilder(this._dataConnect, );
  Deserializer<CreateCourseData> dataDeserializer = (dynamic json)  => CreateCourseData.fromJson(jsonDecode(json));
  
  Future<OperationResult<CreateCourseData, void>> execute() {
    return ref().execute();
  }

  MutationRef<CreateCourseData, void> ref() {
    
    return _dataConnect.mutation("CreateCourse", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class CreateCourseCourseInsert {
  final String id;
  CreateCourseCourseInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateCourseCourseInsert otherTyped = other as CreateCourseCourseInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateCourseCourseInsert({
    required this.id,
  });
}

@immutable
class CreateCourseData {
  final CreateCourseCourseInsert course_insert;
  CreateCourseData.fromJson(dynamic json):
  
  course_insert = CreateCourseCourseInsert.fromJson(json['course_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateCourseData otherTyped = other as CreateCourseData;
    return course_insert == otherTyped.course_insert;
    
  }
  @override
  int get hashCode => course_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['course_insert'] = course_insert.toJson();
    return json;
  }

  CreateCourseData({
    required this.course_insert,
  });
}

