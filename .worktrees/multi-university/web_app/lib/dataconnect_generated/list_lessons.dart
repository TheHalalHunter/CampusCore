part of 'generated.dart';

class ListLessonsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListLessonsVariablesBuilder(this._dataConnect, );
  Deserializer<ListLessonsData> dataDeserializer = (dynamic json)  => ListLessonsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListLessonsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListLessonsData, void> ref() {
    
    return _dataConnect.query("ListLessons", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListLessonsLessons {
  final String title;
  ListLessonsLessons.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListLessonsLessons otherTyped = other as ListLessonsLessons;
    return title == otherTyped.title;
    
  }
  @override
  int get hashCode => title.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    return json;
  }

  ListLessonsLessons({
    required this.title,
  });
}

@immutable
class ListLessonsData {
  final List<ListLessonsLessons> lessons;
  ListLessonsData.fromJson(dynamic json):
  
  lessons = (json['lessons'] as List<dynamic>)
        .map((e) => ListLessonsLessons.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListLessonsData otherTyped = other as ListLessonsData;
    return lessons == otherTyped.lessons;
    
  }
  @override
  int get hashCode => lessons.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['lessons'] = lessons.map((e) => e.toJson()).toList();
    return json;
  }

  ListLessonsData({
    required this.lessons,
  });
}

