package com.findmyteam.modules.user.service;

import com.findmyteam.common.exception.BusinessException;
import com.findmyteam.modules.game.entity.Game;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

import java.util.Arrays;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

@Service
public class RiotApiService {

    private final RestClient restClient;
    private final String apiKey;

    public RiotApiService(RestClient.Builder restClientBuilder,
                          @Value("${riot.api-key:}") String apiKey) {
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.restClient = restClientBuilder
            .defaultHeader("X-Riot-Token", this.apiKey)
            .build();
    }

    public boolean supports(Game game) {
        return resolveGameType(game) != null;
    }

    public RiotVerificationData verify(Game game, String riotGameName, String riotTagLine, String region) {
        ensureConfigured();
        RiotGameType gameType = requireSupportedGame(game);
        String normalizedRegion = normalizeRegion(gameType, region);
        String accountRegion = toAccountRegion(normalizedRegion);

        RiotAccountResponse account = fetchRiotAccountByRiotId(accountRegion, riotGameName, riotTagLine);
        String verifiedRank = fetchVerifiedRank(gameType, normalizedRegion, account.puuid());

        return new RiotVerificationData(
            account.gameName() != null ? account.gameName() : riotGameName,
            account.tagLine() != null ? account.tagLine() : riotTagLine,
            account.puuid(),
            normalizedRegion,
            verifiedRank,
            verifiedRank != null
        );
    }

    public RiotVerificationData refresh(Game game, String puuid, String region, String riotGameName, String riotTagLine) {
        ensureConfigured();
        RiotGameType gameType = requireSupportedGame(game);
        String normalizedRegion = normalizeRegion(gameType, region);
        String accountRegion = toAccountRegion(normalizedRegion);

        RiotAccountResponse account = fetchRiotAccountByPuuid(accountRegion, puuid);
        String verifiedRank = fetchVerifiedRank(gameType, normalizedRegion, puuid);

        return new RiotVerificationData(
            account.gameName() != null ? account.gameName() : riotGameName,
            account.tagLine() != null ? account.tagLine() : riotTagLine,
            puuid,
            normalizedRegion,
            verifiedRank,
            verifiedRank != null
        );
    }

    private void ensureConfigured() {
        if (apiKey.isBlank()) {
            throw new BusinessException("Riot API key chưa được cấu hình");
        }
    }

    private RiotGameType requireSupportedGame(Game game) {
        RiotGameType gameType = resolveGameType(game);
        if (gameType == null) {
            throw new BusinessException("Game này hiện chưa hỗ trợ xác minh Riot");
        }
        return gameType;
    }

    private RiotGameType resolveGameType(Game game) {
        if (game == null || game.getName() == null) {
            return null;
        }

        String normalizedName = normalizeText(game.getName());
        return switch (normalizedName) {
            case "valorant" -> RiotGameType.VALORANT;
            case "lien minh huyen thoai", "league of legends", "lol" -> RiotGameType.LEAGUE_OF_LEGENDS;
            case "dau truong chan ly", "teamfight tactics", "tft" -> RiotGameType.TFT;
            default -> null;
        };
    }

    private String fetchVerifiedRank(RiotGameType gameType, String region, String puuid) {
        return switch (gameType) {
            case LEAGUE_OF_LEGENDS -> fetchLeagueRank(region, puuid);
            case TFT -> fetchTftRank(region, puuid);
            case VALORANT -> fetchValorantRank(region, puuid);
        };
    }

    private RiotAccountResponse fetchRiotAccountByRiotId(String region, String riotGameName, String riotTagLine) {
        try {
            RiotAccountResponse response = restClient.get()
                .uri("https://{region}.api.riotgames.com/riot/account/v1/accounts/by-riot-id/{gameName}/{tagLine}",
                    region, riotGameName, riotTagLine)
                .retrieve()
                .body(RiotAccountResponse.class);

            if (response == null || isBlank(response.puuid())) {
                throw new BusinessException("Không tìm thấy Riot account");
            }
            return response;
        } catch (RestClientResponseException ex) {
            throw mapAccountException(ex);
        } catch (RestClientException ex) {
            throw new BusinessException("Không thể kết nối Riot API lúc này");
        }
    }

    private RiotAccountResponse fetchRiotAccountByPuuid(String region, String puuid) {
        try {
            RiotAccountResponse response = restClient.get()
                .uri("https://{region}.api.riotgames.com/riot/account/v1/accounts/by-puuid/{puuid}", region, puuid)
                .retrieve()
                .body(RiotAccountResponse.class);

            if (response == null || isBlank(response.puuid())) {
                throw new BusinessException("Không tìm thấy Riot account đã liên kết");
            }
            return response;
        } catch (RestClientResponseException ex) {
            throw mapAccountException(ex);
        } catch (RestClientException ex) {
            throw new BusinessException("Không thể kết nối Riot API lúc này");
        }
    }

