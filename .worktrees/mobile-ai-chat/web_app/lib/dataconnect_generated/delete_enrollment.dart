part of 'generated.dart';

class DeleteEnrollmentVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  DeleteEnrollmentVariablesBuilder(this._dataConnect, );
  Deserializer<DeleteEnrollmentData> dataDeserializer = (dynamic json)  => DeleteEnrollmentData.fromJson(jsonDecode(json));
  
  Future<OperationResult<DeleteEnrollmentData, void>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteEnrollmentData, void> ref() {
    
    return _dataConnect.mutation("DeleteEnrollment", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class DeleteEnrollmentEnrollmentDelete {
  final String id;
  DeleteEnrollmentEnrollmentDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteEnrollmentEnrollmentDelete otherTyped = other as DeleteEnrollmentEnrollmentDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteEnrollmentEnrollmentDelete({
    required this.id,
  });
}

@immutable
class DeleteEnrollmentData {
  final DeleteEnrollmentEnrollmentDelete? enrollment_delete;
  DeleteEnrollmentData.fromJson(dynamic json):
  
  enrollment_delete = json['enrollment_delete'] == null ? null : DeleteEnrollmentEnrollmentDelete.fromJson(json['enrollment_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteEnrollmentData otherTyped = other as DeleteEnrollmentData;
    return enrollment_delete == otherTyped.enrollment_delete;
    
  }
  @override
  int get hashCode => enrollment_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (enrollment_delete != null) {
      json['enrollment_delete'] = enrollment_delete!.toJson();
    }
    return json;
  }

  DeleteEnrollmentData({
    this.enrollment_delete,
  });
}

