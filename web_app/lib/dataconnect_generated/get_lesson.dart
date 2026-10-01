part of 'generated.dart';

class GetLessonVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetLessonVariablesBuilder(this._dataConnect, );
  Deserializer<GetLessonData> dataDeserializer = (dynamic json)  => GetLessonData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetLessonData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetLessonData, void> ref() {
    
    return _dataConnect.query("GetLesson", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetLessonLesson {
  final String title;
  GetLessonLesson.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetLessonLesson otherTyped = other as GetLessonLesson;
    return title == otherTyped.title;
    
  }
  @override
  int get hashCode => title.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    return json;
  }

  GetLessonLesson({
    required this.title,
  });
}

@immutable
class GetLessonData {
  final GetLessonLesson? lesson;
  GetLessonData.fromJson(dynamic json):
  
  lesson = json['lesson'] == null ? null : GetLessonLesson.fromJson(json['lesson']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetLessonData otherTyped = other as GetLessonData;
    return lesson == otherTyped.lesson;
    
  }
  @override
  int get hashCode => lesson.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (lesson != null) {
      json['lesson'] = lesson!.toJson();
    }
    return json;
  }

  GetLessonData({
    this.lesson,
  });
}

