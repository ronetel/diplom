const express = require('express')
const router = express.Router()
const auth = require('../middleware/auth_mw')
const pool = require('../db')

// ============================================
// Получить все образы пользователя
// ============================================
router.get('/', auth, async (req, res) => {
  try {
    const { event, season, is_favorite, page = 1, limit = 20 } = req.query
    const userId = req.user.id
    const offset = (page - 1) * limit

    let whereClause = 'WHERE o.owner_id = $1'
    const params = [userId]

    if (event) {
      params.push(event)
      whereClause += ` AND o.event = $${params.length}`
    }

    if (season) {
      params.push(season)
      whereClause += ` AND o.season = $${params.length}`
    }

    if (is_favorite === 'true') {
      whereClause += ` AND o.is_favorite = TRUE`
    }

    const countResult = await pool.query(`SELECT COUNT(*) FROM outfits o ${whereClause}`, params)
    const totalCount = parseInt(countResult.rows[0].count)

    params.push(limit, offset)
    const result = await pool.query(
      `SELECT o.*, u.username as owner_username
       FROM outfits o
       JOIN users u ON o.owner_id = u.id
       ${whereClause}
       ORDER BY o.created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    )

    // Добавляем информацию об одежде в каждый образ
    const outfitsWithClothes = await Promise.all(
      result.rows.map(async (outfit) => {
        if (outfit.clothes_ids && outfit.clothes_ids.length > 0) {
          const clothesResult = await pool.query(
            'SELECT * FROM clothes WHERE id = ANY($1)',
            [outfit.clothes_ids]
          )
          return { ...outfit, clothes: clothesResult.rows }
        }
        return { ...outfit, clothes: [] }
      })
    )

    res.json({
      outfits: outfitsWithClothes,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalCount,
        pages: Math.ceil(totalCount / limit)
      }
    })
  } catch (err) {
    console.error('Get outfits error:', err)
    res.status(500).json({ message: 'Internal server error' })
  }
})

// ============================================
// Получить образ по ID
// ============================================
router.get('/:id', auth, async (req, res) => {
  try {
    const outfitId = req.params.id
    const userId = req.user.id

    const result = await pool.query(
      `SELECT o.*, u.username as owner_username
       FROM outfits o
       JOIN users u ON o.owner_id = u.id
       WHERE o.id = $1`,
      [outfitId]
    )

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Outfit not found' })
    }

    const outfit = result.rows[0]

    // Проверяем права доступа
    if (outfit.owner_id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized' })
    }

    // Получаем одежду
    if (outfit.clothes_ids && outfit.clothes_ids.length > 0) {
      const clothesResult = await pool.query(
        'SELECT * FROM clothes WHERE id = ANY($1)',
        [outfit.clothes_ids]
      )
      outfit.clothes = clothesResult.rows
    } else {
      outfit.clothes = []
    }

    res.json({ outfit })
  } catch (err) {
    res.status(500).json({ message: 'Internal server error' })
  }
})

// ============================================
// Создать новый образ
// ============================================
router.post('/', auth, async (req, res) => {
  try {
    const { name, description, event = 'casual', season, clothes_ids, thumbnail_url } = req.body
    const userId = req.user.id

    if (!name) {
      return res.status(400).json({ message: 'Name is required' })
    }

    // Проверяем, что все ID одежды принадлежат пользователю
    if (clothes_ids && clothes_ids.length > 0) {
      const clothesResult = await pool.query(
        'SELECT id FROM clothes WHERE id = ANY($1) AND owner_id = $2',
        [clothes_ids, userId]
      )
      if (clothesResult.rows.length !== clothes_ids.length) {
        return res.status(403).json({ message: 'Some clothes do not belong to you' })
      }
    }

    const result = await pool.query(
      `INSERT INTO outfits(owner_id, name, description, event, season, clothes_ids, thumbnail_url)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [userId, name, description, event, season, clothes_ids || [], thumbnail_url]
    )

    const outfit = result.rows[0]

    // Получаем одежду
    if (clothes_ids && clothes_ids.length > 0) {
      const clothesResult = await pool.query(
        'SELECT * FROM clothes WHERE id = ANY($1)',
        [clothes_ids]
      )
      outfit.clothes = clothesResult.rows
    } else {
      outfit.clothes = []
    }

    res.status(201).json({ outfit })
  } catch (err) {
    console.error('Create outfit error:', err)
    res.status(500).json({ message: 'Internal server error' })
  }
})

