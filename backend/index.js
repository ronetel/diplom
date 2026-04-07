const express = require('express')
const cors = require('cors')
const dotenv = require('dotenv')
const { Pool } = require('pg')

dotenv.config()

const app = express()
app.use(cors())
app.use(express.json({ limit: '50mb' }))
app.use(express.urlencoded({ extended: true, limit: '50mb' }))

const port = process.env.PORT || 8000

// Database connection
const pool = new Pool({ connectionString: process.env.DATABASE_URL })

// Provide pool to routers via req.app.locals
app.locals.pool = pool

// Health check
app.get('/', (req, res) => res.json({
  status: 'ok',
  service: 'Wardrobe API',
  version: '1.0.0'
}))

// Import routes
const authRouter = require('./routes/auth')
const clothesRouter = require('./routes/clothes')
const outfitsRouter = require('./routes/outfits')
const uploadRouter = require('./routes/upload')
const postsRouter = require('./routes/posts')
const weatherRouter = require('./routes/weather')
const adminRouter = require('./routes/admin')

// Use routes
app.use('/auth', authRouter)
app.use('/clothes', clothesRouter)
app.use('/outfits', outfitsRouter)
app.use('/upload', uploadRouter)
app.use('/posts', postsRouter)
app.use('/weather', weatherRouter)
app.use('/admin', adminRouter)

// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err)
  res.status(500).json({ message: 'Internal server error' })
})

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Endpoint not found' })
})

app.listen(port, () => {
  console.log(`Wardrobe backend listening on port ${port}`)
  console.log(`Database URL: ${process.env.DATABASE_URL ? 'configured' : 'NOT SET'}`)
  console.log(`Cloudinary: ${process.env.CLOUDINARY_CLOUD_NAME ? 'configured' : 'NOT SET'}`)
  console.log(`OpenWeather API: ${process.env.OPENWEATHER_API_KEY ? 'configured' : 'NOT SET'}`)
})

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully')
  pool.end()
  process.exit(0)
})

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully')
  pool.end()
  process.exit(0)
})
