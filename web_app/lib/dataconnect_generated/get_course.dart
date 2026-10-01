part of 'generated.dart';

class GetCourseVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetCourseVariablesBuilder(this._dataConnect, );
  Deserializer<GetCourseData> dataDeserializer = (dynamic json)  => GetCourseData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetCourseData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetCourseData, void> ref() {
    
    return _dataConnect.query("GetCourse", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetCourseCourse {
  final String title;
  final String description;
  GetCourseCourse.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']),
  description = nativeFromJson<String>(json['description']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCourseCourse otherTyped = other as GetCourseCourse;
    return title == otherTyped.title && 
    description == otherTyped.description;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, description.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    json['description'] = nativeToJson<String>(description);
    return json;
  }

  GetCourseCourse({
    required this.title,
    required this.description,
  });
}

@immutable
class GetCourseData {
  final GetCourseCourse? course;
  GetCourseData.fromJson(dynamic json):
  
  course = json['course'] == null ? null : GetCourseCourse.fromJson(json['course']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCourseData otherTyped = other as GetCourseData;
    return course == otherTyped.course;
    
  }
  @override
  int get hashCode => course.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (course != null) {
      json['course'] = course!.toJson();
    }
    return json;
  }

  GetCourseData({
    this.course,
  });
}

