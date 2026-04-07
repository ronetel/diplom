const express = require('express')
const router = express.Router()
const axios = require('axios')
const auth = require('../middleware/auth_mw')
const pool = require('../db')
require('dotenv').config()

const OPENWEATHER_API_KEY = process.env.OPENWEATHER_API_KEY

// ============================================
// Получить текущую погоду по координатам
// ============================================
router.get('/current', async (req, res) => {
  try {
    const { lat, lon } = req.query

    if (!lat || !lon) {
      return res.status(400).json({ message: 'Latitude and longitude required' })
    }

    // Проверяем кэш (кэшируем на 10 минут)
    const cacheResult = await pool.query(
      `SELECT * FROM weather_cache
       WHERE ABS(lat - $1) < 0.01 AND ABS(lng - $2) < 0.01
       AND fetched_at > NOW() - INTERVAL '10 minutes'`,
      [lat, lon]
    )

    if (cacheResult.rows.length > 0) {
      return res.json({ weather: cacheResult.rows[0].data })
    }

    // Запрашиваем у OpenWeatherMap
    const response = await axios.get(
      `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${OPENWEATHER_API_KEY}&units=metric`
    )

    const weatherData = response.data

    // Сохраняем в кэш
    await pool.query(
      `INSERT INTO weather_cache(lat, lng, data)
       VALUES ($1, $2, $3)
       ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data, fetched_at = CURRENT_TIMESTAMP`,
      [lat, lon, JSON.stringify(weatherData)]
    )

    res.json({ weather: weatherData })
  } catch (err) {
    console.error('Weather API error:', err.response?.data || err.message)
    res.status(500).json({ message: 'Failed to fetch weather data' })
  }
})

// ============================================
// Получить погоду по названию города
// ============================================
router.get('/city/:city', async (req, res) => {
  try {
    const city = req.params.city

    if (!OPENWEATHER_API_KEY) {
      return res.status(500).json({ message: 'Weather API key not configured' })
    }

    const response = await axios.get(
      `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(city)}&appid=${OPENWEATHER_API_KEY}&units=metric`
    )

    res.json({ weather: response.data })
  } catch (err) {
    console.error('Weather city API error:', err.response?.data || err.message)
    if (err.response?.status === 404) {
      return res.status(404).json({ message: 'City not found' })
    }
    res.status(500).json({ message: 'Failed to fetch weather data' })
  }
})

// ============================================
// Получить прогноз на 5 дней
// ============================================
router.get('/forecast', async (req, res) => {
  try {
    const { lat, lon } = req.query

    if (!lat || !lon) {
      return res.status(400).json({ message: 'Latitude and longitude required' })
    }

    if (!OPENWEATHER_API_KEY) {
      return res.status(500).json({ message: 'Weather API key not configured' })
    }

    const response = await axios.get(
      `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&appid=${OPENWEATHER_API_KEY}&units=metric`
    )

    res.json({ forecast: response.data })
  } catch (err) {
    console.error('Weather forecast API error:', err.response?.data || err.message)
    res.status(500).json({ message: 'Failed to fetch forecast data' })
  }
})

// ============================================
// Получить рекомендацию образа на основе погоды
// ============================================
router.get('/recommend', auth, async (req, res) => {
  try {
    const { lat, lon, event = 'casual' } = req.query
    const userId = req.user.id

    let weatherData = null
    let temp = 20 // Температура по умолчанию

    if (lat && lon) {
      try {
        const weatherResponse = await axios.get(
          `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${OPENWEATHER_API_KEY}&units=metric`
        )
        weatherData = weatherResponse.data
        temp = weatherData.main.temp
      } catch (err) {
        console.error('Weather fetch error:', err.message)
      }
    }

    // Определяем рекомендации на основе температуры
    const recommendations = {
      temp: temp,
      season: getSeasonFromTemp(temp),
      suggestions: getClothingSuggestions(temp),
      event: event
    }

    // Пытаемся найти подходящую одежду пользователя
    const clothesResult = await pool.query(
      `SELECT * FROM clothes
       WHERE owner_id = $1 AND event = $2
       ORDER BY RANDOM()
       LIMIT 20`,
      [userId, event]
    )

    // Разделяем одежду по типам
    const clothes = {
      tops: clothesResult.rows.filter(c => c.type === 'top'),
      bottoms: clothesResult.rows.filter(c => c.type === 'bottom'),
      shoes: clothesResult.rows.filter(c => c.type === 'shoes'),
      outerwear: clothesResult.rows.filter(c => c.type === 'outerwear'),
      accessories: clothesResult.rows.filter(c => c.type === 'accessory')
    }

    // Формируем рекомендованный образ
    const recommendedOutfit = []
    if (clothes.tops.length > 0) {
      recommendedOutfit.push(clothes.tops[0])
    }
    if (clothes.bottoms.length > 0) {
      recommendedOutfit.push(clothes.bottoms[0])
    }
    if (clothes.shoes.length > 0) {
      recommendedOutfit.push(clothes.shoes[0])
    }
    // Добавляем верхнюю одежду если холодно
    if (temp < 15 && clothes.outerwear.length > 0) {
      recommendedOutfit.push(clothes.outerwear[0])
    }

    res.json({
      weather: weatherData,
      recommendations,
      availableClothes: clothes,
      recommendedOutfit
    })
  } catch (err) {
    console.error('Weather recommend error:', err)
    res.status(500).json({ message: 'Internal server error' })
  }
})

// ============================================
// Вспомогательные функции
// ============================================
function getSeasonFromTemp(temp) {
  if (temp < 5) return 'winter'
  if (temp < 15) return 'autumn'
  if (temp < 25) return 'spring'
  return 'summer'
}

function getClothingSuggestions(temp) {
  const suggestions = []

  if (temp < 0) {
    suggestions.push('Очень холодно! Нужна теплая зимняя куртка')
    suggestions.push('Шапка и шарф обязательны')
    suggestions.push('Теплая обувь')
  } else if (temp < 10) {
    suggestions.push('Прохладно, возьмите куртку или пальто')
    suggestions.push('Легкий свитер или худи')
    suggestions.push('Закрытая обувь')
  } else if (temp < 20) {
    suggestions.push('Умеренная температура')
    suggestions.push('Лонгслив или футболка с кардиганом')
    suggestions.push('Джинсы или брюки')
  } else if (temp < 30) {
    suggestions.push('Тепло! Легкая одежда')
    suggestions.push('Футболка или майка')
    suggestions.push('Шорты или легкие брюки')
  } else {
    suggestions.push('Жарко! Максимально легкая одежда')
    suggestions.push('Светлые ткани')
    suggestions.push('Головной убор от солнца')
  }

  return suggestions
}

module.exports = router
