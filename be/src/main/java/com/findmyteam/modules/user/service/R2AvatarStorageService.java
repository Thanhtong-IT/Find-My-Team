package com.findmyteam.modules.user.service;

import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.modules.user.dto.AvatarUploadUrlResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;

import java.net.URI;
import java.time.Duration;
import java.util.Locale;
import java.util.UUID;

@Service
public class R2AvatarStorageService {

    private final String endpoint;
    private final String region;
    private final String accessKeyId;
    private final String secretAccessKey;
    private final String bucket;
    private final String publicBaseUrl;
    private final long presignTtlSeconds;

    public R2AvatarStorageService(
        @Value("${storage.r2.endpoint:}") String endpoint,
        @Value("${storage.r2.region:auto}") String region,
        @Value("${storage.r2.access-key-id:}") String accessKeyId,
        @Value("${storage.r2.secret-access-key:}") String secretAccessKey,
        @Value("${storage.r2.bucket:}") String bucket,
        @Value("${storage.r2.public-base-url:}") String publicBaseUrl,
        @Value("${storage.r2.presign-ttl-seconds:300}") long presignTtlSeconds
    ) {
        this.endpoint = endpoint == null ? "" : endpoint.trim();
        this.region = region == null ? "" : region.trim();
        this.accessKeyId = accessKeyId == null ? "" : accessKeyId.trim();
        this.secretAccessKey = secretAccessKey == null ? "" : secretAccessKey.trim();
        this.bucket = bucket == null ? "" : bucket.trim();
        this.publicBaseUrl = publicBaseUrl == null ? "" : publicBaseUrl.trim();
        this.presignTtlSeconds = presignTtlSeconds;
    }

    public AvatarUploadUrlResponse createAvatarUploadUrl(UUID userId, String contentType) {
        ensureConfigured();

        String normalizedContentType = normalizeContentType(contentType);
        String extension = resolveExtension(normalizedContentType);
        String objectKey = "avatars/" + userId + "/" + UUID.randomUUID() + "." + extension;
        String publicUrl = buildPublicUrl(objectKey);

        try (S3Presigner presigner = createPresigner()) {
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucket)
                .key(objectKey)
                .contentType(normalizedContentType)
                .build();

            PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofSeconds(presignTtlSeconds))
                .putObjectRequest(putObjectRequest)
                .build();

            PresignedPutObjectRequest presignedRequest = presigner.presignPutObject(presignRequest);
            return new AvatarUploadUrlResponse(
                presignedRequest.url().toString(),
                publicUrl,
                objectKey,
                presignTtlSeconds
            );
        }
    }

    private S3Presigner createPresigner() {
        return S3Presigner.builder()
            .region(Region.of(region))
            .endpointOverride(createUri(endpoint, "R2 endpoint"))
            .credentialsProvider(StaticCredentialsProvider.create(
                AwsBasicCredentials.create(accessKeyId, secretAccessKey)
            ))
            .serviceConfiguration(S3Configuration.builder()
                .pathStyleAccessEnabled(true)
                .build())
            .build();
    }

    private void ensureConfigured() {
        if (endpoint.isBlank() || region.isBlank() || accessKeyId.isBlank() || secretAccessKey.isBlank() || bucket.isBlank() || publicBaseUrl.isBlank()) {
            throw new BusinessException("Cấu hình R2 chưa sẵn sàng");
        }
    }

    private URI createUri(String value, String label) {
        if (value.contains("<") || value.contains(">")) {
            throw new BusinessException(label + " khong hop le. Hay thay placeholder bang URL that");
        }

        try {
            URI uri = URI.create(value);
            if (uri.getScheme() == null || uri.getHost() == null) {
                throw new BusinessException(label + " khong hop le");
            }
            return uri;
        } catch (IllegalArgumentException ex) {
            throw new BusinessException(label + " khong hop le");
        }
    }

    private String normalizeContentType(String contentType) {
        if (contentType == null) {
            throw new BusinessException("Content type là bắt buộc");
        }

        String normalized = contentType.trim().toLowerCase(Locale.ROOT);
        return switch (normalized) {
            case "image/jpeg", "image/jpg", "image/pjpeg", "jpg", "jpeg" -> "image/jpeg";
            case "image/png", "png" -> "image/png";
            case "image/webp", "webp" -> "image/webp";
            default -> throw new BusinessException("Chỉ hỗ trợ ảnh jpeg, png hoặc webp");
        };
    }

    private String resolveExtension(String contentType) {
        return switch (contentType) {
            case "image/jpeg" -> "jpg";
            case "image/png" -> "png";
            case "image/webp" -> "webp";
            default -> throw new BusinessException("Chỉ hỗ trợ ảnh jpeg, png hoặc webp");
        };
    }

    private String buildPublicUrl(String objectKey) {
        return trimTrailingSlash(createUri(publicBaseUrl, "R2 public base URL").toString()) + "/" + objectKey;
    }

    private String trimTrailingSlash(String value) {
        if (value.endsWith("/")) {
            return value.substring(0, value.length() - 1);
        }
        return value;
    }
}
