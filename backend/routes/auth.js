const express = require("express");
const router = express.Router();
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const pool = require("../db");
require("dotenv").config();

const JWT_SECRET = process.env.JWT_SECRET || "replace_this_with_secure_secret";
const SALT_ROUNDS = 10;

// ============================================
// Middleware для проверки роли
// ============================================
const requireRole = (roles) => {
  return (req, res, next) => {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ message: "No token" });

    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      if (!roles.includes(decoded.role)) {
        return res.status(403).json({ message: "Insufficient permissions" });
      }
      req.user = decoded;
      next();
    } catch (err) {
      return res.status(401).json({ message: "Invalid token" });
    }
  };
};

// ============================================
// Регистрация
// ============================================
router.post("/register", async (req, res) => {
  const { email, username, password } = req.body;

  if (!email || !username || !password) {
    return res
      .status(400)
      .json({ message: "Email, username and password required" });
  }

  // Валидация email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ message: "Invalid email format" });
  }

  // Валидация username (минимум 3 символа, буквы, цифры, подчеркивания)
  const usernameRegex = /^[a-zA-Z0-9_]{3,30}$/;
  if (!usernameRegex.test(username)) {
    return res
      .status(400)
      .json({
        message:
          "Username must be 3-30 characters, alphanumeric and underscores only",
      });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

    const result = await pool.query(
      `INSERT INTO users(email, username, password_hash, role) VALUES ($1,$2,$3,$4) RETURNING id, email, username, role, created_at`,
      [email, username, hashedPassword, "user"],
    );

    const user = result.rows[0];
    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
      },
      JWT_SECRET,
      { expiresIn: "7d" },
    );

    res.status(201).json({
      token,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
        createdAt: user.created_at,
        clothesCount: 0,
        outfitsCount: 0,
        postsCount: 0,
      },
    });
  } catch (err) {
    console.error("Registration error:", err);
    if (err.code === "23505") {
      if (err.constraint?.includes("email")) {
        return res.status(409).json({ message: "Email already exists" });
      }
      if (err.constraint?.includes("username")) {
        return res.status(409).json({ message: "Username already exists" });
      }
    }
    res.status(500).json({ message: "Internal error" });
  }
});

// ============================================
// Вход
// ============================================
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: "Email and password required" });
  }

  try {
    const result = await pool.query(
      `SELECT id, email, username, password_hash, role, avatar_url, is_banned, ban_until, ban_reason, created_at
       FROM users WHERE email = $1`,
      [email],
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const user = result.rows[0];

    // Проверка бана
    if (user.is_banned) {
      if (user.ban_until && new Date(user.ban_until) > new Date()) {
        return res.status(403).json({
          message: "Account is banned",
          banReason: user.ban_reason,
          banUntil: user.ban_until,
        });
      }
      // Если бан истек, снимаем его
      if (user.ban_until && new Date(user.ban_until) <= new Date()) {
        await pool.query(
          "UPDATE users SET is_banned = FALSE, ban_until = NULL, ban_reason = NULL WHERE id = $1",
          [user.id],
        );
      }
    }

    const passwordMatch = await bcrypt.compare(password, user.password_hash);
    if (!passwordMatch) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
      },
      JWT_SECRET,
      { expiresIn: "7d" },
    );

    // Получить статистику пользователя
    const statsResult = await pool.query(
      `SELECT
        (SELECT COUNT(*) FROM clothes WHERE owner_id = $1) as clothes_count,
        (SELECT COUNT(*) FROM outfits WHERE owner_id = $1) as outfits_count,
        (SELECT COUNT(*) FROM posts WHERE author_id = $1) as posts_count`,
      [user.id],
    );
    const stats = statsResult.rows[0];

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
        avatarUrl: user.avatar_url,
        createdAt: user.created_at,
        clothesCount: parseInt(stats.clothes_count),
        outfitsCount: parseInt(stats.outfits_count),
        postsCount: parseInt(stats.posts_count),
      },
    });
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: "Internal error" });
  }
});

