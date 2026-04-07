const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth_mw");
const pool = require("../db");

// ============================================
// Получить ленту постов
// ============================================
router.get("/feed", async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const countResult = await pool.query(
      "SELECT COUNT(*) FROM posts WHERE is_hidden = FALSE",
    );
    const totalCount = parseInt(countResult.rows[0].count);

    const result = await pool.query(
      `SELECT p.*, u.username, u.avatar_url,
        (SELECT COUNT(*) FROM likes WHERE post_id = p.id) as likes_count,
        (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND is_hidden = FALSE) as comments_count
       FROM posts p
       JOIN users u ON p.author_id = u.id
       WHERE p.is_hidden = FALSE
       ORDER BY p.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset],
    );

    // Загружаем outfit для каждого поста
    for (const post of result.rows) {
      if (post.outfit_id) {
        const outfitResult = await pool.query(
          `SELECT o.* FROM outfits o WHERE o.id = $1`,
          [post.outfit_id],
        );
        if (outfitResult.rows.length > 0) {
          const outfit = outfitResult.rows[0];
          if (outfit.clothes_ids && outfit.clothes_ids.length > 0) {
            const clothesResult = await pool.query(
              "SELECT * FROM clothes WHERE id = ANY($1)",
              [outfit.clothes_ids],
            );
            outfit.clothes = clothesResult.rows;
          }
          post.outfit = outfit;
        }
      }
    }

    res.json({
      posts: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalCount,
        pages: Math.ceil(totalCount / limit),
      },
    });
  } catch (err) {
    console.error("Get feed error:", err);
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Получить посты пользователя
// ============================================
router.get("/user/:userId", async (req, res) => {
  try {
    const userId = req.params.userId;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const countResult = await pool.query(
      "SELECT COUNT(*) FROM posts WHERE author_id = $1 AND is_hidden = FALSE",
      [userId],
    );
    const totalCount = parseInt(countResult.rows[0].count);

    const result = await pool.query(
      `SELECT p.*, u.username, u.avatar_url,
        (SELECT COUNT(*) FROM likes WHERE post_id = p.id) as likes_count,
        (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND is_hidden = FALSE) as comments_count
       FROM posts p
       JOIN users u ON p.author_id = u.id
       WHERE p.author_id = $1 AND p.is_hidden = FALSE
       ORDER BY p.created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset],
    );

    // Загружаем outfit для каждого поста
    for (const post of result.rows) {
      if (post.outfit_id) {
        const outfitResult = await pool.query(
          `SELECT o.* FROM outfits o WHERE o.id = $1`,
          [post.outfit_id],
        );
        if (outfitResult.rows.length > 0) {
          const outfit = outfitResult.rows[0];
          if (outfit.clothes_ids && outfit.clothes_ids.length > 0) {
            const clothesResult = await pool.query(
              "SELECT * FROM clothes WHERE id = ANY($1)",
              [outfit.clothes_ids],
            );
            outfit.clothes = clothesResult.rows;
          }
          post.outfit = outfit;
        }
      }
    }

    res.json({
      posts: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalCount,
        pages: Math.ceil(totalCount / limit),
      },
    });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Получить пост по ID
