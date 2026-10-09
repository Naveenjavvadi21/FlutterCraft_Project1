import 'package:chatflow/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators Tests', () {
    test('Email validator accepts valid emails', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(Validators.validateEmail('test.dev@chatflow.io'), isNull);
      expect(Validators.validateEmail('user+alias@domain.co'), isNull);
    });

    test('Email validator rejects invalid emails', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('invalid'), isNotNull);
      expect(Validators.validateEmail('missing@domain'), isNotNull);
      expect(Validators.validateEmail('@domain.com'), isNotNull);
    });

    test('Password validator enforces min length', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('strongPass123'), isNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('Confirm password validator matches password', () {
      expect(Validators.validateConfirmPassword('pass123', 'pass123'), isNull);
      expect(Validators.validateConfirmPassword('pass123', 'different'), isNotNull);
      expect(Validators.validateConfirmPassword('', 'pass123'), isNotNull);
    });

    test('Name validator ensures reasonable length', () {
      expect(Validators.validateName('John Doe'), isNull);
      expect(Validators.validateName('A'), isNotNull);
      expect(Validators.validateName(''), isNotNull);
    });

    test('Group name validator ensures reasonable length', () {
      expect(Validators.validateGroupName('Flutter Developers'), isNull);
      expect(Validators.validateGroupName('AB'), isNotNull);
      expect(Validators.validateGroupName(''), isNotNull);
    });

    test('Message validator checks whitespace trimming', () {
      expect(Validators.isValidMessage('Hello World'), isTrue);
      expect(Validators.isValidMessage('   '), isFalse);
      expect(Validators.isValidMessage(''), isFalse);
      expect(Validators.isValidMessage(null), isFalse);
    });
  });
}
