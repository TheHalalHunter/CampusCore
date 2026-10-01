part of 'generated.dart';

class ListCoursesVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListCoursesVariablesBuilder(this._dataConnect, );
  Deserializer<ListCoursesData> dataDeserializer = (dynamic json)  => ListCoursesData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListCoursesData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListCoursesData, void> ref() {
    
    return _dataConnect.query("ListCourses", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListCoursesCourses {
  final String title;
  ListCoursesCourses.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListCoursesCourses otherTyped = other as ListCoursesCourses;
    return title == otherTyped.title;
    
  }
  @override
  int get hashCode => title.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    return json;
  }

  ListCoursesCourses({
    required this.title,
  });
}

@immutable
class ListCoursesData {
  final List<ListCoursesCourses> courses;
  ListCoursesData.fromJson(dynamic json):
  
  courses = (json['courses'] as List<dynamic>)
        .map((e) => ListCoursesCourses.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListCoursesData otherTyped = other as ListCoursesData;
    return courses == otherTyped.courses;
    
  }
  @override
  int get hashCode => courses.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['courses'] = courses.map((e) => e.toJson()).toList();
    return json;
  }

  ListCoursesData({
    required this.courses,
  });
}

