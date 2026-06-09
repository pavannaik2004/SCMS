const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Path to the local Storage directory
const storageDir = path.join(__dirname, '../../Storage');
if (!fs.existsSync(storageDir)) {
  fs.mkdirSync(storageDir, { recursive: true });
}

// Disk storage engine configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, storageDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, `${file.fieldname}-${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

// File filter restricting types to images and videos
const fileFilter = (req, file, cb) => {
  const allowedExtensions = /jpeg|jpg|png|webp|gif|mp4|mov|avi|mkv|quicktime/;
  const extname = allowedExtensions.test(path.extname(file.originalname).toLowerCase());
  const isImage = file.mimetype.startsWith('image/');
  const isVideo = file.mimetype.startsWith('video/');

  if (extname && (isImage || isVideo)) {
    return cb(null, true);
  }
  
  cb(new Error('Error: Only image and video files are permitted.'));
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB hard limit for parser (specific sizes checked in routes)
  }
});

module.exports = upload;
