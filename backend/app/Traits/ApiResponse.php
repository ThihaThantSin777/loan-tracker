<?php

namespace App\Traits;

trait ApiResponse
{
    /**
     * Return a success response
     */
    protected function success($data = null, string $message = 'Success', int $code = 200)
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $code);
    }

    /**
     * Return a created response
     */
    protected function created($data = null, string $message = 'Created successfully')
    {
        return $this->success($data, $message, 201);
    }

    /**
     * Return an error response
     */
    protected function error(string $message, string $errorCode = 'ERROR', int $code = 400, $errors = null)
    {
        $response = [
            'success' => false,
            'message' => $message,
            'error_code' => $errorCode,
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        return response()->json($response, $code);
    }

    /**
     * Return a not found response
     */
    protected function notFound(string $message = 'Resource not found')
    {
        return $this->error($message, 'NOT_FOUND', 404);
    }

    /**
     * Return an unauthorized response
     */
    protected function unauthorized(string $message = 'Unauthorized')
    {
        return $this->error($message, 'UNAUTHORIZED', 401);
    }

    /**
     * Return a forbidden response
     */
    protected function forbidden(string $message = 'Forbidden')
    {
        return $this->error($message, 'FORBIDDEN', 403);
    }

    /**
     * Return a validation error response
     */
    protected function validationError(string $message, $errors)
    {
        return $this->error($message, 'VALIDATION_ERROR', 422, $errors);
    }
}