// ============================================
router.get("/:id", async (req, res) => {
  try {
    const postId = req.params.id;

    const result = await pool.query(
      `SELECT p.*, u.username, u.avatar_url,
        (SELECT COUNT(*) FROM likes WHERE post_id = p.id) as likes_count,
        (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND is_hidden = FALSE) as comments_count
       FROM posts p
       JOIN users u ON p.author_id = u.id
       WHERE p.id = $1`,
      [postId],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Post not found" });
    }

    const post = result.rows[0];

    // Получаем комментарии
    const commentsResult = await pool.query(
      `SELECT c.*, u.username, u.avatar_url
       FROM comments c
       JOIN users u ON c.author_id = u.id
       WHERE c.post_id = $1 AND c.is_hidden = FALSE
       ORDER BY c.created_at DESC`,
      [postId],
    );
    post.comments = commentsResult.rows;

    // Получаем образ, если есть
    if (post.outfit_id) {
      const outfitResult = await pool.query(
        `SELECT o.* FROM outfits o WHERE o.id = $1`,
        [post.outfit_id],
      );
      if (outfitResult.rows.length > 0) {
        const outfit = outfitResult.rows[0];
        if (outfit.clothes_ids && outfit.clothes_ids.length > 0) {
          const clothesResult = await pool.query(
            "SELECT * FROM clothes WHERE id = ANY($1)",
            [outfit.clothes_ids],
          );
          outfit.clothes = clothesResult.rows;
        }
        post.outfit = outfit;
      }
    }

    res.json({ post });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Создать пост
// ============================================
router.post("/", auth, async (req, res) => {
  try {
    const { outfit_id, title, content, image_urls, tags } = req.body;
    const userId = req.user.id;

    // Проверяем, что outfit принадлежит пользователю
    if (outfit_id) {
      const outfitResult = await pool.query(
        "SELECT owner_id FROM outfits WHERE id = $1",
        [outfit_id],
      );
      if (outfitResult.rows.length === 0) {
        return res.status(404).json({ message: "Outfit not found" });
      }
      if (outfitResult.rows[0].owner_id !== userId) {
        return res
          .status(403)
          .json({ message: "Outfit does not belong to you" });
      }
    }

    const result = await pool.query(
      `INSERT INTO posts(author_id, outfit_id, title, content, image_urls, tags)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [userId, outfit_id, title, content, image_urls || [], tags || []],
    );

    const post = result.rows[0];

    // Добавляем информацию об авторе
    const userResult = await pool.query(
      "SELECT username, avatar_url FROM users WHERE id = $1",
      [userId],
    );
    post.username = userResult.rows[0]?.username;
    post.avatar_url = userResult.rows[0]?.avatar_url;
    post.likes_count = 0;
    post.comments_count = 0;

    res.status(201).json({ post });
  } catch (err) {
    console.error("Create post error:", err);
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Обновить пост
// ============================================
router.put("/:id", auth, async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.id;

    // Проверяем владельца
    const postResult = await pool.query(
      "SELECT author_id FROM posts WHERE id = $1",
      [postId],
    );
    if (postResult.rows.length === 0) {
      return res.status(404).json({ message: "Post not found" });
    }

    // Только автор или модератор/админ может редактировать
    if (
      postResult.rows[0].author_id !== userId &&
      !["moderator", "admin"].includes(req.user.role)
    ) {
      return res.status(403).json({ message: "Not authorized" });
    }

    const { title, content, image_urls, tags } = req.body;

    const updates = [];
    const values = [];
    let paramCount = 1;

    if (title !== undefined) {
      updates.push(`title = $${paramCount++}`);
      values.push(title);
    }
    if (content !== undefined) {
      updates.push(`content = $${paramCount++}`);
      values.push(content);
    }
    if (image_urls !== undefined) {
      updates.push(`image_urls = $${paramCount++}`);
      values.push(image_urls);
    }
    if (tags !== undefined) {
      updates.push(`tags = $${paramCount++}`);
      values.push(tags);
    }

    if (updates.length === 0) {
      return res.status(400).json({ message: "No fields to update" });
    }

    values.push(postId);
    const query = `UPDATE posts SET ${updates.join(", ")} WHERE id = $${paramCount} RETURNING *`;

    const result = await pool.query(query, values);
    res.json({ post: result.rows[0] });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Удалить пост
// ============================================
router.delete("/:id", auth, async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.id;

    // Проверяем владельца
    const postResult = await pool.query(
      "SELECT author_id FROM posts WHERE id = $1",
      [postId],
    );
    if (postResult.rows.length === 0) {
      return res.status(404).json({ message: "Post not found" });
    }

    // Только автор или модератор/админ может удалять
    if (
      postResult.rows[0].author_id !== userId &&
      !["moderator", "admin"].includes(req.user.role)
    ) {
      return res.status(403).json({ message: "Not authorized" });
    }

    await pool.query("DELETE FROM posts WHERE id = $1", [postId]);
    res.json({ message: "Post deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Лайкнуть пост
// ============================================
router.post("/:id/like", auth, async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.id;

    // Проверяем существование поста
    const postResult = await pool.query("SELECT id FROM posts WHERE id = $1", [
      postId,
    ]);
    if (postResult.rows.length === 0) {
      return res.status(404).json({ message: "Post not found" });
    }

    // Добавляем лайк (игнорируем если уже есть)
    await pool.query(
      "INSERT INTO likes(post_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
      [postId, userId],
    );

    // Получаем общее количество лайков
    const countResult = await pool.query(
      "SELECT COUNT(*) FROM likes WHERE post_id = $1",
      [postId],
    );

    res.json({ liked: true, likesCount: parseInt(countResult.rows[0].count) });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Убрать лайк
// ============================================
router.delete("/:id/like", auth, async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.id;

    await pool.query("DELETE FROM likes WHERE post_id = $1 AND user_id = $2", [
      postId,
      userId,
    ]);

    const countResult = await pool.query(
      "SELECT COUNT(*) FROM likes WHERE post_id = $1",
      [postId],
    );

    res.json({ liked: false, likesCount: parseInt(countResult.rows[0].count) });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Получить лайки поста
// ============================================
router.get("/:id/likes", async (req, res) => {
  try {
    const postId = req.params.id;

    const result = await pool.query(
      `SELECT l.*, u.username, u.avatar_url
       FROM likes l
       JOIN users u ON l.user_id = u.id
       WHERE l.post_id = $1
       ORDER BY l.created_at DESC`,
      [postId],
    );

    res.json({ likes: result.rows });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Проверить, лайкнул ли пользователь пост
// ============================================
router.get("/:id/like/status", auth, async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.id;

    const result = await pool.query(
      "SELECT id FROM likes WHERE post_id = $1 AND user_id = $2",
      [postId, userId],
    );

    res.json({ liked: result.rows.length > 0 });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Добавить комментарий
// ============================================
router.post("/:id/comments", auth, async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.id;
    const { content } = req.body;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ message: "Content is required" });
    }

    // Проверяем существование поста
    const postResult = await pool.query("SELECT id FROM posts WHERE id = $1", [
      postId,
    ]);
    if (postResult.rows.length === 0) {
      return res.status(404).json({ message: "Post not found" });
    }

    const result = await pool.query(
      `INSERT INTO comments(post_id, author_id, content)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [postId, userId, content],
    );

    const comment = result.rows[0];

    // Добавляем информацию об авторе
    const userResult = await pool.query(
      "SELECT username, avatar_url FROM users WHERE id = $1",
      [userId],
    );
    comment.username = userResult.rows[0]?.username;
    comment.avatar_url = userResult.rows[0]?.avatar_url;

    res.status(201).json({ comment });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Получить комментарии поста
// ============================================
router.get("/:id/comments", async (req, res) => {
  try {
    const postId = req.params.id;
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT c.*, u.username, u.avatar_url
       FROM comments c
       JOIN users u ON c.author_id = u.id
       WHERE c.post_id = $1 AND c.is_hidden = FALSE
       ORDER BY c.created_at DESC
       LIMIT $2 OFFSET $3`,
      [postId, limit, offset],
    );

    res.json({ comments: result.rows });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Удалить комментарий
// ============================================
router.delete("/:postId/comments/:commentId", auth, async (req, res) => {
  try {
    const { postId, commentId } = req.params;
    const userId = req.user.id;

    // Проверяем владельца комментария
    const commentResult = await pool.query(
      "SELECT author_id FROM comments WHERE id = $1 AND post_id = $2",
      [commentId, postId],
    );
    if (commentResult.rows.length === 0) {
      return res.status(404).json({ message: "Comment not found" });
    }

    // Только автор или модератор/админ может удалять
    if (
      commentResult.rows[0].author_id !== userId &&
      !["moderator", "admin"].includes(req.user.role)
    ) {
      return res.status(403).json({ message: "Not authorized" });
    }

    await pool.query("DELETE FROM comments WHERE id = $1", [commentId]);
    res.json({ message: "Comment deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// MODERATOR: Скрыть/показать пост
// ============================================
router.put("/:id/hide", auth, async (req, res) => {
  try {
    if (!["moderator", "admin"].includes(req.user.role)) {
      return res.status(403).json({ message: "Not authorized" });
    }

    const postId = req.params.id;
    const { isHidden, reason } = req.body;

    const result = await pool.query(
      `UPDATE posts SET is_hidden = $1, report_reason = $2 WHERE id = $3 RETURNING *`,
      [isHidden, reason || null, postId],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Post not found" });
    }

    res.json({ post: result.rows[0] });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// MODERATOR: Получить жалобы на посты
// ============================================
router.get("/reports/list", auth, async (req, res) => {
  try {
    if (!["moderator", "admin"].includes(req.user.role)) {
      return res.status(403).json({ message: "Not authorized" });
    }

    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT p.*, u.username, u.avatar_url
       FROM posts p
       JOIN users u ON p.author_id = u.id
       WHERE p.is_reported = TRUE
       ORDER BY p.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset],
    );

    res.json({ posts: result.rows });
  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
});

module.exports = router;
