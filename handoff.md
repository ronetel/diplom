# Handoff — Wardrobe Backend

## Цель
Задеплоить бекенд бесплатно до августа + починить отправку email.

---

## Текущая проблема

### 1. Email не работает на Render
Render (free tier) **блокирует исходящие SMTP-порты** (25, 465, 587).
Nodemailer с smtp.mail.ru даёт `Connection timeout`.
Решение — использовать HTTP API вместо SMTP, **но**:
- Mailjet — не хотим
- Brevo — недоступен из России
- Resend — требует верифицированный домен, домена нет

### 2. Vercel не работает
Попробовали Vercel — упали на лимит **250MB** из-за тяжёлых пакетов:
- `@imgly/background-removal-node`
- `onnxruntime-node`

**Открытый вопрос:** нужна ли фича удаления фона на защите?
- Если нет → удалить пакеты → Vercel заработает
- Если да → нужна другая платформа

### 3. Хостинг
- Render — бесплатно навсегда, но SMTP заблокирован
- Vercel — 250MB лимит
- Railway / Fly.io — пользователь считает что 30 дней бесплатно (на самом деле Railway даёт $5/мес кредитов, может хватить до августа)

---

## Что было сделано

### `backend/services/email_service.js`
Файл менялся несколько раз. **Текущее состояние:** nodemailer + smtp.mail.ru (порт 465).
```
SMTP_USER = ronetel09@mail.ru
SMTP_PASS = пароль_приложения (из настроек mail.ru → Безопасность → Пароли для приложений)
```

### `backend/index.js`
- Добавлен `module.exports = app` для Vercel
- `app.listen` обёрнут в условие `if (!VERCEL)`

### `backend/vercel.json`
Создан для Vercel деплоя:
```json
{
  "version": 2,
  "builds": [{ "src": "index.js", "use": "@vercel/node" }],
  "routes": [{ "src": "/(.*)", "dest": "index.js" }]
}
```

### `backend/package.json`
Добавлен пакет `resend` (не используется, можно удалить).

---

## Варианты продолжения

### Вариант A — Vercel + без background removal
1. Удалить из `package.json`: `@imgly/background-removal-node`, `onnxruntime-node`
2. Удалить соответствующий код из роутов (найти где используется `backgroundRemoval`)
3. Задеплоить на Vercel
4. Для email — Vercel не блокирует SMTP, mail.ru должен работать
5. Добавить env vars на Vercel: `SMTP_USER`, `SMTP_PASS`, `DATABASE_URL`, `JWT_SECRET`, `CLOUDINARY_*`

### Вариант B — Render + другой email сервис
Остаться на Render, найти HTTP API email сервис доступный из России.
Возможные варианты: **Unisender** (российский), **SendPulse** (есть в России).

### Вариант C — Railway
- Деплой на Railway (git connect → авто деплой)
- SMTP не блокируется → nodemailer + mail.ru работает
- $5/мес кредитов — может хватить до августа при малой нагрузке

---

## Ключевые файлы
- `backend/index.js` — точка входа
- `backend/services/email_service.js` — сервис отправки email
- `backend/routes/auth.js` — регистрация, верификация email, сброс пароля
- `backend/routes/upload.js` — загрузка изображений (там скорее всего background removal)
- `backend/vercel.json` — конфиг Vercel
- `backend/package.json` — зависимости

## Переменные окружения (нужны везде)
```
DATABASE_URL
JWT_SECRET
SMTP_USER
SMTP_PASS
CLOUDINARY_CLOUD_NAME
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET
OPENWEATHER_API_KEY
GROQ_API_KEY
```