// ============================================
// Получить текущего пользователя
// ============================================
router.get("/me", async (req, res) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) return res.status(401).json({ message: "No token" });

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const result = await pool.query(
      `SELECT id, email, username, role, avatar_url, created_at,
        (SELECT COUNT(*) FROM clothes WHERE owner_id = $1) as clothes_count,
        (SELECT COUNT(*) FROM outfits WHERE owner_id = $1) as outfits_count,
        (SELECT COUNT(*) FROM posts WHERE author_id = $1) as posts_count
       FROM users WHERE id = $1`,
      [decoded.id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({ user: result.rows[0] });
  } catch (err) {
    res.status(401).json({ message: "Invalid token" });
  }
});

// ============================================
// Обновить профиль
// ============================================
router.put("/profile", async (req, res) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) return res.status(401).json({ message: "No token" });

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const { username, avatarUrl } = req.body;

    const updates = [];
    const values = [];
    let paramCount = 1;

    if (username) {
      if (!/^[a-zA-Z0-9_]{3,30}$/.test(username)) {
        return res.status(400).json({ message: "Invalid username format" });
      }
      updates.push(`username = $${paramCount++}`);
      values.push(username);
    }

    if (avatarUrl !== undefined) {
      updates.push(`avatar_url = $${paramCount++}`);
      values.push(avatarUrl);
    }

    if (updates.length === 0) {
      return res.status(400).json({ message: "No fields to update" });
    }

    values.push(decoded.id);
    const query = `UPDATE users SET ${updates.join(", ")} WHERE id = $${paramCount} RETURNING
      id, email, username, avatar_url, role, created_at,
      (SELECT COUNT(*) FROM clothes WHERE owner_id = $${paramCount}) as clothes_count,
      (SELECT COUNT(*) FROM outfits WHERE owner_id = $${paramCount}) as outfits_count,
      (SELECT COUNT(*) FROM posts WHERE author_id = $${paramCount}) as posts_count`;

    const result = await pool.query(query, values);
    res.json({ user: result.rows[0] });
  } catch (err) {
    console.error("Update profile error:", err);
    if (err.code === "23505") {
      return res.status(409).json({ message: "Username already exists" });
    }
    res.status(500).json({ message: "Internal error" });
  }
});

// ============================================
// Сменить пароль
// ============================================
router.put("/password", async (req, res) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) return res.status(401).json({ message: "No token" });

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res
        .status(400)
        .json({ message: "Current and new password required" });
    }

    const userResult = await pool.query(
      "SELECT password_hash FROM users WHERE id = $1",
      [decoded.id],
    );
    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    const passwordMatch = await bcrypt.compare(
      currentPassword,
      userResult.rows[0].password_hash,
    );
    if (!passwordMatch) {
      return res.status(401).json({ message: "Current password is incorrect" });
    }

    const hashedPassword = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await pool.query("UPDATE users SET password_hash = $1 WHERE id = $2", [
      hashedPassword,
      decoded.id,
    ]);

    res.json({ message: "Password updated successfully" });
  } catch (err) {
    res.status(500).json({ message: "Internal error" });
  }
});

