| Файл | Размер (KB) | Используемые библиотеки/модули | Доп. файлы ||---|---:|---|---|| backend/db.js | 0.18 | pg, dotenv | - |
| backend/helpers/logger.js | 0.61 | ../db | - |
| backend/index.js | 1.80 | express, cors, dotenv, pg, ./routes/auth, ./routes/clothes, ./routes/outfits, ./routes/upload, ./routes/posts, ./routes/admin | - |
| backend/middleware/auth_mw.js | 0.72 | jsonwebtoken, dotenv | - |
| backend/routes/admin.js | 16.00 | express, ../db, ../middleware/auth_mw, ../helpers/logger | - |
| backend/routes/auth.js | 18.93 | express, bcrypt, jsonwebtoken, ../db, dotenv | - |
| backend/routes/clothes.js | 9.79 | express, ../middleware/auth_mw, ../db | - |
| backend/routes/outfits.js | 10.75 | express, ../middleware/auth_mw, ../db | - |
| backend/routes/posts.js | 16.19 | express, ../middleware/auth_mw, ../db, jsonwebtoken | - |
| backend/routes/upload.js | 6.01 | express, cloudinary, dotenv, multer, ../db, ../middleware/auth_mw, @imgly/background-removal-node | - |
| backend/routes/weather.js | 6.18 | express, axios, ../middleware/auth_mw, ../db, dotenv | - |
| lib/data/clothing_categories.dart | 12.96 | - | - |
| lib/data/outfit_data.dart | 0.87 | - | - |
| lib/main.dart | 1.65 | flutter, provider, providers, screens | - |
| lib/models/auth_response.dart | 1.21 | user.dart | - |
| lib/models/cloth.dart | 4.62 | - | - |
| lib/models/comment.dart | 1.35 | - | - |
| lib/models/models.dart | 0.15 | - | - |
| lib/models/outfit.dart | 4.08 | cloth.dart | - |
| lib/models/post.dart | 4.06 | outfit.dart, comment.dart | - |
| lib/models/user.dart | 3.42 | - | - |
| lib/models/weather.dart | 4.03 | - | - |
| lib/providers/auth_provider.dart | 4.55 | flutter, ../models/user.dart, ../services/auth_service.dart | - |
| lib/screens/add_cloth_page.dart | 18.10 | dart:typed_data, flutter, image_picker, ../data/clothing_categories.dart, ../models/cloth.dart, ../services/cloth_service.dart | - |
| lib/screens/admin_panel_page.dart | 12.11 | flutter, provider, ../providers/auth_provider.dart, ../services/auth_service.dart, ../models/user.dart | - |
| lib/screens/calendar_page.dart | 0.94 | flutter | - |
| lib/screens/closet_page.dart | 8.87 | cached_network_image, flutter, ../models/cloth.dart, ../services/cloth_service.dart, add_cloth_page.dart, cloth_detail_page.dart | - |
| lib/screens/cloth_detail_page.dart | 23.83 | cached_network_image, flutter, ../data/clothing_categories.dart, ../models/cloth.dart, ../services/cloth_service.dart | - |
| lib/screens/create_outfit_page.dart | 10.70 | flutter, ../models/cloth.dart, ../services/cloth_service.dart, ../services/outfit_service.dart | - |
| lib/screens/create_post_page.dart | 5.70 | flutter, ../models/outfit.dart, ../services/post_service.dart, ../services/outfit_service.dart | - |
| lib/screens/feed_page.dart | 30.29 | dart:io, cached_network_image, flutter, image_picker, provider, ../models/outfit.dart, ../models/post.dart, ../providers/auth_provider.dart, ../models/user.dart, ../services/api_service.dart, ../services/follow_service.dart, ../services/outfit_service.dart, ../services/post_service.dart, post_detail_page.dart, user_profile_page.dart | - |
| lib/screens/home_screen.dart | 3.29 | flutter, provider, ../providers/auth_provider.dart, closet_page.dart, outfits_page.dart, feed_page.dart, recommend_page.dart, moderation_page.dart, profile_page.dart, login_page.dart | - |
| lib/screens/login_page.dart | 7.08 | flutter, provider, ../providers/auth_provider.dart, register_page.dart, home_screen.dart | - |
| lib/screens/moderation_page.dart | 41.41 | flutter, provider, ../providers/auth_provider.dart, ../services/admin_service.dart, ../models/user.dart | - |
| lib/screens/moderator_panel_page.dart | 12.55 | flutter, provider, ../models/post.dart, ../models/user.dart, ../providers/auth_provider.dart, ../services/auth_service.dart, ../services/post_service.dart | - |
| lib/screens/my_outfit_page.dart | 0.38 | flutter | - |
| lib/screens/outfit_canvas_page.dart | 26.63 | dart:math, dart:typed_data, dart:ui, flutter, cached_network_image, ../models/cloth.dart, ../services/cloth_service.dart, ../services/api_service.dart, outfit_save_page.dart | - |
| lib/screens/outfit_detail_page.dart | 18.98 | cached_network_image, flutter, ../data/outfit_data.dart, ../models/cloth.dart, ../models/outfit.dart, ../services/outfit_service.dart | - |
| lib/screens/outfit_save_page.dart | 8.61 | cached_network_image, flutter, ../data/outfit_data.dart, ../models/cloth.dart, ../services/outfit_service.dart | - |
| lib/screens/outfits_page.dart | 7.82 | cached_network_image, flutter, ../models/outfit.dart, ../services/outfit_service.dart, outfit_canvas_page.dart, outfit_detail_page.dart | - |
| lib/screens/post_detail_page.dart | 27.75 | dart:io, cached_network_image, flutter, image_picker, provider, ../models/post.dart, ../models/comment.dart, ../models/outfit.dart, ../services/post_service.dart, ../services/outfit_service.dart, ../services/api_service.dart, ../providers/auth_provider.dart | - |
| lib/screens/profile_page.dart | 0.50 | flutter, provider, ../providers/auth_provider.dart, user_profile_page.dart | - |
| lib/screens/recommend_page.dart | 9.90 | flutter, provider, ../models/weather.dart, ../providers/auth_provider.dart, ../services/weather_service.dart, profile_page.dart | - |
| lib/screens/register_page.dart | 9.08 | flutter, provider, ../providers/auth_provider.dart, home_screen.dart | - |
| lib/screens/user_profile_page.dart | 23.86 | cached_network_image, flutter, image_picker, provider, ../models/post.dart, ../models/user.dart, ../providers/auth_provider.dart, ../services/auth_service.dart, ../services/follow_service.dart, ../services/post_service.dart, login_page.dart, post_detail_page.dart | - |
| lib/services/admin_service.dart | 7.72 | api_service.dart, ../models/user.dart | - |
| lib/services/api_service.dart | 4.56 | dart:convert, http, http_parser, shared_preferences | - |
| lib/services/auth_service.dart | 4.45 | ../models/user.dart, ../models/auth_response.dart, api_service.dart, shared_preferences | - |
| lib/services/cloth_service.dart | 5.78 | ../models/cloth.dart, ../models/auth_response.dart, api_service.dart | - |
| lib/services/follow_service.dart | 1.59 | ../models/user.dart, api_service.dart | - |
| lib/services/outfit_service.dart | 2.77 | ../models/outfit.dart, ../models/auth_response.dart, api_service.dart | - |
| lib/services/post_service.dart | 4.19 | ../models/post.dart, ../models/comment.dart, ../models/auth_response.dart, api_service.dart | - |
| lib/services/weather_service.dart | 3.65 | geolocator, ../models/weather.dart, api_service.dart | - |
