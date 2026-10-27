part of 'generated.dart';

class UpdateCourseVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  UpdateCourseVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateCourseData> dataDeserializer = (dynamic json)  => UpdateCourseData.fromJson(jsonDecode(json));
  
  Future<OperationResult<UpdateCourseData, void>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateCourseData, void> ref() {
    
    return _dataConnect.mutation("UpdateCourse", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class UpdateCourseCourseUpdate {
  final String id;
  UpdateCourseCourseUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCourseCourseUpdate otherTyped = other as UpdateCourseCourseUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateCourseCourseUpdate({
    required this.id,
  });
}

@immutable
class UpdateCourseData {
  final UpdateCourseCourseUpdate? course_update;
  UpdateCourseData.fromJson(dynamic json):
  
  course_update = json['course_update'] == null ? null : UpdateCourseCourseUpdate.fromJson(json['course_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCourseData otherTyped = other as UpdateCourseData;
    return course_update == otherTyped.course_update;
    
  }
  @override
  int get hashCode => course_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (course_update != null) {
      json['course_update'] = course_update!.toJson();
    }
    return json;
  }

  UpdateCourseData({
    this.course_update,
  });
}