// ============================================
// Обновить образ
// ============================================
router.put('/:id', auth, async (req, res) => {
  try {
    const outfitId = req.params.id
    const userId = req.user.id

    // Проверяем владельца
    const outfitResult = await pool.query('SELECT owner_id FROM outfits WHERE id = $1', [outfitId])
    if (outfitResult.rows.length === 0) {
      return res.status(404).json({ message: 'Outfit not found' })
    }

    if (outfitResult.rows[0].owner_id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized' })
    }

    const { name, description, event, season, clothes_ids, thumbnail_url, is_favorite } = req.body

    // Проверяем, что все ID одежды принадлежат пользователю
    if (clothes_ids && clothes_ids.length > 0) {
      const clothesResult = await pool.query(
        'SELECT id FROM clothes WHERE id = ANY($1) AND owner_id = $2',
        [clothes_ids, outfitResult.rows[0].owner_id]
      )
      if (clothesResult.rows.length !== clothes_ids.length) {
        return res.status(403).json({ message: 'Some clothes do not belong to the owner' })
      }
    }

    const updates = []
    const values = []
    let paramCount = 1

    if (name !== undefined) {
      updates.push(`name = $${paramCount++}`)
      values.push(name)
    }
    if (description !== undefined) {
      updates.push(`description = $${paramCount++}`)
      values.push(description)
    }
    if (event !== undefined) {
      updates.push(`event = $${paramCount++}`)
      values.push(event)
    }
    if (season !== undefined) {
      updates.push(`season = $${paramCount++}`)
      values.push(season)
    }
    if (clothes_ids !== undefined) {
      updates.push(`clothes_ids = $${paramCount++}`)
      values.push(clothes_ids)
    }
    if (thumbnail_url !== undefined) {
      updates.push(`thumbnail_url = $${paramCount++}`)
      values.push(thumbnail_url)
    }
    if (is_favorite !== undefined) {
      updates.push(`is_favorite = $${paramCount++}`)
      values.push(is_favorite)
    }

    if (updates.length === 0) {
      return res.status(400).json({ message: 'No fields to update' })
    }

    values.push(outfitId)
    const query = `UPDATE outfits SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`

    const result = await pool.query(query, values)
    const outfit = result.rows[0]

    // Получаем одежду
    if (outfit.clothes_ids && outfit.clothes_ids.length > 0) {
      const clothesResult = await pool.query(
        'SELECT * FROM clothes WHERE id = ANY($1)',
        [outfit.clothes_ids]
      )
      outfit.clothes = clothesResult.rows
    } else {
      outfit.clothes = []
    }

    res.json({ outfit })
  } catch (err) {
    console.error('Update outfit error:', err)
    res.status(500).json({ message: 'Internal server error' })
  }
})

// ============================================
// Удалить образ
// ============================================
router.delete('/:id', auth, async (req, res) => {
  try {
    const outfitId = req.params.id
    const userId = req.user.id

    const outfitResult = await pool.query('SELECT owner_id FROM outfits WHERE id = $1', [outfitId])
    if (outfitResult.rows.length === 0) {
      return res.status(404).json({ message: 'Outfit not found' })
    }

    if (outfitResult.rows[0].owner_id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized' })
    }

    await pool.query('DELETE FROM outfits WHERE id = $1', [outfitId])
    res.json({ message: 'Outfit deleted successfully' })
  } catch (err) {
    res.status(500).json({ message: 'Internal server error' })
  }
})

// ============================================
// Генерация образа на основе погоды (автоматически)
// ============================================
router.post('/generate', auth, async (req, res) => {
  try {
    const { event = 'casual', temp, date } = req.body
    const userId = req.user.id

    // Определяем сезон на основе температуры
    let season = 'all-season'
    if (temp !== undefined) {
      if (temp < 5) season = 'winter'
      else if (temp < 15) season = 'autumn'
      else if (temp < 25) season = 'spring'
      else season = 'summer'
    }

    // Получаем доступную одежду пользователя
    const topResult = await pool.query(
      `SELECT id FROM clothes
       WHERE owner_id = $1 AND type = 'top' AND event = $2
       ORDER BY RANDOM() LIMIT 1`,
      [userId, event]
    )

    const bottomResult = await pool.query(
      `SELECT id FROM clothes
       WHERE owner_id = $1 AND type = 'bottom' AND event = $2
       ORDER BY RANDOM() LIMIT 1`,
      [userId, event]
    )

    const shoesResult = await pool.query(
      `SELECT id FROM clothes
       WHERE owner_id = $1 AND type = 'shoes' AND event = $2
       ORDER BY RANDOM() LIMIT 1`,
      [userId, event]
    )

    const clothesIds = []
    if (topResult.rows.length > 0) clothesIds.push(topResult.rows[0].id)
    if (bottomResult.rows.length > 0) clothesIds.push(bottomResult.rows[0].id)
    if (shoesResult.rows.length > 0) clothesIds.push(shoesResult.rows[0].id)

    if (clothesIds.length === 0) {
      return res.status(404).json({ message: 'No clothes available for this event' })
    }

    // Сохраняем в расписание, если указана дата
    if (date) {
      // Удаляем старую запись на эту дату, если есть
      await pool.query(
        'DELETE FROM outfit_schedule WHERE owner_id = $1 AND scheduled_date = $2',
        [userId, date]
      )
    }

    res.json({
      clothesIds,
      season,
      event,
      temp,
      message: 'Outfit generated successfully'
    })
  } catch (err) {
    console.error('Generate outfit error:', err)
    res.status(500).json({ message: 'Internal server error' })
  }
})

// ============================================
// Получить образы на дату
// ============================================
router.get('/date/:date', auth, async (req, res) => {
  try {
    const date = req.params.date // YYYYMMDD
    const userId = req.user.id

    const year = date.slice(0, 4)
    const month = date.slice(4, 6)
    const day = date.slice(6, 8)
    const dateObj = new Date(year, month - 1, day)
    const begin = new Date(dateObj)
    begin.setHours(0, 0, 0, 0)
    const end = new Date(dateObj)
    end.setHours(23, 59, 59, 999)

    const result = await pool.query(
      `SELECT o.*, os.scheduled_date, os.weather_temp, os.weather_condition
       FROM outfits o
       JOIN outfit_schedule os ON o.id = os.outfit_id
       WHERE os.owner_id = $1 AND os.scheduled_date = $2`,
      [userId, begin]
    )

    res.json({ outfits: result.rows })
  } catch (err) {
    res.status(500).json({ message: 'Internal server error' })
  }
})

module.exports = router
