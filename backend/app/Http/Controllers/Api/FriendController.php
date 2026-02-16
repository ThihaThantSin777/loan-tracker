<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Friendship;
use App\Models\LoanNotification;
use App\Models\User;
use Illuminate\Http\Request;

class FriendController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        // Get all accepted friendships
        $sentFriends = Friendship::where('user_id', $user->id)
            ->where('status', 'accepted')
            ->with('friend')
            ->get()
            ->pluck('friend');

        $receivedFriends = Friendship::where('friend_id', $user->id)
            ->where('status', 'accepted')
            ->with('user')
            ->get()
            ->pluck('user');

        $friends = $sentFriends->merge($receivedFriends);

        return response()->json([
            'friends' => $friends,
        ]);
    }

    public function pendingRequests(Request $request)
    {
        $user = $request->user();

        // Requests sent to this user
        $received = Friendship::where('friend_id', $user->id)
            ->where('status', 'pending')
            ->with('user')
            ->get();

        // Requests sent by this user
        $sent = Friendship::where('user_id', $user->id)
            ->where('status', 'pending')
            ->with('friend')
            ->get();

        return response()->json([
            'received' => $received,
            'sent' => $sent,
        ]);
    }

    public function sendRequest(Request $request)
    {
        $request->validate([
            'email' => 'required_without:phone|email|exists:users,email',
            'phone' => 'required_without:email|string|exists:users,phone',
        ]);

        $user = $request->user();

        // Find friend by email or phone
        $friend = User::where('email', $request->email)
            ->orWhere('phone', $request->phone)
            ->first();

        if (!$friend) {
            return response()->json(['message' => 'User not found'], 404);
        }

        if ($friend->id === $user->id) {
            return response()->json(['message' => 'Cannot add yourself as friend'], 400);
        }

        // Check if friendship already exists
        $existing = Friendship::where(function ($query) use ($user, $friend) {
            $query->where('user_id', $user->id)->where('friend_id', $friend->id);
        })->orWhere(function ($query) use ($user, $friend) {
            $query->where('user_id', $friend->id)->where('friend_id', $user->id);
        })->first();

        if ($existing) {
            return response()->json(['message' => 'Friendship already exists'], 400);
        }

        $friendship = Friendship::create([
            'user_id' => $user->id,
            'friend_id' => $friend->id,
            'status' => 'pending',
        ]);

        // Send notification
        LoanNotification::create([
            'user_id' => $friend->id,
            'sender_id' => $user->id,
            'type' => 'friend_request',
            'title' => 'New Friend Request',
            'message' => "{$user->name} sent you a friend request",
        ]);

        return response()->json([
            'message' => 'Friend request sent',
            'friendship' => $friendship,
        ], 201);
    }

    public function acceptRequest(Request $request, $id)
    {
        $user = $request->user();

        $friendship = Friendship::where('id', $id)
            ->where('friend_id', $user->id)
            ->where('status', 'pending')
            ->firstOrFail();

        $friendship->update(['status' => 'accepted']);

        // Send notification to requester
        LoanNotification::create([
            'user_id' => $friendship->user_id,
            'sender_id' => $user->id,
            'type' => 'friend_accepted',
            'title' => 'Friend Request Accepted',
            'message' => "{$user->name} accepted your friend request",
        ]);

        return response()->json([
            'message' => 'Friend request accepted',
            'friendship' => $friendship,
        ]);
    }

    public function rejectRequest(Request $request, $id)
    {
        $user = $request->user();

        $friendship = Friendship::where('id', $id)
            ->where('friend_id', $user->id)
            ->where('status', 'pending')
            ->firstOrFail();

        $friendship->delete();

        return response()->json([
            'message' => 'Friend request rejected',
        ]);
    }

    public function removeFriend(Request $request, $id)
    {
        $user = $request->user();

        $friendship = Friendship::where(function ($query) use ($user, $id) {
            $query->where('user_id', $user->id)->where('friend_id', $id);
        })->orWhere(function ($query) use ($user, $id) {
            $query->where('user_id', $id)->where('friend_id', $user->id);
        })->firstOrFail();

        $friendship->delete();

        return response()->json([
            'message' => 'Friend removed',
        ]);
    }

    public function searchUsers(Request $request)
    {
        $request->validate([
            'query' => 'required|string|min:2',
        ]);

        $user = $request->user();
        $query = $request->query('query');

        $users = User::where('id', '!=', $user->id)
            ->where(function ($q) use ($query) {
                $q->where('name', 'like', "%{$query}%")
                    ->orWhere('email', 'like', "%{$query}%")
                    ->orWhere('phone', 'like', "%{$query}%");
            })
            ->limit(20)
            ->get(['id', 'name', 'email', 'phone', 'avatar_url']);

        return response()->json([
            'users' => $users,
        ]);
    }
}
