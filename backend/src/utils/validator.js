const Joi = require('joi');

/**
 * Validation Schemas
 */

const registerSchema = Joi.object({
  nik: Joi.string().length(16).pattern(/^[0-9]+$/).required()
    .messages({
      'string.length': 'NIK harus 16 digit',
      'string.pattern.base': 'NIK harus berupa angka',
      'any.required': 'NIK wajib diisi'
    }),
  nama_lengkap: Joi.string().min(3).max(100).required()
    .messages({
      'string.min': 'Nama lengkap minimal 3 karakter',
      'string.max': 'Nama lengkap maksimal 100 karakter',
      'any.required': 'Nama lengkap wajib diisi'
    }),
  nama_panggilan: Joi.string().min(2).max(50).required()
    .messages({
      'string.min': 'Nama panggilan minimal 2 karakter',
      'string.max': 'Nama panggilan maksimal 50 karakter',
      'any.required': 'Nama panggilan wajib diisi'
    }),
  kata_sandi: Joi.string().min(6).required()
    .messages({
      'string.min': 'Password minimal 6 karakter',
      'any.required': 'Password wajib diisi'
    }),
  jenis_kelamin: Joi.string().valid('L', 'P').required()
    .messages({
      'any.only': 'Jenis kelamin harus L atau P',
      'any.required': 'Jenis kelamin wajib diisi'
    }),
  tanggal_lahir: Joi.date().max('now').required()
    .messages({
      'date.max': 'Tanggal lahir tidak valid',
      'any.required': 'Tanggal lahir wajib diisi'
    }),
  alamat_lengkap: Joi.string().min(10).required()
    .messages({
      'string.min': 'Alamat minimal 10 karakter',
      'any.required': 'Alamat lengkap wajib diisi'
    }),
  kota: Joi.string().min(3).max(50).required()
    .messages({
      'string.min': 'Kota minimal 3 karakter',
      'any.required': 'Kota wajib diisi'
    }),
  bio: Joi.string().max(500).allow('', null).optional()
});

const loginSchema = Joi.object({
  nik: Joi.string().length(16).required()
    .messages({
      'string.length': 'NIK harus 16 digit',
      'any.required': 'NIK wajib diisi'
    }),
  kata_sandi: Joi.string().required()
    .messages({
      'any.required': 'Password wajib diisi'
    })
});

const updateProfileSchema = Joi.object({
  nama_lengkap: Joi.string().min(3).max(100).optional(),
  nama_panggilan: Joi.string().min(2).max(50).optional(),
  jenis_kelamin: Joi.string().valid('L', 'P').optional(),
  tanggal_lahir: Joi.date().max('now').optional(),
  alamat_lengkap: Joi.string().min(10).optional(),
  kota: Joi.string().min(3).max(50).optional(),
  bio: Joi.string().max(500).allow('', null).optional(),
  // Detail pengguna
  pekerjaan: Joi.string().max(50).allow('', null).optional(),
  nama_instansi: Joi.string().max(100).allow('', null).optional(),
  pendidikan_terakhir: Joi.string().max(50).allow('', null).optional(),
  keahlian_khusus: Joi.string().allow('', null).optional(),
  preferensi_lokasi: Joi.string().valid('online', 'offline', 'keduanya').optional(),
  zona_waktu: Joi.string().max(50).optional(),
  bahasa: Joi.string().max(100).optional()
});

const changePasswordSchema = Joi.object({
  kata_sandi_lama: Joi.string().required()
    .messages({
      'any.required': 'Password lama wajib diisi'
    }),
  kata_sandi_baru: Joi.string().min(6).required()
    .messages({
      'string.min': 'Password baru minimal 6 karakter',
      'any.required': 'Password baru wajib diisi'
    }),
  konfirmasi_kata_sandi: Joi.string().valid(Joi.ref('kata_sandi_baru')).required()
    .messages({
      'any.only': 'Konfirmasi password tidak cocok',
      'any.required': 'Konfirmasi password wajib diisi'
    })
});

const addSkillSchema = Joi.object({
  nama_keahlian: Joi.string().min(3).max(100).required()
    .messages({
      'string.min': 'Nama keahlian minimal 3 karakter',
      'string.max': 'Nama keahlian maksimal 100 karakter',
      'any.required': 'Nama keahlian wajib diisi'
    }),
  id_kategori: Joi.number().integer().positive().required()
    .messages({
      'number.base': 'ID kategori harus berupa angka',
      'any.required': 'Kategori wajib dipilih'
    }),
  tipe: Joi.string().valid('dikuasai', 'dicari').required()
    .messages({
      'any.only': 'Tipe harus dikuasai atau dicari',
      'any.required': 'Tipe wajib diisi'
    }),
  tingkat: Joi.string().valid('pemula', 'menengah', 'mahir', 'ahli').optional(),
  pengalaman: Joi.string().max(50).allow('', null).optional(),
  deskripsi: Joi.string().max(1000).allow('', null).optional(),
  harga_per_jam: Joi.number().integer().min(1).optional()
    .messages({
      'number.min': 'Harga minimal 1 skillcoin'
    }),
  link_portofolio: Joi.string().max(255).allow('', null).optional()
    .messages({
      // Removed uri restriction
    }),
  tanggal_berakhir: Joi.date().allow(null).optional()
    .messages({
      'date.base': 'Tanggal berakhir harus berupa tanggal yang valid'
    })
});

const updateSkillSchema = Joi.object({
  nama_keahlian: Joi.string().min(3).max(100).optional(),
  id_kategori: Joi.number().integer().positive().optional(),
  tingkat: Joi.string().valid('pemula', 'menengah', 'mahir', 'ahli').optional(),
  pengalaman: Joi.string().max(50).allow('', null).optional(),
  deskripsi: Joi.string().max(1000).allow('', null).optional(),
  harga_per_jam: Joi.number().integer().min(1).optional(),
  link_portofolio: Joi.string().max(255).allow('', null).optional()
});

/**
 * Validate request data
 */
const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    
    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path[0],
        message: detail.message
      }));
      
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors
      });
    }
    
    next();
  };
};

module.exports = {
  validate,
  registerSchema,
  loginSchema,
  updateProfileSchema,
  changePasswordSchema,
  addSkillSchema,
  updateSkillSchema
};
