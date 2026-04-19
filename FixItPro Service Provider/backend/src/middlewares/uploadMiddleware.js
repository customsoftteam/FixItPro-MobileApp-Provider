const multer = require('multer');
const ApiError = require('../utils/apiError');

const storage = multer.memoryStorage();

const imageFileFilter = (req, file, cb) => {
  if (!file.mimetype.startsWith('image/')) {
    cb(new ApiError(400, 'Only image files are allowed'));
    return;
  }
  cb(null, true);
};

const serviceDocumentFileFilter = (req, file, cb) => {
  const isImage = file.mimetype.startsWith('image/');
  const isPdf = file.mimetype === 'application/pdf';

  if (!isImage && !isPdf) {
    cb(new ApiError(400, 'Only image or PDF files are allowed'));
    return;
  }
  cb(null, true);
};

const imageUpload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: imageFileFilter,
});

const serviceDocumentUpload = multer({
  storage,
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: serviceDocumentFileFilter,
});

const uploadDocuments = imageUpload.fields([
  { name: 'aadharFront', maxCount: 1 },
  { name: 'aadharBack', maxCount: 1 },
  { name: 'panImage', maxCount: 1 },
]);

const uploadProfileImage = imageUpload.single('profileImage');
const uploadServiceDocuments = serviceDocumentUpload.array('documents', 10);

module.exports = { uploadDocuments, uploadProfileImage, uploadServiceDocuments };
