class OpenAIError implements Exception {
  OpenAIError(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class APIError extends OpenAIError {
  APIError({required this.status, required this.body, required String message})
    : super(message);

  final int status;
  final Map<String, dynamic>? body;
}

class BadRequestError extends APIError {
  BadRequestError({required super.message, required super.body})
    : super(status: 400);
}

class AuthenticationError extends APIError {
  AuthenticationError({required super.message, required super.body})
    : super(status: 401);
}

class PermissionDeniedError extends APIError {
  PermissionDeniedError({required super.message, required super.body})
    : super(status: 403);
}

class NotFoundError extends APIError {
  NotFoundError({required super.message, required super.body})
    : super(status: 404);
}

class UnprocessableEntityError extends APIError {
  UnprocessableEntityError({required super.message, required super.body})
    : super(status: 422);
}

class RateLimitError extends APIError {
  RateLimitError({required super.message, required super.body})
    : super(status: 429);
}

class InternalServerError extends APIError {
  InternalServerError({
    required super.status,
    required super.message,
    required super.body,
  });
}

class APIConnectionError extends OpenAIError {
  APIConnectionError(super.message);
}

Never throwForStatus(int status, String message, Map<String, dynamic>? body) {
  switch (status) {
    case 400:
      throw BadRequestError(message: message, body: body);
    case 401:
      throw AuthenticationError(message: message, body: body);
    case 403:
      throw PermissionDeniedError(message: message, body: body);
    case 404:
      throw NotFoundError(message: message, body: body);
    case 422:
      throw UnprocessableEntityError(message: message, body: body);
    case 429:
      throw RateLimitError(message: message, body: body);
    default:
      if (status >= 500) {
        throw InternalServerError(status: status, message: message, body: body);
      }
      throw APIError(status: status, body: body, message: message);
  }
}
