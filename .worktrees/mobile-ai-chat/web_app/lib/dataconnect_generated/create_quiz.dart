part of 'generated.dart';

class CreateQuizVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  CreateQuizVariablesBuilder(this._dataConnect, );
  Deserializer<CreateQuizData> dataDeserializer = (dynamic json)  => CreateQuizData.fromJson(jsonDecode(json));
  
  Future<OperationResult<CreateQuizData, void>> execute() {
    return ref().execute();
  }

  MutationRef<CreateQuizData, void> ref() {
    
    return _dataConnect.mutation("CreateQuiz", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class CreateQuizQuizInsert {
  final String id;
  CreateQuizQuizInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateQuizQuizInsert otherTyped = other as CreateQuizQuizInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateQuizQuizInsert({
    required this.id,
  });
}

@immutable
class CreateQuizData {
  final CreateQuizQuizInsert quiz_insert;
  CreateQuizData.fromJson(dynamic json):
  
  quiz_insert = CreateQuizQuizInsert.fromJson(json['quiz_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateQuizData otherTyped = other as CreateQuizData;
    return quiz_insert == otherTyped.quiz_insert;
    
  }
  @override
  int get hashCode => quiz_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['quiz_insert'] = quiz_insert.toJson();
    return json;
  }

  CreateQuizData({
    required this.quiz_insert,
  });
}

