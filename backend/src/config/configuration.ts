export default () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  database: { url: process.env.DATABASE_URL },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    refreshExpiryDays: parseInt(process.env.REFRESH_TOKEN_EXPIRES_DAYS, 10) || 7,
  },
  cloudinary: {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME,
    apiKey: process.env.CLOUDINARY_API_KEY,
    apiSecret: process.env.CLOUDINARY_API_SECRET,
  },
  aiService: {
    url: process.env.AI_SERVICE_URL,
    key: process.env.AI_SERVICE_KEY,
  },
  googleMaps: {
    apiKey: process.env.GOOGLE_MAPS_API_KEY,
  },
});
