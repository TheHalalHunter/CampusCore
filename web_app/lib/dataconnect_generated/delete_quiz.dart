part of 'generated.dart';

class DeleteQuizVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  DeleteQuizVariablesBuilder(this._dataConnect, );
  Deserializer<DeleteQuizData> dataDeserializer = (dynamic json)  => DeleteQuizData.fromJson(jsonDecode(json));
  
  Future<OperationResult<DeleteQuizData, void>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteQuizData, void> ref() {
    
    return _dataConnect.mutation("DeleteQuiz", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class DeleteQuizQuizDelete {
  final String id;
  DeleteQuizQuizDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteQuizQuizDelete otherTyped = other as DeleteQuizQuizDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteQuizQuizDelete({
    required this.id,
  });
}

@immutable
class DeleteQuizData {
  final DeleteQuizQuizDelete? quiz_delete;
  DeleteQuizData.fromJson(dynamic json):
  
  quiz_delete = json['quiz_delete'] == null ? null : DeleteQuizQuizDelete.fromJson(json['quiz_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteQuizData otherTyped = other as DeleteQuizData;
    return quiz_delete == otherTyped.quiz_delete;
    
  }
  @override
  int get hashCode => quiz_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (quiz_delete != null) {
      json['quiz_delete'] = quiz_delete!.toJson();
    }
    return json;
  }

  DeleteQuizData({
    this.quiz_delete,
  });
}

