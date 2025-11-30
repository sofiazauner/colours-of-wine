import './models.dart';

class ValidationResult {
  final bool ok;
  final String message;

  ValidationResult(this.ok, this.message);

  static ValidationResult success() {
    return ValidationResult(true, "");
  }

  static ValidationResult error(String message) {
    return ValidationResult(false, message);
  }
}

class WineDataValidator {
  static ValidationResult validate(WineData data) {
    if (data.grapeVariety.isEmpty) {
      return ValidationResult.error("Grape Variety is mandatory");
    }
    return ValidationResult.success();
  }
}
