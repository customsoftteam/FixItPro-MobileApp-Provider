const streamifier = require('streamifier');
const cloudinary = require('../config/cloudinary');

const uploadFileToCloudinary = (fileBuffer, folder, resourceType = 'auto') =>
  new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: resourceType,
      },
      (error, result) => {
        if (error) {
          reject(error);
          return;
        }
        resolve(result.secure_url);
      }
    );

    streamifier.createReadStream(fileBuffer).pipe(uploadStream);
  });

const uploadImageToCloudinary = (fileBuffer, folder) =>
  uploadFileToCloudinary(fileBuffer, folder, 'image');

module.exports = {
  uploadImageToCloudinary,
  uploadFileToCloudinary,
};
