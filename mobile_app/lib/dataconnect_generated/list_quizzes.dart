part of 'generated.dart';

class ListQuizzesVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListQuizzesVariablesBuilder(this._dataConnect, );
  Deserializer<ListQuizzesData> dataDeserializer = (dynamic json)  => ListQuizzesData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListQuizzesData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListQuizzesData, void> ref() {
    
    return _dataConnect.query("ListQuizzes", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListQuizzesQuizzes {
  final String title;
  ListQuizzesQuizzes.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListQuizzesQuizzes otherTyped = other as ListQuizzesQuizzes;
    return title == otherTyped.title;
    
  }
  @override
  int get hashCode => title.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    return json;
  }

  ListQuizzesQuizzes({
    required this.title,
  });
}

@immutable
class ListQuizzesData {
  final List<ListQuizzesQuizzes> quizzes;
  ListQuizzesData.fromJson(dynamic json):
  
  quizzes = (json['quizzes'] as List<dynamic>)
        .map((e) => ListQuizzesQuizzes.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListQuizzesData otherTyped = other as ListQuizzesData;
    return quizzes == otherTyped.quizzes;
    
  }
  @override
  int get hashCode => quizzes.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['quizzes'] = quizzes.map((e) => e.toJson()).toList();
    return json;
  }

  ListQuizzesData({
    required this.quizzes,
  });
}