    private String fetchLeagueRank(String region, String puuid) {
        try {
            LeagueEntryResponse[] entries = restClient.get()
                .uri("https://{region}.api.riotgames.com/lol/league/v4/entries/by-puuid/{puuid}", region, puuid)
                .retrieve()
                .body(LeagueEntryResponse[].class);
            return pickRank(entries, "RANKED_SOLO_5x5");
        } catch (RestClientResponseException ex) {
            throw mapRankException(ex);
        } catch (RestClientException ex) {
            throw new BusinessException("Không thể đồng bộ rank Riot lúc này");
        }
    }

    private String fetchTftRank(String region, String puuid) {
        try {
            LeagueEntryResponse[] entries = restClient.get()
                .uri("https://{region}.api.riotgames.com/tft/league/v1/entries/by-puuid/{puuid}", region, puuid)
                .retrieve()
                .body(LeagueEntryResponse[].class);
            return pickRank(entries, "RANKED_TFT");
        } catch (RestClientResponseException ex) {
            throw mapRankException(ex);
        } catch (RestClientException ex) {
            throw new BusinessException("Không thể đồng bộ rank Riot lúc này");
        }
    }

    private String fetchValorantRank(String region, String puuid) {
        try {
            ValorantRankResponse response = restClient.get()
                .uri("https://{region}.api.riotgames.com/val/ranked/v1/by-puuid/{puuid}", region, puuid)
                .retrieve()
                .body(ValorantRankResponse.class);
            return response == null ? null : firstNonBlank(response.tierName(), response.currentTierPatched());
        } catch (RestClientResponseException ex) {
            if (ex.getStatusCode().value() == 404) {
                return null;
            }
            throw mapRankException(ex);
        } catch (RestClientException ex) {
            throw new BusinessException("Không thể đồng bộ rank Riot lúc này");
        }
    }

    private String pickRank(LeagueEntryResponse[] entries, String preferredQueueType) {
        if (entries == null || entries.length == 0) {
            return null;
        }

        LeagueEntryResponse preferred = Arrays.stream(entries)
            .filter(Objects::nonNull)
            .filter(entry -> preferredQueueType.equalsIgnoreCase(entry.queueType()))
            .findFirst()
            .orElseGet(() -> Arrays.stream(entries).filter(Objects::nonNull).findFirst().orElse(null));

        if (preferred == null || isBlank(preferred.tier())) {
            return null;
        }

        return firstNonBlank(
            formatRank(preferred.tier(), preferred.rank()),
            preferred.tier()
        );
    }

    private String formatRank(String tier, String division) {
        if (isBlank(tier)) {
            return null;
        }
        if (isBlank(division)) {
            return tier;
        }
        return tier + " " + division;
    }

    private BusinessException mapAccountException(RestClientResponseException ex) {
        return switch (ex.getStatusCode().value()) {
            case 400 -> new BusinessException("Riot ID hoặc region không hợp lệ");
            case 401, 403 -> new BusinessException("Riot API key không hợp lệ hoặc không có quyền truy cập");
            case 404 -> new BusinessException("Không tìm thấy Riot account");
            case 429 -> new BusinessException("Riot API đang giới hạn tần suất, vui lòng thử lại sau");
            default -> new BusinessException("Không thể xác minh Riot account lúc này");
        };
    }

    private BusinessException mapRankException(RestClientResponseException ex) {
        return switch (ex.getStatusCode().value()) {
            case 400 -> new BusinessException("Region Riot không hợp lệ cho game này");
            case 401, 403 -> new BusinessException("Riot API key không hợp lệ hoặc không có quyền truy cập");
            case 404 -> new BusinessException("Không tìm thấy dữ liệu rank Riot cho tài khoản này");
            case 429 -> new BusinessException("Riot API đang giới hạn tần suất, vui lòng thử lại sau");
            default -> new BusinessException("Không thể đồng bộ rank Riot lúc này");
        };
    }

    private String normalizeRegion(RiotGameType gameType, String region) {
        if (isBlank(region)) {
            throw new BusinessException("Region Riot là bắt buộc");
        }

        String normalized = region.trim().toLowerCase(Locale.ROOT);
        return switch (gameType) {
            case LEAGUE_OF_LEGENDS, TFT -> normalizeLeagueRegion(normalized);
            case VALORANT -> normalizeValorantRegion(normalized);
        };
    }

    private String normalizeLeagueRegion(String region) {
        Map<String, String> aliases = Map.ofEntries(
            Map.entry("vn", "vn2"),
            Map.entry("vn2", "vn2"),
            Map.entry("kr", "kr"),
            Map.entry("jp", "jp1"),
            Map.entry("jp1", "jp1"),
            Map.entry("na", "na1"),
            Map.entry("na1", "na1"),
            Map.entry("br", "br1"),
            Map.entry("br1", "br1"),
            Map.entry("euw", "euw1"),
            Map.entry("euw1", "euw1"),
            Map.entry("eune", "eun1"),
            Map.entry("eun1", "eun1"),
            Map.entry("lan", "la1"),
            Map.entry("la1", "la1"),
            Map.entry("las", "la2"),
            Map.entry("la2", "la2"),
            Map.entry("oce", "oc1"),
            Map.entry("oc1", "oc1"),
            Map.entry("tr", "tr1"),
            Map.entry("tr1", "tr1"),
            Map.entry("ru", "ru"),
            Map.entry("ph", "ph2"),
            Map.entry("ph2", "ph2"),
            Map.entry("sg", "sg2"),
            Map.entry("sg2", "sg2"),
            Map.entry("th", "th2"),
            Map.entry("th2", "th2"),
            Map.entry("tw", "tw2"),
            Map.entry("tw2", "tw2")
        );

        String normalized = aliases.get(region);
        if (normalized == null) {
            throw new BusinessException("Region Riot không hợp lệ cho LoL/TFT");
        }
        return normalized;
    }

