package com.college.notice.shared.config;

import java.util.ArrayList;
import java.util.List;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Allowed origin patterns for browser clients (e.g. Flutter web). Use
 * {@code http://localhost:*} style patterns; add LAN patterns only when needed for local testing.
 */
@ConfigurationProperties(prefix = "app.cors")
@Getter
@Setter
public class CorsProperties {

    private List<String> allowedOriginPatterns = new ArrayList<>(
            List.of("http://localhost:*", "http://127.0.0.1:*")
    );
}
