# Loan Tracker - Backend API (Laravel)

## Overview
A Laravel REST API backend for the Loan Tracker mobile application. Handles authentication, loans, payments, friends, and push notifications.

---

## What's Done

### Authentication
- [x] User registration with email/phone
- [x] User login with Sanctum tokens
- [x] User logout
- [x] Get current user profile
- [x] Update profile
- [x] FCM token management

### Friends System
- [x] List friends
- [x] Search users by email
- [x] Send friend request
- [x] Accept/Reject friend request
- [x] Remove friend
- [x] Pending requests list

### Loans Management
- [x] Create loan
- [x] List loans (given & taken)
- [x] Get loan details
- [x] Update loan (due date)
- [x] Delete loan
- [x] Flexible due date (set/change/remove)
- [x] Overdue status tracking

### Payments
- [x] Submit payment (cash/e-wallet)
- [x] Screenshot upload to Cloudinary
- [x] Auto-accept cash payments
- [x] Pending e-wallet verification
- [x] Accept/Reject e-wallet payments
- [x] List pending verifications

### Notifications
- [x] Database notifications
- [x] List notifications (paginated)
- [x] Unread count
- [x] Mark as read (single/all)
- [x] Delete notification
- [x] Push notifications via Firebase

### Auto-Reminders (Scheduled)
- [x] Due today reminders
- [x] Due tomorrow reminders
- [x] Due in 3 days reminders
- [x] Overdue reminders (daily)
- [x] Duplicate prevention (once per day)

### Analytics
- [x] Summary (total lent/borrowed)
- [x] By friend breakdown
- [x] Monthly statistics
- [x] Upcoming due dates

### Security & Error Handling
- [x] Rate limiting for API endpoints
- [x] Comprehensive error handling
- [x] Consistent JSON error responses
- [x] User-friendly error messages

---

## Rate Limiting

API endpoints are protected with rate limiting:

| Limiter | Limit | Applied To |
|---------|-------|------------|
| `auth` | 5 req/min | Login, Register |
| `api` | 60 req/min | All authenticated routes |
| `sensitive` | 10 req/min | Payments (create/accept/reject) |

Error response when rate limited:
```json
{
  "success": false,
  "message": "Too many requests. Please try again later.",
  "error_code": "RATE_LIMITED",
  "retry_after": 60
}
```

---

## Error Handling

All API errors return consistent JSON responses:

```json
{
  "success": false,
  "message": "User-friendly error message",
  "error_code": "ERROR_CODE",
  "errors": {}  // For validation errors
}
```

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| `UNAUTHENTICATED` | 401 | Session expired |
| `VALIDATION_ERROR` | 422 | Invalid input |
| `NOT_FOUND` | 404 | Resource not found |
| `FORBIDDEN` | 403 | No permission |
| `METHOD_NOT_ALLOWED` | 405 | Wrong HTTP method |
| `RATE_LIMITED` | 429 | Too many requests |
| `SERVER_ERROR` | 500 | Internal error |

---

## What Needs To Be Done

### For Local Development

1. **Setup Environment**
   ```bash
   cd backend
   cp .env.example .env
   php artisan key:generate
   ```

2. **Configure Database** (`.env`)
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=loan_tracker
   DB_USERNAME=root
   DB_PASSWORD=
   ```

3. **Run Migrations**
   ```bash
   php artisan migrate
   ```

4. **Start Server**
   ```bash
   php artisan serve
   ```

5. **Test Scheduler Locally**
   ```bash
   # Run once manually
   php artisan loans:send-reminders

   # Or run scheduler continuously
   php artisan schedule:work
   ```

### For Production

1. **Server Requirements**
   - PHP 8.2+
   - MySQL 8.0+
   - Composer
   - SSL certificate (HTTPS)

2. **Environment Configuration** (`.env`)
   ```env
   APP_ENV=production
   APP_DEBUG=false
   APP_URL=https://your-domain.com

   DB_CONNECTION=mysql
   DB_HOST=your-db-host
   DB_PORT=3306
   DB_DATABASE=loan_tracker
   DB_USERNAME=your-db-user
   DB_PASSWORD=your-db-password

   # Cloudinary (already configured)
   CLOUDINARY_URL=cloudinary://...

   # Firebase (already configured)
   FIREBASE_CREDENTIALS=storage/firebase-credentials.json
   FIREBASE_PROJECT_ID=loan-tracker-a45bc
   ```

3. **Deployment Steps**
   ```bash
   # Upload files to server
   # Then run:
   composer install --optimize-autoloader --no-dev
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   php artisan migrate --force
   ```

4. **Setup Cron Job** (for auto-reminders)
   ```bash
   # Add to crontab (crontab -e)
   * * * * * cd /path-to-your-project && php artisan schedule:run >> /dev/null 2>&1
   ```

5. **Web Server Configuration**

   **Nginx:**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       root /var/www/loan-tracker/backend/public;

       add_header X-Frame-Options "SAMEORIGIN";
       add_header X-Content-Type-Options "nosniff";

       index index.php;

       charset utf-8;

       location / {
           try_files $uri $uri/ /index.php?$query_string;
       }

       location ~ \.php$ {
           fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
           fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
           include fastcgi_params;
       }

       location ~ /\.(?!well-known).* {
           deny all;
       }
   }
   ```

