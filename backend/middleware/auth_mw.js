const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'replace_this_with_secure_secret';

function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header) return res.status(401).json({ message: 'Необходима авторизация' });

  const token = header.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Необходима авторизация' });

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Сессия истекла, войдите снова' });
  }
}

module.exports = authMiddleware;
