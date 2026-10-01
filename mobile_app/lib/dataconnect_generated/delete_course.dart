part of 'generated.dart';

class DeleteCourseVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  DeleteCourseVariablesBuilder(this._dataConnect, );
  Deserializer<DeleteCourseData> dataDeserializer = (dynamic json)  => DeleteCourseData.fromJson(jsonDecode(json));
  
  Future<OperationResult<DeleteCourseData, void>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteCourseData, void> ref() {
    
    return _dataConnect.mutation("DeleteCourse", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class DeleteCourseCourseDelete {
  final String id;
  DeleteCourseCourseDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteCourseCourseDelete otherTyped = other as DeleteCourseCourseDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteCourseCourseDelete({
    required this.id,
  });
}

@immutable
class DeleteCourseData {
  final DeleteCourseCourseDelete? course_delete;
  DeleteCourseData.fromJson(dynamic json):
  
  course_delete = json['course_delete'] == null ? null : DeleteCourseCourseDelete.fromJson(json['course_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteCourseData otherTyped = other as DeleteCourseData;
    return course_delete == otherTyped.course_delete;
    
  }
  @override
  int get hashCode => course_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (course_delete != null) {
      json['course_delete'] = course_delete!.toJson();
    }
    return json;
  }

  DeleteCourseData({
    this.course_delete,
  });
}