6. **Security Checklist**
   - [ ] Set `APP_DEBUG=false`
   - [ ] Use HTTPS only
   - [ ] Secure `.env` file permissions
   - [ ] Hide `firebase-credentials.json` from public
   - [ ] Setup firewall rules
   - [ ] Regular database backups

---

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/logout` | Logout |
| GET | `/api/auth/me` | Get current user |
| PUT | `/api/auth/profile` | Update profile |
| PUT | `/api/auth/fcm-token` | Update FCM token |

### Friends
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/friends` | List friends |
| GET | `/api/friends/pending` | Pending requests |
| GET | `/api/friends/search?email=` | Search users |
| POST | `/api/friends/request` | Send request |
| POST | `/api/friends/{id}/accept` | Accept request |
| POST | `/api/friends/{id}/reject` | Reject request |
| DELETE | `/api/friends/{id}` | Remove friend |

### Loans
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/loans` | List all loans |
| GET | `/api/loans/{id}` | Get loan details |
| POST | `/api/loans` | Create loan |
| PUT | `/api/loans/{id}` | Update loan |
| DELETE | `/api/loans/{id}` | Delete loan |
| POST | `/api/loans/{id}/remind` | Send reminder |

### Payments
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/payments` | Submit payment |
| GET | `/api/payments/pending` | Pending verifications |
| POST | `/api/payments/{id}/accept` | Accept payment |
| POST | `/api/payments/{id}/reject` | Reject payment |

### Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/notifications` | List notifications |
| GET | `/api/notifications/unread-count` | Unread count |
| PUT | `/api/notifications/{id}/read` | Mark as read |
| PUT | `/api/notifications/read-all` | Mark all read |
| DELETE | `/api/notifications/{id}` | Delete |

### Analytics
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/analytics/summary` | Summary stats |
| GET | `/api/analytics/by-friend` | By friend |
| GET | `/api/analytics/monthly` | Monthly stats |
| GET | `/api/analytics/upcoming-due` | Upcoming due |

---

## Project Structure

```
backend/
├── app/
│   ├── Console/
│   │   └── Commands/
│   │       └── SendLoanReminders.php
│   ├── Http/
│   │   └── Controllers/
│   │       └── Api/
│   │           ├── AuthController.php
│   │           ├── FriendController.php
│   │           ├── LoanController.php
│   │           ├── PaymentController.php
│   │           ├── NotificationController.php
│   │           └── AnalyticsController.php
│   ├── Models/
│   │   ├── User.php
│   │   ├── Loan.php
│   │   ├── Payment.php
│   │   ├── Friendship.php
│   │   ├── LoanNotification.php
│   │   └── ReminderSetting.php
│   └── Services/
│       └── FirebaseNotificationService.php
├── config/
│   ├── cloudinary.php
│   └── firebase.php
├── database/
│   └── migrations/
├── routes/
│   ├── api.php
│   └── console.php
├── storage/
│   └── firebase-credentials.json
└── .env
```

---

## Commands

```bash
# Start development server
php artisan serve

# Run migrations
php artisan migrate

# Run seeders
php artisan db:seed

# Clear caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear

# Run scheduler
php artisan schedule:work

# Run reminders manually
php artisan loans:send-reminders

# List routes
php artisan route:list --path=api
```

---

## Environment Variables

```env
# App
APP_NAME=LoanTracker
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost

# Database
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=loan_tracker
DB_USERNAME=root
DB_PASSWORD=

# Cloudinary
CLOUDINARY_URL=cloudinary://261579122291842:xxx@dxsx0phwi
CLOUDINARY_CLOUD_NAME=dxsx0phwi
CLOUDINARY_API_KEY=261579122291842
CLOUDINARY_API_SECRET=xxx

# Firebase
FIREBASE_CREDENTIALS=storage/firebase-credentials.json
FIREBASE_PROJECT_ID=loan-tracker-a45bc
```
