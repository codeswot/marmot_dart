use mdk_core::encrypted_media::MediaReference;

use crate::api::error::MarmotError;
use crate::convert::group_id_from_hex;
use crate::state;

pub struct EncryptedMediaOutput {
    pub encrypted_data: Vec<u8>,
    pub original_hash: Vec<u8>,
    pub encrypted_hash: Vec<u8>,
    pub mime_type: String,
    pub filename: String,
    pub original_size: u64,
    pub encrypted_size: u64,
    pub nonce: Vec<u8>,
    pub blurhash: Option<String>,
    pub thumbhash: Option<String>,
    pub dimensions_width: Option<u32>,
    pub dimensions_height: Option<u32>,
}

pub struct MediaRefInput {
    pub url: String,
    pub original_hash: Vec<u8>,
    pub mime_type: String,
    pub filename: String,
    pub scheme_version: String,
    pub nonce: Vec<u8>,
}

pub fn encrypt_media(
    db_path: String,
    group_id: String,
    data: Vec<u8>,
    mime_type: String,
    filename: String,
) -> Result<EncryptedMediaOutput, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    state::with_state(&db_path, |s| {
        let manager = s.mdk.media_manager(gid);
        let upload = manager
            .encrypt_for_upload(&data, &mime_type, &filename)
            .map_err(|e| MarmotError::Media(e.to_string()))?;
        Ok(EncryptedMediaOutput {
            encrypted_data: upload.encrypted_data,
            original_hash: upload.original_hash.to_vec(),
            encrypted_hash: upload.encrypted_hash.to_vec(),
            mime_type: upload.mime_type,
            filename: upload.filename,
            original_size: upload.original_size,
            encrypted_size: upload.encrypted_size,
            nonce: upload.nonce.to_vec(),
            blurhash: upload.blurhash,
            thumbhash: upload.thumbhash,
            dimensions_width: upload.dimensions.map(|d| d.0),
            dimensions_height: upload.dimensions.map(|d| d.1),
        })
    })
}

pub fn decrypt_media(
    db_path: String,
    group_id: String,
    encrypted_data: Vec<u8>,
    media_ref: MediaRefInput,
) -> Result<Vec<u8>, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    state::with_state(&db_path, |s| {
        let manager = s.mdk.media_manager(gid);
        let original_hash: [u8; 32] = media_ref
            .original_hash
            .as_slice()
            .try_into()
            .map_err(|_| MarmotError::Media("invalid original_hash length".to_string()))?;
        let nonce: [u8; 12] = media_ref
            .nonce
            .as_slice()
            .try_into()
            .map_err(|_| MarmotError::Media("invalid nonce length".to_string()))?;
        let reference = MediaReference {
            url: media_ref.url,
            original_hash,
            mime_type: media_ref.mime_type,
            filename: media_ref.filename,
            dimensions: None,
            scheme_version: media_ref.scheme_version,
            nonce,
        };
        manager
            .decrypt_from_download(&encrypted_data, &reference)
            .map_err(|e| MarmotError::Media(e.to_string()))
    })
}
