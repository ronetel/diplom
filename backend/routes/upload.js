const express = require("express");
const router = express.Router();
const cloudinary = require("cloudinary").v2;
const dotenv = require("dotenv");
const multer = require("multer");
const upload = multer({ storage: multer.memoryStorage() });
const pool = require("../db");
const auth = require("../middleware/auth_mw");

dotenv.config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// ============================================
// Получить подпись для Cloudinary
// ============================================
router.get("/get-signature", (req, res) => {
  const timestamp = Math.round(new Date().getTime() / 1000);
  const signature = cloudinary.utils.api_sign_request(
    { timestamp },
    process.env.CLOUDINARY_API_SECRET,
  );
  res.json({ timestamp, signature });
});

// ============================================
// Загрузка изображения одежды
// ============================================
router.post("/uploadImage", auth, upload.single("file"), async (req, res) => {
  try {
    const {
      brand_names,
      descriptions,
      event = "casual",
      type,
      color,
      material,
      season,
      size,
    } = req.body;

    if (!req.file) {
      return res.status(400).json({ message: "File required" });
    }

    if (!type) {
      return res.status(400).json({ message: "Type is required" });
    }

    // Upload buffer to cloudinary
    const streamUpload = (fileBuffer) => {
      return new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          {
            resource_type: "image",
            folder: "wardrobe/clothes",
          },
          (error, result) => {
            if (result) resolve(result);
            else reject(error);
          },
        );
        stream.end(fileBuffer);
      });
    };

    const result = await streamUpload(req.file.buffer);
    const imageUrl = result.secure_url;

    // Сохраняем в базу данных
    const dbRes = await pool.query(
      `INSERT INTO clothes(owner_id, image_urls, brand_names, descriptions, type, event, color, material, season, size)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [
        req.user.id,
        imageUrl,
        brand_names || null,
        descriptions || null,
        type,
        event,
        color || null,
        material || null,
        season || null,
        size || null,
      ],
    );

    res.status(201).json({ cloth: dbRes.rows[0] });
  } catch (err) {
    console.error("Upload error:", err);
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Загрузка аватарки пользователя
// ============================================
router.post("/uploadAvatar", auth, upload.single("file"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "File required" });
    }

    const streamUpload = (fileBuffer) => {
      return new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          {
            resource_type: "image",
            folder: "wardrobe/avatars",
            transformation: [{ width: 400, height: 400, crop: "fill" }],
          },
          (error, result) => {
            if (result) resolve(result);
            else reject(error);
          },
        );
        stream.end(fileBuffer);
      });
    };

    const result = await streamUpload(req.file.buffer);
    const avatarUrl = result.secure_url;

    // Обновляем пользователя
    const dbRes = await pool.query(
      `UPDATE users SET avatar_url = $1 WHERE id = $2 RETURNING
        id, username, avatar_url, email, role, created_at,
        (SELECT COUNT(*) FROM clothes WHERE owner_id = $2) as clothes_count,
        (SELECT COUNT(*) FROM outfits WHERE owner_id = $2) as outfits_count,
        (SELECT COUNT(*) FROM posts WHERE author_id = $2) as posts_count`,
      [avatarUrl, req.user.id],
    );

    res.json({ user: dbRes.rows[0] });
  } catch (err) {
    console.error("Avatar upload error:", err);
    res.status(500).json({ message: "Internal server error" });
  }
});

// ============================================
// Загрузка изображения для поста
// ============================================
router.post(
  "/uploadPostImage",
  auth,
  upload.single("file"),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ message: "File required" });
      }

      const streamUpload = (fileBuffer) => {
        return new Promise((resolve, reject) => {
          const stream = cloudinary.uploader.upload_stream(
            {
              resource_type: "image",
              folder: "wardrobe/posts",
              transformation: [{ width: 1200, crop: "limit" }],
            },
            (error, result) => {
              if (result) resolve(result);
              else reject(error);
            },
          );
          stream.end(fileBuffer);
        });
      };

      const result = await streamUpload(req.file.buffer);

      res.json({ imageUrl: result.secure_url });
    } catch (err) {
      console.error("Post image upload error:", err);
      res.status(500).json({ message: "Internal server error" });
    }
  },
);

module.exports = router;
