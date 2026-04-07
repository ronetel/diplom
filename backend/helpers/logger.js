const pool = require('../db')

/**
 * Записывает действие в лог.
 * @param {Object} opts
 * @param {string}  opts.action         - краткий код действия (LOGIN, BAN_USER, DELETE_POST, …)
 * @param {number}  opts.actorId        - id того, кто совершил действие
 * @param {string}  opts.actorUsername  - username того, кто совершил действие
 * @param {string}  [opts.targetType]   - тип объекта (user, post, comment)
 * @param {number}  [opts.targetId]     - id объекта
 * @param {string}  [opts.targetName]   - читаемое имя объекта
 * @param {string}  [opts.details]      - подробности в свободном виде
 */
async function logAction({ action, actorId, actorUsername, targetType, targetId, targetName, details }) {
  try {
    await pool.query(
      `INSERT INTO logs(action, actor_id, actor_username, target_type, target_id, target_name, details)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        action,
        actorId   || null,
        actorUsername || null,
        targetType || null,
        targetId  || null,
        targetName || null,
        details   || null,
      ]
    )
  } catch (err) {
    console.error('Logger error:', err.message)
  }
}

module.exports = { logAction }
