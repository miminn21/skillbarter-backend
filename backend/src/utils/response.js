/**
 * Standard API Response Helper
 */

const success = (res, message, data = null, statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data
  });
};

const error = (res, message, statusCode = 500, errors = null) => {
  return res.status(statusCode).json({
    success: false,
    message,
    errors
  });
};

const validationError = (res, errors) => {
  return res.status(400).json({
    success: false,
    message: 'Validation error',
    errors
  });
};

const unauthorized = (res, message = 'Unauthorized') => {
  return res.status(401).json({
    success: false,
    message
  });
};

const notFound = (res, message = 'Resource not found') => {
  return res.status(404).json({
    success: false,
    message
  });
};

module.exports = {
  success,
  error,
  validationError,
  unauthorized,
  notFound
};