// ============================================
// ADMIN: Получить всех пользователей
// ============================================
router.get("/users", requireRole(["admin", "moderator"]), async (req, res) => {
  try {
    const { page = 1, limit = 20, role, search } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = "";
    const params = [];

    if (role) {
      params.push(role);
      whereClause += `WHERE role = $${params.length}`;
    }

    if (search) {
      params.push(`%${search}%`);
      whereClause += `${whereClause ? " AND" : "WHERE"} (username ILIKE $${params.length} OR email ILIKE $${params.length})`;
    }

    const countResult = await pool.query(
      `SELECT COUNT(*) FROM users ${whereClause}`,
      params,
    );
    const totalCount = parseInt(countResult.rows[0].count);

    params.push(limit, offset);
    const result = await pool.query(
      `SELECT id, email, username, role, avatar_url, is_banned, created_at,
        (SELECT COUNT(*) FROM clothes WHERE owner_id = users.id) as clothes_count,
        (SELECT COUNT(*) FROM posts WHERE author_id = users.id) as posts_count
       FROM users ${whereClause}
       ORDER BY created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params,
    );

    res.json({
      users: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalCount,
        pages: Math.ceil(totalCount / limit),
      },
    });
  } catch (err) {
    console.error("Get users error:", err);
    res.status(500).json({ message: "Internal error" });
  }
});

// ============================================
// ADMIN: Получить пользователя по ID
// ============================================
router.get(
  "/users/:id",
  requireRole(["admin", "moderator"]),
  async (req, res) => {
    try {
      const userId = req.params.id;
      const result = await pool.query(
        `SELECT id, email, username, role, avatar_url, is_banned, ban_until, ban_reason, created_at,
        (SELECT COUNT(*) FROM clothes WHERE owner_id = $1) as clothes_count,
        (SELECT COUNT(*) FROM outfits WHERE owner_id = $1) as outfits_count,
        (SELECT COUNT(*) FROM posts WHERE author_id = $1) as posts_count
       FROM users WHERE id = $1`,
        [userId],
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ message: "User not found" });
      }

      res.json({ user: result.rows[0] });
    } catch (err) {
      res.status(500).json({ message: "Internal error" });
    }
  },
);

// ============================================
// ADMIN/MODERATOR: Изменить роль пользователя
// ============================================
router.put("/users/:id/role", requireRole(["admin"]), async (req, res) => {
  try {
    const userId = req.params.id;
    const { role } = req.body;

    if (!["user", "moderator", "admin"].includes(role)) {
      return res.status(400).json({ message: "Invalid role" });
    }

    const result = await pool.query(
      "UPDATE users SET role = $1 WHERE id = $2 RETURNING id, email, username, role",
      [role, userId],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({ user: result.rows[0] });
  } catch (err) {
    res.status(500).json({ message: "Internal error" });
  }
});

// ============================================
// ADMIN/MODERATOR: Заблокировать пользователя
// ============================================
router.post(
  "/users/:id/ban",
  requireRole(["admin", "moderator"]),
  async (req, res) => {
    try {
      const userId = req.params.id;
      const { banType, banUntil, reason } = req.body;
      const moderatorId = req.user.id;

      if (!["permanent", "temporary", "period"].includes(banType)) {
        return res.status(400).json({ message: "Invalid ban type" });
      }

      // Проверяем, что не блокируем админа
      const userResult = await pool.query(
        "SELECT role FROM users WHERE id = $1",
        [userId],
      );
      if (userResult.rows.length === 0) {
        return res.status(404).json({ message: "User not found" });
      }

      if (userResult.rows[0].role === "admin") {
        return res.status(403).json({ message: "Cannot ban admin users" });
      }

      // Записываем в историю банов
      await pool.query(
        `INSERT INTO bans(user_id, moderator_id, ban_type, ban_until, reason)
       VALUES ($1, $2, $3, $4, $5)`,
        [userId, moderatorId, banType, banUntil || null, reason],
      );

      // Обновляем пользователя
      await pool.query(
        `UPDATE users SET is_banned = TRUE, ban_until = $1, ban_reason = $2 WHERE id = $3`,
        [banUntil || null, reason, userId],
      );

      res.json({ message: "User banned successfully" });
    } catch (err) {
      console.error("Ban error:", err);
      res.status(500).json({ message: "Internal error" });
    }
  },
);

// ============================================
// ADMIN/MODERATOR: Разблокировать пользователя
// ============================================
router.post(
  "/users/:id/unban",
  requireRole(["admin", "moderator"]),
  async (req, res) => {
    try {
      const userId = req.params.id;
      const moderatorId = req.user.id;

      // Обновляем пользователя
      await pool.query(
        `UPDATE users SET is_banned = FALSE, ban_until = NULL, ban_reason = NULL WHERE id = $1`,
        [userId],
      );

      // Обновляем историю банов
      await pool.query(
        `UPDATE bans SET lifted_at = CURRENT_TIMESTAMP, lifted_by = $1
       WHERE user_id = $2 AND lifted_at IS NULL`,
        [moderatorId, userId],
      );

      res.json({ message: "User unbanned successfully" });
    } catch (err) {
      res.status(500).json({ message: "Internal error" });
    }
  },
);

// ============================================
// ADMIN: Удалить пользователя
// ============================================
router.delete("/users/:id", requireRole(["admin"]), async (req, res) => {
  try {
    const userId = req.params.id;

    // Проверяем, что не удаляем админа
    const userResult = await pool.query(
      "SELECT role FROM users WHERE id = $1",
      [userId],
    );
    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    if (userResult.rows[0].role === "admin") {
      return res.status(403).json({ message: "Cannot delete admin users" });
    }

    await pool.query("DELETE FROM users WHERE id = $1", [userId]);
    res.json({ message: "User deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: "Internal error" });
  }
});

module.exports = router;
module.exports.requireRole = requireRole;
