import 'package:openai_dart/openai_dart.dart';
import 'package:test/test.dart';

void main() {
  test('status codes map to typed errors', () {
    expect(
      () => throwForStatus(400, 'bad', const <String, dynamic>{}),
      throwsA(isA<BadRequestError>()),
    );
    expect(
      () => throwForStatus(401, 'auth', const <String, dynamic>{}),
      throwsA(isA<AuthenticationError>()),
    );
    expect(
      () => throwForStatus(429, 'rate', const <String, dynamic>{}),
      throwsA(isA<RateLimitError>()),
    );
    expect(
      () => throwForStatus(503, 'server', const <String, dynamic>{}),
      throwsA(isA<InternalServerError>()),
    );
  });
}
