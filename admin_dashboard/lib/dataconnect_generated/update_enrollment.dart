part of 'generated.dart';

class UpdateEnrollmentVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  UpdateEnrollmentVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateEnrollmentData> dataDeserializer = (dynamic json)  => UpdateEnrollmentData.fromJson(jsonDecode(json));
  
  Future<OperationResult<UpdateEnrollmentData, void>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateEnrollmentData, void> ref() {
    
    return _dataConnect.mutation("UpdateEnrollment", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class UpdateEnrollmentEnrollmentUpdate {
  final String id;
  UpdateEnrollmentEnrollmentUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateEnrollmentEnrollmentUpdate otherTyped = other as UpdateEnrollmentEnrollmentUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateEnrollmentEnrollmentUpdate({
    required this.id,
  });
}

@immutable
class UpdateEnrollmentData {
  final UpdateEnrollmentEnrollmentUpdate? enrollment_update;
  UpdateEnrollmentData.fromJson(dynamic json):
  
  enrollment_update = json['enrollment_update'] == null ? null : UpdateEnrollmentEnrollmentUpdate.fromJson(json['enrollment_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateEnrollmentData otherTyped = other as UpdateEnrollmentData;
    return enrollment_update == otherTyped.enrollment_update;
    
  }
  @override
  int get hashCode => enrollment_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (enrollment_update != null) {
      json['enrollment_update'] = enrollment_update!.toJson();
    }
    return json;
  }

  UpdateEnrollmentData({
    this.enrollment_update,
  });
}