    private String normalizeValorantRegion(String region) {
        return switch (region) {
            case "ap", "kr", "na", "latam", "br", "eu" -> region;
            default -> throw new BusinessException("Region Riot không hợp lệ cho Valorant");
        };
    }

    private String toAccountRegion(String region) {
        return switch (region) {
            case "vn2", "kr", "jp1", "ph2", "sg2", "th2", "tw2", "ap" -> "asia";
            case "na1", "br1", "la1", "la2", "na", "br", "latam" -> "americas";
            case "euw1", "eun1", "tr1", "ru", "eu" -> "europe";
            case "oc1" -> "sea";
            default -> throw new BusinessException("Không xác định được cluster Riot cho region đã chọn");
        };
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (!isBlank(value)) {
                return value;
            }
        }
        return null;
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private String normalizeText(String value) {
        Map<Character, Character> vietnameseMap = Map.ofEntries(
            Map.entry('à', 'a'), Map.entry('á', 'a'), Map.entry('ả', 'a'), Map.entry('ã', 'a'), Map.entry('ạ', 'a'),
            Map.entry('ă', 'a'), Map.entry('ằ', 'a'), Map.entry('ắ', 'a'), Map.entry('ẳ', 'a'), Map.entry('ẵ', 'a'), Map.entry('ặ', 'a'),
            Map.entry('â', 'a'), Map.entry('ầ', 'a'), Map.entry('ấ', 'a'), Map.entry('ẩ', 'a'), Map.entry('ẫ', 'a'), Map.entry('ậ', 'a'),
            Map.entry('è', 'e'), Map.entry('é', 'e'), Map.entry('ẻ', 'e'), Map.entry('ẽ', 'e'), Map.entry('ẹ', 'e'),
            Map.entry('ê', 'e'), Map.entry('ề', 'e'), Map.entry('ế', 'e'), Map.entry('ể', 'e'), Map.entry('ễ', 'e'), Map.entry('ệ', 'e'),
            Map.entry('ì', 'i'), Map.entry('í', 'i'), Map.entry('ỉ', 'i'), Map.entry('ĩ', 'i'), Map.entry('ị', 'i'),
            Map.entry('ò', 'o'), Map.entry('ó', 'o'), Map.entry('ỏ', 'o'), Map.entry('õ', 'o'), Map.entry('ọ', 'o'),
            Map.entry('ô', 'o'), Map.entry('ồ', 'o'), Map.entry('ố', 'o'), Map.entry('ổ', 'o'), Map.entry('ỗ', 'o'), Map.entry('ộ', 'o'),
            Map.entry('ơ', 'o'), Map.entry('ờ', 'o'), Map.entry('ớ', 'o'), Map.entry('ở', 'o'), Map.entry('ỡ', 'o'), Map.entry('ợ', 'o'),
            Map.entry('ù', 'u'), Map.entry('ú', 'u'), Map.entry('ủ', 'u'), Map.entry('ũ', 'u'), Map.entry('ụ', 'u'),
            Map.entry('ư', 'u'), Map.entry('ừ', 'u'), Map.entry('ứ', 'u'), Map.entry('ử', 'u'), Map.entry('ữ', 'u'), Map.entry('ự', 'u'),
            Map.entry('ỳ', 'y'), Map.entry('ý', 'y'), Map.entry('ỷ', 'y'), Map.entry('ỹ', 'y'), Map.entry('ỵ', 'y'),
            Map.entry('đ', 'd')
        );

        StringBuilder normalized = new StringBuilder();
        for (char character : value.trim().toLowerCase(Locale.ROOT).toCharArray()) {
            normalized.append(vietnameseMap.getOrDefault(character, character));
        }

        return normalized.toString()
            .replaceAll("[^a-z0-9]+", " ")
            .trim();
    }

    private enum RiotGameType {
        LEAGUE_OF_LEGENDS,
        TFT,
        VALORANT
    }

    public record RiotVerificationData(
        String riotGameName,
        String riotTagLine,
        String puuid,
        String region,
        String verifiedRank,
        boolean rankVerified
    ) {}

    private record RiotAccountResponse(String puuid, String gameName, String tagLine) {}

    private record LeagueEntryResponse(String queueType, String tier, String rank) {}

    private record ValorantRankResponse(String tierName, String currentTierPatched) {}
}
