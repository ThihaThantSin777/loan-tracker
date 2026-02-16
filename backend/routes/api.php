<?php

use App\Http\Controllers\Api\AnalyticsController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\FriendController;
use App\Http\Controllers\Api\LoanController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PaymentController;
use Illuminate\Support\Facades\Route;

// Public routes with strict rate limiting for auth
Route::middleware('throttle:auth')->group(function () {
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);
});

// Protected routes with API rate limiting
Route::middleware(['auth:sanctum', 'throttle:api'])->group(function () {

    // Auth
    Route::prefix('auth')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::put('/fcm-token', [AuthController::class, 'updateFcmToken']);
    });

    // Friends
    Route::prefix('friends')->group(function () {
        Route::get('/', [FriendController::class, 'index']);
        Route::get('/pending', [FriendController::class, 'pendingRequests']);
        Route::get('/search', [FriendController::class, 'searchUsers']);
        Route::post('/request', [FriendController::class, 'sendRequest']);
        Route::post('/{id}/accept', [FriendController::class, 'acceptRequest']);
        Route::post('/{id}/reject', [FriendController::class, 'rejectRequest']);
        Route::delete('/{id}', [FriendController::class, 'removeFriend']);
    });

    // Loans
    Route::prefix('loans')->group(function () {
        Route::get('/', [LoanController::class, 'index']);
        Route::get('/{id}', [LoanController::class, 'show']);
        Route::post('/', [LoanController::class, 'store']);
        Route::put('/{id}', [LoanController::class, 'update']);
        Route::delete('/{id}', [LoanController::class, 'destroy']);
        Route::get('/with-friend/{friendId}', [LoanController::class, 'loansWithFriend']);
        Route::post('/{id}/remind', [NotificationController::class, 'sendReminder']);
    });

    // Payments (with stricter rate limiting for sensitive operations)
    Route::prefix('payments')->group(function () {
        Route::middleware('throttle:sensitive')->group(function () {
            Route::post('/', [PaymentController::class, 'store']);
            Route::post('/{id}/accept', [PaymentController::class, 'accept']);
            Route::post('/{id}/reject', [PaymentController::class, 'reject']);
        });
        Route::get('/pending', [PaymentController::class, 'pendingVerifications']);
    });

    // Notifications
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::get('/unread-count', [NotificationController::class, 'unreadCount']);
        Route::put('/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::put('/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::delete('/{id}', [NotificationController::class, 'delete']);
    });

    // Analytics
    Route::prefix('analytics')->group(function () {
        Route::get('/summary', [AnalyticsController::class, 'summary']);
        Route::get('/by-friend', [AnalyticsController::class, 'byFriend']);
        Route::get('/monthly', [AnalyticsController::class, 'monthly']);
        Route::get('/upcoming-due', [AnalyticsController::class, 'upcomingDueDates']);
    });
});
