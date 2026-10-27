part of 'generated.dart';

class UpdateQuizVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  UpdateQuizVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateQuizData> dataDeserializer = (dynamic json)  => UpdateQuizData.fromJson(jsonDecode(json));
  
  Future<OperationResult<UpdateQuizData, void>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateQuizData, void> ref() {
    
    return _dataConnect.mutation("UpdateQuiz", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class UpdateQuizQuizUpdate {
  final String id;
  UpdateQuizQuizUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateQuizQuizUpdate otherTyped = other as UpdateQuizQuizUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateQuizQuizUpdate({
    required this.id,
  });
}

@immutable
class UpdateQuizData {
  final UpdateQuizQuizUpdate? quiz_update;
  UpdateQuizData.fromJson(dynamic json):
  
  quiz_update = json['quiz_update'] == null ? null : UpdateQuizQuizUpdate.fromJson(json['quiz_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateQuizData otherTyped = other as UpdateQuizData;
    return quiz_update == otherTyped.quiz_update;
    
  }
  @override
  int get hashCode => quiz_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (quiz_update != null) {
      json['quiz_update'] = quiz_update!.toJson();
    }
    return json;
  }

  UpdateQuizData({
    this.quiz_update,
  });
}

